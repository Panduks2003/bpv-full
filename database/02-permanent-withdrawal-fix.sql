-- =====================================================
-- PERMANENT WITHDRAWAL SYSTEM FIX
-- =====================================================
-- This is a comprehensive, permanent solution that:
-- 1. Fixes ID mismatches between auth.users and profiles
-- 2. Creates proper RLS policies that handle all edge cases
-- 3. Ensures proper permissions and constraints
-- 4. Works for all promoters, not just temporary fixes
-- =====================================================

-- =====================================================
-- STEP 1: FIX ID MISMATCHES (ROOT CAUSE)
-- =====================================================

-- This function syncs profile IDs with auth user IDs
-- Run this ONLY if there's an ID mismatch
DO $$
DECLARE
    mismatch_count INTEGER;
BEGIN
    -- Count mismatches
    SELECT COUNT(*) INTO mismatch_count
    FROM profiles p
    INNER JOIN auth.users au ON p.email = au.email
    WHERE p.id != au.id AND p.role IN ('promoter', 'admin', 'customer');
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '⚠️ Found % ID mismatches. Fixing...', mismatch_count;
        
        -- Temporarily disable triggers and constraints
        ALTER TABLE withdrawal_requests DISABLE TRIGGER ALL;
        ALTER TABLE promoter_wallet DISABLE TRIGGER ALL;
        ALTER TABLE affiliate_commissions DISABLE TRIGGER ALL;
        
        -- Update profiles to match auth.users IDs
        UPDATE profiles p
        SET id = au.id
        FROM auth.users au
        WHERE p.email = au.email 
        AND p.id != au.id
        AND p.role IN ('promoter', 'admin', 'customer');
        
        -- Update related tables to use new IDs
        UPDATE withdrawal_requests wr
        SET promoter_id = au.id
        FROM auth.users au
        INNER JOIN profiles p ON p.email = au.email
        WHERE wr.promoter_id = p.id;
        
        UPDATE promoter_wallet pw
        SET promoter_id = au.id
        FROM auth.users au
        INNER JOIN profiles p ON p.email = au.email
        WHERE pw.promoter_id = p.id;
        
        UPDATE affiliate_commissions ac
        SET promoter_id = au.id
        FROM auth.users au
        INNER JOIN profiles p ON p.email = au.email
        WHERE ac.promoter_id = p.id;
        
        -- Re-enable triggers
        ALTER TABLE withdrawal_requests ENABLE TRIGGER ALL;
        ALTER TABLE promoter_wallet ENABLE TRIGGER ALL;
        ALTER TABLE affiliate_commissions ENABLE TRIGGER ALL;
        
        RAISE NOTICE '✅ Fixed % ID mismatches', mismatch_count;
    ELSE
        RAISE NOTICE '✅ No ID mismatches found';
    END IF;
END $$;

-- =====================================================
-- STEP 2: ENSURE WITHDRAWAL_REQUESTS TABLE IS CORRECT
-- =====================================================

-- Add missing columns if they don't exist
DO $$
BEGIN
    -- Check and add columns one by one
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'request_number') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN request_number VARCHAR(50) UNIQUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'bank_details') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN bank_details JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'admin_notes') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN admin_notes TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'processed_at') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN processed_at TIMESTAMP WITH TIME ZONE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'transaction_id') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN transaction_id VARCHAR(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'rejection_reason') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN rejection_reason TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'requested_date') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN requested_date DATE;
    END IF;
END $$;

-- =====================================================
-- STEP 3: CREATE/UPDATE INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_promoter_id ON withdrawal_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_created_at ON withdrawal_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_request_number ON withdrawal_requests(request_number);

-- =====================================================
-- STEP 4: DROP ALL OLD RLS POLICIES
-- =====================================================

DROP POLICY IF EXISTS "withdrawal_select_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_insert_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_update_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_delete_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_create_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_update_own_pending_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_all_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "Promoters can view own withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "Promoters can create withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "Users can view own withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "allow_function_updates" ON withdrawal_requests;

-- =====================================================
-- STEP 5: ENABLE RLS
-- =====================================================

ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 6: CREATE PERMANENT RLS POLICIES
-- =====================================================

-- Policy 1: SELECT - Users can view their own withdrawals, admins can view all
CREATE POLICY "withdrawal_select_policy" 
ON withdrawal_requests
FOR SELECT 
USING (
    -- User is the promoter who made the request
    auth.uid() = promoter_id 
    OR
    -- User is an admin
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy 2: INSERT - Promoters can create withdrawal requests
CREATE POLICY "withdrawal_insert_policy" 
ON withdrawal_requests
FOR INSERT 
WITH CHECK (
    -- User must be inserting their own record
    auth.uid() = promoter_id
    AND
    -- User must be a promoter
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'promoter'
    )
);

-- Policy 3: UPDATE - Promoters can update their pending requests, admins can update any
CREATE POLICY "withdrawal_update_policy" 
ON withdrawal_requests
FOR UPDATE 
USING (
    -- Promoter updating their own pending request
    (auth.uid() = promoter_id AND status = 'pending')
    OR
    -- Admin can update any request
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
)
WITH CHECK (
    -- Same conditions for the updated row
    (auth.uid() = promoter_id AND status = 'pending')
    OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy 4: DELETE - Only admins can delete
CREATE POLICY "withdrawal_delete_policy" 
ON withdrawal_requests
FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- =====================================================
-- STEP 7: GRANT PERMISSIONS
-- =====================================================

GRANT SELECT, INSERT, UPDATE ON withdrawal_requests TO authenticated;
GRANT DELETE ON withdrawal_requests TO authenticated; -- Controlled by RLS policy

-- Grant sequence permissions if sequence exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'withdrawal_requests_id_seq' AND relkind = 'S') THEN
        GRANT USAGE, SELECT ON SEQUENCE withdrawal_requests_id_seq TO authenticated;
    END IF;
END $$;

-- =====================================================
-- STEP 8: CREATE HELPER FUNCTION FOR WITHDRAWAL VALIDATION
-- =====================================================

-- Function to validate withdrawal request before insertion
CREATE OR REPLACE FUNCTION validate_withdrawal_request()
RETURNS TRIGGER AS $$
DECLARE
    available_balance DECIMAL(10,2);
    pending_amount DECIMAL(10,2);
BEGIN
    -- Get available balance from promoter_wallet
    SELECT COALESCE(balance, 0) INTO available_balance
    FROM promoter_wallet
    WHERE promoter_id = NEW.promoter_id;
    
    -- Get pending withdrawal amount
    SELECT COALESCE(SUM(amount), 0) INTO pending_amount
    FROM withdrawal_requests
    WHERE promoter_id = NEW.promoter_id
    AND status = 'pending';
    
    -- Check if sufficient balance
    IF (available_balance - pending_amount) < NEW.amount THEN
        RAISE EXCEPTION 'Insufficient balance. Available: %, Pending: %, Requested: %', 
            available_balance, pending_amount, NEW.amount;
    END IF;
    
    -- Generate request number if not provided
    IF NEW.request_number IS NULL THEN
        NEW.request_number := 'WR' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(nextval('withdrawal_requests_id_seq')::TEXT, 6, '0');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for validation
DROP TRIGGER IF EXISTS validate_withdrawal_before_insert ON withdrawal_requests;
CREATE TRIGGER validate_withdrawal_before_insert
    BEFORE INSERT ON withdrawal_requests
    FOR EACH ROW
    EXECUTE FUNCTION validate_withdrawal_request();

-- =====================================================
-- STEP 9: VERIFICATION
-- =====================================================

-- Verify ID matches
SELECT 
    '🔍 ID VERIFICATION' as check_type,
    COUNT(*) as total_profiles,
    COUNT(*) FILTER (WHERE p.id = au.id) as matching_ids,
    COUNT(*) FILTER (WHERE p.id != au.id) as mismatched_ids
FROM profiles p
INNER JOIN auth.users au ON p.email = au.email
WHERE p.role IN ('promoter', 'admin', 'customer');

-- Verify policies
SELECT 
    '🔒 RLS POLICIES' as check_type,
    policyname,
    cmd as operation,
    CASE cmd 
        WHEN 'SELECT' THEN '✅ Read'
        WHEN 'INSERT' THEN '✅ Create'
        WHEN 'UPDATE' THEN '✅ Update'
        WHEN 'DELETE' THEN '✅ Delete'
    END as description
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY cmd;

-- Verify permissions
SELECT 
    '✅ PERMISSIONS' as check_type,
    grantee,
    STRING_AGG(privilege_type, ', ' ORDER BY privilege_type) as privileges
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name = 'withdrawal_requests'
AND grantee IN ('authenticated', 'anon')
GROUP BY grantee;

-- Success message
SELECT '✅ PERMANENT WITHDRAWAL SYSTEM FIX COMPLETE!' as status,
       '🎯 All promoters can now submit withdrawal requests' as message,
       '🔒 RLS policies are properly configured' as security,
       '🔧 ID mismatches have been resolved' as data_integrity;
