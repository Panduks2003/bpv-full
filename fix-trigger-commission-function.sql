-- =====================================================
-- FIX TRIGGER COMMISSION FUNCTION - THE REAL CULPRIT
-- =====================================================
-- The database trigger is creating commissions with old logic
-- This is why we get ₹1000 instead of ₹800
-- =====================================================

BEGIN;

-- 1. Check the current trigger function
SELECT 
    'Current Trigger Function' as check_type,
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'trigger_commission_distribution';

-- 2. Update the trigger function to use correct pool logic
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
    v_distributed_count INTEGER := 0;
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
    
    -- POOL-BASED COMMISSION DISTRIBUTION
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
                    'TRIGGER-POOL-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-L' || v_level,
                    'Level ' || v_level || ' Commission - ₹' || v_amount || ' (Trigger Pool-based)'
                );
                
                -- DEDUCT FROM POOL
                v_remaining_pool := v_remaining_pool - v_amount;
                v_distributed_count := v_distributed_count + 1;
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
                'TRIGGER-ADMIN-POOL-' || EXTRACT(EPOCH FROM NOW())::BIGINT,
                'Admin Fallback - Pool remainder - ₹' || v_remaining_pool || ' (Trigger)'
            );
                
            v_total_distributed := v_total_distributed + v_remaining_pool;
        END IF;
        
        -- CRITICAL: Ensure total never exceeds ₹800
        IF v_total_distributed > 800.00 THEN
            RAISE EXCEPTION 'TRIGGER POOL LOGIC FAILED: Total ₹% exceeds ₹800!', v_total_distributed;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        -- Log error but don't fail customer creation
        RAISE WARNING 'Commission trigger failed: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Alternative: Disable the trigger completely if we want manual control
-- COMMENT: Uncomment the line below to disable automatic commission distribution
-- DROP TRIGGER IF EXISTS trigger_affiliate_commission ON customers;

COMMIT;

SELECT 
    '🔥 TRIGGER FUNCTION FIXED WITH POOL LOGIC!' as status,
    'Database trigger now uses ₹800 pool instead of ₹800 + ₹200' as fix,
    'Total will NEVER exceed ₹800 from trigger' as guarantee;
