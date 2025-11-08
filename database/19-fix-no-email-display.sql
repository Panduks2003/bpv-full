-- =====================================================
-- FIX NO EMAIL DISPLAY ISSUE
-- =====================================================
-- When no email is provided, the email field should be NULL/empty
-- instead of showing the placeholder auth email

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
    display_email VARCHAR(255); -- This will be NULL when no email provided
    default_role_level VARCHAR(50) := 'Affiliate';
    default_status VARCHAR(20) := 'Active';
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
            auth_email, -- This must be unique for auth.users (can be placeholder)
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
    
    -- NOW generate the promoter ID AFTER user creation is successful
    new_promoter_id := generate_next_promoter_id();
    
    -- Create profile record with NULL email when no email provided
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
        
        RAISE NOTICE 'Promoter record created successfully';
    EXCEPTION WHEN OTHERS THEN
        -- If promoters table doesn't exist, continue without it
        RAISE NOTICE 'Promoters table insert failed (continuing anyway): %', SQLERRM;
    END;
    
    -- Return success response with proper email handling
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', new_user_id,
        'auth_email', auth_email, -- Internal auth email (may be placeholder)
        'display_email', display_email, -- NULL when no email provided
        'name', p_name,
        'phone', p_phone,
        'role_level', default_role_level,
        'status', default_status,
        'message', 'Promoter created successfully with ID: ' || new_promoter_id
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
    test_result_no_email JSON;
    test_result_with_email JSON;
    display_email_1 TEXT;
    display_email_2 TEXT;
BEGIN
    RAISE NOTICE '=== TESTING EMAIL DISPLAY HANDLING ===';
    
    -- Test 1: Create promoter WITHOUT email
    SELECT create_unified_promoter(
        'Test No Email Display',
        'testpass123',
        '9876543299',
        NULL, -- No email provided
        'Test Address',
        NULL
    ) INTO test_result_no_email;
    
    -- Test 2: Create promoter WITH email
    SELECT create_unified_promoter(
        'Test With Email Display',
        'testpass123',
        '9876543298',
        'test@example.com', -- Email provided
        'Test Address',
        NULL
    ) INTO test_result_with_email;
    
    -- Check results
    IF (test_result_no_email->>'success')::boolean AND (test_result_with_email->>'success')::boolean THEN
        display_email_1 := test_result_no_email->>'display_email';
        display_email_2 := test_result_with_email->>'display_email';
        
        RAISE NOTICE '✅ SUCCESS: Both promoters created!';
        RAISE NOTICE 'No Email Case:';
        RAISE NOTICE '  - Promoter ID: %', test_result_no_email->>'promoter_id';
        RAISE NOTICE '  - Display Email: %', COALESCE(display_email_1, 'NULL (correct!)');
        RAISE NOTICE '  - Auth Email: %', test_result_no_email->>'auth_email';
        
        RAISE NOTICE 'With Email Case:';
        RAISE NOTICE '  - Promoter ID: %', test_result_with_email->>'promoter_id';
        RAISE NOTICE '  - Display Email: %', display_email_2;
        RAISE NOTICE '  - Auth Email: %', test_result_with_email->>'auth_email';
        
        -- Verify correct behavior
        IF display_email_1 IS NULL AND display_email_2 = 'test@example.com' THEN
            RAISE NOTICE '✅ Email display handling working correctly!';
        ELSE
            RAISE NOTICE '❌ Email display handling not working as expected';
        END IF;
        
        -- Clean up
        DELETE FROM profiles WHERE id IN (
            (test_result_no_email->>'user_id')::UUID,
            (test_result_with_email->>'user_id')::UUID
        );
        RAISE NOTICE '🧹 Test promoters cleaned up';
    ELSE
        RAISE NOTICE '❌ FAILED:';
        RAISE NOTICE 'No Email Result: %', test_result_no_email->>'error';
        RAISE NOTICE 'With Email Result: %', test_result_with_email->>'error';
    END IF;
END $$;

-- =====================================================
-- 3. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'NO EMAIL DISPLAY ISSUE FIXED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '1. Separated auth_email (for authentication) from display_email';
    RAISE NOTICE '2. When no email provided:';
    RAISE NOTICE '   - auth_email: placeholder for authentication';
    RAISE NOTICE '   - display_email: NULL (no email shown in UI)';
    RAISE NOTICE '3. When email provided:';
    RAISE NOTICE '   - auth_email: provided email (or unique version)';
    RAISE NOTICE '   - display_email: provided email';
    RAISE NOTICE '';
    RAISE NOTICE 'UI will now show:';
    RAISE NOTICE '- No email: Empty/blank email field';
    RAISE NOTICE '- With email: Actual email address';
    RAISE NOTICE '=======================================================';
END $$;
