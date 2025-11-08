-- =====================================================
-- CLEAN UP PIN REQUESTS RLS POLICIES
-- =====================================================
-- Remove conflicting policies and set up clean, working ones

-- Drop all existing policies
DROP POLICY IF EXISTS "allow_all_for_authenticated" ON pin_requests;
DROP POLICY IF EXISTS "Promoters can view own pin requests" ON pin_requests;
DROP POLICY IF EXISTS "Promoters can create pin requests" ON pin_requests;
DROP POLICY IF EXISTS "Users can view own pin requests" ON pin_requests;
DROP POLICY IF EXISTS "Admins can update any pin request" ON pin_requests;

-- Create clean, simple policies
CREATE POLICY "promoters_can_view_own_requests" ON pin_requests
    FOR SELECT USING (promoter_id = auth.uid());

CREATE POLICY "promoters_can_create_requests" ON pin_requests
    FOR INSERT WITH CHECK (promoter_id = auth.uid());

CREATE POLICY "admins_can_view_all_requests" ON pin_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "admins_can_update_requests" ON pin_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Test the policies
SELECT 'Policies cleaned up successfully' as status;

-- Show the new policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE tablename = 'pin_requests';
