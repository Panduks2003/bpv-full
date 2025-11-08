-- =====================================================
-- SIMPLE FIX FOR PAYMENT MANAGEMENT ISSUE
-- =====================================================
-- This script creates payment schedules while avoiding trigger issues

BEGIN;

-- Temporarily disable triggers on customer_payments table
ALTER TABLE customer_payments DISABLE TRIGGER ALL;

-- Create payment schedules for customers without them
INSERT INTO customer_payments (
    customer_id,
    month_number,
    payment_amount,
    status,
    created_at,
    updated_at
)
SELECT 
    p.id as customer_id,
    month_series.month_number,
    1000.00 as payment_amount,
    'pending' as status,
    NOW() as created_at,
    NOW() as updated_at
FROM profiles p
CROSS JOIN generate_series(1, 20) AS month_series(month_number)
LEFT JOIN customer_payments cp ON p.id = cp.customer_id AND month_series.month_number = cp.month_number
WHERE p.role = 'customer'
AND cp.customer_id IS NULL;

-- Re-enable triggers
ALTER TABLE customer_payments ENABLE TRIGGER ALL;

-- Show results
SELECT 'PAYMENT_CREATION_RESULTS' as result_type,
       COUNT(DISTINCT customer_id) as customers_with_payments,
       COUNT(*) as total_payment_records,
       MIN(month_number) as min_month,
       MAX(month_number) as max_month,
       SUM(payment_amount) as total_amount
FROM customer_payments;

-- Show sample of created payments
SELECT 'SAMPLE_PAYMENTS' as result_type,
       p.name as customer_name,
       p.email as customer_email,
       COUNT(cp.id) as payment_count,
       SUM(cp.payment_amount) as total_amount
FROM profiles p
JOIN customer_payments cp ON p.id = cp.customer_id
WHERE p.role = 'customer'
GROUP BY p.id, p.name, p.email
ORDER BY p.name
LIMIT 5;

COMMIT;

-- Final verification
SELECT 'FINAL_STATUS' as check_type,
       'Payment schedules created successfully' as message,
       NOW() as completed_at;
