-- =====================================================
-- QUICK FIX WITHDRAWAL RLS - SIMPLIFIED
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_create_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_update_own_pending_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_all_withdrawals" ON withdrawal_requests;

-- Ensure RLS is enabled
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Policy 1: SELECT - Promoters can view their own, admins can view all
CREATE POLICY "withdrawal_select_policy" 
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

-- Policy 2: INSERT - Any authenticated user can insert their own withdrawal
CREATE POLICY "withdrawal_insert_policy" 
ON withdrawal_requests
FOR INSERT 
WITH CHECK (auth.uid() = promoter_id);

-- Policy 3: UPDATE - Promoters can update their pending requests, admins can update all
CREATE POLICY "withdrawal_update_policy" 
ON withdrawal_requests
FOR UPDATE 
USING (
    (auth.uid() = promoter_id AND status = 'pending')
    OR 
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy 4: Admins can do everything (DELETE)
CREATE POLICY "withdrawal_admin_delete_policy" 
ON withdrawal_requests
FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Verify policies created
SELECT 
    policyname,
    CASE cmd
        WHEN 'SELECT' THEN 'Read'
        WHEN 'INSERT' THEN 'Create'
        WHEN 'UPDATE' THEN 'Update'
        WHEN 'DELETE' THEN 'Delete'
    END as operation
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY policyname;

SELECT '✅ RLS policies simplified! Try withdrawal submission again.' as status;
