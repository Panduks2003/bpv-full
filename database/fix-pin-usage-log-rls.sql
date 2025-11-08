-- =====================================================
-- FIX PIN_USAGE_LOG RLS POLICIES
-- =====================================================
-- This script fixes RLS policies to allow admin users to insert pin usage logs

BEGIN;

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view their own pin usage" ON pin_usage_log;

-- Create more permissive policies for pin_usage_log
CREATE POLICY "Admin can manage all pin usage logs" ON pin_usage_log
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Promoters can view their own pin usage" ON pin_usage_log
    FOR SELECT USING (
        promoter_id = auth.uid() OR 
        customer_id = auth.uid() OR
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Customers can view their related pin usage" ON pin_usage_log
    FOR SELECT USING (
        customer_id = auth.uid() OR
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON pin_usage_log TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE pin_usage_log ENABLE ROW LEVEL SECURITY;

COMMIT;

-- Verification
SELECT 'RLS_POLICIES_CHECK' as check_type,
       schemaname,
       tablename,
       policyname,
       permissive,
       roles,
       cmd,
       qual
FROM pg_policies 
WHERE tablename = 'pin_usage_log';

-- Test admin permissions
SELECT 'ADMIN_PERMISSIONS_CHECK' as check_type,
       table_name,
       privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'pin_usage_log' 
AND grantee = 'authenticated';
