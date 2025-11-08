-- =====================================================
-- CREATE GET_PIN_REQUESTS FUNCTION
-- =====================================================
-- This creates the missing RPC function to get PIN requests
-- Run this in Supabase SQL Editor to eliminate 400 errors
-- =====================================================

-- Drop function if it exists
DROP FUNCTION IF EXISTS get_pin_requests(UUID, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_pin_requests(TEXT, TEXT, INTEGER) CASCADE;

-- Create function to get PIN requests with simpler signature
CREATE OR REPLACE FUNCTION get_pin_requests(
    p_promoter_id TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    promoter_id UUID,
    requested_pins INTEGER,
    formatted_request_id VARCHAR(20),
    reason TEXT,
    status VARCHAR(20),
    approved_by UUID,
    admin_notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    promoter_name TEXT,
    promoter_email TEXT,
    promoter_promoter_id VARCHAR(20)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_promoter_uuid UUID;
BEGIN
    -- Convert text to UUID if provided
    IF p_promoter_id IS NOT NULL AND p_promoter_id != '' THEN
        v_promoter_uuid := p_promoter_id::UUID;
    END IF;
    
    RETURN QUERY
    SELECT 
        pr.id,
        pr.promoter_id,
        COALESCE(pr.requested_pins, pr.quantity, 0)::INTEGER as requested_pins,
        pr.formatted_request_id,
        pr.reason,
        pr.status,
        pr.approved_by,
        pr.admin_notes,
        pr.approved_at,
        pr.created_at,
        pr.updated_at,
        COALESCE(p.name, 'Unknown')::TEXT as promoter_name,
        COALESCE(p.email, 'Unknown')::TEXT as promoter_email,
        COALESCE(p.promoter_id, 'N/A')::VARCHAR(20) as promoter_promoter_id
    FROM pin_requests pr
    LEFT JOIN profiles p ON pr.promoter_id = p.id
    WHERE 
        (v_promoter_uuid IS NULL OR pr.promoter_id = v_promoter_uuid)
        AND (p_status IS NULL OR pr.status = p_status)
    ORDER BY pr.created_at DESC
    LIMIT p_limit;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_pin_requests(TEXT, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pin_requests(TEXT, TEXT, INTEGER) TO anon;

-- Success message
SELECT '✅ get_pin_requests function created successfully!' as result;
