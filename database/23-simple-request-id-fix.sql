-- =====================================================
-- SIMPLE WITHDRAWAL REQUEST ID FIX
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

-- 4. Update existing withdrawal requests with request numbers
UPDATE withdrawal_requests 
SET request_number = 'BPV-WITHDRAW' || LPAD(ROW_NUMBER() OVER (ORDER BY created_at)::TEXT, 2, '0')
WHERE request_number IS NULL;

-- 5. Set sequence to correct value
SELECT setval('withdrawal_request_sequence', 
    (SELECT COUNT(*) FROM withdrawal_requests WHERE request_number IS NOT NULL));

-- 6. Create trigger for new requests
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

-- 7. Verify the update
SELECT 
    id,
    request_number,
    amount,
    status,
    created_at
FROM withdrawal_requests
ORDER BY created_at DESC;

-- Success message
SELECT '✅ Request ID system applied! Existing requests now have BPV-WITHDRAW## format.' as result;
