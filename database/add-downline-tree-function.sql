-- =====================================================
-- ADD PROMOTER DOWNLINE TREE FUNCTION
-- =====================================================
-- This adds the missing get_promoter_downline_tree function

CREATE OR REPLACE FUNCTION get_promoter_downline_tree(p_promoter_code VARCHAR(20))
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    promoter_uuid UUID;
    result JSON;
BEGIN
    -- Get promoter ID from code
    SELECT p.id INTO promoter_uuid 
    FROM profiles p 
    WHERE p.promoter_id = p_promoter_code AND p.role = 'promoter';
    
    IF promoter_uuid IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Promoter not found: ' || p_promoter_code
        );
    END IF;
    
    -- Get complete downline tree
    WITH RECURSIVE downline_tree AS (
        -- Base case: direct children
        SELECT 
            p.id,
            p.promoter_id as code,
            p.name,
            p.email,
            p.phone,
            p.role_level,
            p.status,
            p.created_at,
            1 as level,
            ARRAY[p.promoter_id]::VARCHAR[] as path
        FROM profiles p
        WHERE p.parent_promoter_id = promoter_uuid 
        AND p.role = 'promoter'
        
        UNION ALL
        
        -- Recursive case: children of children
        SELECT 
            p.id,
            p.promoter_id as code,
            p.name,
            p.email,
            p.phone,
            p.role_level,
            p.status,
            p.created_at,
            dt.level + 1,
            dt.path || p.promoter_id::VARCHAR
        FROM profiles p
        JOIN downline_tree dt ON p.parent_promoter_id = dt.id
        WHERE p.role = 'promoter'
        AND NOT (p.promoter_id = ANY(dt.path)) -- Prevent cycles
        AND dt.level < 20 -- Limit depth for performance
    )
    SELECT json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'downline_tree', json_agg(
            json_build_object(
                'code', code,
                'name', name,
                'email', email,
                'phone', phone,
                'role_level', role_level,
                'status', status,
                'level', level,
                'path', path,
                'created_at', created_at
            ) ORDER BY level, code
        ),
        'total_downline', COUNT(*)
    ) INTO result
    FROM downline_tree;
    
    RETURN COALESCE(result, json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'downline_tree', '[]'::json,
        'total_downline', 0,
        'message', 'No downline found'
    ));
END;
$$;

-- Also create a function to get direct children only (simpler version)
CREATE OR REPLACE FUNCTION get_promoter_direct_children(p_promoter_code VARCHAR(20))
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    promoter_uuid UUID;
    result JSON;
BEGIN
    -- Get promoter ID from code
    SELECT p.id INTO promoter_uuid 
    FROM profiles p 
    WHERE p.promoter_id = p_promoter_code AND p.role = 'promoter';
    
    IF promoter_uuid IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Promoter not found: ' || p_promoter_code
        );
    END IF;
    
    -- Get direct children only
    SELECT json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'direct_children', json_agg(
            json_build_object(
                'code', p.promoter_id,
                'name', p.name,
                'email', p.email,
                'phone', p.phone,
                'role_level', p.role_level,
                'status', p.status,
                'created_at', p.created_at
            ) ORDER BY p.created_at
        ),
        'total_children', COUNT(*)
    ) INTO result
    FROM profiles p
    WHERE p.parent_promoter_id = promoter_uuid 
    AND p.role = 'promoter';
    
    RETURN COALESCE(result, json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'direct_children', '[]'::json,
        'total_children', 0,
        'message', 'No direct children found'
    ));
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_promoter_downline_tree(VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION get_promoter_direct_children(VARCHAR) TO authenticated;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'DOWNLINE TREE FUNCTIONS ADDED SUCCESSFULLY';
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'New Functions Available:';
    RAISE NOTICE '  ✅ get_promoter_downline_tree(promoter_code)';
    RAISE NOTICE '  ✅ get_promoter_direct_children(promoter_code)';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage Examples:';
    RAISE NOTICE '  SELECT get_promoter_downline_tree(''BPVP01'');';
    RAISE NOTICE '  SELECT get_promoter_direct_children(''BPVP01'');';
    RAISE NOTICE '=================================================';
END $$;
