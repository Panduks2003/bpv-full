-- =====================================================
-- FIX SEQUENTIAL TRANSACTION ID GENERATION
-- =====================================================
-- This creates a proper sequential ID system for commission
-- transaction IDs instead of using timestamps
-- =====================================================

-- Create a sequence for commission transaction IDs
CREATE SEQUENCE IF NOT EXISTS commission_transaction_seq 
START WITH 1 
INCREMENT BY 1 
NO MAXVALUE 
NO MINVALUE 
CACHE 1;

-- Create a function to generate sequential transaction IDs
CREATE OR REPLACE FUNCTION generate_commission_transaction_id() 
RETURNS VARCHAR(20) AS $$
DECLARE
    next_id INTEGER;
BEGIN
    -- Get next value from sequence
    SELECT nextval('commission_transaction_seq') INTO next_id;
    
    -- Format as COM-XXXXX (5 digits with leading zeros)
    RETURN 'COM-' || LPAD(next_id::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

-- Update the commission distribution function to use sequential IDs
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
    v_result JSON;
    v_distributed_count INTEGER := 0;
    v_total_distributed DECIMAL(10,2) := 0.00;
    v_admin_fallback_count INTEGER := 0;
    v_admin_fallback_total DECIMAL(10,2) := 0.00;
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
                SELECT parent_promoter_id INTO v_recipient_id
                FROM profiles
                WHERE id = v_current_promoter_id
                AND parent_promoter_id IS NOT NULL;
            END IF;
            
            -- Generate sequential transaction ID
            v_transaction_id := generate_commission_transaction_id();
            
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
                -- No promoter at this level, create individual admin fallback record
                IF v_admin_id IS NOT NULL THEN
                    -- Generate sequential transaction ID for admin fallback
                    v_transaction_id := generate_commission_transaction_id();
                    
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
                        v_level, -- Keep the actual level instead of 0
                        v_amount,
                        'credited',
                        v_transaction_id,
                        'Admin Fallback Level ' || v_level || ' - ₹' || v_amount
                    );
                    
                    v_admin_fallback_count := v_admin_fallback_count + 1;
                    v_admin_fallback_total := v_admin_fallback_total + v_amount;
                    v_total_distributed := v_total_distributed + v_amount;
                END IF;
                
                -- Don't move to next level since this level doesn't exist
                -- v_current_promoter_id remains the same
            END IF;
        END LOOP;
        
        -- Update admin wallet if there were any fallback commissions
        IF v_admin_fallback_total > 0 AND v_admin_id IS NOT NULL THEN
            INSERT INTO admin_wallet (admin_id, balance, total_commission_received, unclaimed_commissions, commission_count, last_commission_at)
            VALUES (v_admin_id, v_admin_fallback_total, v_admin_fallback_total, v_admin_fallback_total, v_admin_fallback_count, NOW())
            ON CONFLICT (admin_id) DO UPDATE SET
                balance = admin_wallet.balance + v_admin_fallback_total,
                total_commission_received = admin_wallet.total_commission_received + v_admin_fallback_total,
                unclaimed_commissions = admin_wallet.unclaimed_commissions + v_admin_fallback_total,
                commission_count = admin_wallet.commission_count + v_admin_fallback_count,
                last_commission_at = NOW(),
                updated_at = NOW();
        END IF;
        
        -- Build result JSON
        v_result := json_build_object(
            'success', true,
            'customer_id', p_customer_id,
            'initiator_promoter_id', p_initiator_promoter_id,
            'total_distributed', v_total_distributed,
            'levels_distributed', v_distributed_count,
            'admin_fallback_records', v_admin_fallback_count,
            'admin_fallback_total', v_admin_fallback_total,
            'timestamp', NOW()
        );
        
        RETURN v_result;
        
    EXCEPTION WHEN OTHERS THEN
        -- Rollback on error
        RAISE EXCEPTION 'Commission distribution failed: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set the sequence to start from the next available number
-- This ensures we don't have duplicate IDs with existing records
DO $$
DECLARE
    max_existing_id INTEGER := 0;
    current_max_com VARCHAR(20);
BEGIN
    -- Find the highest existing COM-XXXXX ID
    SELECT MAX(
        CASE 
            WHEN transaction_id ~ '^COM-[0-9]+$' 
            THEN CAST(SUBSTRING(transaction_id FROM 5) AS INTEGER)
            ELSE 0
        END
    ) INTO max_existing_id
    FROM affiliate_commissions
    WHERE transaction_id LIKE 'COM-%';
    
    -- If no existing IDs found, start from 1
    IF max_existing_id IS NULL THEN
        max_existing_id := 0;
    END IF;
    
    -- Set sequence to start from next available number
    PERFORM setval('commission_transaction_seq', max_existing_id + 1, false);
    
    RAISE NOTICE 'Commission transaction sequence set to start from: %', max_existing_id + 1;
END $$;

-- Test the sequential ID generation
DO $$
DECLARE
    test_id1 VARCHAR(20);
    test_id2 VARCHAR(20);
    test_id3 VARCHAR(20);
BEGIN
    -- Generate a few test IDs to verify they're sequential
    SELECT generate_commission_transaction_id() INTO test_id1;
    SELECT generate_commission_transaction_id() INTO test_id2;
    SELECT generate_commission_transaction_id() INTO test_id3;
    
    RAISE NOTICE 'Test sequential IDs generated:';
    RAISE NOTICE '1. %', test_id1;
    RAISE NOTICE '2. %', test_id2;
    RAISE NOTICE '3. %', test_id3;
    
    -- Reset sequence to correct position (subtract the test IDs we just used)
    PERFORM setval('commission_transaction_seq', currval('commission_transaction_seq') - 3);
END $$;

-- Add comments
COMMENT ON SEQUENCE commission_transaction_seq IS 'Sequential counter for commission transaction IDs';
COMMENT ON FUNCTION generate_commission_transaction_id() IS 'Generates sequential transaction IDs in format COM-XXXXX';
COMMENT ON FUNCTION distribute_affiliate_commission IS 'Distributes ₹800 commission with sequential transaction IDs and individual admin fallback records';

-- Success message
SELECT 'Sequential transaction ID system implemented successfully!' as status,
       'Transaction IDs will now be generated as COM-00001, COM-00002, etc.' as description;
