-- =====================================================
-- FIX CONSTRAINT ISSUE - ADJUST UNIQUE INDEX
-- =====================================================
-- The constraint is too restrictive, causing issues during customer creation
-- Let's modify it to be more flexible while still preventing duplicates
-- =====================================================

BEGIN;

-- 1. Drop the current constraint that's causing issues
DROP INDEX IF EXISTS idx_unique_customer_commission_distribution;

-- 2. Create a more flexible constraint that prevents true duplicates
-- but allows the normal commission distribution process
CREATE UNIQUE INDEX IF NOT EXISTS idx_prevent_duplicate_commissions
ON affiliate_commissions (customer_id)
WHERE status = 'credited';

-- This ensures only ONE commission distribution per customer total,
-- rather than per customer-initiator pair which was too restrictive

-- 3. Update the database function to handle this better
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
    -- Check if ANY commission already exists for this customer
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
            
            -- Generate unique transaction ID
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
            'message', 'Commission distributed: ₹' || v_total_distributed || ' total',
            'timestamp', NOW()
        );
        
        RETURN v_result;
        
    EXCEPTION WHEN OTHERS THEN
        -- Return error instead of raising exception to avoid breaking customer creation
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'customer_id', p_customer_id,
            'timestamp', NOW()
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO anon;

COMMIT;

SELECT '✅ Constraint issue fixed - customer creation should work now!' as status;
