-- =====================================================
-- FIX WITHDRAWAL RLS - HANDLE AUTH MISMATCH
-- =====================================================
-- This fixes the RLS policy to work even if auth.uid() 
-- doesn't directly match profiles.id
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "withdrawal_select_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_insert_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_update_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_delete_policy" ON withdrawal_requests;

-- =====================================================
-- CREATE POLICIES THAT WORK WITH AUTH MISMATCH
-- =====================================================

-- Policy 1: SELECT - Check via profiles table
CREATE POLICY "withdrawal_select_policy" 
ON withdrawal_requests
FOR SELECT 
USING (
    -- Direct match
    auth.uid() = promoter_id 
    OR
    -- Match via profiles table (handles auth mismatch)
    promoter_id IN (
        SELECT id FROM profiles 
        WHERE id = auth.uid() 
        OR (email = (SELECT email FROM auth.users WHERE id = auth.uid()))
    )
    OR
    -- Admin access
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy 2: INSERT - Check via profiles table
CREATE POLICY "withdrawal_insert_policy" 
ON withdrawal_requests
FOR INSERT 
WITH CHECK (
    -- Direct match
    auth.uid() = promoter_id 
    OR
    -- Match via profiles table (handles auth mismatch)
    promoter_id IN (
        SELECT id FROM profiles 
        WHERE id = auth.uid() 
        OR (email = (SELECT email FROM auth.users WHERE id = auth.uid()))
    )
);

-- Policy 3: UPDATE - Check via profiles table
CREATE POLICY "withdrawal_update_policy" 
ON withdrawal_requests
FOR UPDATE 
USING (
    (
        -- Direct match
        auth.uid() = promoter_id 
        OR
        -- Match via profiles table
        promoter_id IN (
            SELECT id FROM profiles 
            WHERE id = auth.uid() 
            OR (email = (SELECT email FROM auth.users WHERE id = auth.uid()))
        )
    )
    AND status = 'pending'
    OR
    -- Admin can update any
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
)
WITH CHECK (
    (
        auth.uid() = promoter_id 
        OR
        promoter_id IN (
            SELECT id FROM profiles 
            WHERE id = auth.uid() 
            OR (email = (SELECT email FROM auth.users WHERE id = auth.uid()))
        )
    )
    AND status = 'pending'
    OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy 4: DELETE - Admin only
CREATE POLICY "withdrawal_delete_policy" 
ON withdrawal_requests
FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON withdrawal_requests TO authenticated;

-- =====================================================
-- VERIFY
-- =====================================================
SELECT 
    '✅ Policies Created' as status,
    policyname, 
    cmd
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY cmd;
