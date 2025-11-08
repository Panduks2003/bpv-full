-- =====================================================
-- FIX COMMISSION TRANSACTION ID GENERATION
-- =====================================================
-- Update to use UUID-based transaction IDs to avoid duplicates

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
                SELECT parent_promoter INTO v_recipient_id
                FROM profiles
                WHERE id = v_current_promoter_id
                AND parent_promoter IS NOT NULL;
            END IF;
            
            -- Generate UNIQUE transaction ID using UUID
            v_transaction_id := 'COMM-' || replace(gen_random_uuid()::text, '-', '') || '-L' || v_level;
            
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
        
        -- Credit remaining amount to admin if any
        IF v_remaining_amount > 0 AND v_admin_id IS NOT NULL THEN
            v_transaction_id := 'COMM-ADMIN-' || replace(gen_random_uuid()::text, '-', '');
            
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
                0, -- Admin level
                v_remaining_amount,
                'credited',
                v_transaction_id,
                'Unclaimed Commission Fallback - ₹' || v_remaining_amount
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

-- Verification
SELECT '✅ Commission distribution function updated with UUID-based transaction IDs' as status;
