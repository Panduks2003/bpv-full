-- =====================================================
-- FIX WITHDRAWAL REQUESTS RLS POLICY
-- =====================================================
-- This script fixes the Row-Level Security policies for withdrawal_requests
-- to allow promoters to submit withdrawal requests
-- =====================================================

-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_create_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "allow_all_for_authenticated" ON withdrawal_requests;

-- Ensure RLS is enabled
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- CREATE NEW POLICIES
-- =====================================================

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
-- GRANT PERMISSIONS
-- =====================================================

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE ON withdrawal_requests TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE withdrawal_requests_id_seq TO authenticated;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check that policies are created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read'
        WHEN cmd = 'INSERT' THEN 'Create'
        WHEN cmd = 'UPDATE' THEN 'Update'
        WHEN cmd = 'DELETE' THEN 'Delete'
        WHEN cmd = '*' THEN 'All Operations'
    END as operation
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY policyname;

-- Success message
SELECT '✅ Withdrawal RLS policies fixed! Promoters can now submit withdrawal requests.' as status;
