-- =====================================================
-- UNIFIED PROMOTER SYSTEM - UPDATE PROMOTER FUNCTION
-- =====================================================
-- This file contains the promoter update function

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

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Update promoter profile function created successfully!';
END $$;
