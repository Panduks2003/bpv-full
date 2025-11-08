-- =====================================================
-- INVESTIGATE COMMISSION TRIGGER ISSUE
-- =====================================================
-- This script investigates the commission calculation trigger

-- Check what triggers exist on customer_payments table
SELECT 'TRIGGERS_ON_CUSTOMER_PAYMENTS' as check_type,
       trigger_name,
       event_manipulation,
       action_timing,
       action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'customer_payments'
ORDER BY trigger_name;

-- Check the calculate_commissions function
SELECT 'CALCULATE_COMMISSIONS_FUNCTION' as check_type,
       routine_name,
       routine_type,
       data_type,
       routine_definition
FROM information_schema.routines 
WHERE routine_name LIKE '%commission%'
ORDER BY routine_name;

-- Check affiliate_commissions table structure
SELECT 'AFFILIATE_COMMISSIONS_STRUCTURE' as check_type,
       column_name,
       data_type,
       is_nullable,
       column_default
FROM information_schema.columns 
WHERE table_name = 'affiliate_commissions'
ORDER BY ordinal_position;

-- Check if there are any existing affiliate commission records
SELECT 'EXISTING_COMMISSIONS' as check_type,
       COUNT(*) as total_records,
       COUNT(CASE WHEN customer_id IS NULL THEN 1 END) as null_customer_id_count,
       COUNT(CASE WHEN promoter_id IS NULL THEN 1 END) as null_promoter_id_count
FROM affiliate_commissions;

-- Check customer-promoter relationships
SELECT 'CUSTOMER_PROMOTER_RELATIONSHIPS' as check_type,
       COUNT(*) as total_customers,
       COUNT(CASE WHEN parent_promoter_id IS NOT NULL THEN 1 END) as customers_with_promoter,
       COUNT(CASE WHEN parent_promoter_id IS NULL THEN 1 END) as customers_without_promoter
FROM profiles 
WHERE role = 'customer';

-- Show sample customers and their promoter relationships
SELECT 'SAMPLE_CUSTOMER_PROMOTER_DATA' as check_type,
       c.id as customer_id,
       c.name as customer_name,
       c.parent_promoter_id,
       p.name as promoter_name,
       p.role as promoter_role
FROM profiles c
LEFT JOIN profiles p ON c.parent_promoter_id = p.id
WHERE c.role = 'customer'
ORDER BY c.name
LIMIT 5;
