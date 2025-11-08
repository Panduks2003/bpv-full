-- =====================================================
-- TEST DATABASE FUNCTION - VERIFY POOL LOGIC
-- =====================================================
-- Test the database function to see if it's using correct logic
-- =====================================================

-- 1. Check if the function exists and its definition
SELECT 
    'Function Check' as test_type,
    routine_name,
    routine_type,
    external_language,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'distribute_affiliate_commission'
ORDER BY routine_name;

-- 2. Test the function with a dummy customer ID to see the logic
-- (This will fail but show us the current function behavior)
SELECT 
    'Function Test' as test_type,
    'Testing with dummy data to see current logic' as note;

-- Let's see what the current function returns for a test case
-- We'll use a non-existent customer ID to avoid affecting real data
SELECT distribute_affiliate_commission(
    '00000000-0000-0000-0000-000000000001'::UUID,
    '00000000-0000-0000-0000-000000000002'::UUID
) as function_result;

-- 3. Check recent commission records to see the pattern
SELECT 
    'Recent Commission Pattern' as analysis_type,
    customer_id,
    level,
    recipient_type,
    amount,
    note,
    created_at
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '10 minutes'
ORDER BY customer_id, level;

-- 4. Check if there are multiple functions with the same name
SELECT 
    'Function Versions' as check_type,
    proname as function_name,
    pronargs as num_args,
    prorettype as return_type,
    prosrc as source_code_snippet
FROM pg_proc 
WHERE proname = 'distribute_affiliate_commission';
