-- =====================================================
-- UNIFIED PROMOTER SYSTEM - HIERARCHY FUNCTIONS
-- =====================================================
-- This file contains hierarchy management functions

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

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Hierarchy functions created successfully!';
END $$;
