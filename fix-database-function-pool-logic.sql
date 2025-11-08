-- =====================================================
-- FIX DATABASE FUNCTION - USE POOL LOGIC (₹800 MAX)
-- =====================================================
-- The database function is still using old logic giving ₹800 + ₹200
-- Fix it to use pool-based logic where total never exceeds ₹800
-- =====================================================

BEGIN;

-- Update the database function with correct pool logic
CREATE OR REPLACE FUNCTION distribute_affiliate_commission(
    p_customer_id UUID,
    p_initiator_promoter_id UUID
) RETURNS JSON AS $$
DECLARE
    v_total_pool DECIMAL(10,2) := 800.00;  -- TOTAL POOL = ₹800 (NOT ₹800 + extra)
    v_commission_levels DECIMAL[] := ARRAY[500.00, 100.00, 100.00, 100.00];
    v_current_promoter_id UUID := p_initiator_promoter_id;
    v_level INTEGER;
    v_recipient_id UUID;
    v_amount DECIMAL(10,2);
    v_transaction_id VARCHAR(50);
    v_admin_id UUID;
    v_remaining_pool DECIMAL(10,2) := 800.00;  -- Start with full pool
    v_result JSON;
    v_distributed_count INTEGER := 0;
    v_total_distributed DECIMAL(10,2) := 0.00;
    v_existing_count INTEGER := 0;
BEGIN
    -- Check for existing commissions
    SELECT COUNT(*) INTO v_existing_count
    FROM affiliate_commissions 
    WHERE customer_id = p_customer_id 
    AND status = 'credited';
    
    IF v_existing_count > 0 THEN
        RETURN json_build_object(
            'success', true,
            'skipped', true,
            'message', 'Commission already distributed for this customer',
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
    
    -- Start commission distribution from ₹800 pool
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
                -- Credit commission to promoter (DEDUCT FROM POOL)
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
                v_remaining_pool := v_remaining_pool - v_amount;  -- DEDUCT FROM POOL
                
                -- Move to next level
                v_current_promoter_id := v_recipient_id;
            END IF;
            -- If no promoter, amount stays in remaining pool for admin
        END LOOP;
        
        -- Give admin ONLY the remaining amount from ₹800 pool (NOT EXTRA)
        IF v_remaining_pool > 0 AND v_admin_id IS NOT NULL THEN
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
                v_remaining_pool,
                'credited',
                v_transaction_id,
                'Admin Fallback - Remaining from ₹800 pool - ₹' || v_remaining_pool
            );
                
            v_total_distributed := v_total_distributed + v_remaining_pool;
        END IF;
        
        -- Build result JSON
        v_result := json_build_object(
            'success', true,
            'customer_id', p_customer_id,
            'initiator_promoter_id', p_initiator_promoter_id,
            'total_distributed', v_total_distributed,
            'levels_distributed', v_distributed_count,
            'admin_fallback', v_remaining_pool,
            'message', 'Commission distributed from ₹800 pool: ₹' || v_total_distributed || ' total (NEVER exceeds ₹800)',
            'timestamp', NOW()
        );
        
        -- CRITICAL SAFETY CHECK: Ensure total never exceeds ₹800
        IF v_total_distributed > 800.00 THEN
            RAISE EXCEPTION 'CRITICAL ERROR: Total commission ₹% exceeds ₹800 limit! Pool logic failed.', v_total_distributed;
        END IF;
        
        RETURN v_result;
        
    EXCEPTION WHEN OTHERS THEN
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

-- Update function comment
COMMENT ON FUNCTION distribute_affiliate_commission IS 'Distributes commission from ₹800 pool with admin fallback. Total NEVER exceeds ₹800. Uses pool-based logic.';

COMMIT;

SELECT 
    '🔥 DATABASE FUNCTION FIXED WITH POOL LOGIC!' as status,
    'Total will NEVER exceed ₹800 - admin gets only remaining pool amount' as guarantee,
    'Complete hierarchy: ₹800 to promoters, ₹0 to admin' as example1,
    'Incomplete hierarchy: Some to promoters, remainder to admin from ₹800 pool' as example2;
