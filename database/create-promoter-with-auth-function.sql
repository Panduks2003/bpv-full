-- =====================================================
-- Create Promoter With Auth Function
-- Purpose: Create a new promoter with authentication
-- =====================================================

-- Create or replace the function with explicit type casts
CREATE OR REPLACE FUNCTION create_promoter_with_auth(
    p_name TEXT,
    p_password TEXT,
    p_phone TEXT,
    p_email TEXT,
    p_address TEXT,
    p_parent_promoter_id TEXT, -- Changed from UUID to TEXT to match the error
    p_role_level TEXT,
    p_status TEXT
) RETURNS UUID AS $$
DECLARE
    v_promoter_id TEXT;
    v_profile_id UUID;
    v_auth_id UUID;
    v_next_number INTEGER;
    v_parent_uuid UUID;
BEGIN
    -- Convert parent_promoter_id from TEXT to UUID if provided
    IF p_parent_promoter_id IS NOT NULL THEN
        SELECT id INTO v_parent_uuid FROM profiles WHERE promoter_id = p_parent_promoter_id;
    ELSE
        v_parent_uuid := NULL;
    END IF;
    
    -- Get the next promoter number from sequence
    SELECT COALESCE(MAX(SUBSTRING(promoter_id, 5)::INTEGER), 0) + 1 
    INTO v_next_number 
    FROM promoters;
    
    -- Format the promoter ID
    v_promoter_id := 'BPVP' || LPAD(v_next_number::TEXT, 2, '0');
    
    -- Create the profile entry
    INSERT INTO profiles (
        name,
        phone,
        email,
        address,
        promoter_id,
        parent_promoter_id,
        role_level,
        status,
        role
    ) VALUES (
        p_name,
        p_phone,
        p_email,
        p_address,
        v_promoter_id,
        v_parent_uuid,
        p_role_level,
        p_status,
        'promoter'
    ) RETURNING id INTO v_profile_id;
    
    -- Create auth entry with hashed password
    INSERT INTO auth (
        email,
        password,
        role
    ) VALUES (
        p_email,
        crypt(p_password, gen_salt('bf')),
        'promoter'
    ) RETURNING id INTO v_auth_id;
    
    -- Link auth to profile
    UPDATE profiles 
    SET auth_id = v_auth_id 
    WHERE id = v_profile_id;
    
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
            v_profile_id,
            v_promoter_id,
            v_parent_uuid,
            LOWER(p_status),
            0.05, -- Default 5% commission
            true,
            true,
            NOW(),
            NOW()
        );
    EXCEPTION WHEN OTHERS THEN
        -- If promoters table doesn't exist, continue without it
        RAISE NOTICE 'Promoters table insert failed (continuing anyway): %', SQLERRM;
    END;
    
    -- Return the profile ID
    RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Example usage:
/*
SELECT create_promoter_with_auth(
    'Kaveri Bedasur',                -- name 
    'password123',                   -- password (temporary) 
    '7676449620',                    -- phone 
    'lfshinobi@gmail.com',           -- email 
    'Gokak',                         -- address (placeholder) 
    'BPVP01',                        -- parent_promoter_id (as TEXT)
    'Affiliate',                     -- role_level 
    'Active'                         -- status 
);
*/