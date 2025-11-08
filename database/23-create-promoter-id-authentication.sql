-- =====================================================
-- CREATE PROMOTER ID AUTHENTICATION FUNCTION
-- =====================================================
-- This function allows promoters to login using their Promoter ID + Password

-- =====================================================
-- 1. CREATE AUTHENTICATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION authenticate_promoter_by_id(
    p_promoter_id VARCHAR(20),
    p_password VARCHAR(255)
)
RETURNS TABLE(
    id UUID,
    email VARCHAR(255),
    name VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    role VARCHAR(20),
    promoter_id VARCHAR(20),
    role_level VARCHAR(50),
    status VARCHAR(20),
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
        user_record.email,
        user_record.name,
        user_record.phone,
        user_record.address,
        user_record.role,
        user_record.promoter_id,
        user_record.role_level,
        user_record.status,
        user_record.parent_promoter_id,
        user_record.created_at,
        user_record.updated_at;
        
END;
$$;

-- =====================================================
-- 2. GRANT PERMISSIONS
-- =====================================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id(VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id(VARCHAR, VARCHAR) TO anon;

-- =====================================================
-- 3. CREATE PHONE AUTHENTICATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION authenticate_promoter_by_phone(
    p_phone VARCHAR(20),
    p_password VARCHAR(255)
)
RETURNS TABLE(
    id UUID,
    email VARCHAR(255),
    name VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    role VARCHAR(20),
    promoter_id VARCHAR(20),
    role_level VARCHAR(50),
    status VARCHAR(20),
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
        user_record.email,
        user_record.name,
        user_record.phone,
        user_record.address,
        user_record.role,
        user_record.promoter_id,
        user_record.role_level,
        user_record.status,
        user_record.parent_promoter_id,
        user_record.created_at,
        user_record.updated_at;
        
END;
$$;

-- Grant permissions for phone authentication
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_phone(VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_phone(VARCHAR, VARCHAR) TO anon;

-- =====================================================
-- 4. TEST THE FUNCTIONS
-- =====================================================

DO $$
DECLARE
    test_result RECORD;
    test_promoter_id VARCHAR(20);
BEGIN
    RAISE NOTICE '=== TESTING PROMOTER ID AUTHENTICATION ===';
    
    -- Get a test promoter ID from the database
    SELECT promoter_id INTO test_promoter_id 
    FROM profiles 
    WHERE role = 'promoter' 
    AND promoter_id IS NOT NULL 
    LIMIT 1;
    
    IF test_promoter_id IS NOT NULL THEN
        RAISE NOTICE 'Found test promoter ID: %', test_promoter_id;
        RAISE NOTICE 'Note: You can test authentication with this Promoter ID and the password used during creation.';
        
        -- Test with invalid credentials (should fail)
        BEGIN
            SELECT * INTO test_result 
            FROM authenticate_promoter_by_id(test_promoter_id, 'wrongpassword');
            RAISE NOTICE '❌ ERROR: Authentication should have failed with wrong password';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '✅ SUCCESS: Correctly rejected invalid password';
        END;
        
        -- Test with invalid promoter ID (should fail)
        BEGIN
            SELECT * INTO test_result 
            FROM authenticate_promoter_by_id('INVALID123', 'anypassword');
            RAISE NOTICE '❌ ERROR: Authentication should have failed with invalid ID';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '✅ SUCCESS: Correctly rejected invalid Promoter ID';
        END;
        
    ELSE
        RAISE NOTICE '⚠️  No promoters found for testing. Create a promoter first.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Function created successfully! Promoters can now login with:';
    RAISE NOTICE '- Promoter ID (e.g., PROM0001)';
    RAISE NOTICE '- Password (set during creation)';
    
END $$;

-- =====================================================
-- 5. VERIFY FUNCTIONS EXIST
-- =====================================================

SELECT 
    'FUNCTION_CREATED' as status,
    proname as function_name,
    pg_get_function_arguments(oid) as parameters,
    pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'authenticate_promoter_by_id'
AND pronamespace = 'public'::regnamespace;

-- Also check phone authentication function
SELECT 
    'FUNCTION_CREATED' as status,
    proname as function_name,
    pg_get_function_arguments(oid) as parameters,
    pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'authenticate_promoter_by_phone'
AND pronamespace = 'public'::regnamespace;

-- =====================================================
-- 6. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PROMOTER AUTHENTICATION FUNCTIONS CREATED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Functions created:';
    RAISE NOTICE '1. authenticate_promoter_by_id(promoter_id, password)';
    RAISE NOTICE '2. authenticate_promoter_by_phone(phone, password)';
    RAISE NOTICE '';
    RAISE NOTICE 'Login Methods Available:';
    RAISE NOTICE '🎯 PRIMARY: Promoter ID + Password (e.g., PROM0001)';
    RAISE NOTICE '📱 SECONDARY: Phone + Password (e.g., 9876543210)';
    RAISE NOTICE '📧 SECONDARY: Email + Password (existing method)';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage in frontend:';
    RAISE NOTICE '- Login page supports all three methods';
    RAISE NOTICE '- Promoter ID is the default/primary method';
    RAISE NOTICE '- Secure password verification using crypt()';
    RAISE NOTICE '';
    RAISE NOTICE 'Your system is now ready for multi-method promoter login!';
    RAISE NOTICE '=======================================================';
END $$;
