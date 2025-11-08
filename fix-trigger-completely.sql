-- =====================================================
-- FIX TRIGGER COMPLETELY - FORCE REPLACEMENT
-- =====================================================
-- The trigger function was updated but old trigger still firing
-- Need to completely replace the trigger mechanism
-- =====================================================

BEGIN;

-- 1. Check all triggers on customers table
SELECT 
    'Current Triggers on Customers' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'customers'
ORDER BY trigger_name;

-- 2. Drop ALL commission-related triggers
DROP TRIGGER IF EXISTS trigger_affiliate_commission ON customers;
DROP TRIGGER IF EXISTS trigger_commission_distribution ON customers;
DROP TRIGGER IF EXISTS auto_commission_trigger ON customers;

-- 3. Drop the old function completely and recreate
DROP FUNCTION IF EXISTS trigger_commission_distribution() CASCADE;

-- 4. Create the NEW trigger function with correct pool logic
CREATE OR REPLACE FUNCTION trigger_commission_distribution()
RETURNS TRIGGER AS $$
DECLARE
    v_commission_levels DECIMAL[] := ARRAY[500.00, 100.00, 100.00, 100.00];
    v_current_promoter_id UUID := NEW.parent_promoter_id;
    v_level INTEGER;
    v_recipient_id UUID;
    v_amount DECIMAL(10,2);
    v_admin_id UUID;
    v_remaining_pool DECIMAL(10,2) := 800.00;  -- START WITH ₹800 POOL
    v_total_distributed DECIMAL(10,2) := 0.00;
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
                    'NEW-TRIGGER-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-L' || v_level,
                    'Level ' || v_level || ' Commission - ₹' || v_amount || ' (NEW Pool Logic)'
                );
                
                -- DEDUCT FROM POOL
                v_remaining_pool := v_remaining_pool - v_amount;
                v_total_distributed := v_total_distributed + v_amount;
                
                -- Move to next level
                v_current_promoter_id := v_recipient_id;
            END IF;
        END LOOP;
        
        -- Give admin ONLY remaining pool amount (if any)
        IF v_remaining_pool > 0 AND v_admin_id IS NOT NULL THEN
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
                'NEW-ADMIN-' || EXTRACT(EPOCH FROM NOW())::BIGINT,
                'Admin Fallback - Pool remainder ₹' || v_remaining_pool || ' (NEW Logic)'
            );
                
            v_total_distributed := v_total_distributed + v_remaining_pool;
        END IF;
        
        -- CRITICAL: Ensure total never exceeds ₹800
        IF v_total_distributed > 800.00 THEN
            RAISE EXCEPTION 'NEW TRIGGER FAILED: Total ₹% exceeds ₹800!', v_total_distributed;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        -- Log error but don't fail customer creation
        RAISE WARNING 'NEW Commission trigger failed: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create the NEW trigger
CREATE TRIGGER trigger_affiliate_commission
    AFTER INSERT ON customers
    FOR EACH ROW
    EXECUTE FUNCTION trigger_commission_distribution();

-- 6. Verify the new setup
SELECT 
    'New Trigger Setup' as verification_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'customers'
AND trigger_name = 'trigger_affiliate_commission';

COMMIT;

SELECT 
    '🔥 TRIGGER COMPLETELY REPLACED!' as status,
    'Old trigger dropped, new trigger with pool logic created' as action,
    'Next customer will use NEW-TRIGGER-... transaction IDs' as identifier;
