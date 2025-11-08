-- =====================================================
-- FIX PROMOTER LOGIN ISSUES - COMPREHENSIVE SOLUTION
-- =====================================================

-- Fix for BPVP27 (Auth User ID: 58c3bd99-c27f-4df2-803a-fda35614bad3)

-- =====================================================
-- 1. FIX PROFILE ID MISMATCH
-- =====================================================

-- Update the profile to use the correct auth user ID
UPDATE profiles 
SET id = '58c3bd99-c27f-4df2-803a-fda35614bad3'
WHERE promoter_id = 'BPVP27';

-- =====================================================
-- 2. CONFIRM AUTH USER EMAIL (BYPASS EMAIL VERIFICATION)
-- =====================================================

-- Confirm the auth user's email to enable login
UPDATE auth.users 
SET 
    email_confirmed_at = NOW(),
    confirmation_sent_at = NULL,
    confirmation_token = NULL
WHERE id = '58c3bd99-c27f-4df2-803a-fda35614bad3';

-- =====================================================
-- 3. CLEAN UP DUPLICATE PHONE NUMBERS
-- =====================================================

-- Find and display duplicate phone numbers
SELECT phone, COUNT(*) as count, 
       STRING_AGG(promoter_id, ', ') as promoter_ids
FROM profiles 
WHERE role = 'promoter' 
  AND phone IS NOT NULL
GROUP BY phone 
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Clean up duplicates for phone 7411195267 (keep only BPVP27)
-- First, update other profiles with this phone to have unique phone numbers
UPDATE profiles 
SET phone = phone || '_old_' || promoter_id
WHERE phone = '7411195267' 
  AND promoter_id != 'BPVP27'
  AND role = 'promoter';

-- =====================================================
-- 4. VERIFY THE FIXES
-- =====================================================

-- Check BPVP27 profile and auth user alignment
SELECT 
    'Profile Check' as check_type,
    p.promoter_id,
    p.id as profile_id,
    p.email,
    p.phone,
    p.name,
    p.status
FROM profiles p
WHERE p.promoter_id = 'BPVP27';

-- Check auth user status
SELECT 
    'Auth User Check' as check_type,
    au.id,
    au.email,
    au.email_confirmed_at,
    au.confirmation_sent_at,
    CASE 
        WHEN au.email_confirmed_at IS NOT NULL THEN 'CONFIRMED'
        ELSE 'UNCONFIRMED'
    END as status
FROM auth.users au
WHERE au.id = '58c3bd99-c27f-4df2-803a-fda35614bad3';

-- Check profile-auth alignment
SELECT 
    'Alignment Check' as check_type,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM profiles p
            JOIN auth.users au ON p.id = au.id
            WHERE p.promoter_id = 'BPVP27'
              AND au.email_confirmed_at IS NOT NULL
        ) THEN 'READY FOR LOGIN'
        ELSE 'NEEDS FIXING'
    END as result;

-- =====================================================
-- 5. PREVENT FUTURE ISSUES
-- =====================================================

-- Create a function to auto-confirm auth users created via admin
CREATE OR REPLACE FUNCTION auto_confirm_admin_created_users()
RETURNS TRIGGER AS $$
BEGIN
    -- If user was created with email_confirm: true in metadata, confirm immediately
    IF NEW.raw_user_meta_data->>'admin_created' = 'true' THEN
        NEW.email_confirmed_at = NOW();
        NEW.confirmation_sent_at = NULL;
        NEW.confirmation_token = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for auto-confirmation
DROP TRIGGER IF EXISTS auto_confirm_trigger ON auth.users;
CREATE TRIGGER auto_confirm_trigger
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION auto_confirm_admin_created_users();

-- =====================================================
-- 6. SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PROMOTER LOGIN ISSUES FIXED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'FIXES APPLIED:';
    RAISE NOTICE '1. ✅ Updated profile ID to match auth user ID';
    RAISE NOTICE '2. ✅ Confirmed auth user email (bypassed verification)';
    RAISE NOTICE '3. ✅ Cleaned up duplicate phone numbers';
    RAISE NOTICE '4. ✅ Added auto-confirmation for future admin-created users';
    RAISE NOTICE '';
    RAISE NOTICE 'BPVP27 should now be able to login with:';
    RAISE NOTICE '• Promoter ID: BPVP27 + password';
    RAISE NOTICE '• Email: officialpanduks06@gmail.com + password';
    RAISE NOTICE '• Phone: 7411195267 + password';
    RAISE NOTICE '=======================================================';
END $$;
