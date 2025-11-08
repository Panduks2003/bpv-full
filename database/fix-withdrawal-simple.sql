-- =====================================================
-- SIMPLE FIX FOR WITHDRAWAL REQUEST RLS
-- =====================================================
-- This uses a simpler approach that just checks if user is a promoter
-- =====================================================

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;

-- Create a simpler INSERT policy that allows any authenticated promoter
CREATE POLICY "promoters_can_insert_withdrawals" 
ON withdrawal_requests FOR INSERT 
WITH CHECK (
    -- Check if the authenticated user is a promoter
    -- This allows the insert regardless of ID mismatch
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE (
            profiles.id = auth.uid() 
            OR 
            profiles.email = (SELECT email FROM auth.users WHERE id = auth.uid())
        )
        AND profiles.role = 'promoter'
    )
    -- AND the promoter_id being inserted matches their profile ID
    AND promoter_id IN (
        SELECT id FROM profiles 
        WHERE (
            id = auth.uid() 
            OR 
            email = (SELECT email FROM auth.users WHERE id = auth.uid())
        )
        AND role = 'promoter'
    )
);

-- Verify the policy
SELECT 
    '✅ Policy Updated' as status,
    policyname,
    'INSERT' as command
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
AND policyname = 'promoters_can_insert_withdrawals';

SELECT '✅ Simplified withdrawal INSERT policy created!' as final_status;
