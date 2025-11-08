-- =====================================================
-- FIX WITHDRAWAL REQUEST ID MISMATCH ISSUE
-- =====================================================
-- This fixes the common issue where profile.id != auth.uid()
-- =====================================================

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_update_own_pending_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_all_withdrawals" ON withdrawal_requests;

-- Step 2: Create policies that handle ID mismatch
-- These policies check BOTH auth.uid() AND profile matching via email

-- Policy 1: View - Check both direct ID match and email-based match
CREATE POLICY "promoters_can_view_own_withdrawals" 
ON withdrawal_requests FOR SELECT 
USING (
    -- Direct ID match
    auth.uid() = promoter_id 
    OR
    -- Email-based match (handles ID mismatch)
    EXISTS (
        SELECT 1 FROM profiles p
        INNER JOIN auth.users au ON p.email = au.email
        WHERE au.id = auth.uid() 
        AND p.id = withdrawal_requests.promoter_id
        AND p.role = 'promoter'
    )
    OR
    -- Admin access
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy 2: Insert - Allow if user is a promoter (check via email too)
CREATE POLICY "promoters_can_insert_withdrawals" 
ON withdrawal_requests FOR INSERT 
WITH CHECK (
    -- Direct ID match
    (
        auth.uid() = promoter_id
        AND EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'promoter'
        )
    )
    OR
    -- Email-based match (handles ID mismatch)
    EXISTS (
        SELECT 1 FROM profiles p
        INNER JOIN auth.users au ON p.email = au.email
        WHERE au.id = auth.uid() 
        AND p.id = promoter_id
        AND p.role = 'promoter'
    )
);

-- Policy 3: Update - Allow updating own pending requests
CREATE POLICY "promoters_can_update_own_pending_withdrawals" 
ON withdrawal_requests FOR UPDATE 
USING (
    status = 'pending'
    AND (
        auth.uid() = promoter_id 
        OR
        EXISTS (
            SELECT 1 FROM profiles p
            INNER JOIN auth.users au ON p.email = au.email
            WHERE au.id = auth.uid() 
            AND p.id = withdrawal_requests.promoter_id
        )
    )
)
WITH CHECK (
    status = 'pending'
    AND (
        auth.uid() = promoter_id 
        OR
        EXISTS (
            SELECT 1 FROM profiles p
            INNER JOIN auth.users au ON p.email = au.email
            WHERE au.id = auth.uid() 
            AND p.id = withdrawal_requests.promoter_id
        )
    )
);

-- Policy 4: Admins can do everything
CREATE POLICY "admins_can_manage_all_withdrawals" 
ON withdrawal_requests FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
    OR
    EXISTS (
        SELECT 1 FROM profiles p
        INNER JOIN auth.users au ON p.email = au.email
        WHERE au.id = auth.uid() 
        AND p.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
    OR
    EXISTS (
        SELECT 1 FROM profiles p
        INNER JOIN auth.users au ON p.email = au.email
        WHERE au.id = auth.uid() 
        AND p.role = 'admin'
    )
);

-- Verify policies were created
SELECT 
    '✅ Policies Updated' as status,
    policyname,
    CASE 
        WHEN cmd = 'r' THEN 'SELECT'
        WHEN cmd = 'a' THEN 'INSERT'
        WHEN cmd = 'w' THEN 'UPDATE'
        WHEN cmd = 'd' THEN 'DELETE'
        WHEN cmd = '*' THEN 'ALL'
    END as command
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
AND policyname LIKE '%promoters%' OR policyname LIKE '%admins%'
ORDER BY policyname;

SELECT '✅ Withdrawal policies updated to handle ID mismatch!' as final_status;
