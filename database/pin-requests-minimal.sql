-- =====================================================
-- MINIMAL PIN REQUESTS SETUP (NO SYNTAX ERRORS)
-- =====================================================

-- Create the pin_requests table
CREATE TABLE IF NOT EXISTS pin_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_number SERIAL UNIQUE,
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pin_requests_promoter_id ON pin_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_pin_requests_status ON pin_requests(status);
CREATE INDEX IF NOT EXISTS idx_pin_requests_created_at ON pin_requests(created_at DESC);

-- Enable RLS
ALTER TABLE pin_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (ignore errors)
DROP POLICY IF EXISTS "promoters_can_view_own_requests" ON pin_requests;
DROP POLICY IF EXISTS "promoters_can_create_requests" ON pin_requests;
DROP POLICY IF EXISTS "admins_can_view_all_requests" ON pin_requests;
DROP POLICY IF EXISTS "admins_can_update_requests" ON pin_requests;

-- Create policies
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
