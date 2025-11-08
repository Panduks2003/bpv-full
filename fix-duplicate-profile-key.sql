-- =====================================================
-- FIX DUPLICATE PROFILE KEY ISSUE
-- =====================================================
-- Auth user c38c36ce-177e-4407-9233-d7fdbd4e150e already has a profile

-- =====================================================
-- 1. INVESTIGATE THE DUPLICATE
-- =====================================================

-- Check what profile is already using this auth user ID
SELECT 'Existing Profile Using Auth User' as info;
SELECT 
    promoter_id,
    id as profile_id,
    email,
    name,
    phone,
    status,
    role,
    created_at
FROM profiles 
WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e';

-- Check all profiles for this email
SELECT 'All Profiles for Email' as info;
SELECT 
    promoter_id,
    id as profile_id,
    email,
    name,
    phone,
    status,
    role,
    created_at
FROM profiles 
WHERE email = 'officialpanduks06@gmail.com'
ORDER BY created_at DESC;

-- Check the current BPVP27 profile
SELECT 'Current BPVP27 Profile' as info;
SELECT 
    promoter_id,
    id as profile_id,
    email,
    name,
    phone,
    status,
    role,
    created_at
FROM profiles 
WHERE promoter_id = 'BPVP27';

-- =====================================================
-- 2. SOLUTION OPTIONS
-- =====================================================

DO $$
DECLARE
    existing_profile_promoter_id TEXT;
    existing_profile_count INTEGER;
    bpvp27_current_id UUID;
BEGIN
    -- Check if the auth user is already linked to another promoter
    SELECT promoter_id INTO existing_profile_promoter_id
    FROM profiles 
    WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e'
    LIMIT 1;
    
    -- Get current BPVP27 profile ID
    SELECT id INTO bpvp27_current_id
    FROM profiles 
    WHERE promoter_id = 'BPVP27';
    
    RAISE NOTICE 'Auth user c38c36ce-177e-4407-9233-d7fdbd4e150e is linked to promoter: %', COALESCE(existing_profile_promoter_id, 'NONE');
    RAISE NOTICE 'BPVP27 current profile ID: %', bpvp27_current_id;
    
    IF existing_profile_promoter_id IS NOT NULL AND existing_profile_promoter_id != 'BPVP27' THEN
        -- Case 1: Auth user is linked to a different promoter
        RAISE NOTICE '⚠️ Auth user is already linked to promoter: %', existing_profile_promoter_id;
        RAISE NOTICE '💡 Options:';
        RAISE NOTICE '   A) Delete the duplicate profile: %', existing_profile_promoter_id;
        RAISE NOTICE '   B) Use a different auth user for BPVP27';
        RAISE NOTICE '   C) Merge the profiles';
        
        -- Check if the existing profile is a duplicate of BPVP27
        SELECT COUNT(*) INTO existing_profile_count
        FROM profiles 
        WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e'
          AND email = 'officialpanduks06@gmail.com'
          AND phone = '7411195267';
          
        IF existing_profile_count > 0 THEN
            RAISE NOTICE '🔍 The existing profile appears to be a duplicate of BPVP27';
            RAISE NOTICE '🔧 Proceeding to delete the duplicate and update BPVP27';
            
            -- Delete the duplicate profile
            DELETE FROM profiles 
            WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e'
              AND promoter_id != 'BPVP27';
            
            -- Now update BPVP27 to use the auth user
            UPDATE profiles 
            SET id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e'
            WHERE promoter_id = 'BPVP27';
            
            RAISE NOTICE '✅ Successfully updated BPVP27 to use auth user';
            
        ELSE
            RAISE NOTICE '❌ Cannot automatically resolve - manual intervention needed';
        END IF;
        
    ELSIF existing_profile_promoter_id = 'BPVP27' THEN
        -- Case 2: Auth user is already correctly linked to BPVP27
        RAISE NOTICE '✅ Auth user is already correctly linked to BPVP27';
        
    ELSE
        -- Case 3: Auth user exists but no profile linked (shouldn't happen with the error)
        RAISE NOTICE '🔧 Auth user exists but no profile linked - updating BPVP27';
        
        UPDATE profiles 
        SET id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e'
        WHERE promoter_id = 'BPVP27';
        
        RAISE NOTICE '✅ Successfully updated BPVP27 to use auth user';
    END IF;
    
    -- Confirm the auth user
    UPDATE auth.users 
    SET 
        email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
        confirmation_sent_at = NULL,
        confirmation_token = NULL
    WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e';
    
    RAISE NOTICE '✅ Auth user confirmed';
    
END $$;

-- =====================================================
-- 3. VERIFICATION
-- =====================================================

-- Check final alignment
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
-- 4. SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'DUPLICATE KEY FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'The script handled the duplicate profile key issue.';
    RAISE NOTICE 'Check the verification results above.';
    RAISE NOTICE 'BPVP27 should now be ready for login!';
    RAISE NOTICE '=======================================================';
END $$;
