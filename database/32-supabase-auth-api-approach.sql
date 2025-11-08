-- =====================================================
-- SUPABASE AUTH API APPROACH
-- =====================================================
-- Use Supabase Auth API instead of direct auth.users insertion

-- =====================================================
-- 1. CREATE SIMPLIFIED PROFILE-ONLY FUNCTION
-- =====================================================

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
    
    RAISE NOTICE '✅ Profile created successfully';
    
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
-- 2. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'SUPABASE AUTH API APPROACH READY';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Created function: create_promoter_profile_only()';
    RAISE NOTICE '';
    RAISE NOTICE 'NEW APPROACH:';
    RAISE NOTICE '1. Frontend uses supabase.auth.signUp() to create auth user';
    RAISE NOTICE '2. Get the user ID from the auth response';
    RAISE NOTICE '3. Call create_promoter_profile_only() with the user ID';
    RAISE NOTICE '4. This creates the profile linked to the auth user';
    RAISE NOTICE '';
    RAISE NOTICE 'This approach respects Supabase Auth table protection';
    RAISE NOTICE 'and uses the proper Auth API for user creation.';
    RAISE NOTICE '=======================================================';
END $$;
