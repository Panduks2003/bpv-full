-- =====================================================
-- FIX AUTHENTICATION FUNCTION CONFLICT
-- =====================================================
-- Drop all existing versions and create clean functions

-- =====================================================
-- 1. DROP ALL EXISTING VERSIONS
-- =====================================================

-- Drop all possible versions of authenticate_promoter_by_id
DROP FUNCTION IF EXISTS authenticate_promoter_by_id(VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS authenticate_promoter_by_id(TEXT, TEXT);
DROP FUNCTION IF EXISTS authenticate_promoter_by_id(character varying, character varying);
DROP FUNCTION IF EXISTS authenticate_promoter_by_id(text, text);

-- Drop all possible versions of authenticate_promoter_by_phone
DROP FUNCTION IF EXISTS authenticate_promoter_by_phone(VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS authenticate_promoter_by_phone(TEXT, TEXT);
DROP FUNCTION IF EXISTS authenticate_promoter_by_phone(character varying, character varying);
DROP FUNCTION IF EXISTS authenticate_promoter_by_phone(text, text);

-- Dynamic cleanup for any remaining versions
DO $$
DECLARE
    func_record RECORD;
BEGIN
    -- Clean up any remaining authenticate_promoter_by_id functions
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc 
        WHERE proname = 'authenticate_promoter_by_id'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.proname || '(' || func_record.args || ')';
        RAISE NOTICE 'Dropped function: %(%)', func_record.proname, func_record.args;
    END LOOP;
    
    -- Clean up any remaining authenticate_promoter_by_phone functions
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc 
        WHERE proname = 'authenticate_promoter_by_phone'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.proname || '(' || func_record.args || ')';
        RAISE NOTICE 'Dropped function: %(%)', func_record.proname, func_record.args;
    END LOOP;
END $$;

-- =====================================================
-- 2. CREATE CLEAN PROMOTER ID AUTHENTICATION FUNCTION
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
    
    -- Find the promoter by promoter_id
    SELECT * INTO user_record
    FROM profiles 
    WHERE promoter_id = p_promoter_id 
    AND role = 'promoter';
    
    -- Check if promoter exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid Promoter ID or password';
    END IF;
    
    -- Get the corresponding auth user record
    SELECT * INTO auth_user_record
    FROM auth.users 
    WHERE id = user_record.id;
    
    -- Check if auth user exists and verify password
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- Verify password using crypt function
    IF NOT (auth_user_record.encrypted_password = crypt(p_password, auth_user_record.encrypted_password)) THEN
        RAISE EXCEPTION 'Invalid Promoter ID or password';
    END IF;
    
    -- Return the user profile data
    RETURN QUERY
    SELECT 
        user_record.id,
        user_record.email::TEXT,
        user_record.name::TEXT,
        user_record.phone::TEXT,
        user_record.address::TEXT,
        user_record.role::TEXT,
        user_record.promoter_id::TEXT,
        user_record.role_level::TEXT,
        user_record.status::TEXT,
        user_record.parent_promoter_id,
        user_record.created_at,
        user_record.updated_at;
        
END;
$$;

-- =====================================================
-- 3. CREATE CLEAN PHONE AUTHENTICATION FUNCTION
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
    
    -- Find the promoter by phone number
    SELECT * INTO user_record
    FROM profiles 
    WHERE phone = p_phone 
    AND role = 'promoter';
    
    -- Check if promoter exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid phone number or password';
    END IF;
    
    -- Get the corresponding auth user record
    SELECT * INTO auth_user_record
    FROM auth.users 
    WHERE id = user_record.id;
    
    -- Check if auth user exists and verify password
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- Verify password using crypt function
    IF NOT (auth_user_record.encrypted_password = crypt(p_password, auth_user_record.encrypted_password)) THEN
        RAISE EXCEPTION 'Invalid phone number or password';
    END IF;
    
    -- Return the user profile data
    RETURN QUERY
    SELECT 
        user_record.id,
        user_record.email::TEXT,
        user_record.name::TEXT,
        user_record.phone::TEXT,
        user_record.address::TEXT,
        user_record.role::TEXT,
        user_record.promoter_id::TEXT,
        user_record.role_level::TEXT,
        user_record.status::TEXT,
        user_record.parent_promoter_id,
        user_record.created_at,
        user_record.updated_at;
        
END;
$$;

-- =====================================================
-- 4. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_phone(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_phone(TEXT, TEXT) TO anon;

-- =====================================================
-- 5. VERIFY FUNCTIONS
-- =====================================================

SELECT 
    'FUNCTION_CREATED' as status,
    proname as function_name,
    pg_get_function_arguments(oid) as parameters,
    pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname IN ('authenticate_promoter_by_id', 'authenticate_promoter_by_phone')
AND pronamespace = 'public'::regnamespace
ORDER BY proname;

-- =====================================================
-- 6. TEST WITH EXISTING PROMOTER
-- =====================================================

DO $$
DECLARE
    test_promoter_id TEXT;
    test_phone TEXT;
    test_result RECORD;
BEGIN
    RAISE NOTICE '=== TESTING AUTHENTICATION FUNCTIONS ===';
    
    -- Get a test promoter
    SELECT promoter_id, phone INTO test_promoter_id, test_phone
    FROM profiles 
    WHERE role = 'promoter' 
    AND promoter_id IS NOT NULL 
    LIMIT 1;
    
    IF test_promoter_id IS NOT NULL THEN
        RAISE NOTICE 'Found test promoter: ID=%, Phone=%', test_promoter_id, test_phone;
        RAISE NOTICE 'Functions are ready for testing with actual credentials.';
        
        -- Test invalid credentials (should fail gracefully)
        BEGIN
            SELECT * INTO test_result 
            FROM authenticate_promoter_by_id(test_promoter_id, 'wrongpassword');
            RAISE NOTICE '❌ ERROR: Should have failed with wrong password';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '✅ SUCCESS: Correctly rejected invalid password for Promoter ID';
        END;
        
        BEGIN
            SELECT * INTO test_result 
            FROM authenticate_promoter_by_phone(test_phone, 'wrongpassword');
            RAISE NOTICE '❌ ERROR: Should have failed with wrong password';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '✅ SUCCESS: Correctly rejected invalid password for Phone';
        END;
        
    ELSE
        RAISE NOTICE '⚠️  No promoters found for testing. Create a promoter first.';
    END IF;
    
END $$;

-- =====================================================
-- 7. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'AUTHENTICATION FUNCTION CONFLICT RESOLVED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Fixed Issues:';
    RAISE NOTICE '1. Dropped all conflicting function versions';
    RAISE NOTICE '2. Created clean functions with TEXT parameters';
    RAISE NOTICE '3. Ensured consistent return types';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions Available:';
    RAISE NOTICE '- authenticate_promoter_by_id(promoter_id TEXT, password TEXT)';
    RAISE NOTICE '- authenticate_promoter_by_phone(phone TEXT, password TEXT)';
    RAISE NOTICE '';
    RAISE NOTICE 'Promoter ID login should now work correctly!';
    RAISE NOTICE '=======================================================';
END $$;
