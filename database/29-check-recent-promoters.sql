-- =====================================================
-- CHECK RECENT PROMOTERS (PROM0013, PROM0014)
-- =====================================================
-- Quick diagnostic of newly created promoters

-- =====================================================
-- 1. CHECK RECENT PROMOTERS IN PROFILES
-- =====================================================

SELECT 
    'RECENT_PROMOTERS_PROFILES' as check_type,
    promoter_id,
    name,
    email,
    phone,
    id,
    created_at
FROM profiles 
WHERE promoter_id IN ('PROM0013', 'PROM0014')
ORDER BY created_at DESC;

-- =====================================================
-- 2. CHECK AUTH RECORDS FOR RECENT PROMOTERS
-- =====================================================

SELECT 
    'RECENT_PROMOTERS_AUTH' as check_type,
    p.promoter_id,
    p.name,
    au.id,
    au.email as auth_email,
    au.created_at,
    CASE WHEN au.encrypted_password IS NOT NULL THEN 'HAS_PASSWORD' ELSE 'NO_PASSWORD' END as password_status,
    LENGTH(au.encrypted_password) as password_length
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.promoter_id IN ('PROM0013', 'PROM0014')
ORDER BY p.created_at DESC;

-- =====================================================
-- 3. TEST AUTHENTICATION FUNCTION WITH RECENT PROMOTERS
-- =====================================================

DO $$
DECLARE
    test_result RECORD;
    promoter_record RECORD;
BEGIN
    RAISE NOTICE '=== TESTING RECENT PROMOTERS AUTHENTICATION ===';
    
    -- Check each recent promoter
    FOR promoter_record IN 
        SELECT p.promoter_id, p.name, au.id as auth_id
        FROM profiles p
        LEFT JOIN auth.users au ON p.id = au.id
        WHERE p.promoter_id IN ('PROM0013', 'PROM0014')
        ORDER BY p.created_at DESC
    LOOP
        RAISE NOTICE 'Checking promoter: % (Name: %, Auth ID: %)', 
            promoter_record.promoter_id, 
            promoter_record.name,
            CASE WHEN promoter_record.auth_id IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END;
        
        -- Test authentication function
        BEGIN
            SELECT * INTO test_result 
            FROM authenticate_promoter_by_id(promoter_record.promoter_id, 'wrongpassword');
            RAISE NOTICE '❌ ERROR: Should have failed with wrong password for %', promoter_record.promoter_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  Result for %: %', promoter_record.promoter_id, SQLERRM;
        END;
    END LOOP;
    
END $$;

-- =====================================================
-- 4. CHECK CREATE_UNIFIED_PROMOTER FUNCTION LOGS
-- =====================================================

-- Check if the function is actually being called and what it returns
DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '=== TESTING CREATE_UNIFIED_PROMOTER FUNCTION ===';
    
    -- Test the function with sample data
    SELECT create_unified_promoter(
        'Test Function Check',
        'testpass123',
        '9876543210',
        'testfunc@example.com',
        'Test Address',
        NULL
    ) INTO test_result;
    
    RAISE NOTICE 'Function result: %', test_result;
    
    -- Check if it created both records
    IF (test_result->>'success')::boolean THEN
        RAISE NOTICE '✅ Function works: %', test_result->>'message';
        RAISE NOTICE 'Auth created: %', test_result->>'auth_created';
        
        -- Clean up test record
        DELETE FROM profiles WHERE promoter_id = test_result->>'promoter_id';
        DELETE FROM auth.users WHERE id = (test_result->>'user_id')::UUID;
        RAISE NOTICE '🧹 Test record cleaned up';
    ELSE
        RAISE NOTICE '❌ Function failed: %', test_result->>'error';
    END IF;
    
END $$;

-- =====================================================
-- 5. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'RECENT PROMOTERS DIAGNOSIS COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Check the results above to see:';
    RAISE NOTICE '1. Whether PROM0013/PROM0014 exist in profiles';
    RAISE NOTICE '2. Whether they have auth.users records';
    RAISE NOTICE '3. What the authentication function returns';
    RAISE NOTICE '4. Whether create_unified_promoter is working';
    RAISE NOTICE '=======================================================';
END $$;
