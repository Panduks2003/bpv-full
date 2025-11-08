-- =====================================================
-- MINIMAL RLS FIX FOR PROMOTER CREATION
-- =====================================================
-- Based on diagnostic output, you have conflicting RLS policies
-- This script removes conflicting policies and keeps only the permissive ones

-- =====================================================
-- 1. REMOVE CONFLICTING RESTRICTIVE POLICIES
-- =====================================================

-- Remove restrictive policies that might conflict with permissive ones
DROP POLICY IF EXISTS "Admin full access" ON profiles;
DROP POLICY IF EXISTS "Simple profiles access" ON profiles;
DROP POLICY IF EXISTS "Ultra simple profiles delete" ON profiles;
DROP POLICY IF EXISTS "Ultra simple profiles update" ON profiles;
DROP POLICY IF EXISTS "Users update own profile" ON profiles;
DROP POLICY IF EXISTS "Users view own profile" ON profiles;

-- Remove duplicate/conflicting policies
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;

-- =====================================================
-- 2. KEEP ONLY THE MOST PERMISSIVE POLICIES
-- =====================================================

-- The diagnostic shows you already have these good policies:
-- - allow_all_profiles (ALL operations with true)
-- - authenticated_users_can_read_profiles
-- - authenticated_users_can_insert_profiles  
-- - authenticated_users_can_update_profiles
-- - service_role_can_do_everything

-- These should be sufficient for promoter creation to work

-- =====================================================
-- 3. ENSURE PROMOTER_ID_SEQUENCE ACCESS
-- =====================================================

-- Grant permissions on sequence table (might be missing)
GRANT SELECT, UPDATE ON promoter_id_sequence TO authenticated;
GRANT SELECT, UPDATE ON promoter_id_sequence TO public;

-- =====================================================
-- 4. TEST THE FIX
-- =====================================================

-- Test promoter creation function
DO $$
DECLARE
    test_result JSON;
BEGIN
    -- Test the function
    SELECT create_unified_promoter(
        'Test Minimal Fix',
        'testpass123',
        '9876543210',
        'test@minimal-fix.com',
        'Test Address',
        NULL,
        'Affiliate',
        'Active'
    ) INTO test_result;
    
    -- Check result
    IF (test_result->>'success')::boolean THEN
        RAISE NOTICE '✅ SUCCESS: Promoter creation function works!';
        RAISE NOTICE 'Result: %', test_result;
        
        -- Clean up test data
        DELETE FROM profiles WHERE id = (test_result->>'user_id')::UUID;
        RAISE NOTICE '🧹 Test promoter cleaned up';
    ELSE
        RAISE NOTICE '❌ FAILED: %', test_result->>'error';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR: %', SQLERRM;
END $$;

-- =====================================================
-- 5. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'MINIMAL RLS FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '1. Removed conflicting restrictive RLS policies';
    RAISE NOTICE '2. Kept permissive policies (allow_all_profiles, etc.)';
    RAISE NOTICE '3. Granted sequence table permissions';
    RAISE NOTICE '4. Tested promoter creation function';
    RAISE NOTICE '';
    RAISE NOTICE 'Try creating a promoter from the admin UI now!';
    RAISE NOTICE '=======================================================';
END $$;
