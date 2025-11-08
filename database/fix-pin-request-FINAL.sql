-- =====================================================
-- FINAL FIX - Drop ALL versions of get_pin_requests
-- =====================================================
-- This removes all duplicate function signatures

-- Drop ALL versions of get_pin_requests (both TEXT and UUID versions)
DROP FUNCTION IF EXISTS get_pin_requests(TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS get_pin_requests(UUID, VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS get_pin_requests(UUID, TEXT, INTEGER);
DROP FUNCTION IF EXISTS get_pin_requests(UUID, CHARACTER VARYING, INTEGER);

-- Drop submit_pin_request to be safe
DROP FUNCTION IF EXISTS submit_pin_request(UUID, INTEGER, TEXT);

-- Recreate submit_pin_request function (clean version)
CREATE FUNCTION submit_pin_request(
    p_promoter_id UUID,
    p_requested_pins INTEGER,
    p_reason TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request_id UUID;
    v_pending_count INTEGER;
    v_result JSON;
BEGIN
    -- Validate promoter exists and has correct role
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = p_promoter_id AND role = 'promoter'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid promoter ID or role'
        );
    END IF;

    -- Check for existing pending requests
    SELECT COUNT(*) INTO v_pending_count
    FROM pin_requests 
    WHERE promoter_id = p_promoter_id AND status = 'pending';

    IF v_pending_count > 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'You already have a pending PIN request. Please wait for admin approval.'
        );
    END IF;

    -- Validate requested pins
    IF p_requested_pins <= 0 OR p_requested_pins > 1000 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Requested PINs must be between 1 and 1000'
        );
    END IF;

    -- Insert the request
    INSERT INTO pin_requests (promoter_id, requested_pins, reason)
    VALUES (p_promoter_id, p_requested_pins, p_reason)
    RETURNING id INTO v_request_id;

    -- Return success result (without request_number)
    v_result := json_build_object(
        'success', true,
        'request_id', v_request_id,
        'message', 'PIN request submitted successfully'
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END $$;

-- Recreate get_pin_requests function (clean version, UUID parameters)
CREATE FUNCTION get_pin_requests(
    p_promoter_id UUID DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE (
    id UUID,
    promoter_id UUID,
    promoter_name TEXT,
    promoter_email TEXT,
    requested_pins INTEGER,
    reason TEXT,
    status VARCHAR(20),
    approved_by UUID,
    admin_name TEXT,
    admin_notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pr.id,
        pr.promoter_id,
        p_promoter.name as promoter_name,
        p_promoter.email as promoter_email,
        pr.requested_pins,
        pr.reason,
        pr.status,
        pr.approved_by,
        p_admin.name as admin_name,
        pr.admin_notes,
        pr.approved_at,
        pr.created_at,
        pr.updated_at
    FROM pin_requests pr
    LEFT JOIN profiles p_promoter ON pr.promoter_id = p_promoter.id
    LEFT JOIN profiles p_admin ON pr.approved_by = p_admin.id
    WHERE 
        (p_promoter_id IS NULL OR pr.promoter_id = p_promoter_id)
        AND (p_status IS NULL OR pr.status = p_status)
    ORDER BY pr.created_at DESC
    LIMIT p_limit;
END $$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION submit_pin_request(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pin_requests(UUID, VARCHAR(20), INTEGER) TO authenticated;

-- Verification - should show only ONE version of each function
SELECT 
    proname as function_name,
    pg_get_function_arguments(oid) as arguments,
    pronargs as num_arguments
FROM pg_proc 
WHERE proname IN ('submit_pin_request', 'get_pin_requests')
ORDER BY proname, pronargs;

-- Success message
SELECT '✅ All duplicate functions removed and recreated successfully!' as status;
