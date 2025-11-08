-- =====================================================
-- GET COMPLETE PROMOTER DOWNLINE FUNCTION
-- Purpose: Retrieve the complete downline hierarchy for a promoter
-- =====================================================

CREATE OR REPLACE FUNCTION get_complete_downline(p_promoter_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Get all promoters in the downline with hierarchy information
    WITH RECURSIVE promoter_tree AS (
        -- Base case: start with the specified promoter
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
            ARRAY[id] as path,
            pins,
            created_at,
            updated_at
        FROM profiles 
        WHERE id = p_promoter_id AND role = 'promoter'
        
        UNION ALL
        
        -- Recursive case: all child promoters in the hierarchy
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
            pt.path || p.id,
            p.pins,
            p.created_at,
            p.updated_at
        FROM profiles p
        JOIN promoter_tree pt ON p.parent_promoter_id = pt.id
        WHERE p.role = 'promoter'
        AND NOT p.id = ANY(pt.path) -- Prevent cycles
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
            'pins', pins,
            'created_at', created_at,
            'updated_at', updated_at
        )
    ) INTO result
    FROM promoter_tree
    WHERE id != p_promoter_id -- Exclude the root promoter
    ORDER BY level, promoter_id;
    
    RETURN COALESCE(result, '[]'::json);
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_complete_downline(UUID) TO authenticated;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Complete downline function created successfully!';
END $$;