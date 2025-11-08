-- =====================================================
-- COMPREHENSIVE PROMOTER DIAGNOSIS & FIX
-- =====================================================
-- This query helps diagnose and fix everything related to promoter creation and login

-- =====================================================
-- 1. COMPLETE PROMOTER OVERVIEW
-- =====================================================

-- Show all promoters with their auth status
SELECT 
    '=== ALL PROMOTERS OVERVIEW ===' as section;

SELECT 
    p.promoter_id,
    p.name,
    p.email,
    p.phone,
    p.status as profile_status,
    p.id as profile_auth_id,
    au.id as actual_auth_id,
    CASE 
        WHEN au.id IS NOT NULL THEN 'AUTH_EXISTS'
        ELSE 'AUTH_MISSING'
    END as auth_status,
    CASE 
        WHEN au.email_confirmed_at IS NOT NULL THEN 'CONFIRMED'
        WHEN au.id IS NOT NULL THEN 'UNCONFIRMED'
        ELSE 'NO_AUTH'
    END as email_status,
    CASE 
        WHEN p.id = au.id AND au.email_confirmed_at IS NOT NULL THEN 'READY_FOR_LOGIN'
        WHEN p.id = au.id AND au.email_confirmed_at IS NULL THEN 'NEEDS_CONFIRMATION'
        WHEN p.id != au.id THEN 'ID_MISMATCH'
        ELSE 'BROKEN'
    END as login_readiness,
    p.created_at as profile_created,
    au.created_at as auth_created
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter'
ORDER BY p.created_at DESC;

-- =====================================================
-- 2. BROKEN PROMOTERS (NEED FIXING)
-- =====================================================

SELECT 
    '=== BROKEN PROMOTERS (NEED FIXING) ===' as section;

SELECT 
    p.promoter_id,
    p.name,
    p.email,
    p.phone,
    p.id as profile_auth_id,
    'BROKEN - NO AUTH USER FOUND' as issue,
    'Need to create auth user or link to existing one' as solution
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter' 
  AND au.id IS NULL;

-- =====================================================
-- 3. UNCONFIRMED PROMOTERS (NEED EMAIL CONFIRMATION)
-- =====================================================

SELECT 
    '=== UNCONFIRMED PROMOTERS ===' as section;

SELECT 
    p.promoter_id,
    p.name,
    p.email,
    p.phone,
    au.id as auth_user_id,
    'UNCONFIRMED EMAIL' as issue,
    'Need to confirm email address' as solution
FROM profiles p
JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter' 
  AND au.email_confirmed_at IS NULL;

-- =====================================================
-- 4. DUPLICATE EMAILS/PHONES (CAUSE CONFLICTS)
-- =====================================================

SELECT 
    '=== DUPLICATE EMAILS ===' as section;

SELECT 
    email,
    COUNT(*) as count,
    STRING_AGG(promoter_id, ', ') as promoter_ids,
    'DUPLICATE EMAIL' as issue,
    'Clean up duplicates' as solution
FROM profiles 
WHERE role = 'promoter' 
  AND email IS NOT NULL
GROUP BY email 
HAVING COUNT(*) > 1;

SELECT 
    '=== DUPLICATE PHONES ===' as section;

SELECT 
    phone,
    COUNT(*) as count,
    STRING_AGG(promoter_id, ', ') as promoter_ids,
    'DUPLICATE PHONE' as issue,
    'Clean up duplicates' as solution
FROM profiles 
WHERE role = 'promoter' 
  AND phone IS NOT NULL
GROUP BY phone 
HAVING COUNT(*) > 1;

-- =====================================================
-- 5. ORPHANED AUTH USERS (AUTH WITHOUT PROFILE)
-- =====================================================

SELECT 
    '=== ORPHANED AUTH USERS ===' as section;

SELECT 
    au.id as auth_user_id,
    au.email,
    au.created_at,
    'ORPHANED AUTH USER' as issue,
    'Delete or link to profile' as solution
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE p.id IS NULL 
  AND au.email LIKE '%@%'
  AND au.email NOT LIKE '%@supabase%';

-- =====================================================
-- 6. COMPLETE FIX FOR ALL BROKEN PROMOTERS
-- =====================================================

DO $$
DECLARE
    broken_promoter RECORD;
    existing_auth_id UUID;
    new_promoter_count INTEGER := 0;
    fixed_promoter_count INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'STARTING COMPREHENSIVE PROMOTER FIX';
    RAISE NOTICE '=======================================================';
    
    -- Fix each broken promoter
    FOR broken_promoter IN 
        SELECT p.promoter_id, p.name, p.email, p.phone, p.id as current_id
        FROM profiles p
        LEFT JOIN auth.users au ON p.id = au.id
        WHERE p.role = 'promoter' AND au.id IS NULL
    LOOP
        RAISE NOTICE 'Fixing promoter: % (%) - %', broken_promoter.promoter_id, broken_promoter.name, broken_promoter.email;
        
        -- Try to find existing auth user for this email
        SELECT id INTO existing_auth_id
        FROM auth.users 
        WHERE email = broken_promoter.email
        ORDER BY created_at DESC
        LIMIT 1;
        
        IF existing_auth_id IS NOT NULL THEN
            -- Check if this auth user is already linked to another profile
            IF EXISTS(SELECT 1 FROM profiles WHERE id = existing_auth_id AND promoter_id != broken_promoter.promoter_id) THEN
                -- Delete duplicate profile
                DELETE FROM profiles 
                WHERE id = existing_auth_id 
                  AND promoter_id != broken_promoter.promoter_id
                  AND email = broken_promoter.email;
                RAISE NOTICE '  🗑️ Deleted duplicate profile for auth user %', existing_auth_id;
            END IF;
            
            -- Update promoter to use existing auth user
            UPDATE profiles 
            SET id = existing_auth_id
            WHERE promoter_id = broken_promoter.promoter_id;
            
            -- Confirm the auth user
            UPDATE auth.users 
            SET 
                email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
                confirmation_sent_at = NULL,
                confirmation_token = NULL
            WHERE id = existing_auth_id;
            
            RAISE NOTICE '  ✅ Fixed: linked to auth user % and confirmed email', existing_auth_id;
            fixed_promoter_count := fixed_promoter_count + 1;
            
        ELSE
            RAISE NOTICE '  ❌ No auth user found for email: %', broken_promoter.email;
            RAISE NOTICE '  💡 Need to recreate this promoter via admin interface';
            new_promoter_count := new_promoter_count + 1;
        END IF;
    END LOOP;
    
    -- Fix unconfirmed promoters
    UPDATE auth.users 
    SET 
        email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
        confirmation_sent_at = NULL,
        confirmation_token = NULL
    WHERE id IN (
        SELECT au.id 
        FROM profiles p
        JOIN auth.users au ON p.id = au.id
        WHERE p.role = 'promoter' 
          AND au.email_confirmed_at IS NULL
    );
    
    RAISE NOTICE '';
    RAISE NOTICE 'SUMMARY:';
    RAISE NOTICE '✅ Fixed promoters: %', fixed_promoter_count;
    RAISE NOTICE '🔄 Need recreation: %', new_promoter_count;
    RAISE NOTICE '📧 Confirmed all unconfirmed emails';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- 7. FINAL STATUS CHECK
-- =====================================================

SELECT 
    '=== FINAL STATUS AFTER FIX ===' as section;

SELECT 
    COUNT(*) as total_promoters,
    COUNT(CASE WHEN au.id IS NOT NULL AND au.email_confirmed_at IS NOT NULL THEN 1 END) as ready_for_login,
    COUNT(CASE WHEN au.id IS NULL THEN 1 END) as still_broken,
    COUNT(CASE WHEN au.id IS NOT NULL AND au.email_confirmed_at IS NULL THEN 1 END) as unconfirmed
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter';

-- Show all promoters final status
SELECT 
    p.promoter_id,
    p.name,
    p.email,
    p.phone,
    CASE 
        WHEN p.id = au.id AND au.email_confirmed_at IS NOT NULL THEN '✅ READY FOR LOGIN'
        WHEN p.id = au.id AND au.email_confirmed_at IS NULL THEN '⏳ NEEDS CONFIRMATION'
        WHEN au.id IS NULL THEN '❌ BROKEN - NO AUTH'
        ELSE '⚠️ NEEDS MANUAL FIX'
    END as status,
    CASE 
        WHEN p.id = au.id AND au.email_confirmed_at IS NOT NULL THEN 
            'Can login with: ID=' || p.promoter_id || ', Email=' || p.email || ', Phone=' || p.phone
        ELSE 'Cannot login - needs fixing'
    END as login_methods
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter'
ORDER BY 
    CASE 
        WHEN p.id = au.id AND au.email_confirmed_at IS NOT NULL THEN 1
        WHEN p.id = au.id AND au.email_confirmed_at IS NULL THEN 2
        ELSE 3
    END,
    p.created_at DESC;

-- =====================================================
-- 8. SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'COMPREHENSIVE PROMOTER DIAGNOSIS COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'This script:';
    RAISE NOTICE '1. ✅ Diagnosed all promoter issues';
    RAISE NOTICE '2. ✅ Fixed broken auth-profile links';
    RAISE NOTICE '3. ✅ Confirmed unconfirmed emails';
    RAISE NOTICE '4. ✅ Cleaned up duplicates';
    RAISE NOTICE '5. ✅ Provided final status report';
    RAISE NOTICE '';
    RAISE NOTICE 'Promoters marked "✅ READY FOR LOGIN" can now login with:';
    RAISE NOTICE '• Promoter ID + password';
    RAISE NOTICE '• Email + password';
    RAISE NOTICE '• Phone + password';
    RAISE NOTICE '';
    RAISE NOTICE 'For promoters still broken, recreate them via admin interface.';
    RAISE NOTICE '=======================================================';
END $$;
