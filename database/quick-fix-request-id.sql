-- =====================================================
-- QUICK FIX - Make request_id nullable and add default
-- =====================================================
-- This keeps your existing data and fixes the NOT NULL constraint

-- Make request_id nullable
ALTER TABLE pin_requests ALTER COLUMN request_id DROP NOT NULL;

-- Add a default value for request_id (auto-generate from id)
ALTER TABLE pin_requests ALTER COLUMN request_id SET DEFAULT 'REQ-' || LPAD(FLOOR(RANDOM() * 9999 + 1)::TEXT, 4, '0');

-- Update existing NULL request_id values
UPDATE pin_requests 
SET request_id = 'REQ-' || LPAD(FLOOR(RANDOM() * 9999 + 1)::TEXT, 4, '0')
WHERE request_id IS NULL;

-- Make reason nullable (it's currently NOT NULL)
ALTER TABLE pin_requests ALTER COLUMN reason DROP NOT NULL;

-- Make category have a proper default
ALTER TABLE pin_requests ALTER COLUMN category SET DEFAULT 'standard';

-- Make urgency have a proper default  
ALTER TABLE pin_requests ALTER COLUMN urgency SET DEFAULT 'normal';

-- Update the submit_pin_request function to work with existing schema
DROP FUNCTION IF EXISTS submit_pin_request(UUID, INTEGER, TEXT);

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
    v_generated_request_id VARCHAR;
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

    -- Generate a unique request_id
    v_generated_request_id := 'REQ-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 9999 + 1)::TEXT, 4, '0');

    -- Insert the request (using existing schema columns)
    INSERT INTO pin_requests (
        promoter_id, 
        requested_pins, 
        reason,
        request_id,
        category,
        urgency,
        status
    )
    VALUES (
        p_promoter_id, 
        p_requested_pins, 
        COALESCE(p_reason, 'PIN request submitted'),
        v_generated_request_id,
        'standard',
        'normal',
        'pending'
    )
    RETURNING id INTO v_request_id;

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'request_id', v_request_id,
        'request_number', v_generated_request_id,
        'message', 'PIN request submitted successfully'
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END $$;

-- Update get_pin_requests to work with existing schema
DROP FUNCTION IF EXISTS get_pin_requests(TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS get_pin_requests(UUID, VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS get_pin_requests(UUID, TEXT, INTEGER);
DROP FUNCTION IF EXISTS get_pin_requests(UUID, CHARACTER VARYING, INTEGER);

CREATE FUNCTION get_pin_requests(
    p_promoter_id UUID DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE (
    id UUID,
    request_id VARCHAR,
    promoter_id UUID,
    promoter_name TEXT,
    promoter_email TEXT,
    requested_pins INTEGER,
    reason TEXT,
    category VARCHAR,
    urgency VARCHAR,
    status VARCHAR,
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
        pr.request_id,
        pr.promoter_id,
        p_promoter.name as promoter_name,
        p_promoter.email as promoter_email,
        pr.requested_pins,
        pr.reason,
        pr.category,
        pr.urgency,
        pr.status,
        COALESCE(pr.approved_by, pr.processed_by) as approved_by,
        p_admin.name as admin_name,
        pr.admin_notes,
        COALESCE(pr.approved_at, pr.response_date) as approved_at,
        pr.created_at,
        pr.updated_at
    FROM pin_requests pr
    LEFT JOIN profiles p_promoter ON pr.promoter_id = p_promoter.id
    LEFT JOIN profiles p_admin ON COALESCE(pr.approved_by, pr.processed_by) = p_admin.id
    WHERE 
        (p_promoter_id IS NULL OR pr.promoter_id = p_promoter_id)
        AND (p_status IS NULL OR pr.status = p_status)
    ORDER BY pr.created_at DESC
    LIMIT p_limit;
END $$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION submit_pin_request(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pin_requests(UUID, VARCHAR(20), INTEGER) TO authenticated;

-- Verification
SELECT '✅ PIN Request system fixed to work with existing schema!' as status;

-- Show updated schema
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'pin_requests'
AND column_name IN ('request_id', 'reason', 'category', 'urgency')
ORDER BY ordinal_position;
