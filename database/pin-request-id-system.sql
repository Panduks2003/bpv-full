-- =====================================================
-- PIN REQUEST ID SYSTEM
-- =====================================================
-- Creates a global sequential ID system for PIN requests
-- Format: PIN-REQ01, PIN-REQ02, etc.
-- =====================================================

BEGIN;

-- =====================================================
-- 1. CREATE SEQUENCE FOR PIN REQUEST IDs
-- =====================================================

-- Create sequence for PIN request numbering
CREATE SEQUENCE IF NOT EXISTS pin_request_sequence
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;

-- =====================================================
-- 2. ADD FORMATTED REQUEST ID COLUMN TO PIN_REQUESTS
-- =====================================================

-- Add formatted_request_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pin_requests' 
        AND column_name = 'formatted_request_id'
    ) THEN
        ALTER TABLE pin_requests ADD COLUMN formatted_request_id VARCHAR(20) UNIQUE;
        RAISE NOTICE 'Added formatted_request_id column to pin_requests';
    END IF;
END $$;

-- =====================================================
-- 3. CREATE FUNCTION TO GENERATE REQUEST ID
-- =====================================================

-- First, remove any default values that depend on the function
DO $$
BEGIN
    -- Remove default from request_id column if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pin_requests' 
        AND column_name = 'request_id'
        AND column_default IS NOT NULL
    ) THEN
        ALTER TABLE pin_requests ALTER COLUMN request_id DROP DEFAULT;
        RAISE NOTICE 'Removed default value from request_id column';
    END IF;
END $$;

-- Drop existing function if it exists with different signature
DROP FUNCTION IF EXISTS generate_pin_request_id() CASCADE;

-- Function to generate PIN request ID
CREATE OR REPLACE FUNCTION generate_pin_request_id()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    next_number INTEGER;
    request_id VARCHAR(20);
BEGIN
    -- Get next sequence value
    SELECT nextval('pin_request_sequence') INTO next_number;
    
    -- Format as PIN-REQ01, PIN-REQ02, etc.
    request_id := 'PIN-REQ' || LPAD(next_number::TEXT, 2, '0');
    
    RETURN request_id;
END;
$$;

-- =====================================================
-- 4. CREATE TRIGGER TO AUTO-GENERATE REQUEST IDs
-- =====================================================

-- Drop existing trigger first (before dropping the function it depends on)
DROP TRIGGER IF EXISTS trigger_set_pin_request_id ON pin_requests;

-- Drop existing trigger function if it exists
DROP FUNCTION IF EXISTS set_pin_request_id() CASCADE;

-- Function for trigger
CREATE OR REPLACE FUNCTION set_pin_request_id()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only set formatted_request_id if it's not already set
    IF NEW.formatted_request_id IS NULL THEN
        NEW.formatted_request_id := generate_pin_request_id();
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER trigger_set_pin_request_id
    BEFORE INSERT ON pin_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_pin_request_id();

-- =====================================================
-- 5. UPDATE EXISTING PIN REQUESTS
-- =====================================================

-- Update existing PIN requests that don't have formatted request IDs
DO $$
DECLARE
    pin_request_record RECORD;
    new_request_id VARCHAR(20);
BEGIN
    -- Loop through existing PIN requests without formatted_request_id
    FOR pin_request_record IN 
        SELECT id FROM pin_requests 
        WHERE formatted_request_id IS NULL 
        ORDER BY created_at ASC
    LOOP
        -- Generate request ID for existing record
        SELECT generate_pin_request_id() INTO new_request_id;
        
        -- Update the record
        UPDATE pin_requests 
        SET formatted_request_id = new_request_id 
        WHERE id = pin_request_record.id;
        
        RAISE NOTICE 'Updated PIN request % with ID %', pin_request_record.id, new_request_id;
    END LOOP;
END $$;

-- =====================================================
-- 6. CREATE INDEX FOR PERFORMANCE
-- =====================================================

-- Create index on formatted_request_id for fast lookups
CREATE INDEX IF NOT EXISTS idx_pin_requests_formatted_request_id 
ON pin_requests(formatted_request_id);

-- =====================================================
-- 7. CREATE HELPER FUNCTIONS
-- =====================================================

-- Drop existing helper functions if they exist
DROP FUNCTION IF EXISTS get_pin_request_by_id(VARCHAR(20)) CASCADE;
DROP FUNCTION IF EXISTS get_next_pin_request_id() CASCADE;

-- Function to get PIN request by formatted request ID
CREATE OR REPLACE FUNCTION get_pin_request_by_id(p_request_id VARCHAR(20))
RETURNS TABLE (
    id UUID,
    promoter_id UUID,
    requested_pins INTEGER,
    status VARCHAR(20),
    formatted_request_id VARCHAR(20),
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pr.id,
        pr.promoter_id,
        pr.requested_pins,
        pr.status,
        pr.formatted_request_id,
        pr.reason,
        pr.created_at
    FROM pin_requests pr
    WHERE pr.formatted_request_id = p_request_id;
END;
$$;

-- Function to get next request ID (for preview)
CREATE OR REPLACE FUNCTION get_next_pin_request_id()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    next_number INTEGER;
    request_id VARCHAR(20);
BEGIN
    -- Get current sequence value + 1 without incrementing
    SELECT last_value + 1 FROM pin_request_sequence INTO next_number;
    
    -- Format as PIN-REQ01, PIN-REQ02, etc.
    request_id := 'PIN-REQ' || LPAD(next_number::TEXT, 2, '0');
    
    RETURN request_id;
END;
$$;

-- =====================================================
-- 8. GRANT PERMISSIONS
-- =====================================================

-- Grant permissions for the functions
GRANT EXECUTE ON FUNCTION generate_pin_request_id TO authenticated;
GRANT EXECUTE ON FUNCTION get_pin_request_by_id TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_pin_request_id TO authenticated;

-- Grant usage on sequence
GRANT USAGE ON SEQUENCE pin_request_sequence TO authenticated;

-- =====================================================
-- 9. VERIFICATION
-- =====================================================

-- Show current sequence value
SELECT 
    'Current Sequence Value' as info,
    last_value as current_value,
    'PIN-REQ' || LPAD((last_value + 1)::TEXT, 2, '0') as next_id
FROM pin_request_sequence;

-- Show all PIN requests with their formatted IDs
SELECT 
    'PIN Requests with IDs' as info,
    id,
    formatted_request_id,
    requested_pins,
    status,
    created_at
FROM pin_requests
ORDER BY created_at DESC
LIMIT 10;

-- Success message
SELECT '✅ PIN Request ID system implemented successfully!' as result;

COMMIT;

