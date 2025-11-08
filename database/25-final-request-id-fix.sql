-- =====================================================
-- FINAL WITHDRAWAL REQUEST ID FIX
-- =====================================================
-- Run this directly in Supabase SQL Editor
-- =====================================================

-- 1. Add request_number column if it doesn't exist
ALTER TABLE withdrawal_requests 
ADD COLUMN IF NOT EXISTS request_number VARCHAR(20) UNIQUE;

-- 2. Create sequence for numbering
CREATE SEQUENCE IF NOT EXISTS withdrawal_request_sequence
    START WITH 1
    INCREMENT BY 1;

-- 3. Function to generate request numbers
CREATE OR REPLACE FUNCTION generate_withdrawal_request_number()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    next_number INTEGER;
    request_number VARCHAR(20);
BEGIN
    SELECT nextval('withdrawal_request_sequence') INTO next_number;
    request_number := 'BPV-WITHDRAW' || LPAD(next_number::TEXT, 2, '0');
    RETURN request_number;
END;
$$;

-- 4. Update existing withdrawal requests with request numbers (FINAL FIXED VERSION)
DO $$
DECLARE
    withdrawal_record RECORD;
    counter INTEGER := 1;
    total_updated INTEGER := 0;
BEGIN
    -- Loop through existing withdrawal requests without request numbers
    FOR withdrawal_record IN 
        SELECT id FROM withdrawal_requests 
        WHERE request_number IS NULL 
        ORDER BY created_at ASC
    LOOP
        -- Update each record with sequential number
        UPDATE withdrawal_requests 
        SET request_number = 'BPV-WITHDRAW' || LPAD(counter::TEXT, 2, '0')
        WHERE id = withdrawal_record.id;
        
        counter := counter + 1;
        total_updated := total_updated + 1;
    END LOOP;
    
    -- Set sequence to correct value (only if we updated records)
    IF total_updated > 0 THEN
        PERFORM setval('withdrawal_request_sequence', total_updated);
        RAISE NOTICE 'Updated % withdrawal requests with sequential numbers', total_updated;
    ELSE
        RAISE NOTICE 'No withdrawal requests found to update';
    END IF;
END $$;

-- 5. Create trigger for new requests
CREATE OR REPLACE FUNCTION set_withdrawal_request_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.request_number IS NULL THEN
        NEW.request_number := generate_withdrawal_request_number();
    END IF;
    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_set_withdrawal_request_number ON withdrawal_requests;

-- Create new trigger
CREATE TRIGGER trigger_set_withdrawal_request_number
    BEFORE INSERT ON withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_withdrawal_request_number();

-- 6. Create index for performance
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_request_number 
ON withdrawal_requests(request_number);

-- 7. Verify the update
SELECT 
    'Updated Withdrawal Requests' as info,
    id,
    request_number,
    amount,
    status,
    created_at
FROM withdrawal_requests
ORDER BY created_at DESC;

-- 8. Show current sequence value
SELECT 
    'Current Sequence Value' as info,
    last_value as current_value,
    'BPV-WITHDRAW' || LPAD((last_value + 1)::TEXT, 2, '0') as next_number
FROM withdrawal_request_sequence;

-- Success message
SELECT '✅ Request ID system applied successfully! All existing requests updated and sequence set correctly.' as result;
