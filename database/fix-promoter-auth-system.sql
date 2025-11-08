-- =====================================================
-- FIX PROMOTER AUTHENTICATION SYSTEM
-- =====================================================
-- This fixes the systemic issue where promoters can't login
-- after being created through the admin panel

-- =====================================================
-- 1. IMPROVED PROMOTER AUTHENTICATION FUNCTIONS
-- =====================================================

-- Fix authenticate_promoter_by_id function
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
    SELECT p.* INTO user_record
    FROM profiles p
    WHERE p.promoter_id = p_promoter_id 
    AND p.role = 'promoter'
    AND p.status = 'Active';
    
    -- Check if promoter exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid Promoter ID or password';
    END IF;
    
    -- Get the corresponding auth user record
    SELECT au.* INTO auth_user_record
    FROM auth.users au
    WHERE au.id = user_record.id;
    
    -- Check if auth user exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- Verify password - try multiple methods for compatibility
    IF NOT (
        -- Method 1: Direct encrypted password comparison (Supabase default)
        auth_user_record.encrypted_password = crypt(p_password, auth_user_record.encrypted_password)
        OR
        -- Method 2: Check if it's a bcrypt hash
        (auth_user_record.encrypted_password LIKE '$2%' AND 
         auth_user_record.encrypted_password = crypt(p_password, auth_user_record.encrypted_password))
        OR
        -- Method 3: For development/testing - plain text comparison (remove in production)
        (auth_user_record.encrypted_password = p_password)
    ) THEN
        RAISE EXCEPTION 'Invalid Promoter ID or password';
    END IF;
    
    -- Return the user profile data
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

-- Fix authenticate_promoter_by_phone function
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
    
    -- Find the promoter by phone
    SELECT p.* INTO user_record
    FROM profiles p
    WHERE p.phone = p_phone 
    AND p.role = 'promoter'
    AND p.status = 'Active';
    
    -- Check if promoter exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid phone number or password';
    END IF;
    
    -- Get the corresponding auth user record
    SELECT au.* INTO auth_user_record
    FROM auth.users au
    WHERE au.id = user_record.id;
    
    -- Check if auth user exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- Verify password - try multiple methods for compatibility
    IF NOT (
        -- Method 1: Direct encrypted password comparison (Supabase default)
        auth_user_record.encrypted_password = crypt(p_password, auth_user_record.encrypted_password)
        OR
        -- Method 2: Check if it's a bcrypt hash
        (auth_user_record.encrypted_password LIKE '$2%' AND 
         auth_user_record.encrypted_password = crypt(p_password, auth_user_record.encrypted_password))
        OR
        -- Method 3: For development/testing - plain text comparison (remove in production)
        (auth_user_record.encrypted_password = p_password)
    ) THEN
        RAISE EXCEPTION 'Invalid phone number or password';
    END IF;
    
    -- Return the user profile data
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
-- 2. IMPROVED PROMOTER CREATION FUNCTION
-- =====================================================

-- Enhanced create_promoter_profile_only function with better error handling
CREATE OR REPLACE FUNCTION create_promoter_profile_only(
    p_user_id UUID,
    p_name TEXT,
    p_phone TEXT,
    p_email TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_promoter_id TEXT;
    result JSON;
    auth_user_exists BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '🚀 Creating promoter profile for user ID: %', p_user_id;
    
    -- Input validation
    IF p_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User ID is required');
    END IF;
    
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Name is required');
    END IF;
    
    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Phone number is required');
    END IF;
    
    -- Check if auth user exists
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = p_user_id) INTO auth_user_exists;
    
    IF NOT auth_user_exists THEN
        RAISE NOTICE '⚠️ Warning: Auth user % not found in auth.users table', p_user_id;
        RETURN json_build_object(
            'success', false, 
            'error', 'Auth user not found. Please ensure the user is created in Supabase Auth first.'
        );
    END IF;
    
    RAISE NOTICE '✅ Auth user % exists', p_user_id;
    
    -- Generate promoter ID
    new_promoter_id := generate_next_promoter_id();
    RAISE NOTICE '🆔 Generated Promoter ID: %', new_promoter_id;
    
    -- Create profile record
    INSERT INTO profiles (
        id,
        email,
        name,
        role,
        phone,
        address,
        promoter_id,
        role_level,
        status,
        parent_promoter_id,
        created_at,
        updated_at
    ) VALUES (
        p_user_id,
        p_email,
        TRIM(p_name),
        'promoter',
        TRIM(p_phone),
        p_address,
        new_promoter_id,
        'Affiliate',
        'Active',
        p_parent_promoter_id,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE '✅ Profile created successfully with ID: %', new_promoter_id;
    
    -- Verify the relationship was created correctly
    IF NOT EXISTS(
        SELECT 1 FROM profiles p 
        JOIN auth.users au ON p.id = au.id 
        WHERE p.promoter_id = new_promoter_id
    ) THEN
        RAISE NOTICE '⚠️ Warning: Profile-Auth relationship verification failed';
    ELSE
        RAISE NOTICE '✅ Profile-Auth relationship verified';
    END IF;
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', p_user_id,
        'name', p_name,
        'phone', p_phone,
        'email', p_email,
        'message', 'Promoter profile created successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Profile creation failed: % (Code: %)', SQLERRM, SQLSTATE;
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
END;
$$;

-- =====================================================
-- 3. DIAGNOSTIC FUNCTION
-- =====================================================

-- Function to diagnose auth issues for a promoter
CREATE OR REPLACE FUNCTION diagnose_promoter_auth(p_promoter_id TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    profile_exists BOOLEAN := FALSE;
    auth_exists BOOLEAN := FALSE;
    profile_record RECORD;
    auth_record RECORD;
BEGIN
    -- Check if profile exists
    SELECT * INTO profile_record FROM profiles WHERE promoter_id = p_promoter_id;
    profile_exists := FOUND;
    
    IF profile_exists THEN
        -- Check if corresponding auth user exists
        SELECT * INTO auth_record FROM auth.users WHERE id = profile_record.id;
        auth_exists := FOUND;
    END IF;
    
    -- Build and return diagnostic result in one go
    RETURN json_build_object(
        'promoter_id', p_promoter_id,
        'profile_exists', profile_exists,
        'auth_exists', auth_exists,
        'diagnosis', CASE 
            WHEN NOT profile_exists THEN 'Profile not found'
            WHEN NOT auth_exists THEN 'Auth user missing - this is the problem!'
            ELSE 'Both profile and auth user exist - check password'
        END,
        'profile_info', CASE 
            WHEN profile_exists THEN json_build_object(
                'id', profile_record.id,
                'name', profile_record.name,
                'email', profile_record.email,
                'phone', profile_record.phone,
                'status', profile_record.status
            )
            ELSE NULL
        END,
        'auth_info', CASE 
            WHEN auth_exists THEN json_build_object(
                'id', auth_record.id,
                'email', auth_record.email,
                'created_at', auth_record.created_at,
                'email_confirmed_at', auth_record.email_confirmed_at
            )
            ELSE NULL
        END
    );
END;
$$;

-- =====================================================
-- 4. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_phone(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_phone(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION create_promoter_profile_only(UUID, TEXT, TEXT, TEXT, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION diagnose_promoter_auth(TEXT) TO authenticated;

-- =====================================================
-- 5. TEST THE SYSTEM
-- =====================================================

DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PROMOTER AUTHENTICATION SYSTEM FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    
    -- Test diagnostic function with BPVP24
    SELECT diagnose_promoter_auth('BPVP24') INTO test_result;
    RAISE NOTICE 'BPVP24 Diagnosis: %', test_result;
    
    RAISE NOTICE '';
    RAISE NOTICE 'SYSTEM IMPROVEMENTS:';
    RAISE NOTICE '1. ✅ Enhanced password verification (multiple methods)';
    RAISE NOTICE '2. ✅ Better error messages and logging';
    RAISE NOTICE '3. ✅ Auth user existence verification';
    RAISE NOTICE '4. ✅ Profile-Auth relationship validation';
    RAISE NOTICE '5. ✅ Diagnostic function for troubleshooting';
    RAISE NOTICE '';
    RAISE NOTICE 'LOGIN METHODS NOW SUPPORTED:';
    RAISE NOTICE '• Promoter ID + Password';
    RAISE NOTICE '• Phone Number + Password';
    RAISE NOTICE '• Email + Password (via Supabase Auth)';
    RAISE NOTICE '';
    RAISE NOTICE 'To diagnose any promoter: SELECT diagnose_promoter_auth(''PROMOTER_ID'');';
    RAISE NOTICE '=======================================================';
END $$;
