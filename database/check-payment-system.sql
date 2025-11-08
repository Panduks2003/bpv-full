-- =====================================================
-- CHECK PAYMENT SYSTEM STATUS
-- =====================================================
-- This script checks the current state of the payment system

-- 1. Check if customer_payments table exists
SELECT 'TABLE_EXISTS' as check_type,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.tables 
           WHERE table_name = 'customer_payments' AND table_schema = 'public'
       ) THEN 'YES' ELSE 'NO' END as status;

-- 2. Check table structure
SELECT 'TABLE_STRUCTURE' as check_type, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'customer_payments' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Check if there are any customers
SELECT 'CUSTOMER_COUNT' as check_type, COUNT(*) as count
FROM profiles 
WHERE role = 'customer';

-- 4. Check if there are any payment records
SELECT 'PAYMENT_RECORDS_COUNT' as check_type, COUNT(*) as count
FROM customer_payments;

-- 5. Check sample payment data (if any exists)
SELECT 'SAMPLE_PAYMENTS' as check_type, 
       customer_id, 
       month_number, 
       amount, 
       status, 
       payment_date,
       marked_by,
       created_at
FROM customer_payments 
ORDER BY created_at DESC 
LIMIT 5;

-- 6. Check customers without payment schedules
SELECT 'CUSTOMERS_WITHOUT_PAYMENTS' as check_type,
       p.id as customer_id,
       p.name as customer_name,
       p.email as customer_email,
       p.created_at as customer_created_at
FROM profiles p
LEFT JOIN customer_payments cp ON p.id = cp.customer_id
WHERE p.role = 'customer' 
AND cp.customer_id IS NULL
LIMIT 10;

-- 7. Check RLS policies on customer_payments
SELECT 'RLS_POLICIES' as check_type,
       schemaname,
       tablename,
       policyname,
       permissive,
       roles,
       cmd,
       qual
FROM pg_policies 
WHERE tablename = 'customer_payments';

-- 8. Check table permissions
SELECT 'TABLE_PERMISSIONS' as check_type,
       grantee,
       privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'customer_payments';
