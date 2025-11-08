-- =====================================================
-- FIX WITHDRAWAL INSERT RLS POLICY
-- =====================================================
-- This fixes the "new row violates row-level security policy" error
-- by simplifying the INSERT policy
-- =====================================================

-- Drop existing INSERT policy
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;

-- Create simplified INSERT policy
-- This allows authenticated users to insert if they're inserting their own promoter_id
CREATE POLICY "promoters_can_insert_withdrawals" 
ON withdrawal_requests
FOR INSERT 
WITH CHECK (
    auth.uid() = promoter_id
);

-- Verify the policy
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

-- Test the current user's auth context
SELECT 
    '🔐 Auth Context' as check_type,
    auth.uid() as current_user_id,
    auth.role() as current_role;

-- Check if current user is a promoter
SELECT 
    '👤 User Profile' as check_type,
    id,
    name,
    email,
    role,
    promoter_id
FROM profiles
WHERE id = auth.uid();

-- Success message
SELECT '✅ Withdrawal INSERT policy simplified! Try submitting a withdrawal request again.' as status;
