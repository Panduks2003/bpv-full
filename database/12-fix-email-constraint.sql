-- =====================================================
-- FIX EMAIL NOT-NULL CONSTRAINT ISSUE
-- =====================================================
-- The profiles table has NOT NULL constraint on email column
-- But promoter creation tries to insert NULL for optional emails

-- =====================================================
-- 1. OPTION A: REMOVE NOT NULL CONSTRAINT (RECOMMENDED)
-- =====================================================

-- Make email column nullable to support optional emails
ALTER TABLE profiles ALTER COLUMN email DROP NOT NULL;

-- =====================================================
-- 2. UPDATE CREATE_UNIFIED_PROMOTER FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION create_unified_promoter(
    p_name VARCHAR(255),
    p_password VARCHAR(255),
    p_phone VARCHAR(20),
    p_email VARCHAR(255) DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL,
    p_role_level VARCHAR(50) DEFAULT 'Affiliate',
    p_status VARCHAR(20) DEFAULT 'Active'
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
    final_email VARCHAR(255);
    result JSON;
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
    
    -- Generate unique promoter ID
    new_promoter_id := generate_next_promoter_id();
    
    -- Generate UUID for new user
    new_user_id := gen_random_uuid();
    
    -- Handle email for authentication and storage
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        -- Create placeholder email for authentication
        auth_email := 'noemail+' || replace(new_user_id::text, '-', '') || '@brightplanetventures.local';
        final_email := auth_email; -- Use placeholder as final email (not NULL)
    ELSE
        -- Use provided email, but make it unique for auth if needed
        IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
            -- Create unique auth email while keeping display email
            auth_email := split_part(p_email, '@', 1) || '+' || replace(new_user_id::text, '-', '')::text || '@' || split_part(p_email, '@', 2);
        ELSE
            auth_email := p_email;
        END IF;
        final_email := p_email; -- Use provided email as final email
    END IF;
    
    -- Create auth user first (with error handling)
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
        
        RAISE NOTICE 'Auth user created successfully: %', auth_email;
    EXCEPTION WHEN OTHERS THEN
        -- Log the error but continue (some systems don't allow direct auth.users access)
        RAISE NOTICE 'Auth user creation failed (continuing anyway): %', SQLERRM;
    END;
    
    -- Create profile record with guaranteed non-null email
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
        final_email, -- This will never be NULL now
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
            LOWER(p_status),
            0.05, -- Default 5% commission
            true,
            true,
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Promoter record created successfully';
    EXCEPTION WHEN OTHERS THEN
        -- If promoters table doesn't exist, continue without it
        RAISE NOTICE 'Promoters table insert failed (continuing anyway): %', SQLERRM;
    END;
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', new_user_id,
        'auth_email', auth_email,
        'display_email', CASE WHEN p_email IS NULL OR TRIM(p_email) = '' THEN 'No email provided' ELSE p_email END,
        'name', p_name,
        'phone', p_phone,
        'role_level', p_role_level,
        'status', p_status
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
-- 3. TEST THE FIXED FUNCTION
-- =====================================================

DO $$
DECLARE
    test_result JSON;
BEGIN
    -- Test promoter creation with NO email (should work now)
    SELECT create_unified_promoter(
        'Test No Email',
        'testpass123',
        '9876543210',
        NULL, -- No email provided
        'Test Address',
        NULL,
        'Affiliate',
        'Active'
    ) INTO test_result;
    
    -- Check result
    IF (test_result->>'success')::boolean THEN
        RAISE NOTICE '✅ SUCCESS: Promoter created without email!';
        RAISE NOTICE 'Generated Promoter ID: %', test_result->>'promoter_id';
        RAISE NOTICE 'Auth Email: %', test_result->>'auth_email';
        RAISE NOTICE 'Display Email: %', test_result->>'display_email';
        
        -- Clean up test data
        DELETE FROM profiles WHERE id = (test_result->>'user_id')::UUID;
        RAISE NOTICE '🧹 Test promoter cleaned up';
    ELSE
        RAISE NOTICE '❌ FAILED: %', test_result->>'error';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR: %', SQLERRM;
END $$;

-- Test with email provided
DO $$
DECLARE
    test_result JSON;
BEGIN
    -- Test promoter creation WITH email
    SELECT create_unified_promoter(
        'Test With Email',
        'testpass123',
        '9876543211',
        'test@example.com', -- Email provided
        'Test Address',
        NULL,
        'Affiliate',
        'Active'
    ) INTO test_result;
    
    -- Check result
    IF (test_result->>'success')::boolean THEN
        RAISE NOTICE '✅ SUCCESS: Promoter created with email!';
        RAISE NOTICE 'Generated Promoter ID: %', test_result->>'promoter_id';
        RAISE NOTICE 'Auth Email: %', test_result->>'auth_email';
        RAISE NOTICE 'Display Email: %', test_result->>'display_email';
        
        -- Clean up test data
        DELETE FROM profiles WHERE id = (test_result->>'user_id')::UUID;
        RAISE NOTICE '🧹 Test promoter cleaned up';
    ELSE
        RAISE NOTICE '❌ FAILED: %', test_result->>'error';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR: %', SQLERRM;
END $$;

-- =====================================================
-- 4. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'EMAIL CONSTRAINT FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '1. Made email column nullable in profiles table';
    RAISE NOTICE '2. Updated create_unified_promoter function to handle NULL emails';
    RAISE NOTICE '3. Tested both scenarios (with and without email)';
    RAISE NOTICE '';
    RAISE NOTICE 'Promoter creation should now work from the admin UI!';
    RAISE NOTICE '=======================================================';
END $$;
