-- =====================================================
-- CHECK CURRENT IMPLEMENTATION STATUS
-- =====================================================
-- This query checks what's currently implemented in the database
-- Run this BEFORE applying the promoter creation fix

-- =====================================================
-- 1. CHECK TABLES AND THEIR STRUCTURE
-- =====================================================

-- Check if required tables exist
SELECT 
    'TABLE_EXISTS' as check_type,
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN 'EXISTS'
        ELSE 'MISSING'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'promoters', 'customers', 'promoter_id_sequence', 'auth.users')
ORDER BY table_name;

-- Check profiles table structure
SELECT 
    'PROFILES_COLUMNS' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check promoters table structure (if exists)
SELECT 
    'PROMOTERS_COLUMNS' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'promoters' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check customers table structure (if exists)
SELECT 
    'CUSTOMERS_COLUMNS' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'customers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 2. CHECK FUNCTIONS
-- =====================================================

-- Check if required functions exist (using pg_proc for better compatibility)
SELECT 
    'FUNCTIONS' as check_type,
    proname as function_name,
    CASE 
        WHEN prokind = 'f' THEN 'FUNCTION'
        WHEN prokind = 'p' THEN 'PROCEDURE'
        ELSE 'OTHER'
    END as routine_type,
    CASE 
        WHEN prosecdef THEN 'DEFINER'
        ELSE 'INVOKER'
    END as security_type,
    'EXISTS' as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN (
    'generate_next_promoter_id',
    'create_unified_promoter',
    'update_promoter_profile',
    'create_customer_final',
    'authenticate_customer_by_card_no'
)
ORDER BY p.proname;

-- Get function signatures for existing functions (simplified approach)
SELECT 
    'FUNCTION_DETAILS' as check_type,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as parameters,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN (
    'generate_next_promoter_id',
    'create_unified_promoter',
    'update_promoter_profile'
)
ORDER BY p.proname;

-- =====================================================
-- 3. CHECK RLS POLICIES
-- =====================================================

-- Check RLS status on tables
SELECT 
    'RLS_STATUS' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN 'ENABLED'
        ELSE 'DISABLED'
    END as status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'promoters', 'customers')
ORDER BY tablename;

-- Check existing RLS policies
SELECT 
    'RLS_POLICIES' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command_type,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 4. CHECK DATA COUNTS
-- =====================================================

-- Check current data in tables
DO $$
DECLARE
    profiles_count INTEGER := 0;
    promoters_count INTEGER := 0;
    customers_count INTEGER := 0;
    admin_count INTEGER := 0;
    promoter_count INTEGER := 0;
    customer_count INTEGER := 0;
    sequence_count INTEGER := 0;
BEGIN
    -- Count profiles
    BEGIN
        SELECT COUNT(*) INTO profiles_count FROM profiles;
    EXCEPTION WHEN OTHERS THEN
        profiles_count := -1; -- Table doesn't exist or access denied
    END;
    
    -- Count by role
    BEGIN
        SELECT COUNT(*) INTO admin_count FROM profiles WHERE role = 'admin';
        SELECT COUNT(*) INTO promoter_count FROM profiles WHERE role = 'promoter';
        SELECT COUNT(*) INTO customer_count FROM profiles WHERE role = 'customer';
    EXCEPTION WHEN OTHERS THEN
        admin_count := -1;
        promoter_count := -1;
        customer_count := -1;
    END;
    
    -- Count promoters table
    BEGIN
        SELECT COUNT(*) INTO promoters_count FROM promoters;
    EXCEPTION WHEN OTHERS THEN
        promoters_count := -1;
    END;
    
    -- Count customers table
    BEGIN
        SELECT COUNT(*) INTO customers_count FROM customers;
    EXCEPTION WHEN OTHERS THEN
        customers_count := -1;
    END;
    
    -- Count sequence table
    BEGIN
        SELECT COUNT(*) INTO sequence_count FROM promoter_id_sequence;
    EXCEPTION WHEN OTHERS THEN
        sequence_count := -1;
    END;
    
    -- Output results
    RAISE NOTICE 'DATA_COUNTS check_type:';
    RAISE NOTICE 'Total profiles: %', profiles_count;
    RAISE NOTICE 'Admin users: %', admin_count;
    RAISE NOTICE 'Promoter users: %', promoter_count;
    RAISE NOTICE 'Customer users: %', customer_count;
    RAISE NOTICE 'Promoters table records: %', promoters_count;
    RAISE NOTICE 'Customers table records: %', customers_count;
    RAISE NOTICE 'Promoter ID sequence records: %', sequence_count;
END $$;

-- =====================================================
-- 5. CHECK PERMISSIONS
-- =====================================================

-- Check table permissions for authenticated role
SELECT 
    'TABLE_PERMISSIONS' as check_type,
    table_name,
    privilege_type,
    grantee,
    'GRANTED' as status
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'promoters', 'customers', 'promoter_id_sequence')
AND grantee IN ('authenticated', 'public', 'anon')
ORDER BY table_name, privilege_type;

-- Check function permissions (using pg_proc approach)
SELECT 
    'FUNCTION_PERMISSIONS' as check_type,
    p.proname as function_name,
    CASE 
        WHEN has_function_privilege('authenticated', p.oid, 'EXECUTE') THEN 'EXECUTE - authenticated'
        ELSE 'NO EXECUTE - authenticated'
    END as permission_status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN (
    'generate_next_promoter_id',
    'create_unified_promoter',
    'update_promoter_profile'
)
ORDER BY p.proname;

-- =====================================================
-- 6. TEST FUNCTION AVAILABILITY
-- =====================================================

-- Test if functions can be called (this will show errors if functions don't exist)
DO $$
DECLARE
    test_result TEXT;
    test_json JSON;
BEGIN
    -- Test generate_next_promoter_id
    BEGIN
        SELECT generate_next_promoter_id() INTO test_result;
        RAISE NOTICE 'FUNCTION_TEST: generate_next_promoter_id - SUCCESS (Generated: %)', test_result;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'FUNCTION_TEST: generate_next_promoter_id - FAILED (%)', SQLERRM;
    END;
    
    -- Test create_unified_promoter (dry run)
    BEGIN
        SELECT create_unified_promoter(
            'Test Function Check',
            'testpass123',
            '9876543210',
            NULL,
            NULL,
            NULL,
            'Affiliate',
            'Active'
        ) INTO test_json;
        
        -- Clean up if successful
        IF (test_json->>'success')::boolean THEN
            DELETE FROM profiles WHERE id = (test_json->>'user_id')::UUID;
            RAISE NOTICE 'FUNCTION_TEST: create_unified_promoter - SUCCESS (cleaned up test data)';
        ELSE
            RAISE NOTICE 'FUNCTION_TEST: create_unified_promoter - FAILED (%)', test_json->>'error';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'FUNCTION_TEST: create_unified_promoter - FAILED (%)', SQLERRM;
    END;
END $$;

-- =====================================================
-- 7. CHECK SEQUENCE STATUS
-- =====================================================

-- Check promoter ID sequence current value
DO $$
DECLARE
    current_number INTEGER := 0;
    last_promoter_id TEXT := '';
BEGIN
    -- Check sequence table
    BEGIN
        SELECT last_promoter_number INTO current_number FROM promoter_id_sequence LIMIT 1;
        RAISE NOTICE 'SEQUENCE_STATUS: Current number in sequence: %', current_number;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'SEQUENCE_STATUS: promoter_id_sequence table not accessible (%)', SQLERRM;
    END;
    
    -- Check last promoter ID in profiles
    BEGIN
        SELECT promoter_id INTO last_promoter_id 
        FROM profiles 
        WHERE promoter_id IS NOT NULL 
        ORDER BY created_at DESC 
        LIMIT 1;
        
        IF last_promoter_id IS NOT NULL THEN
            RAISE NOTICE 'SEQUENCE_STATUS: Last promoter ID in profiles: %', last_promoter_id;
        ELSE
            RAISE NOTICE 'SEQUENCE_STATUS: No promoter IDs found in profiles table';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'SEQUENCE_STATUS: Cannot check promoter IDs in profiles (%)', SQLERRM;
    END;
END $$;

-- =====================================================
-- SUMMARY
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'IMPLEMENTATION CHECK COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Review the output above to understand:';
    RAISE NOTICE '1. Which tables exist and their structure';
    RAISE NOTICE '2. Which functions are available';
    RAISE NOTICE '3. RLS policy status and configuration';
    RAISE NOTICE '4. Current data counts';
    RAISE NOTICE '5. Permission settings';
    RAISE NOTICE '6. Function test results';
    RAISE NOTICE '7. Sequence status';
    RAISE NOTICE '';
    RAISE NOTICE 'Use this information to determine what needs to be fixed';
    RAISE NOTICE 'before applying the promoter creation fix.';
    RAISE NOTICE '=======================================================';
END $$;
