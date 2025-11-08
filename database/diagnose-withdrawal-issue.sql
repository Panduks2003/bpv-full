-- =====================================================
-- DIAGNOSE WITHDRAWAL REQUEST ISSUE
-- =====================================================
-- This will help identify the ID mismatch problem
-- =====================================================

-- 1. Check current user's auth ID vs profile ID
SELECT 
    '🔍 Current User Check' as check_type,
    auth.uid() as auth_user_id,
    p.id as profile_id,
    p.name,
    p.role,
    p.promoter_id,
    CASE 
        WHEN auth.uid() = p.id THEN '✅ IDs Match'
        ELSE '❌ ID MISMATCH - This is the problem!'
    END as status
FROM profiles p
WHERE p.id = auth.uid() OR p.email = (SELECT email FROM auth.users WHERE id = auth.uid());

-- 2. Check if there are duplicate profiles for the same email
SELECT 
    '🔍 Duplicate Profile Check' as check_type,
    au.email,
    au.id as auth_id,
    p.id as profile_id,
    p.role,
    p.promoter_id
FROM auth.users au
LEFT JOIN profiles p ON p.email = au.email
WHERE au.id = auth.uid()
ORDER BY p.created_at DESC;

-- 3. Check withdrawal_requests table structure
SELECT 
    '📋 Withdrawal Table Check' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'withdrawal_requests'
ORDER BY ordinal_position;

-- 4. Test if current user can insert (this will fail but show the error)
-- Comment this out if you don't want to test
/*
INSERT INTO withdrawal_requests (promoter_id, amount, status, reason)
VALUES (auth.uid(), 100, 'pending', 'Test withdrawal')
RETURNING *;
*/
