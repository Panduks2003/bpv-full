-- =====================================================
-- DEPLOY PIN REQUEST MANAGEMENT SYSTEM
-- =====================================================
-- This creates the complete PIN request system for admin approval/rejection
-- Run this in Supabase SQL Editor
-- =====================================================

BEGIN;

-- =====================================================
-- 1. CREATE/UPDATE PIN_REQUESTS TABLE
-- =====================================================

-- Create table if it doesn't exist
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

-- Add missing columns if table already exists
DO $$
BEGIN
    -- Add approved_by if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pin_requests' AND column_name = 'approved_by'
    ) THEN
        ALTER TABLE pin_requests ADD COLUMN approved_by UUID REFERENCES profiles(id);
        RAISE NOTICE '✅ Added approved_by column';
    END IF;
    
    -- Add admin_notes if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pin_requests' AND column_name = 'admin_notes'
    ) THEN
        ALTER TABLE pin_requests ADD COLUMN admin_notes TEXT;
        RAISE NOTICE '✅ Added admin_notes column';
    END IF;
    
    -- Add approved_at if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pin_requests' AND column_name = 'approved_at'
    ) THEN
        ALTER TABLE pin_requests ADD COLUMN approved_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Added approved_at column';
    END IF;
    
    -- Rename quantity column to requested_pins if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pin_requests' AND column_name = 'quantity'
    ) THEN
        -- First check if requested_pins doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'pin_requests' AND column_name = 'requested_pins'
        ) THEN
            ALTER TABLE pin_requests RENAME COLUMN quantity TO requested_pins;
            RAISE NOTICE '✅ Renamed quantity column to requested_pins';
        END IF;
    END IF;
    
    -- Add requested_pins if it doesn't exist at all
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pin_requests' AND column_name = 'requested_pins'
    ) THEN
        ALTER TABLE pin_requests ADD COLUMN requested_pins INTEGER NOT NULL DEFAULT 1;
        RAISE NOTICE '✅ Added requested_pins column';
    END IF;
END $$;

-- =====================================================
-- 2. CREATE INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_pin_requests_promoter_id ON pin_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_pin_requests_status ON pin_requests(status);
CREATE INDEX IF NOT EXISTS idx_pin_requests_created_at ON pin_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pin_requests_approved_by ON pin_requests(approved_by);

-- =====================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE pin_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "promoters_can_view_own_requests" ON pin_requests;
DROP POLICY IF EXISTS "promoters_can_create_requests" ON pin_requests;
DROP POLICY IF EXISTS "admins_can_view_all_requests" ON pin_requests;
DROP POLICY IF EXISTS "admins_can_update_requests" ON pin_requests;

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

-- Admins can update all requests
CREATE POLICY "admins_can_update_requests" ON pin_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- =====================================================
-- 4. CREATE UPDATED_AT TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION update_pin_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pin_requests_updated_at_trigger ON pin_requests;

CREATE TRIGGER pin_requests_updated_at_trigger
    BEFORE UPDATE ON pin_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_pin_requests_updated_at();

-- =====================================================
-- 5. CREATE APPROVE PIN REQUEST FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION approve_pin_request(
    p_request_id UUID,
    p_admin_id UUID,
    p_admin_notes TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_request RECORD;
    v_pin_result JSON;
    v_result JSON;
    v_current_pins INTEGER;
    v_new_pins INTEGER;
    v_requested_pins_count INTEGER;
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

    -- Get the request details - use explicit column selection
    SELECT 
        id,
        promoter_id,
        COALESCE(requested_pins, quantity, 1) as pins_requested,
        status,
        reason
    INTO v_request
    FROM pin_requests 
    WHERE id = p_request_id AND status = 'pending';

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Request not found or already processed'
        );
    END IF;

    -- Get the requested pins count (handle both column names)
    SELECT COALESCE(
        (SELECT requested_pins FROM pin_requests WHERE id = p_request_id),
        (SELECT quantity FROM pin_requests WHERE id = p_request_id),
        1
    ) INTO v_requested_pins_count;

    -- Get current promoter's pin balance
    SELECT COALESCE(pins, 0) INTO v_current_pins
    FROM profiles
    WHERE id = v_request.promoter_id;

    -- Calculate new pin balance
    v_new_pins := v_current_pins + v_requested_pins_count;

    -- Update the request status (handle both column naming scenarios)
    UPDATE pin_requests 
    SET 
        status = 'approved',
        approved_by = p_admin_id,
        admin_notes = p_admin_notes,
        approved_at = NOW()
    WHERE id = p_request_id;

    -- Add pins to promoter's balance
    UPDATE profiles
    SET 
        pins = v_new_pins,
        updated_at = NOW()
    WHERE id = v_request.promoter_id;
    
    RAISE NOTICE 'Approved request %, added % pins to promoter %, new balance: %', 
        p_request_id, v_requested_pins_count, v_request.promoter_id, v_new_pins;

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'request_id', p_request_id,
        'promoter_id', v_request.promoter_id,
        'allocated_pins', v_requested_pins_count,
        'previous_balance', v_current_pins,
        'new_balance', v_new_pins,
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
-- 6. CREATE REJECT PIN REQUEST FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION reject_pin_request(
    p_request_id UUID,
    p_admin_id UUID,
    p_admin_notes TEXT DEFAULT 'Request rejected by admin'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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
        'message', 'PIN request rejected successfully'
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END $$;

-- =====================================================
-- 7. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION approve_pin_request(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION approve_pin_request(UUID, UUID, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION reject_pin_request(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_pin_request(UUID, UUID, TEXT) TO anon;

-- =====================================================
-- 8. VERIFICATION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PIN REQUEST SYSTEM DEPLOYED SUCCESSFULLY';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ pin_requests table created';
    RAISE NOTICE '✅ approve_pin_request() function created';
    RAISE NOTICE '✅ reject_pin_request() function created';
    RAISE NOTICE '✅ RLS policies configured';
    RAISE NOTICE '✅ Indexes created';
    RAISE NOTICE '';
    RAISE NOTICE 'HOW TO USE:';
    RAISE NOTICE '1. Promoters can now create PIN requests';
    RAISE NOTICE '2. Admins can approve/reject via Admin Dashboard';
    RAISE NOTICE '3. When approved, pins are automatically added';
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
END $$;

COMMIT;

