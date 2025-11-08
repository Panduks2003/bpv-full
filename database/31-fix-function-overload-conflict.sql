-- =====================================================
-- FIX FUNCTION OVERLOAD CONFLICT
-- =====================================================
-- Drop all versions of create_promoter_with_auth and create clean version

-- =====================================================
-- 1. DROP ALL EXISTING VERSIONS
-- =====================================================

-- Drop all possible versions of create_promoter_with_auth
DROP FUNCTION IF EXISTS create_promoter_with_auth(VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, UUID);
DROP FUNCTION IF EXISTS create_promoter_with_auth(TEXT, TEXT, TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS create_promoter_with_auth(character varying, character varying, character varying, character varying, text, uuid);
DROP FUNCTION IF EXISTS create_promoter_with_auth(text, text, text, text, text, uuid);

-- Dynamic cleanup for any remaining versions
DO $$
DECLARE
    func_record RECORD;
BEGIN
    -- Clean up any remaining create_promoter_with_auth functions
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc 
        WHERE proname = 'create_promoter_with_auth'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.proname || '(' || func_record.args || ')';
        RAISE NOTICE 'Dropped function: %(%)', func_record.proname, func_record.args;
    END LOOP;
END $$;

-- =====================================================
-- 2. CREATE CLEAN FUNCTION WITH EXPLICIT TYPES
-- =====================================================

CREATE OR REPLACE FUNCTION create_promoter_with_auth(
    p_name TEXT,
    p_password TEXT,
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
    new_user_id UUID;
    new_promoter_id TEXT;
    auth_email TEXT;
    display_email TEXT;
    result JSON;
    auth_success BOOLEAN := FALSE;
    profile_success BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '🚀 Starting promoter creation: %', p_name;
    
    -- Input validation
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Name is required');
    END IF;
    
    IF p_password IS NULL OR LENGTH(TRIM(p_password)) < 6 THEN
        RETURN json_build_object('success', false, 'error', 'Password must be at least 6 characters');
    END IF;
    
    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Phone number is required');
    END IF;
    
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
-- 3. TEST THE CLEAN FUNCTION
-- =====================================================

DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== TESTING CLEAN PROMOTER CREATION FUNCTION ===';
    
    SELECT create_promoter_with_auth(
        'Test Auth Creation'::TEXT,
        'testpass123'::TEXT,
        '9876543210'::TEXT,
        'testauth2@example.com'::TEXT,
        'Test Address'::TEXT,
        NULL::UUID
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
-- 4. VERIFY FUNCTION EXISTS
-- =====================================================

SELECT 
    'FUNCTION_CREATED' as status,
    proname as function_name,
    pg_get_function_arguments(oid) as parameters
FROM pg_proc 
WHERE proname = 'create_promoter_with_auth'
AND pronamespace = 'public'::regnamespace;

-- =====================================================
-- 5. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'FUNCTION OVERLOAD CONFLICT RESOLVED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Created clean function: create_promoter_with_auth()';
    RAISE NOTICE 'All parameters are explicitly typed as TEXT/UUID';
    RAISE NOTICE 'Function includes detailed logging for debugging';
    RAISE NOTICE '';
    RAISE NOTICE 'This function properly stores the form password';
    RAISE NOTICE 'in auth.users for Promoter ID authentication.';
    RAISE NOTICE '=======================================================';
END $$;
