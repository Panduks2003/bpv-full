-- =====================================================
-- PIN REQUEST AND ALLOCATION WORKFLOW SYSTEM
-- =====================================================
-- Complete system for promoters to request PINs and admins to approve/reject

BEGIN;

-- =====================================================
-- 1. PIN REQUESTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS pin_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_number SERIAL UNIQUE, -- Human-readable request number (REQ-001, REQ-002, etc.)
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    requested_pins INTEGER NOT NULL CHECK (requested_pins > 0),
    reason TEXT, -- Optional reason provided by promoter
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    approved_by UUID REFERENCES profiles(id), -- Admin who processed the request
    admin_notes TEXT, -- Optional notes from admin
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_pin_requests_promoter_id ON pin_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_pin_requests_status ON pin_requests(status);
CREATE INDEX IF NOT EXISTS idx_pin_requests_created_at ON pin_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pin_requests_approved_by ON pin_requests(approved_by);

-- =====================================================
-- 3. ROW LEVEL SECURITY POLICIES
-- =====================================================

ALTER TABLE pin_requests ENABLE ROW LEVEL SECURITY;

-- Promoters can view their own requests
CREATE POLICY "promoters_can_view_own_requests" ON pin_requests
    FOR SELECT USING (promoter_id = auth.uid());

-- Promoters can create their own requests
CREATE POLICY "promoters_can_create_requests" ON pin_requests
    FOR INSERT WITH CHECK (promoter_id = auth.uid());

-- Admins can view all requests
CREATE POLICY "admins_can_view_all_requests" ON pin_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Admins can update all requests (for approval/rejection)
CREATE POLICY "admins_can_update_requests" ON pin_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- =====================================================
-- 4. TRIGGER FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_pin_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER pin_requests_updated_at_trigger
    BEFORE UPDATE ON pin_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_pin_requests_updated_at();

-- =====================================================
-- 5. PIN REQUEST SUBMISSION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION submit_pin_request(
    p_promoter_id UUID,
    p_requested_pins INTEGER,
    p_reason TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request_id UUID;
    v_request_number INTEGER;
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

    -- Check for existing pending requests (optional constraint)
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
    RETURNING id, request_number INTO v_request_id, v_request_number;

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'request_id', v_request_id,
        'request_number', v_request_number,
        'message', 'PIN request submitted successfully'
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END $$;

-- =====================================================
-- 6. PIN REQUEST APPROVAL FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION approve_pin_request(
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
        v_request.requested_pins,
        p_admin_id
    ) INTO v_pin_result;

    -- Check if PIN allocation was successful
    IF NOT (v_pin_result->>'success')::boolean THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to allocate PINs: ' || (v_pin_result->>'error')
        );
    END IF;

    -- Update the request status
    UPDATE pin_requests 
    SET 
        status = 'approved',
        approved_by = p_admin_id,
        admin_notes = p_admin_notes,
        approved_at = NOW()
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

-- =====================================================
-- 7. PIN REQUEST REJECTION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION reject_pin_request(
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

    -- Update the request status
    UPDATE pin_requests 
    SET 
        status = 'rejected',
        approved_by = p_admin_id,
        admin_notes = p_admin_notes,
        approved_at = NOW()
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

-- =====================================================
-- 8. GET PIN REQUESTS FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION get_pin_requests(
    p_promoter_id UUID DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE (
    id UUID,
    request_number INTEGER,
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
        pr.request_number,
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

-- =====================================================
-- 9. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION submit_pin_request(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION approve_pin_request(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_pin_request(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pin_requests(UUID, VARCHAR(20), INTEGER) TO authenticated;

COMMIT;

-- =====================================================
-- 10. VERIFICATION QUERIES
-- =====================================================

-- Verify table creation
SELECT 'pin_requests' as table_name, 
       CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pin_requests') 
            THEN 'CREATED' ELSE 'MISSING' END as status;

-- Verify functions
SELECT 'PIN_REQUEST_FUNCTIONS' as component, COUNT(*) as count
FROM pg_proc 
WHERE proname IN (
    'submit_pin_request',
    'approve_pin_request', 
    'reject_pin_request',
    'get_pin_requests'
);

-- Show sample data structure
SELECT 'SAMPLE_STRUCTURE' as info, 
       column_name, 
       data_type, 
       is_nullable
FROM information_schema.columns 
WHERE table_name = 'pin_requests'
ORDER BY ordinal_position;

RAISE NOTICE 'PIN Request and Allocation Workflow System installation completed successfully!';
