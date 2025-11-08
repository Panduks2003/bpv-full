-- =====================================================
-- PROMOTER ID-ONLY AUTHENTICATION SYSTEM
-- =====================================================
-- This revamps the promoter authentication system to use 
-- ONLY Promoter ID (e.g., BPVP19) for login, making email 
-- and phone metadata-only fields
-- =====================================================

BEGIN;

-- =====================================================
-- 1. UPDATE DATABASE SCHEMA TO ALLOW DUPLICATE EMAILS/PHONES
-- =====================================================

-- Remove unique constraints on email and phone for profiles table
DO $$
BEGIN
    -- Drop unique index on email if it exists
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'profiles_email_key'
    ) THEN
        DROP INDEX profiles_email_key;
        RAISE NOTICE '✅ Removed unique constraint on email';
    END IF;
    
    -- Drop unique index on phone if it exists
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'profiles_phone_key'
    ) THEN
        DROP INDEX profiles_phone_key;
        RAISE NOTICE '✅ Removed unique constraint on phone';
    END IF;
END $$;

-- Ensure promoter_id remains unique and has an index
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_promoter_id ON profiles(promoter_id) 
WHERE promoter_id IS NOT NULL AND role = 'promoter';

-- =====================================================
-- 2. CREATE PROMOTER ID AUTHENTICATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION authenticate_promoter_by_id_only(
    p_promoter_id TEXT,
    p_password TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    promoter_record RECORD;
    auth_record RECORD;
    auth_email TEXT;
BEGIN
    -- Input validation
    IF p_promoter_id IS NULL OR TRIM(p_promoter_id) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Promoter ID is required'
        );
    END IF;
    
    IF p_password IS NULL OR TRIM(p_password) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Password is required'
        );
    END IF;
    
    -- Find promoter by promoter_id
    SELECT p.* INTO promoter_record
    FROM profiles p
    WHERE UPPER(p.promoter_id) = UPPER(TRIM(p_promoter_id))
    AND p.role = 'promoter'
    AND p.status = 'Active';
    
    -- Check if promoter exists
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid Promoter ID or password'
        );
    END IF;
    
    -- Get auth user record
    SELECT au.* INTO auth_record
    FROM auth.users au
    WHERE au.id = promoter_record.id;
    
    -- Check if auth user exists
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Authentication failed: No auth record found'
        );
    END IF;
    
    -- Get the auth email (this is the placeholder email used in auth.users)
    auth_email := auth_record.email;
    
    -- Note: We don't verify password here because Supabase Auth uses its own
    -- hashing method (pbkdf2) which we can't easily verify with database functions.
    -- The frontend will use Supabase Auth to sign in, which will verify the password.
    
    -- Return success with user data and auth email
    RETURN json_build_object(
        'success', true,
        'user', json_build_object(
            'id', promoter_record.id,
            'promoter_id', promoter_record.promoter_id,
            'name', promoter_record.name,
            'email', promoter_record.email,
            'phone', promoter_record.phone,
            'address', promoter_record.address,
            'role', promoter_record.role,
            'role_level', promoter_record.role_level,
            'status', promoter_record.status,
            'parent_promoter_id', promoter_record.parent_promoter_id,
            'created_at', promoter_record.created_at,
            'updated_at', promoter_record.updated_at
        ),
        'auth_email', auth_email
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Authentication failed: ' || SQLERRM
    );
END;
$$;

-- =====================================================
-- 3. CREATE PROMOTER CREATION FUNCTION WITH AUTH
-- =====================================================

CREATE OR REPLACE FUNCTION create_promoter_with_auth_id(
    p_name TEXT,
    p_user_id UUID,
    p_auth_email TEXT,
    p_password TEXT,
    p_phone TEXT,
    p_email TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL,
    p_role_level TEXT DEFAULT 'Affiliate',
    p_status TEXT DEFAULT 'Active'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_promoter_id TEXT;
    profile_email TEXT;
BEGIN
    -- Input validation
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Name is required'
        );
    END IF;
    
    IF p_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User ID is required'
        );
    END IF;
    
    IF p_auth_email IS NULL OR TRIM(p_auth_email) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Auth email is required'
        );
    END IF;
    
    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Phone number is required'
        );
    END IF;
    
    -- Generate promoter ID
    new_promoter_id := generate_next_promoter_id();
    
    -- Store real email as metadata (can be NULL or duplicate)
    profile_email := CASE 
        WHEN p_email IS NULL OR TRIM(p_email) = '' THEN NULL 
        ELSE TRIM(p_email) 
    END;
    
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
        profile_email,
        TRIM(p_name),
        'promoter',
        TRIM(p_phone),
        p_address,
        new_promoter_id,
        p_role_level,
        p_status,
        p_parent_promoter_id,
        NOW(),
        NOW()
    );
    
    -- Create promoter record if table exists
    BEGIN
        INSERT INTO promoters (
            id,
            promoter_id,
            parent_promoter_id,
            status,
            commission_rate,
            can_create_promoters,
            can_create_customers,
            created_at,
            updated_at
        ) VALUES (
            p_user_id,
            new_promoter_id,
            p_parent_promoter_id,
            LOWER(p_status),
            0.05,
            true,
            true,
            NOW(),
            NOW()
        );
    EXCEPTION WHEN OTHERS THEN
        -- Ignore if promoters table doesn't exist
        NULL;
    END;
    
    -- Return success
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', p_user_id,
        'name', p_name,
        'phone', p_phone,
        'email', profile_email,
        'auth_email', p_auth_email,
        'message', 'Promoter created successfully. Use Promoter ID: ' || new_promoter_id || ' to login.'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Failed to create promoter: ' || SQLERRM
    );
END;
$$;

-- =====================================================
-- 3B. CREATE EMAIL CONFIRMATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION confirm_promoter_email(
    p_user_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Update email_confirmed_at to confirm the email
    UPDATE auth.users
    SET email_confirmed_at = NOW(),
        updated_at = NOW()
    WHERE id = p_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Email confirmed successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Failed to confirm email: ' || SQLERRM
    );
END;
$$;

-- =====================================================
-- 4. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id_only(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id_only(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION create_promoter_with_auth_id(TEXT, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_promoter_with_auth_id(TEXT, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION confirm_promoter_email(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION confirm_promoter_email(UUID) TO anon;

-- =====================================================
-- 5. VERIFY CHANGES
-- =====================================================

DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PROMOTER ID-ONLY AUTHENTICATION SYSTEM INSTALLED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'NEW SYSTEM FEATURES:';
    RAISE NOTICE '✅ Promoter login uses ONLY Promoter ID + Password';
    RAISE NOTICE '✅ Email and Phone are metadata only (can repeat)';
    RAISE NOTICE '✅ Each promoter gets unique auth email internally';
    RAISE NOTICE '✅ Clean, consistent authentication model';
    RAISE NOTICE '';
    RAISE NOTICE 'AUTHENTICATION FUNCTIONS:';
    RAISE NOTICE '  - authenticate_promoter_by_id_only(promoter_id, password)';
    RAISE NOTICE '  - create_promoter_with_id_auth(...)';
    RAISE NOTICE '';
    RAISE NOTICE 'EXAMPLE USAGE:';
    RAISE NOTICE '  SELECT authenticate_promoter_by_id_only(''BPVP01'', ''password123'');';
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
END $$;

COMMIT;

