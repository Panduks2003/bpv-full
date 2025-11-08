-- =====================================================
-- DROP AND RECREATE PIN REQUESTS TABLE
-- =====================================================
-- This completely recreates the pin_requests table with the correct schema

-- Drop the existing table completely
DROP TABLE IF EXISTS pin_requests CASCADE;

-- Create the pin_requests table with correct schema
CREATE TABLE pin_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    requested_pins INTEGER NOT NULL CHECK (requested_pins > 0),
    reason TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    approved_by UUID REFERENCES profiles(id),
    admin_notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_pin_requests_promoter_id ON pin_requests(promoter_id);
CREATE INDEX idx_pin_requests_status ON pin_requests(status);
CREATE INDEX idx_pin_requests_created_at ON pin_requests(created_at DESC);
CREATE INDEX idx_pin_requests_approved_by ON pin_requests(approved_by);

-- Enable Row Level Security
ALTER TABLE pin_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "promoters_can_view_own_requests" ON pin_requests
    FOR SELECT USING (promoter_id = auth.uid());

CREATE POLICY "promoters_can_create_requests" ON pin_requests
    FOR INSERT WITH CHECK (promoter_id = auth.uid());

CREATE POLICY "admins_can_view_all_requests" ON pin_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "admins_can_update_requests" ON pin_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_pin_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER pin_requests_updated_at_trigger
    BEFORE UPDATE ON pin_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_pin_requests_updated_at();

-- Drop existing functions
DROP FUNCTION IF EXISTS get_pin_requests(TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS get_pin_requests(UUID, VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS get_pin_requests(UUID, TEXT, INTEGER);
DROP FUNCTION IF EXISTS get_pin_requests(UUID, CHARACTER VARYING, INTEGER);
DROP FUNCTION IF EXISTS submit_pin_request(UUID, INTEGER, TEXT);

-- Create submit_pin_request function
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

    -- Return success result
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

-- Create get_pin_requests function
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

-- Verification
SELECT 'PIN Requests system completely recreated!' as status;

-- Show the new table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'pin_requests'
ORDER BY ordinal_position;
