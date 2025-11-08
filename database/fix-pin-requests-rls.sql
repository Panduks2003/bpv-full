-- =====================================================
-- FIX PIN REQUESTS RLS POLICIES
-- =====================================================
-- This script fixes the RLS policies for pin_requests table

-- First, let's check if the table exists and what policies are there
SELECT 'pin_requests table exists' as status, 
       CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pin_requests') 
            THEN 'YES' ELSE 'NO' END as table_exists;

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "promoters_can_view_own_requests" ON pin_requests;
DROP POLICY IF EXISTS "promoters_can_create_requests" ON pin_requests;
DROP POLICY IF EXISTS "admins_can_view_all_requests" ON pin_requests;
DROP POLICY IF EXISTS "admins_can_update_requests" ON pin_requests;

-- Disable RLS temporarily to test
ALTER TABLE pin_requests DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS
ALTER TABLE pin_requests ENABLE ROW LEVEL SECURITY;

-- Create simple, permissive policies for testing
CREATE POLICY "allow_all_for_authenticated" ON pin_requests
    FOR ALL USING (auth.role() = 'authenticated');

-- Alternative: Create specific policies
-- CREATE POLICY "promoters_can_view_own_requests" ON pin_requests
--     FOR SELECT USING (promoter_id = auth.uid());

-- CREATE POLICY "promoters_can_create_requests" ON pin_requests
--     FOR INSERT WITH CHECK (promoter_id = auth.uid());

-- CREATE POLICY "admins_can_view_all_requests" ON pin_requests
--     FOR SELECT USING (
--         EXISTS (
--             SELECT 1 FROM profiles 
--             WHERE profiles.id = auth.uid() 
--             AND profiles.role = 'admin'
--         )
--     );

-- CREATE POLICY "admins_can_update_requests" ON pin_requests
--     FOR UPDATE USING (
--         EXISTS (
--             SELECT 1 FROM profiles 
--             WHERE profiles.id = auth.uid() 
--             AND profiles.role = 'admin'
--         )
--     );

-- Test query to see if we can access the table
SELECT 'Test query result' as test, COUNT(*) as row_count FROM pin_requests;

-- Show current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'pin_requests';
