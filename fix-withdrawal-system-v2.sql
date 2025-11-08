-- Fix withdrawal system by creating missing tables and updating logic (Fixed Version)

-- 1. Check if promoter_wallet table exists
SELECT 
    'TABLE_CHECK' as check_type,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('promoter_wallet', 'withdrawal_requests', 'profiles')
  AND table_schema = 'public';

-- 2. Create promoter_wallet table if it doesn't exist
CREATE TABLE IF NOT EXISTS promoter_wallet (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    balance DECIMAL(10,2) DEFAULT 0.00,
    total_earned DECIMAL(10,2) DEFAULT 0.00,
    total_withdrawn DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(promoter_id)
);

-- 3. Create withdrawal_requests table if it doesn't exist
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    request_number VARCHAR(50) UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'completed', 'rejected')),
    reason TEXT,
    requested_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    transaction_id VARCHAR(100),
    rejection_reason TEXT,
    bank_details JSONB,
    admin_notes TEXT
);

-- 4. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_promoter_wallet_promoter_id ON promoter_wallet(promoter_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_promoter_id ON withdrawal_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);

-- 5. Drop existing function if it exists and create new one
DROP FUNCTION IF EXISTS generate_withdrawal_request_number();

CREATE OR REPLACE FUNCTION generate_withdrawal_request_number()
RETURNS TEXT AS $$
DECLARE
    next_number INTEGER;
    request_number TEXT;
BEGIN
    -- Get the next sequence number
    SELECT COALESCE(MAX(CAST(SUBSTRING(request_number FROM 3) AS INTEGER)), 0) + 1
    INTO next_number
    FROM withdrawal_requests
    WHERE request_number ~ '^WR[0-9]+$';
    
    -- Format as WR000001, WR000002, etc.
    request_number := 'WR' || LPAD(next_number::TEXT, 6, '0');
    
    RETURN request_number;
END;
$$ LANGUAGE plpgsql;

-- 6. Drop existing trigger and function, then create new ones
DROP TRIGGER IF EXISTS trigger_set_withdrawal_request_number ON withdrawal_requests;
DROP FUNCTION IF EXISTS set_withdrawal_request_number();

CREATE OR REPLACE FUNCTION set_withdrawal_request_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.request_number IS NULL THEN
        NEW.request_number := generate_withdrawal_request_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_withdrawal_request_number
    BEFORE INSERT ON withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_withdrawal_request_number();

-- 7. Populate promoter_wallet with data from profiles and affiliate_commissions
INSERT INTO promoter_wallet (promoter_id, balance, total_earned, total_withdrawn)
SELECT 
    p.id as promoter_id,
    COALESCE(p.wallet_balance, 0) as balance,
    COALESCE((
        SELECT SUM(ac.amount)
        FROM affiliate_commissions ac
        WHERE ac.recipient_id = p.id
          AND ac.status = 'credited'
    ), 0) as total_earned,
    0 as total_withdrawn
FROM profiles p
WHERE p.role = 'promoter'
ON CONFLICT (promoter_id) DO UPDATE SET
    balance = EXCLUDED.balance,
    total_earned = EXCLUDED.total_earned,
    updated_at = NOW();

-- 8. Grant permissions
GRANT SELECT, INSERT, UPDATE ON promoter_wallet TO authenticated;
GRANT SELECT, INSERT, UPDATE ON withdrawal_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE ON promoter_wallet TO anon;
GRANT SELECT, INSERT, UPDATE ON withdrawal_requests TO anon;

-- 9. Verify the setup
SELECT 
    'SETUP_VERIFICATION' as check_type,
    pw.promoter_id,
    p.name,
    p.promoter_id as promoter_code,
    pw.balance,
    pw.total_earned,
    pw.total_withdrawn
FROM promoter_wallet pw
JOIN profiles p ON pw.promoter_id = p.id
WHERE p.promoter_id = 'BPVP15';

SELECT 'WITHDRAWAL_SYSTEM_FIXED_V2' as result;
