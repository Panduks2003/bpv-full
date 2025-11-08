-- =====================================================
-- DIAGNOSE COMMISSION HISTORY ISSUES
-- =====================================================
-- This script diagnoses commission display problems
-- =====================================================

-- Check commission tables structure
SELECT 'COMMISSION_TABLES' as check_type,
       table_name,
       table_type
FROM information_schema.tables 
WHERE table_name LIKE '%commission%'
ORDER BY table_name;

-- Check affiliate_commissions table structure
SELECT 'AFFILIATE_COMMISSIONS_COLUMNS' as check_type,
       column_name,
       data_type,
       is_nullable
FROM information_schema.columns 
WHERE table_name = 'affiliate_commissions'
ORDER BY ordinal_position;

-- Check if there are any commission records
SELECT 'TOTAL_COMMISSION_RECORDS' as check_type,
       COUNT(*) as total_records
FROM affiliate_commissions;

-- Check commission records for promoter BPVP09
SELECT 'PROMOTER_COMMISSION_COUNT' as check_type,
       COUNT(*) as records_for_bpvp09
FROM affiliate_commissions ac
JOIN profiles p ON ac.promoter_id = p.id
WHERE p.promoter_id = 'BPVP09' OR p.customer_id = 'BPVP09';

-- Show sample commission records
SELECT 'SAMPLE_COMMISSIONS' as check_type,
       ac.id,
       ac.promoter_id,
       ac.customer_id,
       ac.created_at,
       p.name as promoter_name,
       p.promoter_id as promoter_code
FROM affiliate_commissions ac
LEFT JOIN profiles p ON ac.promoter_id = p.id
ORDER BY ac.created_at DESC
LIMIT 5;

-- Check RLS policies on affiliate_commissions
SELECT 'RLS_POLICIES' as check_type,
       schemaname,
       tablename,
       policyname,
       permissive,
       roles,
       cmd,
       qual
FROM pg_policies 
WHERE tablename = 'affiliate_commissions';

-- Check if RLS is enabled
SELECT 'RLS_STATUS' as check_type,
       relname as table_name,
       relrowsecurity as rls_enabled
FROM pg_class 
WHERE relname = 'affiliate_commissions';

-- Check profiles table for BPVP09
SELECT 'BPVP09_PROFILE' as check_type,
       id,
       name,
       promoter_id,
       customer_id,
       role,
       status
FROM profiles 
WHERE promoter_id = 'BPVP09' OR customer_id = 'BPVP09';
