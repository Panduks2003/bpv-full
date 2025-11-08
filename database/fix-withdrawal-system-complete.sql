-- =====================================================
-- COMPLETE WITHDRAWAL SYSTEM FIX
-- =====================================================
-- This script fixes all withdrawal system issues:
-- 1. Ensures table exists with all required columns
-- 2. Creates request_number auto-generation system
-- 3. Fixes RLS policies for promoters and admins
-- 4. Adds missing columns (processed_by, completed_at, requested_date)
-- 5. Creates proper indexes
-- =====================================================

-- =====================================================
-- STEP 1: CREATE OR UPDATE WITHDRAWAL_REQUESTS TABLE
-- =====================================================

-- Create table if it doesn't exist
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    reason TEXT,
    requested_date DATE DEFAULT CURRENT_DATE,
    bank_details JSONB,
    admin_notes TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    transaction_id VARCHAR(100),
    rejection_reason TEXT,
    request_number VARCHAR(50) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns if they don't exist
DO $$
BEGIN
    -- Add request_number column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'request_number'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN request_number VARCHAR(50) UNIQUE;
    END IF;
    
    -- Add bank_details column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'bank_details'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN bank_details JSONB;
    END IF;
    
    -- Add admin_notes column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'admin_notes'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN admin_notes TEXT;
    END IF;
    
    -- Add processed_at column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'processed_at'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN processed_at TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- Add processed_by column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'processed_by'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN processed_by UUID REFERENCES profiles(id) ON DELETE SET NULL;
    END IF;
    
    -- Add completed_at column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'completed_at'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- Add transaction_id column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'transaction_id'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN transaction_id VARCHAR(100);
    END IF;
    
    -- Add rejection_reason column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'rejection_reason'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN rejection_reason TEXT;
    END IF;
    
    -- Add requested_date column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'requested_date'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN requested_date DATE DEFAULT CURRENT_DATE;
    END IF;
END $$;

-- =====================================================
-- STEP 2: CREATE REQUEST NUMBER GENERATION SYSTEM
-- =====================================================

-- Create sequence for withdrawal request numbers
CREATE SEQUENCE IF NOT EXISTS withdrawal_request_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    CACHE 1;

-- Drop existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS generate_withdrawal_request_number();

-- Function to generate request numbers (WR-001, WR-002, etc.)
CREATE FUNCTION generate_withdrawal_request_number()
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
DECLARE
    next_number INTEGER;
    request_number VARCHAR(50);
BEGIN
    -- Get next sequence value
    SELECT nextval('withdrawal_request_number_seq') INTO next_number;
    
    -- Format as WR-001, WR-002, etc.
    request_number := 'WR-' || LPAD(next_number::TEXT, 3, '0');
    
    RETURN request_number;
END;
$$;

-- Drop existing trigger function first
DROP FUNCTION IF EXISTS set_withdrawal_request_number() CASCADE;

-- Trigger function to auto-generate request numbers
CREATE FUNCTION set_withdrawal_request_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only set request_number if it's NULL
    IF NEW.request_number IS NULL THEN
        NEW.request_number := generate_withdrawal_request_number();
    END IF;
    
    -- Update updated_at timestamp
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_set_withdrawal_request_number ON withdrawal_requests;

-- Create trigger for new withdrawal requests
CREATE TRIGGER trigger_set_withdrawal_request_number
    BEFORE INSERT ON withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_withdrawal_request_number();

-- Create trigger for updates
DROP TRIGGER IF EXISTS trigger_update_withdrawal_timestamp ON withdrawal_requests;

CREATE TRIGGER trigger_update_withdrawal_timestamp
    BEFORE UPDATE ON withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_withdrawal_request_number();

-- Update existing withdrawal requests without request numbers
DO $$
DECLARE
    withdrawal_record RECORD;
    counter INTEGER := 1;
BEGIN
    -- Loop through existing withdrawal requests without request numbers
    FOR withdrawal_record IN 
        SELECT id FROM withdrawal_requests 
        WHERE request_number IS NULL 
        ORDER BY created_at ASC
    LOOP
        -- Update each record with sequential number
        UPDATE withdrawal_requests 
        SET request_number = 'WR-' || LPAD(counter::TEXT, 3, '0')
        WHERE id = withdrawal_record.id;
        
        counter := counter + 1;
    END LOOP;
    
    -- Set sequence to correct value
    IF counter > 1 THEN
        PERFORM setval('withdrawal_request_number_seq', counter - 1);
    END IF;
END $$;

-- =====================================================
-- STEP 3: FIX RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_create_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_update_own_pending_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_all_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "allow_all_for_authenticated" ON withdrawal_requests;

-- Policy 1: Promoters can view their own withdrawal requests
CREATE POLICY "promoters_can_view_own_withdrawals" 
ON withdrawal_requests
FOR SELECT 
USING (
    auth.uid() = promoter_id 
    OR 
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy 2: Promoters can insert their own withdrawal requests
CREATE POLICY "promoters_can_insert_withdrawals" 
ON withdrawal_requests
FOR INSERT 
WITH CHECK (
    auth.uid() = promoter_id
    AND
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'promoter'
    )
);

-- Policy 3: Promoters can update their own pending withdrawal requests
CREATE POLICY "promoters_can_update_own_pending_withdrawals" 
ON withdrawal_requests
FOR UPDATE 
USING (
    auth.uid() = promoter_id 
    AND status = 'pending'
)
WITH CHECK (
    auth.uid() = promoter_id 
    AND status = 'pending'
);

-- Policy 4: Admins can do everything
CREATE POLICY "admins_can_manage_all_withdrawals" 
ON withdrawal_requests
FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- =====================================================
-- STEP 4: GRANT PERMISSIONS
-- =====================================================

-- Grant table permissions
GRANT SELECT, INSERT, UPDATE ON withdrawal_requests TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE withdrawal_request_number_seq TO authenticated;

-- =====================================================
-- STEP 5: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_promoter_id ON withdrawal_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_created_at ON withdrawal_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_request_number ON withdrawal_requests(request_number);

-- =====================================================
-- STEP 6: ADD BANK_ACCOUNTS COLUMN TO PROFILES
-- =====================================================

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
-- STEP 7: VERIFICATION
-- =====================================================

-- Check table structure
SELECT 
    '📋 Table Structure' as check_type,
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'withdrawal_requests'
ORDER BY ordinal_position;

-- Check sequence
SELECT 
    '🔢 Sequence Info' as check_type,
    sequencename as name,
    last_value
FROM pg_sequences 
WHERE schemaname = 'public' 
AND sequencename = 'withdrawal_request_number_seq';

-- Check policies
SELECT 
    '🔒 RLS Policies' as check_type,
    policyname,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read'
        WHEN cmd = 'INSERT' THEN 'Create'
        WHEN cmd = 'UPDATE' THEN 'Update'
        WHEN cmd = 'DELETE' THEN 'Delete'
        WHEN cmd = '*' THEN 'All Operations'
    END as operation,
    permissive as is_permissive
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY policyname;

-- Check existing withdrawal requests
SELECT 
    '📊 Existing Requests' as check_type,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN request_number IS NOT NULL THEN 1 END) as with_request_number,
    COUNT(CASE WHEN request_number IS NULL THEN 1 END) as without_request_number
FROM withdrawal_requests;

-- Success message
SELECT '✅ Withdrawal system fixed completely! Promoters can now submit withdrawal requests.' as status;
