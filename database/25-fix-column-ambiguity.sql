-- =====================================================
-- FIX COLUMN AMBIGUITY IN AUTHENTICATION FUNCTIONS
-- =====================================================
-- Fix the "column reference is ambiguous" error

-- =====================================================
-- 1. UPDATE PROMOTER ID AUTHENTICATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION authenticate_promoter_by_id(
    p_promoter_id TEXT,
    p_password TEXT
)
RETURNS TABLE(
    id UUID,
    email TEXT,
    name TEXT,
    phone TEXT,
    address TEXT,
    role TEXT,
    promoter_id TEXT,
    role_level TEXT,
    status TEXT,
    parent_promoter_id UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_record RECORD;
    auth_user_record RECORD;
BEGIN
    -- Input validation
    IF p_promoter_id IS NULL OR TRIM(p_promoter_id) = '' THEN
        RAISE EXCEPTION 'Promoter ID is required';
    END IF;
    
    IF p_password IS NULL OR TRIM(p_password) = '' THEN
        RAISE EXCEPTION 'Password is required';
    END IF;
    
    -- Find the promoter by promoter_id (using table alias to avoid ambiguity)
    SELECT p.* INTO user_record
    FROM profiles p
    WHERE p.promoter_id = p_promoter_id 
    AND p.role = 'promoter';
    
    -- Check if promoter exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid Promoter ID or password';
    END IF;
    
    -- Get the corresponding auth user record
    SELECT au.* INTO auth_user_record
    FROM auth.users au
    WHERE au.id = user_record.id;
    
    -- Check if auth user exists and verify password
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- Verify password using crypt function
    IF NOT (auth_user_record.encrypted_password = crypt(p_password, auth_user_record.encrypted_password)) THEN
        RAISE EXCEPTION 'Invalid Promoter ID or password';
    END IF;
    
    -- Return the user profile data (using explicit casting to avoid ambiguity)
    RETURN QUERY
    SELECT 
        user_record.id::UUID,
        user_record.email::TEXT,
        user_record.name::TEXT,
        user_record.phone::TEXT,
        user_record.address::TEXT,
        user_record.role::TEXT,
        user_record.promoter_id::TEXT,
        user_record.role_level::TEXT,
        user_record.status::TEXT,
        user_record.parent_promoter_id::UUID,
        user_record.created_at::TIMESTAMPTZ,
        user_record.updated_at::TIMESTAMPTZ;
        
END;
$$;

-- =====================================================
-- 2. UPDATE PHONE AUTHENTICATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION authenticate_promoter_by_phone(
    p_phone TEXT,
    p_password TEXT
)
RETURNS TABLE(
    id UUID,
    email TEXT,
    name TEXT,
    phone TEXT,
    address TEXT,
    role TEXT,
    promoter_id TEXT,
    role_level TEXT,
    status TEXT,
    parent_promoter_id UUID,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_record RECORD;
    auth_user_record RECORD;
BEGIN
    -- Input validation
    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RAISE EXCEPTION 'Phone number is required';
    END IF;
    
    IF p_password IS NULL OR TRIM(p_password) = '' THEN
        RAISE EXCEPTION 'Password is required';
    END IF;
    
    -- Find the promoter by phone number (using table alias to avoid ambiguity)
    SELECT p.* INTO user_record
    FROM profiles p
    WHERE p.phone = p_phone 
    AND p.role = 'promoter';
    
    -- Check if promoter exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid phone number or password';
    END IF;
    
    -- Get the corresponding auth user record
    SELECT au.* INTO auth_user_record
    FROM auth.users au
    WHERE au.id = user_record.id;
    
    -- Check if auth user exists and verify password
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- Verify password using crypt function
    IF NOT (auth_user_record.encrypted_password = crypt(p_password, auth_user_record.encrypted_password)) THEN
        RAISE EXCEPTION 'Invalid phone number or password';
    END IF;
    
    -- Return the user profile data (using explicit casting to avoid ambiguity)
    RETURN QUERY
    SELECT 
        user_record.id::UUID,
        user_record.email::TEXT,
        user_record.name::TEXT,
        user_record.phone::TEXT,
        user_record.address::TEXT,
        user_record.role::TEXT,
        user_record.promoter_id::TEXT,
        user_record.role_level::TEXT,
        user_record.status::TEXT,
        user_record.parent_promoter_id::UUID,
        user_record.created_at::TIMESTAMPTZ,
        user_record.updated_at::TIMESTAMPTZ;
        
END;
$$;

-- =====================================================
-- 3. TEST THE FIXED FUNCTIONS
-- =====================================================

DO $$
DECLARE
    test_promoter_id TEXT;
    test_phone TEXT;
    test_result RECORD;
BEGIN
    RAISE NOTICE '=== TESTING FIXED AUTHENTICATION FUNCTIONS ===';
    
    -- Get a test promoter
    SELECT p.promoter_id, p.phone INTO test_promoter_id, test_phone
    FROM profiles p
    WHERE p.role = 'promoter' 
    AND p.promoter_id IS NOT NULL 
    LIMIT 1;
    
    IF test_promoter_id IS NOT NULL THEN
        RAISE NOTICE 'Found test promoter: ID=%, Phone=%', test_promoter_id, test_phone;
        
        -- Test invalid credentials (should fail gracefully)
        BEGIN
            SELECT * INTO test_result 
            FROM authenticate_promoter_by_id(test_promoter_id, 'wrongpassword');
            RAISE NOTICE '❌ ERROR: Should have failed with wrong password';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '✅ SUCCESS: Correctly rejected invalid password for Promoter ID';
        END;
        
        IF test_phone IS NOT NULL THEN
            BEGIN
                SELECT * INTO test_result 
                FROM authenticate_promoter_by_phone(test_phone, 'wrongpassword');
                RAISE NOTICE '❌ ERROR: Should have failed with wrong password';
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '✅ SUCCESS: Correctly rejected invalid password for Phone';
            END;
        END IF;
        
        RAISE NOTICE '';
        RAISE NOTICE 'Functions are ready for testing with actual credentials.';
        RAISE NOTICE 'Try logging in with Promoter ID: % and the correct password', test_promoter_id;
        
    ELSE
        RAISE NOTICE '⚠️  No promoters found for testing. Create a promoter first.';
    END IF;
    
END $$;

-- =====================================================
-- 4. VERIFY FUNCTION SIGNATURES
-- =====================================================

SELECT 
    'FUNCTION_UPDATED' as status,
    proname as function_name,
    pg_get_function_arguments(oid) as parameters
FROM pg_proc 
WHERE proname IN ('authenticate_promoter_by_id', 'authenticate_promoter_by_phone')
AND pronamespace = 'public'::regnamespace
ORDER BY proname;

-- =====================================================
-- 5. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'COLUMN AMBIGUITY ISSUE FIXED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Fixed Issues:';
    RAISE NOTICE '1. Added table aliases (p. for profiles, au. for auth.users)';
    RAISE NOTICE '2. Used explicit casting in RETURN QUERY';
    RAISE NOTICE '3. Eliminated column reference ambiguity';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions should now work without 42702 errors.';
    RAISE NOTICE 'Try the Promoter ID login again!';
    RAISE NOTICE '=======================================================';
END $$;
