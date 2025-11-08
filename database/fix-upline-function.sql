-- =====================================================
-- FIX: PROMOTER UPLINE CHAIN FUNCTION
-- =====================================================
-- This fixes the column ambiguity error in get_promoter_upline_chain

-- Drop and recreate the function with proper table aliases
DROP FUNCTION IF EXISTS get_promoter_upline_chain(VARCHAR);

-- Function to get promoter upline chain (FIXED)
CREATE OR REPLACE FUNCTION get_promoter_upline_chain(p_promoter_code VARCHAR(20))
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    promoter_uuid UUID;
    result JSON;
BEGIN
    -- Get promoter ID from code (using table alias to avoid ambiguity)
    SELECT p.id INTO promoter_uuid 
    FROM profiles p 
    WHERE p.promoter_id = p_promoter_code AND p.role = 'promoter';
    
    IF promoter_uuid IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Promoter not found: ' || p_promoter_code
        );
    END IF;
    
    -- Get complete upline chain
    WITH upline_chain AS (
        SELECT 
            h.level,
            h.relationship_type,
            h.ancestor_code,
            h.path_to_root,
            p.name as ancestor_name,
            p.email as ancestor_email,
            p.phone as ancestor_phone,
            p.role_level,
            p.status,
            p.created_at as ancestor_created_at
        FROM promoter_hierarchy h
        JOIN profiles p ON h.ancestor_id = p.id
        WHERE h.promoter_id = promoter_uuid
        ORDER BY h.level ASC
    )
    SELECT json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'upline_chain', json_agg(
            json_build_object(
                'level', level,
                'relationship_type', relationship_type,
                'ancestor_code', ancestor_code,
                'ancestor_name', ancestor_name,
                'ancestor_email', ancestor_email,
                'ancestor_phone', ancestor_phone,
                'role_level', role_level,
                'status', status,
                'created_at', ancestor_created_at,
                'path_to_root', path_to_root
            ) ORDER BY level
        ),
        'total_levels', COUNT(*)
    ) INTO result
    FROM upline_chain;
    
    RETURN COALESCE(result, json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'upline_chain', '[]'::json,
        'total_levels', 0,
        'message', 'No upline found - this is a root promoter'
    ));
END;
$$;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Fixed get_promoter_upline_chain function - column ambiguity resolved';
END $$;
