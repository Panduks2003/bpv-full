-- =====================================================
-- CREATE SEQUENTIAL TRANSACTION ID SYSTEM
-- =====================================================
-- This creates a clean sequential numbering system:
-- COM-01, COM-02, COM-03, etc.
-- =====================================================

BEGIN;

-- =====================================================
-- CREATE SEQUENCE FOR TRANSACTION IDs
-- =====================================================

-- Create a sequence for transaction IDs
CREATE SEQUENCE IF NOT EXISTS transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 1;

-- =====================================================
-- CREATE FUNCTION TO GENERATE SEQUENTIAL TRANSACTION IDs
-- =====================================================

-- Function to generate clean sequential transaction IDs
CREATE OR REPLACE FUNCTION generate_transaction_id()
RETURNS TEXT AS $$
DECLARE
    v_next_id INTEGER;
    v_formatted_id TEXT;
BEGIN
    -- Get next value from sequence
    v_next_id := nextval('transaction_id_seq');
    
    -- Format as COM-XX (pad with zeros)
    v_formatted_id := 'COM-' || LPAD(v_next_id::TEXT, 2, '0');
    
    RETURN v_formatted_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- UPDATE COMMISSION DISTRIBUTION FUNCTION
-- =====================================================

-- Update the distribute_affiliate_commission function to use sequential IDs
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
            
            -- Generate sequential transaction ID
            v_transaction_id := generate_transaction_id();
            
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
        IF v_remaining_amount > 0 AND v_admin_id IS NOT NULL AND v_distributed_count < 4 THEN
            -- Generate sequential transaction ID for admin
            v_transaction_id := generate_transaction_id();
            
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

-- =====================================================
-- UPDATE TRIGGER FUNCTION FOR SEQUENTIAL IDs
-- =====================================================

-- Update the trigger function to also use sequential IDs
CREATE OR REPLACE FUNCTION trigger_commission_distribution()
RETURNS TRIGGER AS $$
DECLARE
    v_commission_levels DECIMAL[] := ARRAY[500.00, 100.00, 100.00, 100.00];
    v_current_promoter_id UUID := NEW.parent_promoter_id;
    v_level INTEGER;
    v_recipient_id UUID;
    v_amount DECIMAL(10,2);
    v_admin_id UUID;
    v_remaining_pool DECIMAL(10,2) := 800.00;
    v_total_distributed DECIMAL(10,2) := 0.00;
    v_transaction_id VARCHAR(50);
BEGIN
    -- Only process if customer has a parent promoter
    IF NEW.parent_promoter_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Get admin ID for fallback
    SELECT id INTO v_admin_id 
    FROM profiles 
    WHERE role = 'admin' 
    LIMIT 1;
    
    -- POOL-BASED COMMISSION DISTRIBUTION (₹800 MAX)
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
            
            -- Generate sequential transaction ID
            v_transaction_id := generate_transaction_id();
            
            -- ONLY DISTRIBUTE IF PROMOTER EXISTS AND POOL HAS FUNDS
            IF v_recipient_id IS NOT NULL AND v_remaining_pool >= v_amount THEN
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
                    NEW.id,
                    NEW.parent_promoter_id,
                    v_recipient_id,
                    'promoter',
                    v_level,
                    v_amount,
                    'credited',
                    v_transaction_id,
                    'Level ' || v_level || ' Commission - ₹' || v_amount || ' (Auto-Trigger)'
                );
                
                -- DEDUCT FROM POOL
                v_remaining_pool := v_remaining_pool - v_amount;
                v_total_distributed := v_total_distributed + v_amount;
                
                -- Move to next level
                v_current_promoter_id := v_recipient_id;
            END IF;
        END LOOP;
        
        -- Give admin any remaining pool amount
        IF v_remaining_pool > 0 AND v_admin_id IS NOT NULL THEN
            -- Generate sequential transaction ID for admin
            v_transaction_id := generate_transaction_id();
            
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
                NEW.id,
                NEW.parent_promoter_id,
                v_admin_id,
                'admin',
                0,
                v_remaining_pool,
                'credited',
                v_transaction_id,
                'Admin Fallback - Pool remainder ₹' || v_remaining_pool || ' (Auto-Trigger)'
            );
                
            v_total_distributed := v_total_distributed + v_remaining_pool;
        END IF;
        
        -- CRITICAL: Ensure total never exceeds ₹800
        IF v_total_distributed > 800.00 THEN
            RAISE EXCEPTION 'TRIGGER FAILED: Total ₹% exceeds ₹800!', v_total_distributed;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        -- Log error but don't fail customer creation
        RAISE WARNING 'Commission trigger failed: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO anon;
GRANT EXECUTE ON FUNCTION generate_transaction_id() TO authenticated;
GRANT EXECUTE ON FUNCTION generate_transaction_id() TO anon;

-- =====================================================
-- TEST THE SEQUENTIAL SYSTEM
-- =====================================================

-- Test generating a few sequential IDs
SELECT 
    '🧪 TESTING SEQUENTIAL TRANSACTION IDs' as test_type,
    generate_transaction_id() as id_1,
    generate_transaction_id() as id_2,
    generate_transaction_id() as id_3,
    generate_transaction_id() as id_4,
    generate_transaction_id() as id_5;

-- Show current sequence value
SELECT 
    '📊 SEQUENCE STATUS' as status_type,
    'transaction_id_seq' as sequence_name,
    last_value as current_value,
    'Next ID will be: COM-' || LPAD((last_value + 1)::TEXT, 2, '0') as next_id
FROM transaction_id_seq;

COMMIT;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 
    '🎉 SEQUENTIAL TRANSACTION ID SYSTEM DEPLOYED!' as final_status,
    'Transaction IDs now: COM-01, COM-02, COM-03, etc.' as format,
    'Clean, sequential, and easy to reference' as benefit;
