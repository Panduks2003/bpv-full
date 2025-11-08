-- Fix missing payment schedules for specific customers
-- Run this in Supabase SQL Editor

-- Create payment schedules for customers that are missing them
INSERT INTO customer_payments (
    customer_id,
    month_number,
    payment_amount,
    status,
    created_at,
    updated_at
)
SELECT 
    customer_id,
    generate_series(1, 20) as month_number,
    1000.00 as payment_amount,
    'pending' as status,
    NOW() as created_at,
    NOW() as updated_at
FROM (
    VALUES 
        ('cb3d4184-58dd-420d-bfed-57c8c900c51b'::uuid),
        ('67067adf-1738-482b-bef6-d85c26b15ba9'::uuid)
) AS missing_customers(customer_id)
WHERE NOT EXISTS (
    SELECT 1 FROM customer_payments cp 
    WHERE cp.customer_id = missing_customers.customer_id
);

-- Verify the fix
SELECT 
    'PAYMENT_VERIFICATION' as check_type,
    customer_id,
    COUNT(*) as payment_count,
    'Expected: 20' as expected
FROM customer_payments 
WHERE customer_id IN (
    'cb3d4184-58dd-420d-bfed-57c8c900c51b',
    '67067adf-1738-482b-bef6-d85c26b15ba9'
)
GROUP BY customer_id
ORDER BY customer_id;

-- Check overall system health
SELECT 
    'SYSTEM_HEALTH' as check_type,
    COUNT(DISTINCT p.id) as total_customers,
    COUNT(DISTINCT cp.customer_id) as customers_with_payments,
    COUNT(cp.id) as total_payment_records,
    ROUND(COUNT(cp.id)::decimal / COUNT(DISTINCT p.id), 1) as avg_payments_per_customer
FROM profiles p
LEFT JOIN customer_payments cp ON p.id = cp.customer_id
WHERE p.role = 'customer';

SELECT 'MISSING_PAYMENTS_FIXED' as status;
