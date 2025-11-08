-- =====================================================
-- FORCE FIX BPVP27 - DIRECT APPROACH
-- =====================================================
-- The profile is still using non-existent auth user ID

-- =====================================================
-- 1. CURRENT STATE DIAGNOSIS
-- =====================================================

-- Check current BPVP27 profile
SELECT 'Current BPVP27 State' as info;
SELECT 
    promoter_id,
    id as profile_id,
    email,
    name,
    phone,
    status,
    created_at
FROM profiles 
WHERE promoter_id = 'BPVP27';

-- Check all auth users for this email
SELECT 'All Auth Users for Email' as info;
SELECT 
    id as auth_user_id,
    email,
    email_confirmed_at,
    created_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'CONFIRMED'
        ELSE 'UNCONFIRMED'
    END as status
FROM auth.users 
WHERE email = 'officialpanduks06@gmail.com'
ORDER BY created_at DESC;

-- =====================================================
-- 2. FORCE UPDATE BPVP27 PROFILE
-- =====================================================

DO $$
DECLARE
    working_auth_id UUID;
    auth_count INTEGER;
BEGIN
    -- Find any working auth user for this email
    SELECT COUNT(*) INTO auth_count
    FROM auth.users 
    WHERE email = 'officialpanduks06@gmail.com';
    
    RAISE NOTICE 'Found % auth users for officialpanduks06@gmail.com', auth_count;
    
    IF auth_count > 0 THEN
        -- Get the first available auth user
        SELECT id INTO working_auth_id
        FROM auth.users 
        WHERE email = 'officialpanduks06@gmail.com'
        ORDER BY created_at DESC
        LIMIT 1;
        
        RAISE NOTICE 'Using auth user: %', working_auth_id;
        
        -- Check if this auth user is already linked to another profile
        IF EXISTS(SELECT 1 FROM profiles WHERE id = working_auth_id AND promoter_id != 'BPVP27') THEN
            RAISE NOTICE '⚠️ Auth user % is linked to another profile', working_auth_id;
            
            -- Delete the other profile if it's a duplicate
            DELETE FROM profiles 
            WHERE id = working_auth_id 
              AND promoter_id != 'BPVP27'
              AND email = 'officialpanduks06@gmail.com';
            
            RAISE NOTICE '🗑️ Deleted duplicate profile for auth user %', working_auth_id;
        END IF;
        
        -- Force update BPVP27 profile to use working auth user
        UPDATE profiles 
        SET 
            id = working_auth_id,
            email = 'officialpanduks06@gmail.com'
        WHERE promoter_id = 'BPVP27';
        
        RAISE NOTICE '✅ Updated BPVP27 profile to use auth user: %', working_auth_id;
        
        -- Confirm the auth user
        UPDATE auth.users 
        SET 
            email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
            confirmation_sent_at = NULL,
            confirmation_token = NULL
        WHERE id = working_auth_id;
        
        RAISE NOTICE '✅ Confirmed auth user: %', working_auth_id;
        
    ELSE
        RAISE NOTICE '❌ No auth users found for officialpanduks06@gmail.com';
        RAISE NOTICE '💡 Need to create a new auth user or recreate the promoter';
    END IF;
END $$;

-- =====================================================
-- 3. VERIFICATION
-- =====================================================

-- Check updated BPVP27 profile
SELECT 'Updated BPVP27 Profile' as info;
SELECT 
    promoter_id,
    id as profile_id,
    email,
    name,
    phone,
    status
FROM profiles 
WHERE promoter_id = 'BPVP27';

-- Final alignment check
SELECT 
    'Final Alignment Check' as check_type,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM profiles p
            JOIN auth.users au ON p.id = au.id
            WHERE p.promoter_id = 'BPVP27'
              AND au.email_confirmed_at IS NOT NULL
              AND p.email = au.email
              AND p.status = 'Active'
        ) THEN 'READY FOR LOGIN'
        ELSE 'STILL NEEDS FIXING'
    END as result;

-- Detailed verification
SELECT 
    'Final Detailed Verification' as check_type,
    p.promoter_id,
    p.id as profile_id,
    au.id as auth_user_id,
    p.email as profile_email,
    au.email as auth_email,
    CASE WHEN p.id = au.id THEN 'MATCH' ELSE 'MISMATCH' END as id_match,
    CASE WHEN p.email = au.email THEN 'MATCH' ELSE 'MISMATCH' END as email_match,
    CASE WHEN au.email_confirmed_at IS NOT NULL THEN 'CONFIRMED' ELSE 'UNCONFIRMED' END as auth_status,
    p.status as profile_status
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.promoter_id = 'BPVP27';

-- =====================================================
-- 4. ALTERNATIVE: RECREATE PROMOTER (IF STILL FAILING)
-- =====================================================

-- If the above doesn't work, we need to recreate the promoter completely
-- This is the nuclear option - only use if everything else fails

/*
-- STEP 1: Backup current BPVP27 data
CREATE TEMP TABLE bpvp27_backup AS
SELECT * FROM profiles WHERE promoter_id = 'BPVP27';

-- STEP 2: Delete current BPVP27 profile
DELETE FROM profiles WHERE promoter_id = 'BPVP27';

-- STEP 3: Get or create a working auth user
-- (This would need to be done through the admin interface)

-- STEP 4: Recreate BPVP27 with working auth user ID
-- INSERT INTO profiles (id, email, name, role, phone, promoter_id, role_level, status, created_at, updated_at)
-- SELECT 
--     'WORKING_AUTH_USER_ID_HERE',
--     email, name, role, phone, promoter_id, role_level, status, created_at, NOW()
-- FROM bpvp27_backup;
*/

-- =====================================================
-- 5. SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'FORCE FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Attempted to force-fix BPVP27 profile alignment.';
    RAISE NOTICE 'Check the verification results above.';
    RAISE NOTICE '';
    RAISE NOTICE 'If still failing, you may need to:';
    RAISE NOTICE '1. Delete BPVP27 and recreate it via admin interface';
    RAISE NOTICE '2. Or create a new auth user manually';
    RAISE NOTICE '=======================================================';
END $$;
