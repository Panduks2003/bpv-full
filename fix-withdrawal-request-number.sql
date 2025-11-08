-- Fix the ambiguous column reference in withdrawal request number generation

-- 1. Drop and recreate the function with proper table alias
DROP FUNCTION IF EXISTS generate_withdrawal_request_number();

CREATE OR REPLACE FUNCTION generate_withdrawal_request_number()
RETURNS TEXT AS $$
DECLARE
    next_number INTEGER;
    request_number TEXT;
BEGIN
    -- Get the next sequence number with proper table alias
    SELECT COALESCE(MAX(CAST(SUBSTRING(wr.request_number FROM 3) AS INTEGER)), 0) + 1
    INTO next_number
    FROM withdrawal_requests wr
    WHERE wr.request_number ~ '^WR[0-9]+$';
    
    -- Format as WR000001, WR000002, etc.
    request_number := 'WR' || LPAD(next_number::TEXT, 6, '0');
    
    RETURN request_number;
END;
$$ LANGUAGE plpgsql;

-- 2. Also ensure the trigger function is correct
DROP FUNCTION IF EXISTS set_withdrawal_request_number();

CREATE OR REPLACE FUNCTION set_withdrawal_request_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.request_number IS NULL OR NEW.request_number = '' THEN
        NEW.request_number := generate_withdrawal_request_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Recreate the trigger
DROP TRIGGER IF EXISTS trigger_set_withdrawal_request_number ON withdrawal_requests;

CREATE TRIGGER trigger_set_withdrawal_request_number
    BEFORE INSERT ON withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_withdrawal_request_number();

-- 4. Test the function
SELECT 
    'FUNCTION_TEST' as test_type,
    generate_withdrawal_request_number() as next_request_number;

SELECT 'WITHDRAWAL_REQUEST_NUMBER_FIXED' as result;
