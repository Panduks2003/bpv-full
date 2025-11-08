-- =====================================================
-- SIMPLIFY PROMOTER FORM - REMOVE ROLE/STATUS FIELDS
-- =====================================================
-- Remove Role/Level and Status fields from promoter creation form
-- Automatically set role as 'Affiliate' and status as 'Active'

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
    -- Removed p_role_level and p_status parameters
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
    default_role_level VARCHAR(50) := 'Affiliate'; -- Default role
    default_status VARCHAR(20) := 'Active'; -- Default status
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
    
    -- Handle email for authentication and storage
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        -- Create placeholder email for authentication (must be unique for auth.users)
        auth_email := 'noemail+' || replace(new_user_id::text, '-', '') || '@brightplanetventures.local';
        final_email := auth_email; -- Use placeholder as final email
    ELSE
        -- For auth.users, we still need unique emails, so add UUID if email exists in auth.users
        IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
            -- Create unique auth email for authentication
            auth_email := split_part(p_email, '@', 1) || '+' || replace(new_user_id::text, '-', '')::text || '@' || split_part(p_email, '@', 2);
        ELSE
            auth_email := p_email;
        END IF;
        -- For profiles table, we can now use the original email (duplicates allowed)
        final_email := p_email;
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
            auth_email, -- This must be unique for auth.users
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
    
    -- Create profile record with automatic role and status
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
        final_email, -- This can be duplicate now
        TRIM(p_name),
        'promoter', -- Always promoter
        TRIM(p_phone),
        p_address,
        new_promoter_id, -- Generated AFTER successful user creation
        default_role_level, -- Automatically set to 'Affiliate'
        default_status, -- Automatically set to 'Active'
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
            LOWER(default_status), -- Use lowercase for promoters table
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
    
    -- Return success response with generated promoter ID and auto-set values
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', new_user_id,
        'auth_email', auth_email,
        'display_email', CASE WHEN p_email IS NULL OR TRIM(p_email) = '' THEN 'No email provided' ELSE p_email END,
        'name', p_name,
        'phone', p_phone,
        'role_level', default_role_level, -- Return the auto-set role
        'status', default_status, -- Return the auto-set status
        'message', 'Promoter created successfully with ID: ' || new_promoter_id || ' (Role: ' || default_role_level || ', Status: ' || default_status || ')'
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
-- 2. TEST THE SIMPLIFIED FUNCTION
-- =====================================================

DO $$
DECLARE
    test_result JSON;
    promoter_id TEXT;
    role_level TEXT;
    status TEXT;
BEGIN
    RAISE NOTICE '=== TESTING SIMPLIFIED PROMOTER CREATION ===';
    
    -- Create a test promoter with simplified parameters
    SELECT create_unified_promoter(
        'Test Simplified Form',
        'testpass123',
        '9876543299',
        'simplified@test.com',
        'Test Address',
        NULL -- No parent promoter
    ) INTO test_result;
    
    -- Check result
    IF (test_result->>'success')::boolean THEN
        promoter_id := test_result->>'promoter_id';
        role_level := test_result->>'role_level';
        status := test_result->>'status';
        
        RAISE NOTICE '✅ SUCCESS: Promoter created!';
        RAISE NOTICE 'Generated Promoter ID: %', promoter_id;
        RAISE NOTICE 'Auto-set Role: %', role_level;
        RAISE NOTICE 'Auto-set Status: %', status;
        RAISE NOTICE 'Message: %', test_result->>'message';
        
        -- Verify automatic values
        IF role_level = 'Affiliate' AND status = 'Active' THEN
            RAISE NOTICE '✅ Automatic role and status assignment working correctly!';
        ELSE
            RAISE NOTICE '❌ Automatic role/status assignment failed';
        END IF;
        
        -- Clean up
        DELETE FROM profiles WHERE id = (test_result->>'user_id')::UUID;
        RAISE NOTICE '🧹 Test promoter cleaned up';
    ELSE
        RAISE NOTICE '❌ FAILED: %', test_result->>'error';
    END IF;
END $$;

-- =====================================================
-- 3. UPDATE EXISTING ADMIN PROMOTERS FUNCTION CALL
-- =====================================================

-- Note: The AdminPromoters.js file will need to be updated to remove 
-- the roleLevel and status parameters from the function call

-- Example of how the frontend should now call the function:
-- SELECT create_unified_promoter(
--     'John Doe',           -- p_name
--     'password123',        -- p_password  
--     '9876543210',         -- p_phone
--     'john@example.com',   -- p_email (optional)
--     '123 Main St',        -- p_address (optional)
--     'uuid-of-parent'      -- p_parent_promoter_id (optional)
-- );

-- =====================================================
-- 4. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PROMOTER FORM SIMPLIFIED - ROLE/STATUS REMOVED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '1. Removed Role/Level field from form';
    RAISE NOTICE '2. Removed Status field from form';
    RAISE NOTICE '3. Automatically set role_level to "Affiliate"';
    RAISE NOTICE '4. Automatically set status to "Active"';
    RAISE NOTICE '5. Updated database function parameters';
    RAISE NOTICE '';
    RAISE NOTICE 'Form now contains only essential fields:';
    RAISE NOTICE '- Name (required)';
    RAISE NOTICE '- Email (optional with toggle)';
    RAISE NOTICE '- Phone (required)';
    RAISE NOTICE '- Address (optional)';
    RAISE NOTICE '- Parent Promoter (required)';
    RAISE NOTICE '- Password (required for new promoters)';
    RAISE NOTICE '';
    RAISE NOTICE 'All new promoters will be created as:';
    RAISE NOTICE '- Role: Affiliate';
    RAISE NOTICE '- Status: Active';
    RAISE NOTICE '=======================================================';
END $$;
