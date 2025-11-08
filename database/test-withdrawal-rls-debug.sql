-- =====================================================
-- DEBUG WITHDRAWAL RLS AND AUTH
-- =====================================================

-- Step 1: Check if RLS is enabled
SELECT 
    '🔒 RLS Status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'withdrawal_requests';

-- Step 2: Check all RLS policies
SELECT 
    '📋 All RLS Policies' as check_type,
    policyname,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read'
        WHEN cmd = 'INSERT' THEN 'Create'
        WHEN cmd = 'UPDATE' THEN 'Update'
        WHEN cmd = 'DELETE' THEN 'Delete'
        WHEN cmd = '*' THEN 'All Operations'
    END as operation,
    permissive,
    roles
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY policyname;

-- Step 3: Check table grants
SELECT 
    '✅ Table Permissions' as check_type,
    grantee,
    privilege_type
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name = 'withdrawal_requests'
AND grantee IN ('authenticated', 'anon', 'public');

-- Step 4: List some promoters
SELECT 
    '👥 Sample Promoters' as check_type,
    id,
    name,
    email,
    role,
    promoter_id
FROM profiles
WHERE role = 'promoter'
LIMIT 5;

-- SUCCESS MESSAGE
SELECT '✅ Diagnostic complete. Now run the fix-withdrawal-insert-policy.sql script.' as next_step;
