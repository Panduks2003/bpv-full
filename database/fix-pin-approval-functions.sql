-- =====================================================
-- FIX PIN APPROVAL AND REJECTION FUNCTIONS
-- =====================================================
-- This fixes the approve/reject functions to work with existing schema

-- Drop existing approval/rejection functions
DROP FUNCTION IF EXISTS approve_pin_request(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS reject_pin_request(UUID, UUID, TEXT);

-- Create approve_pin_request function (works with existing schema)
CREATE FUNCTION approve_pin_request(
    p_request_id UUID,
    p_admin_id UUID,
    p_admin_notes TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
    v_pin_result JSON;
    v_result JSON;
BEGIN
    -- Validate admin exists and has correct role
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = p_admin_id AND role = 'admin'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid admin ID or insufficient permissions'
        );
    END IF;

    -- Get the request details
    SELECT * INTO v_request
    FROM pin_requests 
    WHERE id = p_request_id AND status = 'pending';

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Request not found or already processed'
        );
    END IF;

    -- Allocate PINs using the unified PIN transaction system
    SELECT admin_allocate_pins(
        v_request.promoter_id,
        v_request.requested_pins,  -- Use requested_pins, not quantity
        p_admin_id
    ) INTO v_pin_result;

    -- Check if PIN allocation was successful
    IF NOT (v_pin_result->>'success')::boolean THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to allocate PINs: ' || (v_pin_result->>'error')
        );
    END IF;

    -- Update the request status (using existing schema columns)
    UPDATE pin_requests 
    SET 
        status = 'approved',
        approved_by = p_admin_id,
        processed_by = p_admin_id,
        admin_notes = p_admin_notes,
        approved_at = NOW(),
        response_date = NOW()
    WHERE id = p_request_id;

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'request_id', p_request_id,
        'promoter_id', v_request.promoter_id,
        'allocated_pins', v_request.requested_pins,
        'new_balance', (v_pin_result->>'balance_after')::integer,
        'message', 'PIN request approved and PINs allocated successfully'
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END $$;

-- Create reject_pin_request function (works with existing schema)
CREATE FUNCTION reject_pin_request(
    p_request_id UUID,
    p_admin_id UUID,
    p_admin_notes TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request RECORD;
    v_result JSON;
BEGIN
    -- Validate admin exists and has correct role
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = p_admin_id AND role = 'admin'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid admin ID or insufficient permissions'
        );
    END IF;

    -- Get the request details
    SELECT * INTO v_request
    FROM pin_requests 
    WHERE id = p_request_id AND status = 'pending';

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Request not found or already processed'
        );
    END IF;

    -- Update the request status (using existing schema columns)
    UPDATE pin_requests 
    SET 
        status = 'rejected',
        approved_by = p_admin_id,
        processed_by = p_admin_id,
        admin_notes = p_admin_notes,
        approved_at = NOW(),
        response_date = NOW()
    WHERE id = p_request_id;

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'request_id', p_request_id,
        'promoter_id', v_request.promoter_id,
        'message', 'PIN request rejected'
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END $$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION approve_pin_request(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_pin_request(UUID, UUID, TEXT) TO authenticated;

-- Verification
SELECT '✅ PIN approval and rejection functions fixed!' as status;

-- Show all PIN request functions
SELECT 
    proname as function_name,
    pg_get_function_arguments(oid) as arguments
FROM pg_proc 
WHERE proname IN ('submit_pin_request', 'get_pin_requests', 'approve_pin_request', 'reject_pin_request')
ORDER BY proname;
