-- =====================================================
-- DIAGNOSE WITHDRAWAL AUTH ISSUE
-- =====================================================

-- Check the promoter's profile and auth user
SELECT 
    '🔍 Promoter Profile Check' as check_type,
    p.id as profile_id,
    p.promoter_id as promoter_code,
    p.full_name,
    p.role,
    p.email
FROM profiles p
WHERE p.promoter_id = 'BPVP36';

-- Check if there's an auth.users record
SELECT 
    '🔐 Auth User Check' as check_type,
    au.id as auth_uid,
    au.email,
    au.created_at
FROM auth.users au
WHERE au.email IN (
    SELECT email FROM profiles WHERE promoter_id = 'BPVP36'
);

-- Check if profile.id matches auth.users.id
SELECT 
    '⚠️ ID Mismatch Check' as check_type,
    p.id as profile_id,
    au.id as auth_uid,
    CASE 
        WHEN p.id = au.id THEN '✅ IDs Match'
        ELSE '❌ IDs DO NOT MATCH - THIS IS THE PROBLEM!'
    END as match_status,
    p.email,
    p.promoter_id
FROM profiles p
LEFT JOIN auth.users au ON p.email = au.email
WHERE p.promoter_id = 'BPVP36';

-- Check current RLS policies
SELECT 
    '🔒 Current RLS Policies' as check_type,
    policyname,
    cmd,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY cmd;
