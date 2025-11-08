-- =====================================================
-- FIX ALIGNMENT ISSUE - TARGETED SOLUTION
-- =====================================================
-- This addresses the specific alignment check failure

-- =====================================================
-- 1. DETAILED DIAGNOSIS
-- =====================================================

-- Check current state of BPVP27
SELECT 'Current Profile State' as info;
SELECT 
    promoter_id,
    id as profile_id,
    email,
    phone,
    name,
    status,
    role
FROM profiles 
WHERE promoter_id = 'BPVP27';

-- Check auth user state
SELECT 'Current Auth User State' as info;
SELECT 
    id as auth_user_id,
    email,
    email_confirmed_at,
    confirmation_sent_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'CONFIRMED'
        ELSE 'UNCONFIRMED'
    END as confirmation_status
FROM auth.users 
WHERE id = '58c3bd99-c27f-4df2-803a-fda35614bad3';

-- =====================================================
-- 2. FORCE ALIGNMENT FIX
-- =====================================================

-- Step 1: Ensure profile has correct auth user ID
UPDATE profiles 
SET id = '58c3bd99-c27f-4df2-803a-fda35614bad3'
WHERE promoter_id = 'BPVP27';

-- Step 2: Force confirm the auth user
UPDATE auth.users 
SET 
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    confirmation_sent_at = NULL,
    confirmation_token = NULL,
    email_change_sent_at = NULL,
    email_change_token_new = NULL,
    email_change_token_current = NULL
WHERE id = '58c3bd99-c27f-4df2-803a-fda35614bad3';

-- Step 3: Ensure email consistency
UPDATE profiles 
SET email = (
    SELECT email FROM auth.users WHERE id = '58c3bd99-c27f-4df2-803a-fda35614bad3'
)
WHERE promoter_id = 'BPVP27';

-- =====================================================
-- 3. VERIFICATION AFTER FIX
-- =====================================================

-- Re-run the alignment check
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
    'Detailed Verification' as check_type,
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
-- 4. ALTERNATIVE FIX (IF ABOVE DOESN'T WORK)
-- =====================================================

-- If the above doesn't work, we may need to recreate the profile with correct ID
-- This is a more drastic measure - only use if alignment still fails

/*
-- Delete existing profile (BACKUP FIRST!)
-- INSERT INTO profiles_backup SELECT * FROM profiles WHERE promoter_id = 'BPVP27';

-- Recreate profile with correct auth user ID
DELETE FROM profiles WHERE promoter_id = 'BPVP27';

INSERT INTO profiles (
    id,
    email,
    name,
    role,
    phone,
    address,
    promoter_id,
    role_level,
    status,
    parent_promoter_id,
    created_at,
    updated_at
) VALUES (
    '58c3bd99-c27f-4df2-803a-fda35614bad3',
    'officialpanduks06@gmail.com',
    'Pandu Shirabur',
    'promoter',
    '7411195267',
    NULL,
    'BPVP27',
    'Affiliate',
    'Active',
    NULL,
    NOW(),
    NOW()
);
*/

-- =====================================================
-- 5. SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'ALIGNMENT FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Actions taken:';
    RAISE NOTICE '1. ✅ Forced profile ID to match auth user ID';
    RAISE NOTICE '2. ✅ Force-confirmed auth user email';
    RAISE NOTICE '3. ✅ Ensured email consistency between profile and auth';
    RAISE NOTICE '';
    RAISE NOTICE 'Run the verification queries above to check alignment.';
    RAISE NOTICE 'If still failing, uncomment and run the alternative fix.';
    RAISE NOTICE '=======================================================';
END $$;
