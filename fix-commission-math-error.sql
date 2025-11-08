-- =====================================================
-- FIX COMMISSION MATH ERROR - ADMIN GETTING TOO MUCH
-- =====================================================
-- The admin is getting wrong amounts - fix the calculation
-- =====================================================

BEGIN;

-- First, let's check the current commission function logic
-- Drop and recreate with correct math

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
    v_promoter_total DECIMAL(10,2) := 0.00;
BEGIN
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
                    v_promoter_total := v_promoter_total + v_amount;
                    
                    -- Move to next level (current recipient becomes the promoter to check)
                    v_current_promoter_id := v_recipient_id;
                ELSE
                    -- Recipient is not a valid promoter, add this level's amount to admin
                    v_remaining_amount := v_remaining_amount + v_amount;
                END IF;
            ELSE
                -- No promoter at this level, add this level's amount to admin
                v_remaining_amount := v_remaining_amount + v_amount;
            END IF;
        END LOOP;
        
        -- Credit remaining amount to admin ONLY if there are missing levels
        IF v_remaining_amount > 0 AND v_admin_id IS NOT NULL THEN
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
                'Admin Fallback - Missing levels - ₹' || v_remaining_amount,
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
        END IF;
        
        -- Calculate total distributed
        v_total_distributed := v_promoter_total + v_remaining_amount;
        
        -- Build result JSON
        v_result := json_build_object(
            'success', true,
            'customer_id', p_customer_id,
            'initiator_promoter_id', p_initiator_promoter_id,
            'total_distributed', v_total_distributed,
            'promoter_total', v_promoter_total,
            'admin_fallback', v_remaining_amount,
            'levels_distributed', v_distributed_count,
            'message', 'Promoters: ₹' || v_promoter_total || ', Admin: ₹' || v_remaining_amount || ', Total: ₹' || v_total_distributed,
            'timestamp', NOW()
        );
        
        -- Verify total is exactly ₹800
        IF v_total_distributed != 800.00 THEN
            RAISE EXCEPTION 'Commission total error: Expected ₹800, got ₹%', v_total_distributed;
        END IF;
        
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
COMMENT ON FUNCTION distribute_affiliate_commission IS 'Distributes exactly ₹800 commission. Promoters get their levels, admin gets remaining amount for missing levels only.';

-- Test the math with a verification query
SELECT 
    'Math Verification' as test_type,
    customer_id,
    SUM(CASE WHEN recipient_type = 'promoter' THEN amount ELSE 0 END) as promoter_total,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_total,
    SUM(amount) as grand_total
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '2 hours'
GROUP BY customer_id
HAVING SUM(amount) != 800.00
ORDER BY customer_id;

COMMIT;
