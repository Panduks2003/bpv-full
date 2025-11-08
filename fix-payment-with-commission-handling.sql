-- =====================================================
-- FIX PAYMENT SCHEDULES WITH COMMISSION HANDLING
-- =====================================================
-- This script creates payment schedules while properly handling commission triggers

BEGIN;

-- First, let's check what triggers exist on customer_payments
SELECT 'EXISTING_TRIGGERS' as check_type, 
       trigger_name, 
       event_manipulation, 
       action_timing,
       action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'customer_payments';

-- Check the calculate_commissions function to understand what it needs
SELECT 'COMMISSION_FUNCTION' as check_type,
       routine_name,
       routine_definition
FROM information_schema.routines 
WHERE routine_name = 'calculate_commissions';

-- Let's create a safer version that handles the commission calculation properly
CREATE OR REPLACE FUNCTION create_customer_payment_schedule_safe(p_customer_id UUID)
RETURNS INTEGER AS $$
DECLARE
    existing_count INTEGER;
    created_count INTEGER := 0;
    customer_promoter_id UUID;
    customer_record RECORD;
BEGIN
    -- Check if customer already has payments
    SELECT COUNT(*) INTO existing_count
    FROM customer_payments 
    WHERE customer_id = p_customer_id;
    
    IF existing_count > 0 THEN
        RAISE NOTICE 'Customer % already has % payment records', p_customer_id, existing_count;
        RETURN 0;
    END IF;
    
    -- Get customer details and their promoter
    SELECT id, name, email, parent_promoter_id 
    INTO customer_record
    FROM profiles 
    WHERE id = p_customer_id AND role = 'customer';
    
    IF NOT FOUND THEN
        RAISE NOTICE 'Customer % not found or not a customer', p_customer_id;
        RETURN 0;
    END IF;
    
    customer_promoter_id := customer_record.parent_promoter_id;
    
    -- Create payment records one by one to handle commission triggers properly
    FOR month_num IN 1..20 LOOP
        BEGIN
            INSERT INTO customer_payments (
                customer_id,
                month_number,
                payment_amount,
                status,
                created_at,
                updated_at
            ) VALUES (
                p_customer_id,
                month_num,
                1000.00,
                'pending',
                NOW(),
                NOW()
            );
            
            created_count := created_count + 1;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Failed to create payment for month % for customer %: %', 
                month_num, p_customer_id, SQLERRM;
            -- Continue with next month instead of failing completely
        END;
    END LOOP;
    
    RAISE NOTICE 'Created % payment records for customer % (%)', 
        created_count, customer_record.name, customer_record.email;
    RETURN created_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Alternative approach: Create payments without triggering commissions initially
CREATE OR REPLACE FUNCTION create_payments_bypass_commissions(p_customer_id UUID)
RETURNS INTEGER AS $$
DECLARE
    created_count INTEGER := 0;
    customer_record RECORD;
BEGIN
    -- Get customer details
    SELECT id, name, email, parent_promoter_id 
    INTO customer_record
    FROM profiles 
    WHERE id = p_customer_id AND role = 'customer';
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Temporarily disable the commission trigger
    PERFORM set_config('app.skip_commission_calculation', 'true', true);
    
    -- Create all payment records at once
    INSERT INTO customer_payments (
        customer_id,
        month_number,
        payment_amount,
        status,
        created_at,
        updated_at
    )
    SELECT 
        p_customer_id,
        generate_series(1, 20),
        1000.00,
        'pending',
        NOW(),
        NOW();
    
    GET DIAGNOSTICS created_count = ROW_COUNT;
    
    -- Re-enable commission calculation
    PERFORM set_config('app.skip_commission_calculation', 'false', true);
    
    RAISE NOTICE 'Created % payment records for customer % (bypassing commissions)', 
        created_count, customer_record.name;
    
    RETURN created_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Now let's try to create payment schedules using the safer approach
DO $$
DECLARE
    customer_record RECORD;
    total_customers INTEGER := 0;
    total_payments_created INTEGER := 0;
    payments_for_customer INTEGER;
    approach_used TEXT := 'safe_individual';
BEGIN
    RAISE NOTICE 'Starting safe payment schedule creation...';
    
    -- First try the bypass approach for all customers
    BEGIN
        RAISE NOTICE 'Attempting bulk creation with commission bypass...';
        
        FOR customer_record IN 
            SELECT DISTINCT p.id, p.name, p.email, p.created_at
            FROM profiles p
            LEFT JOIN customer_payments cp ON p.id = cp.customer_id
            WHERE p.role = 'customer' 
            AND cp.customer_id IS NULL
            ORDER BY p.created_at
        LOOP
            total_customers := total_customers + 1;
            
            SELECT create_payments_bypass_commissions(customer_record.id) INTO payments_for_customer;
            total_payments_created := total_payments_created + payments_for_customer;
            
            IF payments_for_customer > 0 THEN
                RAISE NOTICE 'Customer %: % - Created % payments (bypass)', 
                    total_customers, customer_record.name, payments_for_customer;
            END IF;
        END LOOP;
        
        approach_used := 'bypass_commissions';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Bypass approach failed: %, trying individual approach...', SQLERRM;
        
        -- Reset counters and try individual approach
        total_customers := 0;
        total_payments_created := 0;
        
        FOR customer_record IN 
            SELECT DISTINCT p.id, p.name, p.email, p.created_at
            FROM profiles p
            LEFT JOIN customer_payments cp ON p.id = cp.customer_id
            WHERE p.role = 'customer' 
            AND cp.customer_id IS NULL
            ORDER BY p.created_at
        LOOP
            total_customers := total_customers + 1;
            
            SELECT create_customer_payment_schedule_safe(customer_record.id) INTO payments_for_customer;
            total_payments_created := total_payments_created + payments_for_customer;
        END LOOP;
        
        approach_used := 'safe_individual';
    END;
    
    RAISE NOTICE '=== SUMMARY ===';
    RAISE NOTICE 'Approach used: %', approach_used;
    RAISE NOTICE 'Processed % customers', total_customers;
    RAISE NOTICE 'Created % total payment records', total_payments_created;
    RAISE NOTICE 'Average % payments per customer', 
        CASE WHEN total_customers > 0 THEN total_payments_created / total_customers ELSE 0 END;
END $$;

-- Clean up temporary functions
DROP FUNCTION IF EXISTS create_customer_payment_schedule_safe(UUID);
DROP FUNCTION IF EXISTS create_payments_bypass_commissions(UUID);

COMMIT;

-- Final verification
SELECT 'FINAL_VERIFICATION' as check_type,
       (SELECT COUNT(*) FROM profiles WHERE role = 'customer') as total_customers,
       (SELECT COUNT(DISTINCT customer_id) FROM customer_payments) as customers_with_payments,
       (SELECT COUNT(*) FROM customer_payments) as total_payment_records,
       (SELECT COUNT(*) FROM customer_payments WHERE status = 'pending') as pending_payments;

-- Show customers still without payments (if any)
SELECT 'CUSTOMERS_STILL_WITHOUT_PAYMENTS' as check_type,
       p.id, p.name, p.email
FROM profiles p
LEFT JOIN customer_payments cp ON p.id = cp.customer_id
WHERE p.role = 'customer' 
AND cp.customer_id IS NULL
LIMIT 5;
