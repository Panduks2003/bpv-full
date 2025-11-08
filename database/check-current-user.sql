-- =====================================================
-- CHECK CURRENT USER FOR WITHDRAWAL DEBUGGING
-- =====================================================
-- Run this while logged in as the promoter
-- =====================================================

-- 1. Check auth.uid()
SELECT 
    '🔍 Auth User' as check_type,
    auth.uid() as current_auth_uid;

-- 2. Check if profile exists for this auth.uid()
SELECT 
    '🔍 Profile Check' as check_type,
    p.id,
    p.email,
    p.name,
    p.role,
    p.promoter_id,
    CASE 
        WHEN p.id = auth.uid() THEN '✅ ID Matches auth.uid()'
        ELSE '❌ ID Does NOT match auth.uid()'
    END as id_match_status
FROM profiles p
WHERE p.id = auth.uid();

-- 3. Check if there's a profile with same email but different ID
SELECT 
    '🔍 Email Match Check' as check_type,
    au.id as auth_id,
    au.email as auth_email,
    p.id as profile_id,
    p.email as profile_email,
    p.role,
    CASE 
        WHEN au.id = p.id THEN '✅ IDs Match'
        ELSE '❌ ID MISMATCH - This is the problem!'
    END as status
FROM auth.users au
LEFT JOIN profiles p ON p.email = au.email
WHERE au.id = auth.uid();

-- 4. Test the RLS policy condition
SELECT 
    '🧪 RLS Policy Test' as check_type,
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() AND role = 'promoter'
    ) as can_insert_withdrawal;

-- 5. Show what the INSERT would look like
SELECT 
    '📝 Insert Preview' as check_type,
    auth.uid() as promoter_id_to_insert,
    1000 as amount,
    'pending' as status,
    'Test withdrawal' as reason;
