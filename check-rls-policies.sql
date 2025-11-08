-- Check RLS policies on affiliate_commissions table

-- 1. Check if RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    hasrls
FROM pg_tables 
WHERE tablename = 'affiliate_commissions';

-- 2. Check existing RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'affiliate_commissions';

-- 3. Check table permissions
SELECT 
    table_schema,
    table_name,
    privilege_type,
    grantee
FROM information_schema.table_privileges 
WHERE table_name = 'affiliate_commissions';

-- 4. Test if current user can access the table
SELECT 
    'CURRENT_USER_ACCESS_TEST' as test_type,
    current_user as database_user,
    session_user as session_user;

-- 5. Check if there are any triggers or functions affecting the table
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'affiliate_commissions';

SELECT 'RLS_POLICY_CHECK_COMPLETE' as result;
