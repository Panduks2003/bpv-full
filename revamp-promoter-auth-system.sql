-- =====================================================
-- REVAMP PROMOTER AUTHENTICATION SYSTEM
-- =====================================================
-- This script implements Promoter ID-only authentication system
-- with email/phone as metadata only (no uniqueness constraints)

-- =====================================================
-- 1. REMOVE UNIQUE CONSTRAINTS ON EMAIL AND PHONE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== STEP 1: REMOVING UNIQUE CONSTRAINTS ===';
    
    -- Drop unique constraint on email if it exists
    BEGIN
        ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_email_key;
        RAISE NOTICE '✅ Removed unique constraint on profiles.email';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  No unique constraint found on profiles.email';
    END;
    
    -- Drop unique constraint on phone if it exists
    BEGIN
        ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_phone_key;
        RAISE NOTICE '✅ Removed unique constraint on profiles.phone';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  No unique constraint found on profiles.phone';
    END;
    
    -- Drop any other email/phone unique indexes
    BEGIN
        DROP INDEX IF EXISTS idx_profiles_email_unique;
        DROP INDEX IF EXISTS idx_profiles_phone_unique;
        RAISE NOTICE '✅ Removed any unique indexes on email/phone';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  No unique indexes found on email/phone';
    END;
END $$;

-- =====================================================
-- 2. UPDATE PROMOTER ID GENERATION TO USE BPVP FORMAT
-- =====================================================

-- Update the promoter ID generation function to use BPVP format
CREATE OR REPLACE FUNCTION generate_next_promoter_id()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_number INTEGER;
    new_promoter_id VARCHAR(20);
BEGIN
    -- Get and increment the next number atomically
    UPDATE promoter_id_sequence 
    SET last_promoter_number = last_promoter_number + 1,
        updated_at = NOW()
    RETURNING last_promoter_number INTO next_number;
    
    -- Format as BPVP01, BPVP02, etc. (2-digit format)
    new_promoter_id := 'BPVP' || LPAD(next_number::TEXT, 2, '0');
    
    -- Ensure uniqueness (in case of race conditions)
    WHILE EXISTS (SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) LOOP
        UPDATE promoter_id_sequence 
        SET last_promoter_number = last_promoter_number + 1,
            updated_at = NOW()
        RETURNING last_promoter_number INTO next_number;
        
        new_promoter_id := 'BPVP' || LPAD(next_number::TEXT, 2, '0');
    END LOOP;
    
    RETURN new_promoter_id;
END;
$$;

-- =====================================================
-- 3. CREATE NEW PROMOTER CREATION FUNCTION (PROMOTER ID ONLY)
-- =====================================================

CREATE OR REPLACE FUNCTION create_promoter_with_id_auth(
    p_name VARCHAR(255),
    p_email VARCHAR(255) DEFAULT NULL,
    p_password VARCHAR(255),
    p_phone VARCHAR(20),
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL,
    p_role_level VARCHAR(50) DEFAULT 'Affiliate',
    p_status VARCHAR(20) DEFAULT 'Active'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
    new_promoter_id VARCHAR(20);
    auth_email VARCHAR(255);
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
    
    -- Generate unique promoter ID
    new_promoter_id := generate_next_promoter_id();
    
    -- Generate UUID for new user
    new_user_id := gen_random_uuid();
    
    -- Create unique placeholder email for Supabase auth
    -- This ensures Supabase auth works while allowing duplicate real emails
    auth_email := 'promoter+' || new_promoter_id || '@app.local';
    
    -- Create auth user with placeholder email
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
            NOW(), -- Auto-confirm
            NOW(),
            NOW(),
            'authenticated',
            'authenticated'
        );
        
        RAISE NOTICE '✅ Created Supabase auth user with email: %', auth_email;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to create authentication record: ' || SQLERRM
        );
    END;
    
    -- Create profile record with real email (can be duplicate) and auth linkage
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
        profile_auth_id, -- Link to Supabase auth user
        created_at,
        updated_at
    ) VALUES (
        new_user_id,
        p_email, -- Real email (can be duplicate or NULL)
        TRIM(p_name),
        'promoter',
        TRIM(p_phone),
        p_address,
        new_promoter_id,
        p_role_level,
        p_status,
        p_parent_promoter_id,
        new_user_id, -- Same as ID for direct linkage
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
    EXCEPTION WHEN OTHERS THEN
        -- Continue if promoters table doesn't exist
        NULL;
    END;
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', new_user_id,
        'auth_email', auth_email,
        'display_email', p_email,
        'name', p_name,
        'phone', p_phone,
        'role_level', p_role_level,
        'status', p_status,
        'message', 'Promoter created successfully. Login with Promoter ID: ' || new_promoter_id
    );
    
EXCEPTION WHEN OTHERS THEN
    -- Return error response
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;

-- =====================================================
-- 4. CREATE PROMOTER ID AUTHENTICATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION authenticate_promoter_by_id_only(
    p_promoter_id VARCHAR(20),
    p_password VARCHAR(255)
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    promoter_record RECORD;
    auth_user_record RECORD;
    auth_email VARCHAR(255);
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
    
    -- Find the promoter by promoter_id
    SELECT * INTO promoter_record
    FROM profiles 
    WHERE promoter_id = p_promoter_id 
    AND role = 'promoter'
    AND status = 'Active';
    
    -- Check if promoter exists
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid Promoter ID or password'
        );
    END IF;
    
    -- Get the corresponding auth user record using profile_auth_id
    SELECT * INTO auth_user_record
    FROM auth.users 
    WHERE id = promoter_record.profile_auth_id;
    
    -- Check if auth user exists
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Authentication record not found. Please contact support.'
        );
    END IF;
    
    -- Verify password using crypt function
    IF NOT (auth_user_record.encrypted_password = crypt(p_password, auth_user_record.encrypted_password)) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid Promoter ID or password'
        );
    END IF;
    
    -- Return successful authentication with user data
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
        'auth_email', auth_user_record.email,
        'message', 'Authentication successful'
    );
        
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id_only(VARCHAR, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_promoter_by_id_only(VARCHAR, VARCHAR) TO anon;

-- =====================================================
-- 5. ADD PROFILE_AUTH_ID COLUMN IF NOT EXISTS
-- =====================================================

DO $$
BEGIN
    -- Add profile_auth_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'profile_auth_id'
    ) THEN
        ALTER TABLE profiles ADD COLUMN profile_auth_id UUID REFERENCES auth.users(id);
        CREATE INDEX IF NOT EXISTS idx_profiles_profile_auth_id ON profiles(profile_auth_id);
        RAISE NOTICE '✅ Added profile_auth_id column to profiles table';
    ELSE
        RAISE NOTICE '⚠️  profile_auth_id column already exists';
    END IF;
END $$;

-- =====================================================
-- 6. CLEAN UP BROKEN PROMOTER DATA
-- =====================================================

DO $$
DECLARE
    broken_count INTEGER;
    cleaned_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== STEP 6: CLEANING UP BROKEN PROMOTER DATA ===';
    
    -- Count broken promoters (AUTH_MISSING)
    SELECT COUNT(*) INTO broken_count
    FROM profiles p
    LEFT JOIN auth.users au ON p.id = au.id
    WHERE p.role = 'promoter' 
    AND au.id IS NULL;
    
    RAISE NOTICE 'Found % broken promoters (AUTH_MISSING)', broken_count;
    
    IF broken_count > 0 THEN
        -- Delete broken promoter profiles that have no auth users
        DELETE FROM profiles 
        WHERE role = 'promoter' 
        AND id NOT IN (SELECT id FROM auth.users);
        
        GET DIAGNOSTICS cleaned_count = ROW_COUNT;
        RAISE NOTICE '✅ Cleaned up % broken promoter profiles', cleaned_count;
    END IF;
    
    -- Update existing promoters to link profile_auth_id properly
    UPDATE profiles 
    SET profile_auth_id = id 
    WHERE role = 'promoter' 
    AND profile_auth_id IS NULL 
    AND id IN (SELECT id FROM auth.users);
    
    GET DIAGNOSTICS cleaned_count = ROW_COUNT;
    RAISE NOTICE '✅ Updated % promoter profiles with proper auth linkage', cleaned_count;
    
END $$;

-- =====================================================
-- 7. MIGRATE EXISTING PROMOTERS TO NEW SYSTEM
-- =====================================================

DO $$
DECLARE
    promoter_record RECORD;
    new_auth_email VARCHAR(255);
    migration_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== STEP 7: MIGRATING EXISTING PROMOTERS ===';
    
    -- Migrate promoters that have real emails to placeholder auth emails
    FOR promoter_record IN 
        SELECT p.id, p.promoter_id, p.email, p.name
        FROM profiles p
        JOIN auth.users au ON p.id = au.id
        WHERE p.role = 'promoter'
        AND p.promoter_id IS NOT NULL
        AND au.email = p.email -- Real email used in auth
        AND NOT au.email LIKE '%@app.local' -- Not already migrated
    LOOP
        -- Create new placeholder auth email
        new_auth_email := 'promoter+' || promoter_record.promoter_id || '@app.local';
        
        -- Update auth user email to placeholder
        UPDATE auth.users 
        SET email = new_auth_email,
            updated_at = NOW()
        WHERE id = promoter_record.id;
        
        -- Ensure profile_auth_id is set
        UPDATE profiles 
        SET profile_auth_id = promoter_record.id,
            updated_at = NOW()
        WHERE id = promoter_record.id;
        
        migration_count := migration_count + 1;
        RAISE NOTICE '✅ Migrated promoter % (%) to placeholder auth email', 
            promoter_record.promoter_id, promoter_record.name;
    END LOOP;
    
    RAISE NOTICE '✅ Migrated % existing promoters to new system', migration_count;
END $$;

-- =====================================================
-- 8. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for efficient Promoter ID authentication
CREATE INDEX IF NOT EXISTS idx_profiles_promoter_id_role_status ON profiles(promoter_id, role, status);
CREATE INDEX IF NOT EXISTS idx_profiles_role_status_active ON profiles(role, status) WHERE status = 'Active';

-- =====================================================
-- 9. VERIFICATION AND TESTING
-- =====================================================

DO $$
DECLARE
    total_promoters INTEGER;
    ready_promoters INTEGER;
    test_promoter_id VARCHAR(20);
BEGIN
    RAISE NOTICE '=== STEP 9: SYSTEM VERIFICATION ===';
    
    -- Count total promoters
    SELECT COUNT(*) INTO total_promoters
    FROM profiles 
    WHERE role = 'promoter';
    
    -- Count ready promoters (have auth linkage)
    SELECT COUNT(*) INTO ready_promoters
    FROM profiles p
    JOIN auth.users au ON p.profile_auth_id = au.id
    WHERE p.role = 'promoter' 
    AND p.status = 'Active'
    AND p.promoter_id IS NOT NULL;
    
    RAISE NOTICE 'Total promoters: %', total_promoters;
    RAISE NOTICE 'Ready for Promoter ID login: %', ready_promoters;
    
    -- Get a sample promoter ID for testing
    SELECT promoter_id INTO test_promoter_id
    FROM profiles 
    WHERE role = 'promoter' 
    AND promoter_id IS NOT NULL 
    AND status = 'Active'
    LIMIT 1;
    
    IF test_promoter_id IS NOT NULL THEN
        RAISE NOTICE '';
        RAISE NOTICE '🧪 TEST AUTHENTICATION:';
        RAISE NOTICE 'You can test login with Promoter ID: %', test_promoter_id;
        RAISE NOTICE 'Use the password that was set during promoter creation.';
    END IF;
END $$;

-- =====================================================
-- 10. FINAL STATUS REPORT
-- =====================================================

SELECT 
    '=== PROMOTER AUTHENTICATION SYSTEM STATUS ===' as section;

SELECT 
    COUNT(*) as total_promoters,
    COUNT(CASE WHEN au.id IS NOT NULL AND p.promoter_id IS NOT NULL THEN 1 END) as ready_for_login,
    COUNT(CASE WHEN au.id IS NULL THEN 1 END) as missing_auth,
    COUNT(CASE WHEN p.promoter_id IS NULL THEN 1 END) as missing_promoter_id
FROM profiles p
LEFT JOIN auth.users au ON p.profile_auth_id = au.id
WHERE p.role = 'promoter';

-- Show sample promoters ready for login
SELECT 
    p.promoter_id,
    p.name,
    p.email as display_email,
    p.phone,
    au.email as auth_email,
    CASE 
        WHEN p.promoter_id IS NOT NULL AND au.id IS NOT NULL THEN '✅ READY FOR PROMOTER ID LOGIN'
        WHEN p.promoter_id IS NULL THEN '❌ MISSING PROMOTER ID'
        WHEN au.id IS NULL THEN '❌ MISSING AUTH'
        ELSE '⚠️ NEEDS REVIEW'
    END as status
FROM profiles p
LEFT JOIN auth.users au ON p.profile_auth_id = au.id
WHERE p.role = 'promoter'
ORDER BY 
    CASE 
        WHEN p.promoter_id IS NOT NULL AND au.id IS NOT NULL THEN 1
        ELSE 2
    END,
    p.created_at DESC
LIMIT 10;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '🎉 PROMOTER AUTHENTICATION SYSTEM REVAMP COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ CHANGES IMPLEMENTED:';
    RAISE NOTICE '1. Removed unique constraints on email and phone fields';
    RAISE NOTICE '2. Updated Promoter ID generation to BPVP format';
    RAISE NOTICE '3. Created Promoter ID-only authentication function';
    RAISE NOTICE '4. Migrated existing promoters to placeholder auth emails';
    RAISE NOTICE '5. Cleaned up broken AUTH_MISSING entries';
    RAISE NOTICE '6. Added proper auth linkage with profile_auth_id';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 NEW LOGIN SYSTEM:';
    RAISE NOTICE '• PRIMARY: Promoter ID + Password (e.g., BPVP01)';
    RAISE NOTICE '• Email and phone are metadata only (can duplicate)';
    RAISE NOTICE '• Supabase auth uses unique placeholder emails internally';
    RAISE NOTICE '• Clean, consistent, and scalable authentication';
    RAISE NOTICE '';
    RAISE NOTICE '📱 NEXT STEPS:';
    RAISE NOTICE '1. Update frontend login components';
    RAISE NOTICE '2. Update promoter creation forms';
    RAISE NOTICE '3. Test authentication with existing promoters';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 AVAILABLE FUNCTIONS:';
    RAISE NOTICE '• create_promoter_with_id_auth() - Create new promoters';
    RAISE NOTICE '• authenticate_promoter_by_id_only() - Login authentication';
    RAISE NOTICE '• generate_next_promoter_id() - Generate BPVP IDs';
    RAISE NOTICE '';
    RAISE NOTICE 'System is now ready for Promoter ID-centric authentication!';
    RAISE NOTICE '=======================================================';
END $$;
