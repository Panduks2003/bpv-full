-- =====================================================
-- FIX ADMIN FALLBACK COMMISSION ISSUE
-- =====================================================
-- This script fixes the commission function to prevent
-- admin fallback when complete promoter hierarchy exists
-- =====================================================

BEGIN;

-- Drop existing commission function
DROP FUNCTION IF EXISTS distribute_affiliate_commission(UUID, UUID) CASCADE;

-- Create corrected commission distribution function
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
                    -- Recipient is not a valid promoter, add to admin fallback
                    v_remaining_amount := v_remaining_amount + v_amount;
                END IF;
            ELSE
                -- No promoter at this level, add to admin fallback
                v_remaining_amount := v_remaining_amount + v_amount;
            END IF;
        END LOOP;
        
        -- ONLY credit remaining amount to admin if there are missing levels
        -- DO NOT give admin commission if all 4 levels were distributed
        IF v_remaining_amount > 0 AND v_admin_id IS NOT NULL AND v_distributed_count < 4 THEN
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
                'Admin Fallback - No promoter hierarchy - ₹' || v_remaining_amount,
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
            'admin_fallback', CASE WHEN v_distributed_count = 4 THEN 0 ELSE v_remaining_amount END,
            'message', CASE 
                WHEN v_distributed_count = 4 THEN 'Complete hierarchy - ₹800 distributed to 4 levels'
                ELSE 'Partial hierarchy - ₹' || v_total_distributed || ' distributed, ₹' || v_remaining_amount || ' to admin'
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
COMMENT ON FUNCTION distribute_affiliate_commission IS 'Distributes ₹800 commission across 4 affiliate levels. Admin fallback ONLY when hierarchy is incomplete.';

COMMIT;
