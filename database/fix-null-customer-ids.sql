-- =====================================================
-- FIX NULL CUSTOMER IDs
-- =====================================================
-- Assigns unique customer IDs to customers who don't have one
-- =====================================================

-- Update customers with null customer_id
UPDATE profiles
SET customer_id = 'BPC' || LPAD(
    (
        SELECT COALESCE(MAX(CAST(SUBSTRING(customer_id FROM 4) AS INTEGER)), 0) + 1
        FROM profiles 
        WHERE customer_id IS NOT NULL 
        AND customer_id ~ '^BPC[0-9]+$'
    )::TEXT, 
    3, 
    '0'
)
WHERE role = 'customer' 
AND customer_id IS NULL
RETURNING customer_id, name, id;

-- Verify all customers have customer_ids
SELECT 
    '✅ VERIFICATION' as status,
    COUNT(*) as total_customers,
    COUNT(*) FILTER (WHERE customer_id IS NOT NULL) as with_customer_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) as without_customer_id
FROM profiles
WHERE role = 'customer';

-- Show all customers
SELECT 
    customer_id,
    name,
    phone,
    status,
    CASE 
        WHEN customer_id IS NOT NULL THEN '✅ Can Login'
        ELSE '❌ Cannot Login'
    END as login_status
FROM profiles
WHERE role = 'customer'
ORDER BY created_at DESC;
