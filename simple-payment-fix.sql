-- =====================================================
-- SIMPLE PAYMENT FIX - DIRECT INSERT
-- =====================================================
-- This script creates payment records directly, avoiding problematic triggers

BEGIN;

-- Method 1: Insert payments directly without using functions
-- This bypasses any custom functions that might have issues

INSERT INTO customer_payments (
    customer_id,
    month_number,
    payment_amount,
    status,
    created_at,
    updated_at
)
SELECT 
    customers_without_payments.customer_id,
    month_numbers.month_number,
    1000.00,
    'pending',
    NOW(),
    NOW()
FROM (
    -- Get customers who don't have any payment records
    SELECT p.id as customer_id, p.name, p.email
    FROM profiles p
    WHERE p.role = 'customer'
    AND NOT EXISTS (
        SELECT 1 FROM customer_payments cp 
        WHERE cp.customer_id = p.id
    )
) customers_without_payments
CROSS JOIN (
    -- Generate month numbers 1-20
    SELECT generate_series(1, 20) as month_number
) month_numbers;

-- Check results
SELECT 'INSERTION_RESULTS' as check_type,
       COUNT(*) as records_inserted
FROM customer_payments
WHERE created_at >= NOW() - INTERVAL '1 minute';

COMMIT;

-- Verification queries
SELECT 'FINAL_STATUS' as check_type,
       (SELECT COUNT(*) FROM profiles WHERE role = 'customer') as total_customers,
       (SELECT COUNT(DISTINCT customer_id) FROM customer_payments) as customers_with_payments,
       (SELECT COUNT(*) FROM customer_payments) as total_payment_records;

-- Show sample of created payments
SELECT 'SAMPLE_CREATED_PAYMENTS' as check_type,
       p.name as customer_name,
       COUNT(cp.id) as payment_count,
       MIN(cp.month_number) as first_month,
       MAX(cp.month_number) as last_month
FROM profiles p
JOIN customer_payments cp ON p.id = cp.customer_id
WHERE p.role = 'customer'
AND cp.created_at >= NOW() - INTERVAL '1 minute'
GROUP BY p.id, p.name
ORDER BY p.name
LIMIT 5;
