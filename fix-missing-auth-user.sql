-- =====================================================
-- FIX MISSING AUTH USER - CRITICAL ISSUE
-- =====================================================
-- The auth user 58c3bd99-c27f-4df2-803a-fda35614bad3 doesn't exist!

-- =====================================================
-- 1. DIAGNOSE THE MISSING AUTH USER
-- =====================================================

-- Check if the auth user actually exists
SELECT 'Auth User Existence Check' as check_type;
SELECT 
    CASE 
        WHEN EXISTS(SELECT 1 FROM auth.users WHERE id = '58c3bd99-c27f-4df2-803a-fda35614bad3') 
        THEN 'AUTH USER EXISTS'
        ELSE 'AUTH USER MISSING'
    END as result;

-- Check what auth users exist for this email
SELECT 'Auth Users for Email' as check_type;
SELECT 
    id,
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
-- 2. SOLUTION OPTIONS
-- =====================================================

-- OPTION A: Find existing auth user and update profile to use it
DO $$
DECLARE
    existing_auth_id UUID;
    auth_count INTEGER;
BEGIN
    -- Count auth users with this email
    SELECT COUNT(*) INTO auth_count
    FROM auth.users 
    WHERE email = 'officialpanduks06@gmail.com';
    
    RAISE NOTICE 'Found % auth users for email officialpanduks06@gmail.com', auth_count;
    
    IF auth_count > 0 THEN
        -- Get the most recent auth user for this email
        SELECT id INTO existing_auth_id
        FROM auth.users 
        WHERE email = 'officialpanduks06@gmail.com'
        ORDER BY created_at DESC
        LIMIT 1;
        
        RAISE NOTICE 'Using existing auth user: %', existing_auth_id;
        
        -- Update profile to use existing auth user
        UPDATE profiles 
        SET id = existing_auth_id
        WHERE promoter_id = 'BPVP27';
        
        -- Confirm the auth user
        UPDATE auth.users 
        SET 
            email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
            confirmation_sent_at = NULL,
            confirmation_token = NULL
        WHERE id = existing_auth_id;
        
        RAISE NOTICE '✅ Updated profile BPVP27 to use existing auth user: %', existing_auth_id;
        
    ELSE
        RAISE NOTICE '❌ No auth users found for email officialpanduks06@gmail.com';
        RAISE NOTICE '💡 You will need to create a new auth user or use a different approach';
    END IF;
END $$;

-- =====================================================
-- 3. VERIFICATION AFTER FIX
-- =====================================================

-- Check the alignment again
SELECT 
    'Post-Fix Alignment Check' as check_type,
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
    'Post-Fix Detailed Verification' as check_type,
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
-- 4. ALTERNATIVE: CREATE NEW AUTH USER (IF NEEDED)
-- =====================================================

-- If no existing auth user found, create a new one
-- NOTE: This requires admin privileges and may not work in all setups

/*
-- Only run this if no existing auth user was found above
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    confirmation_sent_at,
    confirmation_token,
    recovery_sent_at,
    recovery_token,
    email_change_sent_at,
    email_change,
    email_change_token_new,
    email_change_token_current,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    phone,
    phone_confirmed_at,
    phone_change,
    phone_change_token,
    phone_change_sent_at,
    email_change_confirm_status,
    banned_until,
    reauthentication_token,
    reauthentication_sent_at,
    is_sso_user
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    '58c3bd99-c27f-4df2-803a-fda35614bad3',
    'authenticated',
    'authenticated',
    'officialpanduks06@gmail.com',
    crypt('YourPasswordHere', gen_salt('bf')), -- Replace with actual password
    NOW(),
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    '{"provider": "email", "providers": ["email"]}',
    '{"name": "Pandu Shirabur", "phone": "7411195267", "role": "promoter"}',
    false,
    NOW(),
    NOW(),
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    0,
    NULL,
    NULL,
    NULL,
    false
);
*/

-- =====================================================
-- 5. SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'MISSING AUTH USER FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'The script attempted to:';
    RAISE NOTICE '1. Find existing auth user for officialpanduks06@gmail.com';
    RAISE NOTICE '2. Update profile to use existing auth user';
    RAISE NOTICE '3. Confirm the auth user';
    RAISE NOTICE '';
    RAISE NOTICE 'Check the verification results above.';
    RAISE NOTICE 'If still failing, you may need to recreate the promoter.';
    RAISE NOTICE '=======================================================';
END $$;
