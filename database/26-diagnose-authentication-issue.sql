-- =====================================================
-- DIAGNOSE AUTHENTICATION ISSUE
-- =====================================================
-- Check why PROM0009 authentication is failing

-- =====================================================
-- 1. CHECK PROMOTER PROM0009 IN PROFILES TABLE
-- =====================================================

SELECT 
    'PROMOTER_IN_PROFILES' as check_type,
    id,
    name,
    email,
    phone,
    promoter_id,
    role,
    status,
    created_at
FROM profiles 
WHERE promoter_id = 'PROM0009';

-- =====================================================
-- 2. CHECK IF AUTH.USERS RECORD EXISTS
-- =====================================================

SELECT 
    'AUTH_USER_EXISTS' as check_type,
    au.id,
    au.email,
    au.created_at,
    au.email_confirmed_at,
    CASE WHEN au.encrypted_password IS NOT NULL THEN 'HAS_PASSWORD' ELSE 'NO_PASSWORD' END as password_status
FROM auth.users au
WHERE au.id IN (
    SELECT p.id FROM profiles p WHERE p.promoter_id = 'PROM0009'
);

-- =====================================================
-- 3. CHECK ALL PROMOTERS WITH MISSING AUTH RECORDS
-- =====================================================

SELECT 
    'PROMOTERS_WITHOUT_AUTH' as check_type,
    p.promoter_id,
    p.name,
    p.email,
    p.phone,
    p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter' 
AND au.id IS NULL
ORDER BY p.created_at DESC;

-- =====================================================
-- 4. CHECK ALL PROMOTERS WITH AUTH RECORDS
-- =====================================================

SELECT 
    'PROMOTERS_WITH_AUTH' as check_type,
    p.promoter_id,
    p.name,
    p.email,
    p.phone,
    CASE WHEN au.encrypted_password IS NOT NULL THEN 'HAS_PASSWORD' ELSE 'NO_PASSWORD' END as password_status,
    p.created_at
FROM profiles p
INNER JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter'
ORDER BY p.created_at DESC
LIMIT 10;

-- =====================================================
-- 5. TEST AUTHENTICATION FUNCTION WITH EXISTING DATA
-- =====================================================

DO $$
DECLARE
    test_promoter RECORD;
    test_result RECORD;
BEGIN
    RAISE NOTICE '=== TESTING AUTHENTICATION WITH EXISTING PROMOTERS ===';
    
    -- Find a promoter that has both profile and auth records
    SELECT p.promoter_id, p.name, p.email
    INTO test_promoter
    FROM profiles p
    INNER JOIN auth.users au ON p.id = au.id
    WHERE p.role = 'promoter' 
    AND p.promoter_id IS NOT NULL
    AND au.encrypted_password IS NOT NULL
    LIMIT 1;
    
    IF test_promoter.promoter_id IS NOT NULL THEN
        RAISE NOTICE 'Found testable promoter: % (%, %)', 
            test_promoter.promoter_id, test_promoter.name, test_promoter.email;
        
        -- Test with wrong password (should fail gracefully)
        BEGIN
            SELECT * INTO test_result 
            FROM authenticate_promoter_by_id(test_promoter.promoter_id, 'wrongpassword');
            RAISE NOTICE '❌ ERROR: Should have failed with wrong password';
        EXCEPTION 
            WHEN OTHERS THEN
                IF SQLERRM = 'Invalid Promoter ID or password' THEN
                    RAISE NOTICE '✅ SUCCESS: Function correctly validates passwords';
                ELSE
                    RAISE NOTICE '⚠️  Unexpected error: %', SQLERRM;
                END IF;
        END;
        
        RAISE NOTICE '';
        RAISE NOTICE 'To test successful login, use:';
        RAISE NOTICE 'Promoter ID: %', test_promoter.promoter_id;
        RAISE NOTICE 'Password: [the password you set when creating this promoter]';
        
    ELSE
        RAISE NOTICE '⚠️  No promoters found with both profile and auth records';
        RAISE NOTICE 'This suggests promoters are not being created with proper auth records';
    END IF;
    
END $$;

-- =====================================================
-- 6. SHOW RECENT PROMOTER CREATION ACTIVITY
-- =====================================================

SELECT 
    'RECENT_PROMOTERS' as check_type,
    p.promoter_id,
    p.name,
    p.created_at,
    CASE WHEN au.id IS NOT NULL THEN 'HAS_AUTH' ELSE 'NO_AUTH' END as auth_status
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter'
ORDER BY p.created_at DESC
LIMIT 5;

-- =====================================================
-- 7. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'AUTHENTICATION DIAGNOSIS COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Check the results above to understand:';
    RAISE NOTICE '1. Whether PROM0009 exists in profiles table';
    RAISE NOTICE '2. Whether it has a corresponding auth.users record';
    RAISE NOTICE '3. Which promoters can be used for testing';
    RAISE NOTICE '';
    RAISE NOTICE 'Common issues:';
    RAISE NOTICE '- Promoter exists in profiles but not in auth.users';
    RAISE NOTICE '- Auth record exists but password is not set';
    RAISE NOTICE '- Promoter was created before auth functions were working';
    RAISE NOTICE '=======================================================';
END $$;
