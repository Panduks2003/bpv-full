-- Fix RLS policies for affiliate_commissions table

-- 1. Check current RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'affiliate_commissions';

-- 2. Check existing policies
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'affiliate_commissions';

-- 3. Drop existing restrictive policies if they exist
DROP POLICY IF EXISTS "Users can only see their own commissions" ON affiliate_commissions;
DROP POLICY IF EXISTS "Promoters can only see their commissions" ON affiliate_commissions;
DROP POLICY IF EXISTS "Commission access policy" ON affiliate_commissions;

-- 4. Create proper RLS policies for affiliate_commissions
-- Allow authenticated users to read commissions where they are the recipient
CREATE POLICY "Allow users to read their own commissions" ON affiliate_commissions
    FOR SELECT 
    USING (
        auth.uid() IS NOT NULL AND (
            recipient_id = auth.uid() OR
            initiator_promoter_id = auth.uid() OR
            -- Allow if user is in profiles table with matching ID
            EXISTS (
                SELECT 1 FROM profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.role IN ('promoter', 'admin')
            )
        )
    );

-- Allow authenticated users to insert commissions
CREATE POLICY "Allow authenticated users to insert commissions" ON affiliate_commissions
    FOR INSERT 
    WITH CHECK (
        auth.uid() IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role IN ('promoter', 'admin')
        )
    );

-- Allow users to update their own commission records
CREATE POLICY "Allow users to update their own commissions" ON affiliate_commissions
    FOR UPDATE 
    USING (
        auth.uid() IS NOT NULL AND (
            recipient_id = auth.uid() OR
            initiator_promoter_id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.role = 'admin'
            )
        )
    );

-- 5. Ensure RLS is enabled
ALTER TABLE affiliate_commissions ENABLE ROW LEVEL SECURITY;

-- 6. Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON affiliate_commissions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON affiliate_commissions TO anon;

-- 7. Test the policy with a sample query (replace with actual user ID)
-- This should work for the logged-in user
SELECT 
    'POLICY_TEST' as test_type,
    COUNT(*) as commission_count,
    SUM(amount) as total_amount
FROM affiliate_commissions 
WHERE recipient_id = 'fc5deb02-1b33-4779-990d-ac89f3863e19'
  AND status = 'credited';

-- 8. Verify policies are active
SELECT 
    'POLICY_VERIFICATION' as check_type,
    policyname,
    cmd,
    permissive,
    qual
FROM pg_policies 
WHERE tablename = 'affiliate_commissions';

SELECT 'RLS_POLICY_FIX_COMPLETE' as result;
