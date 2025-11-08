-- =====================================================
-- CHECK PROM0010 STATUS
-- =====================================================
-- Quick check of the newly created PROM0010

-- =====================================================
-- 1. CHECK PROM0010 IN PROFILES
-- =====================================================

SELECT 
    'PROM0010_PROFILE' as check_type,
    id,
    name,
    email,
    phone,
    promoter_id,
    role,
    status,
    created_at
FROM profiles 
WHERE promoter_id = 'PROM0010';

-- =====================================================
-- 2. CHECK PROM0010 AUTH RECORD
-- =====================================================

SELECT 
    'PROM0010_AUTH' as check_type,
    au.id,
    au.email,
    au.created_at,
    au.email_confirmed_at,
    CASE WHEN au.encrypted_password IS NOT NULL THEN 'HAS_PASSWORD' ELSE 'NO_PASSWORD' END as password_status,
    LENGTH(au.encrypted_password) as password_length
FROM auth.users au
WHERE au.id IN (
    SELECT p.id FROM profiles p WHERE p.promoter_id = 'PROM0010'
);

-- =====================================================
-- 3. TEST AUTHENTICATION FUNCTION DIRECTLY
-- =====================================================

DO $$
DECLARE
    test_result RECORD;
    promoter_exists BOOLEAN := FALSE;
    auth_exists BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=== TESTING PROM0010 AUTHENTICATION ===';
    
    -- Check if promoter exists
    SELECT EXISTS(SELECT 1 FROM profiles WHERE promoter_id = 'PROM0010' AND role = 'promoter') INTO promoter_exists;
    
    -- Check if auth record exists
    SELECT EXISTS(
        SELECT 1 FROM auth.users au 
        INNER JOIN profiles p ON au.id = p.id 
        WHERE p.promoter_id = 'PROM0010'
    ) INTO auth_exists;
    
    RAISE NOTICE 'Promoter exists in profiles: %', promoter_exists;
    RAISE NOTICE 'Auth record exists: %', auth_exists;
    
    IF promoter_exists AND auth_exists THEN
        -- Test with wrong password
        BEGIN
            SELECT * INTO test_result 
            FROM authenticate_promoter_by_id('PROM0010', 'wrongpassword');
            RAISE NOTICE '❌ ERROR: Should have failed with wrong password';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '✅ Function works: %', SQLERRM;
        END;
        
        RAISE NOTICE '';
        RAISE NOTICE 'PROM0010 has both profile and auth records.';
        RAISE NOTICE 'Try logging in with the correct password you set during creation.';
        
    ELSIF promoter_exists AND NOT auth_exists THEN
        RAISE NOTICE '';
        RAISE NOTICE '❌ PROBLEM: PROM0010 exists in profiles but has no auth.users record';
        RAISE NOTICE 'This means the promoter creation process is not creating auth records properly.';
        
    ELSIF NOT promoter_exists THEN
        RAISE NOTICE '';
        RAISE NOTICE '❌ PROBLEM: PROM0010 does not exist in profiles table';
        RAISE NOTICE 'The promoter creation may have failed.';
    END IF;
    
END $$;

-- =====================================================
-- 4. CHECK CREATE_UNIFIED_PROMOTER FUNCTION
-- =====================================================

SELECT 
    'FUNCTION_CHECK' as check_type,
    proname as function_name,
    pg_get_function_arguments(oid) as parameters
FROM pg_proc 
WHERE proname = 'create_unified_promoter'
AND pronamespace = 'public'::regnamespace;

-- =====================================================
-- 5. COMPLETION MESSAGE
-- =====================================================


