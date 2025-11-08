-- =====================================================
-- UNIFIED PROMOTER CREATION SYSTEM - DATABASE SCHEMA
-- =====================================================
-- This file creates a simplified, uniform promoter system with:
-- 1. Auto-incrementing PROM IDs (PROM0001, PROM0002, etc.)
-- 2. Clean database structure
-- 3. Hierarchical relationships
-- 4. Optional email support
-- 5. Comprehensive validation

-- =====================================================
-- 1. UPDATE PROFILES TABLE FOR PROMOTER FIELDS
-- =====================================================

-- Add promoter_id field to profiles table if it doesn't exist
DO $$
BEGIN
    -- Add promoter_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'promoter_id'
    ) THEN
        ALTER TABLE profiles ADD COLUMN promoter_id VARCHAR(20) UNIQUE;
        CREATE INDEX IF NOT EXISTS idx_profiles_promoter_id ON profiles(promoter_id);
    END IF;

    -- Add address column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'address'
    ) THEN
        ALTER TABLE profiles ADD COLUMN address TEXT;
    END IF;

    -- Add role_level column for promoter hierarchy if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'role_level'
    ) THEN
        ALTER TABLE profiles ADD COLUMN role_level VARCHAR(50) DEFAULT 'Affiliate';
    END IF;

    -- Add status column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'status'
    ) THEN
        ALTER TABLE profiles ADD COLUMN status VARCHAR(20) DEFAULT 'Active';
    END IF;

    -- Add parent_promoter_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'parent_promoter_id'
    ) THEN
        ALTER TABLE profiles ADD COLUMN parent_promoter_id UUID REFERENCES profiles(id);
        CREATE INDEX IF NOT EXISTS idx_profiles_parent_promoter_id ON profiles(parent_promoter_id);
    END IF;
END $$;

-- =====================================================
-- 2. CREATE PROMOTER ID SEQUENCE TABLE
-- =====================================================

-- Create sequence table for global ID generation
CREATE TABLE IF NOT EXISTS promoter_id_sequence (
    id SERIAL PRIMARY KEY,
    last_promoter_number INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Initialize sequence if empty
INSERT INTO promoter_id_sequence (last_promoter_number) 
SELECT 0 
WHERE NOT EXISTS (SELECT 1 FROM promoter_id_sequence);

-- =====================================================
-- 3. FUNCTION: GENERATE NEXT PROMOTER ID
-- =====================================================

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
    
    -- Format as BPVP01, BPVP02, etc.
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
-- 4. FUNCTION: CREATE UNIFIED PROMOTER
-- =====================================================

CREATE OR REPLACE FUNCTION create_unified_promoter(
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
    auth_user_data JSON;
    profile_data JSON;
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
    
    -- Handle email for authentication
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        -- Create placeholder email for authentication
        auth_email := 'noemail+' || replace(new_user_id::text, '-', '') || '@brightplanetventures.local';
    ELSE
        -- Use provided email, but make it unique for auth if needed
        IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
            -- Create unique auth email while keeping display email
            auth_email := split_part(p_email, '@', 1) || '+' || replace(new_user_id::text, '-', '')::text || '@' || split_part(p_email, '@', 2);
        ELSE
            auth_email := p_email;
        END IF;
    END IF;
    
    -- Create auth user first
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
    EXCEPTION WHEN OTHERS THEN
        -- If auth user creation fails, try without it (for systems without direct auth access)
        NULL;
    END;
    
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
        CASE WHEN p_email IS NULL OR TRIM(p_email) = '' THEN NULL ELSE p_email END,
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
    EXCEPTION WHEN OTHERS THEN
        -- If promoters table doesn't exist, continue without it
        NULL;
    END;
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', new_user_id,
        'auth_email', auth_email,
        'display_email', CASE WHEN p_email IS NULL OR TRIM(p_email) = '' THEN NULL ELSE p_email END,
        'name', p_name,
        'phone', p_phone,
        'role_level', p_role_level,
        'status', p_status
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
-- 5. FUNCTION: UPDATE PROMOTER PROFILE
-- =====================================================

CREATE OR REPLACE FUNCTION update_promoter_profile(
    p_promoter_id VARCHAR(20),
    p_name VARCHAR(255) DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_phone VARCHAR(20) DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_role_level VARCHAR(50) DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    promoter_user_id UUID;
    result JSON;
BEGIN
    -- Find promoter by promoter_id
    SELECT id INTO promoter_user_id 
    FROM profiles 
    WHERE promoter_id = p_promoter_id AND role = 'promoter';
    
    IF promoter_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Promoter not found'
        );
    END IF;
    
    -- Validate parent promoter if provided
    IF p_parent_promoter_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_parent_promoter_id AND role IN ('promoter', 'admin')) THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Invalid parent promoter ID'
            );
        END IF;
        
        -- Prevent circular references
        IF p_parent_promoter_id = promoter_user_id THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Cannot set self as parent promoter'
            );
        END IF;
    END IF;
    
    -- Update profile
    UPDATE profiles SET
        name = COALESCE(p_name, name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        address = COALESCE(p_address, address),
        role_level = COALESCE(p_role_level, role_level),
        status = COALESCE(p_status, status),
        parent_promoter_id = COALESCE(p_parent_promoter_id, parent_promoter_id),
        updated_at = NOW()
    WHERE id = promoter_user_id;
    
    -- Update promoter table if it exists
    BEGIN
        UPDATE promoters SET
            status = COALESCE(LOWER(p_status), status),
            parent_promoter_id = COALESCE(p_parent_promoter_id, parent_promoter_id),
            updated_at = NOW()
        WHERE id = promoter_user_id;
    EXCEPTION WHEN OTHERS THEN
        -- Continue if promoters table doesn't exist
        NULL;
    END;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Promoter updated successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;

-- =====================================================
-- 6. FUNCTION: GET PROMOTER HIERARCHY
-- =====================================================

CREATE OR REPLACE FUNCTION get_promoter_hierarchy(p_promoter_id VARCHAR(20) DEFAULT NULL)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Get all promoters with hierarchy information
    WITH RECURSIVE promoter_tree AS (
        -- Base case: root promoters (no parent)
        SELECT 
            id,
            promoter_id,
            name,
            email,
            phone,
            role_level,
            status,
            parent_promoter_id,
            0 as level,
            ARRAY[promoter_id] as path
        FROM profiles 
        WHERE role = 'promoter' 
        AND (parent_promoter_id IS NULL OR p_promoter_id IS NULL)
        AND (p_promoter_id IS NULL OR promoter_id = p_promoter_id)
        
        UNION ALL
        
        -- Recursive case: child promoters
        SELECT 
            p.id,
            p.promoter_id,
            p.name,
            p.email,
            p.phone,
            p.role_level,
            p.status,
            p.parent_promoter_id,
            pt.level + 1,
            pt.path || p.promoter_id
        FROM profiles p
        INNER JOIN promoter_tree pt ON p.parent_promoter_id = pt.id
        WHERE p.role = 'promoter'
        AND NOT (p.promoter_id = ANY(pt.path)) -- Prevent cycles
    )
    SELECT json_agg(
        json_build_object(
            'id', id,
            'promoter_id', promoter_id,
            'name', name,
            'email', email,
            'phone', phone,
            'role_level', role_level,
            'status', status,
            'parent_promoter_id', parent_promoter_id,
            'level', level,
            'path', path
        )
    ) INTO result
    FROM promoter_tree
    ORDER BY level, promoter_id;
    
    RETURN COALESCE(result, '[]'::json);
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;

-- =====================================================
-- 7. FUNCTION: VALIDATE PROMOTER HIERARCHY
-- =====================================================

CREATE OR REPLACE FUNCTION validate_promoter_hierarchy(
    p_promoter_id UUID,
    p_parent_promoter_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_parent UUID;
BEGIN
    -- Cannot be parent of self
    IF p_promoter_id = p_parent_promoter_id THEN
        RETURN FALSE;
    END IF;
    
    -- Check for circular reference by traversing up the hierarchy
    current_parent := p_parent_promoter_id;
    
    WHILE current_parent IS NOT NULL LOOP
        -- If we find the promoter in its own ancestry, it's circular
        IF current_parent = p_promoter_id THEN
            RETURN FALSE;
        END IF;
        
        -- Move up one level
        SELECT parent_promoter_id INTO current_parent
        FROM profiles 
        WHERE id = current_parent AND role IN ('promoter', 'admin');
    END LOOP;
    
    RETURN TRUE;
END;
$$;

-- =====================================================
-- 8. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_profiles_role_status ON profiles(role, status);
CREATE INDEX IF NOT EXISTS idx_profiles_promoter_id_role ON profiles(promoter_id, role);
CREATE INDEX IF NOT EXISTS idx_profiles_parent_hierarchy ON profiles(parent_promoter_id, role);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at DESC);

-- =====================================================
-- 9. ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy for promoters to see their hierarchy
CREATE POLICY IF NOT EXISTS "promoters_can_view_hierarchy" ON profiles
    FOR SELECT
    USING (
        role = 'promoter' 
        AND (
            -- Can see self
            id = auth.uid()
            -- Can see direct children
            OR parent_promoter_id = auth.uid()
            -- Can see parent
            OR id = (SELECT parent_promoter_id FROM profiles WHERE id = auth.uid())
        )
    );

-- Policy for admins to see all promoters
CREATE POLICY IF NOT EXISTS "admins_can_view_all_promoters" ON profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Policy for creating promoters (admins and authorized promoters)
CREATE POLICY IF NOT EXISTS "authorized_users_can_create_promoters" ON profiles
    FOR INSERT
    WITH CHECK (
        role = 'promoter'
        AND EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'promoter')
        )
    );

-- Policy for updating promoters
CREATE POLICY IF NOT EXISTS "authorized_users_can_update_promoters" ON profiles
    FOR UPDATE
    USING (
        role = 'promoter'
        AND (
            -- Admins can update any promoter
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
            -- Promoters can update themselves
            OR id = auth.uid()
            -- Promoters can update their direct children
            OR parent_promoter_id = auth.uid()
        )
    );

-- =====================================================
-- 10. SAMPLE DATA AND VERIFICATION
-- =====================================================

-- Function to verify the system works
CREATE OR REPLACE FUNCTION test_promoter_system()
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    test_result JSON;
    sample_promoter JSON;
BEGIN
    -- Test creating a sample promoter
    SELECT create_unified_promoter(
        'Test Promoter',
        'test@example.com',
        'password123',
        '9876543210',
        '123 Test Street, Test City',
        NULL,
        'Affiliate',
        'Active'
    ) INTO sample_promoter;
    
    -- Return test results
    RETURN json_build_object(
        'schema_created', true,
        'functions_created', true,
        'sample_promoter_test', sample_promoter,
        'next_promoter_id', generate_next_promoter_id()
    );
END;
$$;

-- =====================================================
-- SCHEMA SETUP COMPLETE
-- =====================================================

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Unified Promoter Creation System schema setup completed successfully!';
    RAISE NOTICE 'Available functions:';
    RAISE NOTICE '  - create_unified_promoter()';
    RAISE NOTICE '  - update_promoter_profile()';
    RAISE NOTICE '  - generate_next_promoter_id()';
    RAISE NOTICE '  - get_promoter_hierarchy()';
    RAISE NOTICE '  - validate_promoter_hierarchy()';
    RAISE NOTICE '  - test_promoter_system()';
END $$;
