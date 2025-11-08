-- =====================================================
-- DEBUG PROMOTER NOT FOUND ISSUE
-- =====================================================
-- This script helps diagnose the promoter lookup issue

-- 1. Check if the promoter exists in profiles table
SELECT 'PROMOTER_EXISTS_CHECK' as check_type,
       CASE WHEN EXISTS (
           SELECT 1 FROM profiles 
           WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e'
       ) THEN 'YES' ELSE 'NO' END as exists_in_profiles;

-- 2. Check promoter details if exists
SELECT 'PROMOTER_DETAILS' as check_type,
       id, name, role, promoter_id, pins, created_at
FROM profiles 
WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e';

-- 3. Check if promoter has correct role
SELECT 'PROMOTER_ROLE_CHECK' as check_type,
       id, name, role, 
       CASE WHEN role = 'promoter' THEN 'CORRECT' ELSE 'WRONG_ROLE' END as role_status
FROM profiles 
WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e';

-- 4. Check all promoters to see available ones
SELECT 'ALL_PROMOTERS' as check_type,
       id, name, role, promoter_id, pins
FROM profiles 
WHERE role = 'promoter'
ORDER BY created_at DESC
LIMIT 10;

-- 5. Check if there are any promoters with pins
SELECT 'PROMOTERS_WITH_PINS' as check_type,
       id, name, promoter_id, pins
FROM profiles 
WHERE role = 'promoter' AND pins > 0
ORDER BY pins DESC;

-- 6. Test the pin check function directly
SELECT 'PIN_CHECK_FUNCTION_TEST' as check_type,
       check_promoter_pins('c38c36ce-177e-4407-9233-d7fdbd4e150e', 1) as has_sufficient_pins;

-- 7. Check auth.users table for this ID
SELECT 'AUTH_USER_CHECK' as check_type,
       CASE WHEN EXISTS (
           SELECT 1 FROM auth.users 
           WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e'
       ) THEN 'EXISTS_IN_AUTH' ELSE 'NOT_IN_AUTH' END as auth_status;
