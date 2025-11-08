-- =====================================================
-- TEMPORARY PERMISSIVE WITHDRAWAL POLICY
-- =====================================================
-- This creates a very permissive policy for debugging
-- Use this to test if the issue is with RLS or something else
-- =====================================================

-- Drop existing INSERT policy
DROP POLICY IF EXISTS "withdrawal_insert_policy" ON withdrawal_requests;

-- Create a VERY permissive INSERT policy (for debugging only)
CREATE POLICY "withdrawal_insert_policy" 
ON withdrawal_requests FOR INSERT 
WITH CHECK (
    -- Allow any authenticated user to insert
    auth.uid() IS NOT NULL
    -- No role check - just needs to be authenticated
);

-- Verify
SELECT 
    '✅ Permissive Policy Created' as status,
    'Any authenticated user can now insert withdrawal requests' as note;

SELECT 
    policyname,
    'INSERT' as operation
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
AND policyname = 'withdrawal_insert_policy';
