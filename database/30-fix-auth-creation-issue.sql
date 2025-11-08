-- =====================================================
-- FIX AUTH RECORD CREATION ISSUE
-- =====================================================
-- The create_unified_promoter function is not creating auth.users records

-- =====================================================
-- 1. CHECK AUTH.USERS TABLE PERMISSIONS
-- =====================================================

-- Check if we can insert into auth.users at all
DO $$
DECLARE
    test_id UUID := gen_random_uuid();
    test_email TEXT := 'test+' || replace(test_id::text, '-', '') || '@test.local';
BEGIN
    RAISE NOTICE '=== TESTING AUTH.USERS INSERT PERMISSIONS ===';
    
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
            test_id,
            '00000000-0000-0000-0000-000000000000',
            test_email,
            crypt('testpass', gen_salt('bf')),
            NOW(),
            NOW(),
            NOW(),
            'authenticated',
            'authenticated'
        );
        
        RAISE NOTICE '✅ SUCCESS: Can insert into auth.users';
        
        -- Clean up
        DELETE FROM auth.users WHERE id = test_id;
        RAISE NOTICE '🧹 Test record cleaned up';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ FAILED: Cannot insert into auth.users: %', SQLERRM;
        RAISE NOTICE 'Error code: %', SQLSTATE;
    END;
END $$;

-- =====================================================
-- 2. CREATE SIMPLIFIED PROMOTER CREATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION create_promoter_with_auth(
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
    result JSON;
    auth_success BOOLEAN := FALSE;
    profile_success BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '🚀 Starting promoter creation: %', p_name;
    
    -- Generate UUID first
    new_user_id := gen_random_uuid();
    RAISE NOTICE '📋 Generated UUID: %', new_user_id;
    
    -- Handle email
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        auth_email := 'noemail+' || replace(new_user_id::text, '-', '') || '@brightplanetventures.local';
        display_email := NULL;
    ELSE
        auth_email := p_email;
        display_email := p_email;
    END IF;
    
    RAISE NOTICE '📧 Auth email: %', auth_email;
    RAISE NOTICE '📧 Display email: %', COALESCE(display_email, 'NULL');
    
    -- Try to create auth user with detailed logging
    BEGIN
        RAISE NOTICE '🔐 Attempting to create auth user...';
        
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
        
        auth_success := TRUE;
        RAISE NOTICE '✅ Auth user created successfully';
        
    EXCEPTION 
        WHEN unique_violation THEN
            RAISE NOTICE '⚠️ Email already exists, trying with UUID suffix...';
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
                    instance_id,
                    auth_email,
                    crypt(p_password, gen_salt('bf')),
                    NOW(),
                    NOW(),
                    NOW(),
                    'authenticated',
                    'authenticated'
                );
                auth_success := TRUE;
                RAISE NOTICE '✅ Auth user created with fallback email: %', auth_email;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '❌ Auth creation failed even with fallback: % (Code: %)', SQLERRM, SQLSTATE;
                auth_success := FALSE;
            END;
        WHEN OTHERS THEN
            RAISE NOTICE '❌ Auth creation failed: % (Code: %)', SQLERRM, SQLSTATE;
            auth_success := FALSE;
    END;
    
    -- Generate promoter ID
    new_promoter_id := generate_next_promoter_id();
    RAISE NOTICE '🆔 Generated Promoter ID: %', new_promoter_id;
    
    -- Create profile record
    BEGIN
        RAISE NOTICE '👤 Creating profile record...';
        
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
            display_email,
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
        
        profile_success := TRUE;
        RAISE NOTICE '✅ Profile created successfully';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Profile creation failed: % (Code: %)', SQLERRM, SQLSTATE;
        profile_success := FALSE;
        
        -- If profile creation fails but auth was created, clean up auth
        IF auth_success THEN
            DELETE FROM auth.users WHERE id = new_user_id;
            RAISE NOTICE '🧹 Cleaned up auth record due to profile failure';
        END IF;
    END;
    
    -- Return detailed result
    RETURN json_build_object(
        'success', auth_success AND profile_success,
        'promoter_id', new_promoter_id,
        'user_id', new_user_id,
        'auth_email', auth_email,
        'display_email', display_email,
        'name', p_name,
        'phone', p_phone,
        'auth_created', auth_success,
        'profile_created', profile_success,
        'message', 
            CASE 
                WHEN auth_success AND profile_success THEN 'Promoter created successfully with full authentication'
                WHEN NOT auth_success THEN 'Failed to create authentication record'
                WHEN NOT profile_success THEN 'Failed to create profile record'
                ELSE 'Unknown error'
            END
    );
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Unexpected error: % (Code: %)', SQLERRM, SQLSTATE;
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
END;
$$;

-- =====================================================
-- 3. TEST THE NEW FUNCTION
-- =====================================================

DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== TESTING NEW PROMOTER CREATION FUNCTION ===';
    
    SELECT create_promoter_with_auth(
        'Test Auth Creation',
        'testpass123',
        '9876543210',
        'testauth2@example.com',
        'Test Address',
        NULL
    ) INTO test_result;
    
    RAISE NOTICE '';
    RAISE NOTICE '📋 Test Result: %', test_result;
    
    -- Clean up if successful
    IF (test_result->>'success')::boolean THEN
        DELETE FROM profiles WHERE id = (test_result->>'user_id')::UUID;
        DELETE FROM auth.users WHERE id = (test_result->>'user_id')::UUID;
        RAISE NOTICE '🧹 Test records cleaned up';
    END IF;
    
END $$;

-- =====================================================
-- 4. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'AUTH CREATION FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Created new function: create_promoter_with_auth()';
    RAISE NOTICE 'This function has detailed logging to show exactly';
    RAISE NOTICE 'what happens during auth.users record creation.';
    RAISE NOTICE '';
    RAISE NOTICE 'If the test above succeeded, the auth creation works.';
    RAISE NOTICE 'If it failed, check the error messages above.';
    RAISE NOTICE '=======================================================';
END $$;
