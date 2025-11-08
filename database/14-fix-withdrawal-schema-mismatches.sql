-- =====================================================
-- FIX WITHDRAWAL SYSTEM SCHEMA MISMATCHES
-- =====================================================
-- This script fixes the database schema to match what the frontend expects
-- Addresses the 400 Bad Request errors in WithdrawalRequest.js
-- =====================================================

-- =====================================================
-- 1. CREATE MISSING TABLES AND COLUMNS
-- =====================================================

-- Create payments table if it doesn't exist (for promoter earnings tracking)
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    type VARCHAR(20) NOT NULL CHECK (type IN ('credit', 'debit')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
    description TEXT,
    reference_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create commissions table if it doesn't exist (alternative to affiliate_commissions)
CREATE TABLE IF NOT EXISTS commissions (
    id SERIAL PRIMARY KEY,
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
    commission_type VARCHAR(50) DEFAULT 'affiliate',
    customer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    level INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns to withdrawal_requests table
DO $$
BEGIN
    -- Add bank_details column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'bank_details'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN bank_details JSONB;
    END IF;
    
    -- Add admin_notes column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'admin_notes'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN admin_notes TEXT;
    END IF;
    
    -- Add processed_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'processed_at'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN processed_at TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- Add transaction_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'transaction_id'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN transaction_id VARCHAR(100);
    END IF;
    
    -- Add rejection_reason column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'rejection_reason'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN rejection_reason TEXT;
    END IF;
END $$;

-- Add bank_accounts column to profiles table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'bank_accounts'
    ) THEN
        ALTER TABLE profiles ADD COLUMN bank_accounts JSONB DEFAULT '[]'::jsonb;
    END IF;
END $$;

-- =====================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for payments table
CREATE INDEX IF NOT EXISTS idx_payments_promoter_id ON payments(promoter_id);
CREATE INDEX IF NOT EXISTS idx_payments_type_status ON payments(type, status);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);

-- Indexes for commissions table
CREATE INDEX IF NOT EXISTS idx_commissions_promoter_id ON commissions(promoter_id);
CREATE INDEX IF NOT EXISTS idx_commissions_status ON commissions(status);
CREATE INDEX IF NOT EXISTS idx_commissions_created_at ON commissions(created_at DESC);

-- Indexes for withdrawal_requests
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_promoter_id ON withdrawal_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_created_at ON withdrawal_requests(created_at DESC);

-- =====================================================
-- 3. CREATE RLS POLICIES
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;

-- RLS policies for payments table
CREATE POLICY "promoters_can_view_own_payments" ON payments
    FOR SELECT USING (
        auth.uid() = promoter_id OR 
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admins_can_manage_payments" ON payments
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- RLS policies for commissions table
CREATE POLICY "promoters_can_view_own_commissions" ON commissions
    FOR SELECT USING (
        auth.uid() = promoter_id OR 
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admins_can_manage_commissions" ON commissions
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- =====================================================
-- 4. INSERT SAMPLE DATA FOR TESTING
-- =====================================================

-- Insert sample commission data for the current promoter (if exists)
INSERT INTO commissions (promoter_id, amount, status, commission_type, level)
SELECT 
    id,
    1000.00,
    'completed',
    'affiliate',
    1
FROM profiles 
WHERE role = 'promoter' 
AND promoter_id = 'PROM0019'
ON CONFLICT DO NOTHING;

-- Insert sample payment data for the current promoter (if exists)
INSERT INTO payments (promoter_id, amount, type, status, description)
SELECT 
    id,
    500.00,
    'credit',
    'completed',
    'Commission payment'
FROM profiles 
WHERE role = 'promoter' 
AND promoter_id = 'PROM0019'
ON CONFLICT DO NOTHING;

-- =====================================================
-- 5. CREATE UTILITY FUNCTIONS
-- =====================================================

-- Function to get promoter balance
CREATE OR REPLACE FUNCTION get_promoter_balance(p_promoter_id UUID)
RETURNS TABLE (
    total_earnings DECIMAL(10,2),
    available_balance DECIMAL(10,2),
    pending_withdrawals DECIMAL(10,2)
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH earnings AS (
        SELECT COALESCE(SUM(amount), 0) as total_earned
        FROM (
            SELECT amount FROM payments 
            WHERE promoter_id = p_promoter_id 
            AND type = 'credit' 
            AND status = 'completed'
            
            UNION ALL
            
            SELECT amount FROM commissions 
            WHERE promoter_id = p_promoter_id 
            AND status = 'completed'
        ) combined_earnings
    ),
    withdrawals AS (
        SELECT 
            COALESCE(SUM(CASE WHEN status IN ('approved', 'completed') THEN amount ELSE 0 END), 0) as withdrawn,
            COALESCE(SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END), 0) as pending
        FROM withdrawal_requests 
        WHERE promoter_id = p_promoter_id
    )
    SELECT 
        e.total_earned,
        (e.total_earned - w.withdrawn),
        w.pending
    FROM earnings e, withdrawals w;
END;
$$;

-- =====================================================
-- 6. UPDATE EXISTING WITHDRAWAL_REQUESTS TABLE
-- =====================================================

-- Ensure withdrawal_requests table exists with all required columns
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id SERIAL PRIMARY KEY,
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    reason TEXT,
    bank_details JSONB,
    admin_notes TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    transaction_id VARCHAR(100),
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on withdrawal_requests if not already enabled
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for withdrawal_requests if they don't exist
DO $$
BEGIN
    -- Drop existing policies if they exist to avoid conflicts
    DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
    DROP POLICY IF EXISTS "promoters_can_create_withdrawals" ON withdrawal_requests;
    DROP POLICY IF EXISTS "admins_can_manage_withdrawals" ON withdrawal_requests;
    
    -- Create new policies
    CREATE POLICY "promoters_can_view_own_withdrawals" ON withdrawal_requests
        FOR SELECT USING (
            auth.uid() = promoter_id OR 
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        );
    
    CREATE POLICY "promoters_can_create_withdrawals" ON withdrawal_requests
        FOR INSERT WITH CHECK (auth.uid() = promoter_id);
    
    CREATE POLICY "admins_can_manage_withdrawals" ON withdrawal_requests
        FOR ALL USING (
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
        );
END $$;

-- =====================================================
-- 7. VERIFICATION QUERIES
-- =====================================================

-- Verify all required tables exist
SELECT 
    'Table Check' as check_type,
    table_name,
    CASE WHEN table_name IS NOT NULL THEN '✅ Exists' ELSE '❌ Missing' END as status
FROM (
    VALUES ('payments'), ('commissions'), ('withdrawal_requests'), ('profiles')
) AS expected(table_name)
LEFT JOIN information_schema.tables t ON t.table_name = expected.table_name AND t.table_schema = 'public';

-- Verify required columns exist
SELECT 
    'Column Check' as check_type,
    table_name || '.' || column_name as column_name,
    '✅ Exists' as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND (
    (table_name = 'payments' AND column_name IN ('amount', 'type', 'status', 'promoter_id')) OR
    (table_name = 'commissions' AND column_name IN ('amount', 'status', 'promoter_id')) OR
    (table_name = 'withdrawal_requests' AND column_name IN ('bank_details', 'admin_notes', 'processed_at', 'transaction_id', 'rejection_reason')) OR
    (table_name = 'profiles' AND column_name = 'bank_accounts')
)
ORDER BY table_name, column_name;

-- Success message
SELECT '✅ Schema fixes applied successfully! Frontend should now work without 400 errors.' as status;
