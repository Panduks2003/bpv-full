-- =====================================================
-- FIX WITHDRAWAL REQUESTS RLS POLICY - IMMEDIATE FIX
-- =====================================================
-- Run this to allow promoters to create withdrawal requests
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_create_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_update_own_pending_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_all_withdrawals" ON withdrawal_requests;

-- Enable RLS
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

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

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON withdrawal_requests TO authenticated;

-- Grant sequence permissions only if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'withdrawal_requests_id_seq' AND relkind = 'S') THEN
        GRANT USAGE, SELECT ON SEQUENCE withdrawal_requests_id_seq TO authenticated;
        RAISE NOTICE '✅ Sequence permissions granted';
    ELSE
        RAISE NOTICE '⚠️ Sequence does not exist - table may use BIGSERIAL or different sequence name';
    END IF;
END $$;

-- Verify policies
SELECT 
    '✅ RLS Policies Created' as status,
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
ORDER BY policyname;
