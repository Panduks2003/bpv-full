-- =====================================================
-- CREATE MISSING PAYMENT SCHEDULES
-- =====================================================
-- This script creates 20-month payment schedules for customers who don't have them

BEGIN;

-- Function to create payment schedule for a customer
CREATE OR REPLACE FUNCTION create_customer_payment_schedule(p_customer_id UUID)
RETURNS INTEGER AS $$
DECLARE
    existing_count INTEGER;
    created_count INTEGER := 0;
BEGIN
    -- Check if customer already has payments
    SELECT COUNT(*) INTO existing_count
    FROM customer_payments 
    WHERE customer_id = p_customer_id;
    
    IF existing_count > 0 THEN
        RAISE NOTICE 'Customer % already has % payment records', p_customer_id, existing_count;
        RETURN 0;
    END IF;
    
    -- Create 20-month payment schedule
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
        generate_series(1, 20) as month_num,
        1000.00,
        'pending',
        NOW(),
        NOW();
    
    GET DIAGNOSTICS created_count = ROW_COUNT;
    
    RAISE NOTICE 'Created % payment records for customer %', created_count, p_customer_id;
    RETURN created_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create payment schedules for all customers without them
DO $$
DECLARE
    customer_record RECORD;
    total_customers INTEGER := 0;
    total_payments_created INTEGER := 0;
    payments_for_customer INTEGER;
BEGIN
    RAISE NOTICE 'Starting payment schedule creation...';
    
    -- Loop through all customers who don't have payment schedules
    FOR customer_record IN 
        SELECT DISTINCT p.id, p.name, p.email, p.created_at
        FROM profiles p
        LEFT JOIN customer_payments cp ON p.id = cp.customer_id
        WHERE p.role = 'customer' 
        AND cp.customer_id IS NULL
        ORDER BY p.created_at
    LOOP
        total_customers := total_customers + 1;
        
        -- Create payment schedule for this customer
        SELECT create_customer_payment_schedule(customer_record.id) INTO payments_for_customer;
        total_payments_created := total_payments_created + payments_for_customer;
        
        RAISE NOTICE 'Customer %: % (%) - Created % payments', 
            total_customers, 
            customer_record.name, 
            customer_record.email,
            payments_for_customer;
    END LOOP;
    
    RAISE NOTICE '=== SUMMARY ===';
    RAISE NOTICE 'Processed % customers', total_customers;
    RAISE NOTICE 'Created % total payment records', total_payments_created;
    RAISE NOTICE 'Average % payments per customer', 
        CASE WHEN total_customers > 0 THEN total_payments_created / total_customers ELSE 0 END;
END $$;

-- Verify the results
SELECT 'VERIFICATION' as check_type,
       'After payment schedule creation' as description,
       (SELECT COUNT(*) FROM profiles WHERE role = 'customer') as total_customers,
       (SELECT COUNT(DISTINCT customer_id) FROM customer_payments) as customers_with_payments,
       (SELECT COUNT(*) FROM customer_payments) as total_payment_records,
       (SELECT COUNT(*) FROM customer_payments WHERE status = 'pending') as pending_payments,
       (SELECT COUNT(*) FROM customer_payments WHERE status = 'paid') as paid_payments;

-- Show sample of created payment schedules
SELECT 'SAMPLE_SCHEDULES' as check_type,
       p.name as customer_name,
       p.email as customer_email,
       COUNT(cp.id) as payment_count,
       MIN(cp.month_number) as first_month,
       MAX(cp.month_number) as last_month,
       SUM(cp.payment_amount) as total_amount
FROM profiles p
JOIN customer_payments cp ON p.id = cp.customer_id
WHERE p.role = 'customer'
GROUP BY p.id, p.name, p.email
ORDER BY p.name
LIMIT 5;

COMMIT;

-- Final success message
SELECT 'SUCCESS' as status, 
       'Payment schedules created successfully' as message,
       NOW() as completed_at;
