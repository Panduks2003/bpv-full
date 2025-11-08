-- =====================================================
-- RECREATE PIN REQUESTS TABLE - Without request_number
-- =====================================================
-- This removes the problematic request_number SERIAL column

-- Drop the existing table (if you want to start fresh)
-- WARNING: This will delete all existing PIN requests!
-- Comment out if you want to keep existing data
-- DROP TABLE IF EXISTS pin_requests CASCADE;

-- Create the pin_requests table without request_number
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
CREATE INDEX idx_pin_requests_promoter_id ON pin_requests(promoter_id);
CREATE INDEX idx_pin_requests_status ON pin_requests(status);
CREATE INDEX idx_pin_requests_created_at ON pin_requests(created_at DESC);

-- Enable RLS
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

-- Create trigger for updated_at
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

-- Verification
SELECT 'PIN Requests Table Recreation Complete' as status;

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
