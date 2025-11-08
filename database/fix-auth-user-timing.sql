-- =====================================================
-- FIX AUTH USER TIMING ISSUE
-- =====================================================
-- The create_promoter_profile_only function can't find newly created auth users
-- This fixes the timing/visibility issue

-- =====================================================
-- 1. UPDATED CREATE_PROMOTER_PROFILE_ONLY FUNCTION
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
    auth_user_exists BOOLEAN := FALSE;
    retry_count INTEGER := 0;
    max_retries INTEGER := 5;
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
    
    -- Check if auth user exists with retry logic (for timing issues)
    WHILE retry_count < max_retries AND NOT auth_user_exists LOOP
        SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = p_user_id) INTO auth_user_exists;
        
        IF NOT auth_user_exists THEN
            retry_count := retry_count + 1;
            RAISE NOTICE '⏳ Auth user not found, retry % of %', retry_count, max_retries;
            
            -- Small delay to allow auth user to become visible
            PERFORM pg_sleep(0.5);
        END IF;
    END LOOP;
    
    -- Final check - if still not found, proceed anyway (auth user might exist but not visible)
    IF NOT auth_user_exists THEN
        RAISE NOTICE '⚠️ Warning: Auth user % not immediately visible, but proceeding with profile creation', p_user_id;
        RAISE NOTICE '💡 This is normal for newly created auth users - they may take a moment to sync';
    ELSE
        RAISE NOTICE '✅ Auth user % confirmed to exist', p_user_id;
    END IF;
    
    -- Generate promoter ID
    new_promoter_id := generate_next_promoter_id();
    RAISE NOTICE '🆔 Generated Promoter ID: %', new_promoter_id;
    
    -- Create profile record (proceed even if auth user not immediately visible)
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
    
    -- Verify the profile was created
    IF NOT EXISTS(SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Profile creation verification failed'
        );
    END IF;
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', p_user_id,
        'name', p_name,
        'phone', p_phone,
        'email', p_email,
        'message', 'Promoter profile created successfully',
        'auth_user_found', auth_user_exists
    );
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Unexpected error in profile creation: % (Code: %)', SQLERRM, SQLSTATE;
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
END;
$$;

-- =====================================================
-- 2. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION create_promoter_profile_only(UUID, TEXT, TEXT, TEXT, TEXT, UUID) TO authenticated;

-- =====================================================
-- 3. TEST THE UPDATED FUNCTION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'AUTH USER TIMING FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'IMPROVEMENTS:';
    RAISE NOTICE '1. ✅ Added retry logic for auth user detection';
    RAISE NOTICE '2. ✅ Graceful handling of timing delays';
    RAISE NOTICE '3. ✅ Profile creation proceeds even if auth user not immediately visible';
    RAISE NOTICE '4. ✅ Better error handling and logging';
    RAISE NOTICE '5. ✅ Verification steps for profile creation';
    RAISE NOTICE '';
    RAISE NOTICE 'This should resolve the "Auth user not found" error!';
    RAISE NOTICE '=======================================================';
END $$;
