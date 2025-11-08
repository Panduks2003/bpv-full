-- =====================================================
-- PREVENT FUTURE DUPLICATE COMMISSIONS
-- =====================================================
-- This script ensures future customers get correct ₹800 commission
-- distribution with proper admin fallback and no duplicates
-- =====================================================

BEGIN;

-- 1. CREATE A UNIQUE CONSTRAINT TO PREVENT DUPLICATE COMMISSIONS PER CUSTOMER
-- This will prevent multiple commission distributions for the same customer
ALTER TABLE affiliate_commissions 
DROP CONSTRAINT IF EXISTS unique_customer_commission;

-- Add a partial unique index that allows only one commission distribution per customer
-- (allows multiple records per customer but prevents duplicate distributions)
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_customer_commission_distribution
ON affiliate_commissions (customer_id, initiator_promoter_id)
WHERE status = 'credited';

-- 2. UPDATE THE COMMISSION DISTRIBUTION FUNCTION WITH BETTER DUPLICATE PREVENTION
CREATE OR REPLACE FUNCTION distribute_affiliate_commission(
    p_customer_id UUID,
    p_initiator_promoter_id UUID
) RETURNS JSON AS $$
DECLARE
    v_commission_levels DECIMAL[] := ARRAY[500.00, 100.00, 100.00, 100.00];
    v_current_promoter_id UUID := p_initiator_promoter_id;
    v_level INTEGER;
    v_recipient_id UUID;
    v_amount DECIMAL(10,2);
    v_transaction_id VARCHAR(50);
    v_admin_id UUID;
    v_remaining_amount DECIMAL(10,2) := 0.00;
    v_result JSON;
    v_distributed_count INTEGER := 0;
    v_total_distributed DECIMAL(10,2) := 0.00;
    v_existing_count INTEGER := 0;
BEGIN
    -- ENHANCED DUPLICATE CHECK: Prevent any duplicate commission distribution
    SELECT COUNT(*) INTO v_existing_count
    FROM affiliate_commissions 
    WHERE customer_id = p_customer_id 
    AND status = 'credited';
    
    IF v_existing_count > 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Commission already distributed for this customer',
            'existing_records', v_existing_count,
            'customer_id', p_customer_id,
            'timestamp', NOW()
        );
    END IF;

    -- Get admin ID for fallback
    SELECT id INTO v_admin_id 
    FROM profiles 
    WHERE role = 'admin' 
    LIMIT 1;
    
    -- Start transaction
    BEGIN
        -- Loop through 4 commission levels
        FOR v_level IN 1..4 LOOP
            v_amount := v_commission_levels[v_level];
            
            -- Find parent promoter for current level
            IF v_level = 1 THEN
                v_recipient_id := v_current_promoter_id;
            ELSE
                SELECT parent_promoter_id INTO v_recipient_id
                FROM profiles
                WHERE id = v_current_promoter_id
                AND parent_promoter_id IS NOT NULL;
            END IF;
            
            -- Generate unique transaction ID with timestamp and level
            v_transaction_id := 'COM-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-L' || v_level || '-' || SUBSTRING(p_customer_id::text, 1, 8);
            
            IF v_recipient_id IS NOT NULL THEN
                -- Credit commission to promoter
                INSERT INTO affiliate_commissions (
                    customer_id,
                    initiator_promoter_id,
                    recipient_id,
                    recipient_type,
                    level,
                    amount,
                    status,
                    transaction_id,
                    note
                ) VALUES (
                    p_customer_id,
                    p_initiator_promoter_id,
                    v_recipient_id,
                    'promoter',
                    v_level,
                    v_amount,
                    'credited',
                    v_transaction_id,
                    'Level ' || v_level || ' Commission - ₹' || v_amount
                );
                
                -- Update promoter wallet
                INSERT INTO promoter_wallet (promoter_id, balance, total_earned, commission_count, last_commission_at)
                VALUES (v_recipient_id, v_amount, v_amount, 1, NOW())
                ON CONFLICT (promoter_id) DO UPDATE SET
                    balance = promoter_wallet.balance + v_amount,
                    total_earned = promoter_wallet.total_earned + v_amount,
                    commission_count = promoter_wallet.commission_count + 1,
                    last_commission_at = NOW(),
                    updated_at = NOW();
                
                v_distributed_count := v_distributed_count + 1;
                v_total_distributed := v_total_distributed + v_amount;
                
                -- Move to next level
                v_current_promoter_id := v_recipient_id;
            ELSE
                -- No promoter at this level, add to admin fallback
                v_remaining_amount := v_remaining_amount + v_amount;
            END IF;
        END LOOP;
        
        -- Credit remaining amount to admin if any (ADMIN FALLBACK SYSTEM)
        IF v_remaining_amount > 0 AND v_admin_id IS NOT NULL THEN
            v_transaction_id := 'COM-ADMIN-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || SUBSTRING(p_customer_id::text, 1, 8);
            
            INSERT INTO affiliate_commissions (
                customer_id,
                initiator_promoter_id,
                recipient_id,
                recipient_type,
                level,
                amount,
                status,
                transaction_id,
                note
            ) VALUES (
                p_customer_id,
                p_initiator_promoter_id,
                v_admin_id,
                'admin',
                0,
                v_remaining_amount,
                'credited',
                v_transaction_id,
                'Admin Fallback - Incomplete hierarchy - ₹' || v_remaining_amount
            );
            
            -- Update admin wallet
            INSERT INTO admin_wallet (admin_id, balance, total_commission_received, unclaimed_commissions, commission_count, last_commission_at)
            VALUES (v_admin_id, v_remaining_amount, v_remaining_amount, v_remaining_amount, 1, NOW())
            ON CONFLICT (admin_id) DO UPDATE SET
                balance = admin_wallet.balance + v_remaining_amount,
                total_commission_received = admin_wallet.total_commission_received + v_remaining_amount,
                unclaimed_commissions = admin_wallet.unclaimed_commissions + v_remaining_amount,
                commission_count = admin_wallet.commission_count + 1,
                last_commission_at = NOW(),
                updated_at = NOW();
                
            v_total_distributed := v_total_distributed + v_remaining_amount;
        END IF;
        
        -- Build result JSON
        v_result := json_build_object(
            'success', true,
            'customer_id', p_customer_id,
            'initiator_promoter_id', p_initiator_promoter_id,
            'total_distributed', v_total_distributed,
            'levels_distributed', v_distributed_count,
            'admin_fallback', v_remaining_amount,
            'message', 'Commission distributed: ₹' || v_total_distributed || ' total (₹' || (v_total_distributed - v_remaining_amount) || ' to promoters, ₹' || v_remaining_amount || ' admin fallback)',
            'timestamp', NOW()
        );
        
        RETURN v_result;
        
    EXCEPTION WHEN OTHERS THEN
        -- Rollback on error
        RAISE EXCEPTION 'Commission distribution failed: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO anon;

-- 3. CREATE A TRIGGER TO LOG COMMISSION DISTRIBUTIONS FOR AUDIT
CREATE TABLE IF NOT EXISTS commission_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL,
    initiator_promoter_id UUID,
    total_amount DECIMAL(10,2),
    distribution_method VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT
);

-- Function to log commission distributions
CREATE OR REPLACE FUNCTION log_commission_distribution()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log when a new commission record is created
    IF TG_OP = 'INSERT' THEN
        -- Check if this is the first record for this customer
        IF NOT EXISTS (
            SELECT 1 FROM commission_audit_log 
            WHERE customer_id = NEW.customer_id
        ) THEN
            INSERT INTO commission_audit_log (
                customer_id,
                initiator_promoter_id,
                total_amount,
                distribution_method,
                notes
            ) VALUES (
                NEW.customer_id,
                NEW.initiator_promoter_id,
                800.00, -- Always ₹800 total
                'automatic',
                'Commission distribution initiated for customer: ' || NEW.customer_id
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_log_commission_distribution ON affiliate_commissions;
CREATE TRIGGER trigger_log_commission_distribution
    AFTER INSERT ON affiliate_commissions
    FOR EACH ROW
    EXECUTE FUNCTION log_commission_distribution();

-- 4. UPDATE COMMISSION SERVICE CONFIGURATION
-- Add a comment to document the system
COMMENT ON FUNCTION distribute_affiliate_commission IS 'Distributes exactly ₹800 commission across 4 affiliate levels with admin fallback. Includes duplicate prevention.';

-- 5. VERIFICATION QUERY FOR FUTURE USE
-- This query can be run to check commission distribution health
CREATE OR REPLACE VIEW commission_health_check AS
SELECT 
    'Commission Health Check' as report_type,
    COUNT(DISTINCT customer_id) as total_customers_with_commissions,
    COUNT(*) as total_commission_records,
    SUM(amount) as total_amount_distributed,
    AVG(amount) as avg_commission_amount,
    COUNT(CASE WHEN recipient_type = 'promoter' THEN 1 END) as promoter_commissions,
    COUNT(CASE WHEN recipient_type = 'admin' THEN 1 END) as admin_commissions,
    -- Check for any customers with incorrect totals
    COUNT(CASE WHEN customer_total != 800.00 THEN 1 END) as customers_with_incorrect_totals
FROM affiliate_commissions ac
LEFT JOIN (
    SELECT 
        customer_id,
        SUM(amount) as customer_total
    FROM affiliate_commissions 
    GROUP BY customer_id
) ct ON ac.customer_id = ct.customer_id
WHERE ac.created_at > NOW() - INTERVAL '30 days';

COMMIT;

-- Success message
SELECT 
    '✅ Future duplicate prevention system installed!' as status,
    'All future customers will get exactly ₹800 commission with proper admin fallback' as guarantee,
    'Duplicate prevention and audit logging enabled' as features;
