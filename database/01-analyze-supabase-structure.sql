-- =====================================================
-- COMPREHENSIVE SUPABASE STRUCTURE ANALYSIS
-- =====================================================
-- This will show us everything in your Supabase database
-- =====================================================

-- 1. CHECK ALL TABLES
SELECT 
    '📋 ALL TABLES' as section,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. CHECK PROFILES TABLE STRUCTURE
SELECT 
    '👤 PROFILES TABLE COLUMNS' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 3. CHECK WITHDRAWAL_REQUESTS TABLE STRUCTURE
SELECT 
    '💰 WITHDRAWAL_REQUESTS TABLE COLUMNS' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'withdrawal_requests'
ORDER BY ordinal_position;

-- 4. CHECK PROMOTER BPVP36 DATA
SELECT 
    '🔍 PROMOTER BPVP36 PROFILE' as section,
    *
FROM profiles
WHERE promoter_id = 'BPVP36';

-- 5. CHECK AUTH USERS
SELECT 
    '🔐 AUTH USERS FOR BPVP36' as section,
    au.id as auth_uid,
    au.email,
    au.created_at,
    au.last_sign_in_at
FROM auth.users au
WHERE au.email IN (SELECT email FROM profiles WHERE promoter_id = 'BPVP36');

-- 6. CHECK ID MISMATCH
SELECT 
    '⚠️ ID MISMATCH ANALYSIS' as section,
    p.id as profile_id,
    au.id as auth_uid,
    p.email,
    p.promoter_id,
    p.role,
    CASE 
        WHEN p.id = au.id THEN '✅ IDs MATCH - No problem'
        WHEN p.id IS NULL THEN '❌ Profile not found'
        WHEN au.id IS NULL THEN '❌ Auth user not found'
        ELSE '❌ IDs DO NOT MATCH - THIS IS THE ROOT CAUSE'
    END as diagnosis
FROM profiles p
LEFT JOIN auth.users au ON p.email = au.email
WHERE p.promoter_id = 'BPVP36';

-- 7. CHECK ALL RLS POLICIES
SELECT 
    '🔒 ALL RLS POLICIES' as section,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    LEFT(qual::text, 100) as using_clause_preview
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd;

-- 8. CHECK TABLE PERMISSIONS
SELECT 
    '✅ TABLE PERMISSIONS' as section,
    table_name,
    grantee,
    privilege_type
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'withdrawal_requests', 'promoter_wallet', 'affiliate_commissions')
AND grantee IN ('authenticated', 'anon', 'service_role')
ORDER BY table_name, grantee, privilege_type;

-- 9. CHECK FOREIGN KEY CONSTRAINTS
SELECT 
    '🔗 FOREIGN KEY CONSTRAINTS' as section,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
AND tc.table_name = 'withdrawal_requests';

-- 10. CHECK EXISTING WITHDRAWAL REQUESTS
SELECT 
    '📊 EXISTING WITHDRAWAL REQUESTS' as section,
    COUNT(*) as total_requests,
    status,
    COUNT(*) FILTER (WHERE promoter_id IN (SELECT id FROM profiles WHERE promoter_id = 'BPVP36')) as bpvp36_requests
FROM withdrawal_requests
GROUP BY status;
