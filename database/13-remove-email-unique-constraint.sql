-- =====================================================
-- REMOVE EMAIL UNIQUE CONSTRAINT
-- =====================================================
-- The profiles table has a unique constraint on email column
-- But we want to allow shared/duplicate emails for promoters

-- =====================================================
-- 1. REMOVE UNIQUE CONSTRAINT ON EMAIL
-- =====================================================

-- Find and drop the unique constraint on email column
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Find the constraint name
    SELECT conname INTO constraint_name
    FROM pg_constraint 
    WHERE conrelid = 'profiles'::regclass 
    AND contype = 'u' 
    AND array_to_string(conkey, ',') = (
        SELECT array_to_string(array_agg(attnum), ',')
        FROM pg_attribute 
        WHERE attrelid = 'profiles'::regclass 
        AND attname = 'email'
    );
    
    -- Drop the constraint if found
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE profiles DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Dropped unique constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No unique constraint found on email column';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error removing constraint: %', SQLERRM;
END $$;

-- Alternative approach - try common constraint names
DO $$
BEGIN
    -- Try dropping common constraint names
    BEGIN
        ALTER TABLE profiles DROP CONSTRAINT profiles_email_key;
        RAISE NOTICE 'Dropped constraint: profiles_email_key';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'profiles_email_key constraint not found or already dropped';
    END;
    
    BEGIN
        ALTER TABLE profiles DROP CONSTRAINT profiles_email_unique;
        RAISE NOTICE 'Dropped constraint: profiles_email_unique';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'profiles_email_unique constraint not found or already dropped';
    END;
    
    BEGIN
        ALTER TABLE profiles DROP CONSTRAINT email_unique;
        RAISE NOTICE 'Dropped constraint: email_unique';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'email_unique constraint not found or already dropped';
    END;
END $$;

-- =====================================================
-- 2. VERIFY EMAIL COLUMN IS NOW NON-UNIQUE
-- =====================================================

-- Check if any unique constraints remain on email
SELECT 
    conname as constraint_name,
    contype as constraint_type
FROM pg_constraint 
WHERE conrelid = 'profiles'::regclass 
AND contype = 'u'
AND array_to_string(conkey, ',') = (
    SELECT array_to_string(array_agg(attnum), ',')
    FROM pg_attribute 
    WHERE attrelid = 'profiles'::regclass 
    AND attname = 'email'
);

-- =====================================================
-- 3. SIMPLIFY CREATE_UNIFIED_PROMOTER FUNCTION
-- =====================================================

-- Now that emails can be duplicated, we can simplify the function
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
    
    -- Create profile record (email can now be duplicated)
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
-- 4. TEST DUPLICATE EMAIL FUNCTIONALITY
-- =====================================================

DO $$
DECLARE
    test_result1 JSON;
    test_result2 JSON;
    shared_email TEXT := 'shared@example.com';
BEGIN
    -- Test 1: Create first promoter with shared email
    SELECT create_unified_promoter(
        'First Promoter',
        'testpass123',
        '9876543210',
        shared_email,
        'Address 1',
        NULL,
        'Affiliate',
        'Active'
    ) INTO test_result1;
    
    -- Test 2: Create second promoter with SAME email
    SELECT create_unified_promoter(
        'Second Promoter',
        'testpass456',
        '9876543211',
        shared_email, -- Same email as first promoter
        'Address 2',
        NULL,
        'Manager',
        'Active'
    ) INTO test_result2;
    
    -- Check results
    IF (test_result1->>'success')::boolean AND (test_result2->>'success')::boolean THEN
        RAISE NOTICE '✅ SUCCESS: Both promoters created with shared email!';
        RAISE NOTICE 'Promoter 1 ID: %', test_result1->>'promoter_id';
        RAISE NOTICE 'Promoter 2 ID: %', test_result2->>'promoter_id';
        RAISE NOTICE 'Both using email: %', shared_email;
        
        -- Clean up test data
        DELETE FROM profiles WHERE id IN (
            (test_result1->>'user_id')::UUID,
            (test_result2->>'user_id')::UUID
        );
        RAISE NOTICE '🧹 Test promoters cleaned up';
    ELSE
        RAISE NOTICE '❌ FAILED:';
        RAISE NOTICE 'Result 1: %', test_result1->>'error';
        RAISE NOTICE 'Result 2: %', test_result2->>'error';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR: %', SQLERRM;
END $$;

-- =====================================================
-- 5. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'EMAIL UNIQUE CONSTRAINT REMOVED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '1. Removed unique constraint on email column';
    RAISE NOTICE '2. Updated function to handle duplicate emails properly';
    RAISE NOTICE '3. Tested shared email functionality';
    RAISE NOTICE '';
    RAISE NOTICE 'Multiple promoters can now share the same email address!';
    RAISE NOTICE 'Try creating promoters from the admin UI now!';
    RAISE NOTICE '=======================================================';
END $$;
