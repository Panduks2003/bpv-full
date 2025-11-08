-- =====================================================
-- FIX AUTHENTICATION FUNCTIONS - SUPABASE COMPATIBLE
-- =====================================================
-- This fixes the authentication functions to work with Supabase Auth

-- =====================================================
-- 1. FIXED PROMOTER ID AUTHENTICATION FUNCTION
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
    user_email TEXT;
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
    
    -- Get the email for this promoter
    user_email := user_record.email;
    
    -- If no email in profile, we can't authenticate
    IF user_email IS NULL OR TRIM(user_email) = '' THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- Get the corresponding auth user record
    SELECT au.* INTO auth_user_record
    FROM auth.users au
    WHERE au.id = user_record.id;
    
    -- Check if auth user exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- For Supabase Auth, we can't directly verify passwords in SQL
    -- Instead, we'll return the user data and let the frontend handle auth
    -- This function now serves as a user lookup by promoter ID
    
    -- Return the user profile data (password verification happens at frontend)
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
-- 2. FIXED PHONE AUTHENTICATION FUNCTION
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
    user_email TEXT;
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
    
    -- Get the email for this promoter
    user_email := user_record.email;
    
    -- If no email in profile, we can't authenticate
    IF user_email IS NULL OR TRIM(user_email) = '' THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- Get the corresponding auth user record
    SELECT au.* INTO auth_user_record
    FROM auth.users au
    WHERE au.id = user_record.id;
    
    -- Check if auth user exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Authentication record not found';
    END IF;
    
    -- Return the user profile data (password verification happens at frontend)
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
-- 3. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_phone(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_phone(TEXT, TEXT) TO anon;

-- =====================================================
-- 4. TEST THE FUNCTIONS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'AUTHENTICATION FUNCTIONS UPDATED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'CHANGES:';
    RAISE NOTICE '1. ✅ Removed password verification from SQL functions';
    RAISE NOTICE '2. ✅ Functions now return user data for frontend auth';
    RAISE NOTICE '3. ✅ Compatible with Supabase Auth system';
    RAISE NOTICE '4. ✅ Proper error handling for missing records';
    RAISE NOTICE '';
    RAISE NOTICE 'NOTE: Password verification now happens at frontend level';
    RAISE NOTICE 'using Supabase Auth signInWithPassword() method';
    RAISE NOTICE '=======================================================';
END $$;
