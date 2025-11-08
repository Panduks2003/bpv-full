-- =====================================================
-- COMPLETE COMMISSION FIX - REMOVE ADMIN FALLBACK BUG
-- =====================================================
-- This script completely fixes the commission system
-- and removes incorrect admin fallback commissions
-- =====================================================

BEGIN;

-- 1. REMOVE INCORRECT ADMIN FALLBACK COMMISSIONS
-- Delete admin commissions where all 4 promoter levels exist
DELETE FROM affiliate_commissions 
WHERE recipient_type = 'admin' 
AND customer_id IN (
    SELECT customer_id 
    FROM affiliate_commissions 
    WHERE recipient_type = 'promoter' 
    GROUP BY customer_id 
    HAVING COUNT(DISTINCT level) = 4
);

-- 2. UPDATE ADMIN WALLET TO REMOVE INCORRECT AMOUNTS
UPDATE admin_wallet 
SET balance = (
    SELECT COALESCE(SUM(amount), 0) 
    FROM affiliate_commissions 
    WHERE recipient_type = 'admin'
),
total_earned = (
    SELECT COALESCE(SUM(amount), 0) 
    FROM affiliate_commissions 
    WHERE recipient_type = 'admin'
),
commission_count = (
    SELECT COUNT(*) 
    FROM affiliate_commissions 
    WHERE recipient_type = 'admin'
);

-- 3. DROP AND RECREATE COMMISSION FUNCTION WITH CORRECT LOGIC
DROP FUNCTION IF EXISTS distribute_affiliate_commission(UUID, UUID) CASCADE;

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
    v_hierarchy_complete BOOLEAN := TRUE;
BEGIN
    -- Get admin ID for fallback (only if needed)
    SELECT id INTO v_admin_id 
    FROM profiles 
    WHERE role = 'admin' 
    LIMIT 1;
    
    -- Start transaction
    BEGIN
        -- Loop through 4 commission levels
        FOR v_level IN 1..4 LOOP
            v_amount := v_commission_levels[v_level];
            v_recipient_id := NULL; -- Reset for each level
            
            -- Find recipient for current level
            IF v_level = 1 THEN
                -- Level 1: Direct promoter (initiator)
                v_recipient_id := v_current_promoter_id;
            ELSE
                -- Level 2-4: Find parent promoter
                SELECT parent_promoter_id INTO v_recipient_id
                FROM profiles
                WHERE id = v_current_promoter_id
                AND parent_promoter_id IS NOT NULL
                AND role = 'promoter';
            END IF;
            
            -- Generate unique transaction ID
            v_transaction_id := 'COM-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || v_level;
            
            IF v_recipient_id IS NOT NULL THEN
                -- Verify recipient is still a valid promoter
                IF EXISTS (SELECT 1 FROM profiles WHERE id = v_recipient_id AND role = 'promoter') THEN
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
                        note,
                        created_at
                    ) VALUES (
                        p_customer_id,
                        p_initiator_promoter_id,
                        v_recipient_id,
                        'promoter',
                        v_level,
                        v_amount,
                        'credited',
                        v_transaction_id,
                        'Level ' || v_level || ' commission - ₹' || v_amount,
                        NOW()
                    );
                    
                    -- Update promoter wallet
                    INSERT INTO promoter_wallet (promoter_id, balance, total_earned, commission_count, last_commission_at, created_at, updated_at)
                    VALUES (v_recipient_id, v_amount, v_amount, 1, NOW(), NOW(), NOW())
                    ON CONFLICT (promoter_id) DO UPDATE SET
                        balance = promoter_wallet.balance + v_amount,
                        total_earned = promoter_wallet.total_earned + v_amount,
                        commission_count = promoter_wallet.commission_count + 1,
                        last_commission_at = NOW(),
                        updated_at = NOW();
                    
                    v_distributed_count := v_distributed_count + 1;
                    v_total_distributed := v_total_distributed + v_amount;
                    
                    -- Move to next level (current recipient becomes the promoter to check)
                    v_current_promoter_id := v_recipient_id;
                ELSE
                    -- Recipient is not a valid promoter
                    v_hierarchy_complete := FALSE;
                    v_remaining_amount := v_remaining_amount + v_amount;
                END IF;
            ELSE
                -- No promoter at this level
                v_hierarchy_complete := FALSE;
                v_remaining_amount := v_remaining_amount + v_amount;
            END IF;
        END LOOP;
        
        -- ADMIN COMMISSION: Only give admin commission if hierarchy is incomplete
        -- If all 4 levels were distributed, NO admin commission
        IF NOT v_hierarchy_complete AND v_remaining_amount > 0 AND v_admin_id IS NOT NULL THEN
            v_transaction_id := 'COM-ADMIN-' || EXTRACT(EPOCH FROM NOW())::BIGINT;
            
            INSERT INTO affiliate_commissions (
                customer_id,
                initiator_promoter_id,
                recipient_id,
                recipient_type,
                level,
                amount,
                status,
                transaction_id,
                note,
                created_at
            ) VALUES (
                p_customer_id,
                p_initiator_promoter_id,
                v_admin_id,
                'admin',
                0, -- Admin level
                v_remaining_amount,
                'credited',
                v_transaction_id,
                'Admin Fallback - Incomplete hierarchy - ₹' || v_remaining_amount,
                NOW()
            );
            
            -- Update admin wallet
            INSERT INTO admin_wallet (balance, total_earned, commission_count, last_commission_at, created_at, updated_at)
            VALUES (v_remaining_amount, v_remaining_amount, 1, NOW(), NOW(), NOW())
            ON CONFLICT DO UPDATE SET
                balance = admin_wallet.balance + v_remaining_amount,
                total_earned = admin_wallet.total_earned + v_remaining_amount,
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
            'hierarchy_complete', v_hierarchy_complete,
            'admin_fallback', CASE WHEN v_hierarchy_complete THEN 0 ELSE v_remaining_amount END,
            'message', CASE 
                WHEN v_hierarchy_complete THEN 'Complete hierarchy - ₹800 distributed to 4 promoter levels, no admin commission'
                ELSE 'Incomplete hierarchy - ₹' || (v_total_distributed - v_remaining_amount) || ' to promoters, ₹' || v_remaining_amount || ' to admin'
            END,
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

-- Add comment
COMMENT ON FUNCTION distribute_affiliate_commission IS 'Distributes ₹800 commission across 4 affiliate levels. Admin gets commission ONLY when hierarchy is incomplete.';

-- 4. VERIFICATION QUERY
-- Check commission distribution for recent customers
SELECT 
    'Commission Verification' as check_type,
    customer_id,
    recipient_type,
    level,
    amount,
    note
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY customer_id, level;

COMMIT;
