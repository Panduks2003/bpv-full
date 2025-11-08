-- =====================================================
-- WITHDRAWAL REQUEST ID SYSTEM
-- =====================================================
-- Creates a global sequential ID system for withdrawal requests
-- Format: BPV-WITHDRAW01, BPV-WITHDRAW02, etc.
-- =====================================================

-- =====================================================
-- 1. CREATE SEQUENCE FOR WITHDRAWAL REQUEST IDs
-- =====================================================

-- Create sequence for withdrawal request numbering
CREATE SEQUENCE IF NOT EXISTS withdrawal_request_sequence
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;

-- =====================================================
-- 2. ADD REQUEST_NUMBER COLUMN TO WITHDRAWAL_REQUESTS
-- =====================================================

-- Add request_number column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'request_number'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN request_number VARCHAR(20) UNIQUE;
        RAISE NOTICE 'Added request_number column to withdrawal_requests';
    END IF;
END $$;

-- =====================================================
-- 3. CREATE FUNCTION TO GENERATE REQUEST NUMBER
-- =====================================================

-- Function to generate withdrawal request number
CREATE OR REPLACE FUNCTION generate_withdrawal_request_number()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    next_number INTEGER;
    request_number VARCHAR(20);
BEGIN
    -- Get next sequence value
    SELECT nextval('withdrawal_request_sequence') INTO next_number;
    
    -- Format as BPV-WITHDRAW01, BPV-WITHDRAW02, etc.
    request_number := 'BPV-WITHDRAW' || LPAD(next_number::TEXT, 2, '0');
    
    RETURN request_number;
END;
$$;

-- =====================================================
-- 4. CREATE TRIGGER TO AUTO-GENERATE REQUEST NUMBERS
-- =====================================================

-- Function for trigger
CREATE OR REPLACE FUNCTION set_withdrawal_request_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only set request_number if it's not already set
    IF NEW.request_number IS NULL THEN
        NEW.request_number := generate_withdrawal_request_number();
    END IF;
    
    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_set_withdrawal_request_number ON withdrawal_requests;

-- Create trigger
CREATE TRIGGER trigger_set_withdrawal_request_number
    BEFORE INSERT ON withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_withdrawal_request_number();

-- =====================================================
-- 5. UPDATE EXISTING WITHDRAWAL REQUESTS
-- =====================================================

-- Update existing withdrawal requests that don't have request numbers
DO $$
DECLARE
    withdrawal_record RECORD;
    new_request_number VARCHAR(20);
BEGIN
    -- Loop through existing withdrawal requests without request numbers
    FOR withdrawal_record IN 
        SELECT id FROM withdrawal_requests 
        WHERE request_number IS NULL 
        ORDER BY created_at ASC
    LOOP
        -- Generate request number for existing record
        SELECT generate_withdrawal_request_number() INTO new_request_number;
        
        -- Update the record
        UPDATE withdrawal_requests 
        SET request_number = new_request_number 
        WHERE id = withdrawal_record.id;
        
        RAISE NOTICE 'Updated withdrawal request % with number %', withdrawal_record.id, new_request_number;
    END LOOP;
END $$;

-- =====================================================
-- 6. CREATE INDEX FOR PERFORMANCE
-- =====================================================

-- Create index on request_number for fast lookups
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_request_number 
ON withdrawal_requests(request_number);

-- =====================================================
-- 7. CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to get withdrawal request by request number
CREATE OR REPLACE FUNCTION get_withdrawal_by_request_number(p_request_number VARCHAR(20))
RETURNS TABLE (
    id UUID,
    promoter_id UUID,
    amount DECIMAL(10,2),
    status VARCHAR(20),
    request_number VARCHAR(20),
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        wr.id,
        wr.promoter_id,
        wr.amount,
        wr.status,
        wr.request_number,
        wr.reason,
        wr.created_at
    FROM withdrawal_requests wr
    WHERE wr.request_number = p_request_number;
END;
$$;

-- Function to get next request number (for preview)
CREATE OR REPLACE FUNCTION get_next_withdrawal_request_number()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    next_number INTEGER;
    request_number VARCHAR(20);
BEGIN
    -- Get current sequence value + 1 without incrementing
    SELECT last_value + 1 FROM withdrawal_request_sequence INTO next_number;
    
    -- Format as BPV-WITHDRAW01, BPV-WITHDRAW02, etc.
    request_number := 'BPV-WITHDRAW' || LPAD(next_number::TEXT, 2, '0');
    
    RETURN request_number;
END;
$$;

-- =====================================================
-- 8. GRANT PERMISSIONS
-- =====================================================

-- Grant permissions for the functions
GRANT EXECUTE ON FUNCTION generate_withdrawal_request_number TO authenticated;
GRANT EXECUTE ON FUNCTION get_withdrawal_by_request_number TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_withdrawal_request_number TO authenticated;

-- Grant usage on sequence
GRANT USAGE ON SEQUENCE withdrawal_request_sequence TO authenticated;

-- =====================================================
-- 9. TEST THE SYSTEM
-- =====================================================

-- Test creating a new withdrawal request
DO $$
DECLARE
    test_promoter_id UUID;
    new_request_id UUID;
    generated_number VARCHAR(20);
BEGIN
    -- Get a promoter ID for testing
    SELECT id INTO test_promoter_id
    FROM profiles 
    WHERE role = 'promoter' 
    LIMIT 1;
    
    IF test_promoter_id IS NOT NULL THEN
        -- Insert test withdrawal request
        INSERT INTO withdrawal_requests (
            promoter_id,
            amount,
            status,
            reason
        ) VALUES (
            test_promoter_id,
            750.00,
            'pending',
            'Test withdrawal with auto-generated request number'
        ) RETURNING id, request_number INTO new_request_id, generated_number;
        
        RAISE NOTICE 'Test withdrawal request created: ID=%, Request Number=%', new_request_id, generated_number;
    ELSE
        RAISE NOTICE 'No promoter found for testing';
    END IF;
END $$;

-- =====================================================
-- 10. VERIFICATION
-- =====================================================

-- Show all withdrawal requests with their request numbers
SELECT 
    'Withdrawal Requests with Numbers' as info,
    id,
    request_number,
    amount,
    status,
    created_at
FROM withdrawal_requests
ORDER BY created_at DESC;

-- Show current sequence value
SELECT 
    'Current Sequence Value' as info,
    last_value as current_value,
    'BPV-WITHDRAW' || LPAD((last_value + 1)::TEXT, 2, '0') as next_number
FROM withdrawal_request_sequence;

-- Success message
SELECT '✅ Withdrawal Request ID system implemented successfully!' as result;
