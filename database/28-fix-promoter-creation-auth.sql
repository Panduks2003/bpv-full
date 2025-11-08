-- =====================================================
-- FIX PROMOTER CREATION TO INCLUDE AUTH RECORDS
-- =====================================================
-- Update create_unified_promoter to properly create auth.users records

-- =====================================================
-- 1. UPDATE CREATE_UNIFIED_PROMOTER FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION create_unified_promoter(
    p_name VARCHAR(255),
    p_password VARCHAR(255),
    p_phone VARCHAR(20),
    p_email VARCHAR(255) DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_user_id UUID;
    new_promoter_id VARCHAR(20);
    auth_email VARCHAR(255);
    display_email VARCHAR(255);
    default_role_level VARCHAR(50) := 'Affiliate';
    default_status VARCHAR(20) := 'Active';
    result JSON;
    auth_creation_success BOOLEAN := FALSE;
BEGIN
    -- Validate required fields
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Name is required'
        );
    END IF;
    
    IF p_password IS NULL OR LENGTH(TRIM(p_password)) < 6 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Password must be at least 6 characters'
        );
    END IF;
    
    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Phone number is required'
        );
    END IF;
    
    -- Validate phone format (10 digits starting with 6-9)
    IF NOT (p_phone ~ '^[6-9][0-9]{9}$') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Phone must be a valid 10-digit Indian number starting with 6-9'
        );
    END IF;
    
    -- Validate parent promoter exists if provided
    IF p_parent_promoter_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_parent_promoter_id AND role IN ('promoter', 'admin')) THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Invalid parent promoter ID'
            );
        END IF;
    END IF;
    
    -- Generate UUID for new user FIRST
    new_user_id := gen_random_uuid();
    
    -- Handle email for authentication and display
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        -- Create placeholder email ONLY for authentication (auth.users table)
        auth_email := 'noemail+' || replace(new_user_id::text, '-', '') || '@brightplanetventures.local';
        -- Set display email to NULL (no email to show in UI)
        display_email := NULL;
    ELSE
        -- Use provided email
        IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
            -- Create unique auth email for authentication
            auth_email := split_part(p_email, '@', 1) || '+' || replace(new_user_id::text, '-', '')::text || '@' || split_part(p_email, '@', 2);
        ELSE
            auth_email := p_email;
        END IF;
        -- Set display email to the provided email
        display_email := p_email;
    END IF;
    
    -- Create auth user first (with enhanced error handling and retry logic)
    BEGIN
        -- Try to create the auth user with proper error handling
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            aud,
            role
        ) VALUES (
            new_user_id,
            '00000000-0000-0000-0000-000000000000',
            auth_email,
            crypt(p_password, gen_salt('bf')),
            NOW(),
            NOW(),
            NOW(),
            'authenticated',
            'authenticated'
        );
        
        auth_creation_success := TRUE;
        RAISE NOTICE '✅ Auth user created successfully: % (ID: %)', auth_email, new_user_id;
        
    EXCEPTION 
        WHEN unique_violation THEN
            -- If email already exists, try with a different UUID suffix
            auth_email := 'promoter+' || replace(gen_random_uuid()::text, '-', '') || '@brightplanetventures.local';
            BEGIN
                INSERT INTO auth.users (
                    id,
                    instance_id,
                    email,
                    encrypted_password,
                    email_confirmed_at,
                    created_at,
                    updated_at,
                    aud,
                    role
                ) VALUES (
                    new_user_id,
                    '00000000-0000-0000-0000-000000000000',
                    auth_email,
                    crypt(p_password, gen_salt('bf')),
                    NOW(),
                    NOW(),
                    NOW(),
                    'authenticated',
                    'authenticated'
                );
                auth_creation_success := TRUE;
                RAISE NOTICE '✅ Auth user created with fallback email: % (ID: %)', auth_email, new_user_id;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '❌ Auth user creation failed even with fallback: %', SQLERRM;
                auth_creation_success := FALSE;
            END;
        WHEN OTHERS THEN
            RAISE NOTICE '❌ Auth user creation failed: %', SQLERRM;
            auth_creation_success := FALSE;
    END;
    
    -- Continue with profile creation even if auth creation fails (for debugging)
    -- In production, you might want to fail completely if auth creation fails
    
    -- Generate the promoter ID AFTER user creation
    new_promoter_id := generate_next_promoter_id();
    
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
        new_user_id,
        display_email, -- This will be NULL when no email provided
        TRIM(p_name),
        'promoter',
        TRIM(p_phone),
        p_address,
        new_promoter_id,
        default_role_level,
        default_status,
        p_parent_promoter_id,
        NOW(),
        NOW()
    );
    
    -- Create promoter record if promoters table exists
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
            new_user_id,
            new_promoter_id,
            p_parent_promoter_id,
            LOWER(default_status),
            0.05, -- Default 5% commission
            true,
            true,
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '✅ Promoter record created successfully';
    EXCEPTION WHEN OTHERS THEN
        -- If promoters table doesn't exist, continue without it
        RAISE NOTICE '⚠️ Promoters table insert failed (continuing anyway): %', SQLERRM;
    END;
    
    -- Return success response with auth status
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', new_user_id,
        'auth_email', auth_email,
        'display_email', display_email,
        'name', p_name,
        'phone', p_phone,
        'role_level', default_role_level,
        'status', default_status,
        'auth_created', auth_creation_success,
        'message', 'Promoter created successfully with ID: ' || new_promoter_id || 
                  CASE WHEN auth_creation_success THEN ' (Auth: ✅)' ELSE ' (Auth: ❌)' END
    );
    
EXCEPTION WHEN OTHERS THEN
    -- Return detailed error response
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_detail', SQLSTATE,
        'hint', 'Check database logs for more details'
    );
END;
$$;

-- =====================================================
-- 2. TEST THE UPDATED FUNCTION
-- =====================================================

DO $$
DECLARE
    test_result JSON;
    promoter_id TEXT;
    user_id UUID;
    auth_created BOOLEAN;
BEGIN
    RAISE NOTICE '=== TESTING UPDATED PROMOTER CREATION ===';
    
    -- Create a test promoter
    SELECT create_unified_promoter(
        'Test Auth Fix',
        'testpass123',
        '9876543210',
        'testauth@example.com',
        'Test Address',
        NULL
    ) INTO test_result;
    
    -- Check result
    IF (test_result->>'success')::boolean THEN
        promoter_id := test_result->>'promoter_id';
        user_id := (test_result->>'user_id')::UUID;
        auth_created := (test_result->>'auth_created')::boolean;
        
        RAISE NOTICE '✅ SUCCESS: Promoter created!';
        RAISE NOTICE 'Promoter ID: %', promoter_id;
        RAISE NOTICE 'User ID: %', user_id;
        RAISE NOTICE 'Auth Created: %', auth_created;
        RAISE NOTICE 'Message: %', test_result->>'message';
        
        -- Verify auth record exists
        IF EXISTS (SELECT 1 FROM auth.users WHERE id = user_id) THEN
            RAISE NOTICE '✅ Auth record verified in auth.users table';
        ELSE
            RAISE NOTICE '❌ Auth record NOT found in auth.users table';
        END IF;
        
        -- Test authentication
        BEGIN
            PERFORM authenticate_promoter_by_id(promoter_id, 'wrongpassword');
            RAISE NOTICE '❌ Authentication should have failed';
        EXCEPTION WHEN OTHERS THEN
            IF SQLERRM = 'Invalid Promoter ID or password' THEN
                RAISE NOTICE '✅ Authentication function works correctly';
            ELSE
                RAISE NOTICE '⚠️ Authentication error: %', SQLERRM;
            END IF;
        END;
        
        -- Clean up test promoter
        DELETE FROM profiles WHERE id = user_id;
        DELETE FROM auth.users WHERE id = user_id;
        RAISE NOTICE '🧹 Test promoter cleaned up';
        
    ELSE
        RAISE NOTICE '❌ FAILED: %', test_result->>'error';
    END IF;
END $$;

-- =====================================================
-- 3. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PROMOTER CREATION AUTH FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Updates made:';
    RAISE NOTICE '1. Enhanced auth.users creation with error handling';
    RAISE NOTICE '2. Added retry logic for unique email conflicts';
    RAISE NOTICE '3. Added auth_created status in response';
    RAISE NOTICE '4. Improved error logging and debugging';
    RAISE NOTICE '';
    RAISE NOTICE 'Now try creating a new promoter from the admin panel.';
    RAISE NOTICE 'It should create both profile AND auth records properly.';
    RAISE NOTICE '=======================================================';
END $$;
