-- =====================================================
-- FINAL COMPREHENSIVE WITHDRAWAL RLS FIX
-- =====================================================
-- This creates the most permissive safe policies
-- that will work with the web application
-- =====================================================

-- Step 1: Drop ALL existing policies
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'withdrawal_requests')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON withdrawal_requests';
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
END $$;

-- Step 2: Ensure RLS is enabled
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Step 3: Create SIMPLE, PERMISSIVE policies

-- SELECT: Anyone authenticated can view their own or admins view all
CREATE POLICY "withdrawal_select_policy" 
ON withdrawal_requests FOR SELECT 
TO authenticated
USING (
    promoter_id = auth.uid()
    OR 
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- INSERT: Any authenticated user can insert (we'll validate in app)
-- This is the most permissive safe policy
CREATE POLICY "withdrawal_insert_policy" 
ON withdrawal_requests FOR INSERT 
TO authenticated
WITH CHECK (
    -- Just check that they're authenticated and inserting their own ID
    promoter_id = auth.uid()
);

-- UPDATE: Can update own pending requests or admin updates all
CREATE POLICY "withdrawal_update_policy" 
ON withdrawal_requests FOR UPDATE 
TO authenticated
USING (
    (promoter_id = auth.uid() AND status = 'pending')
    OR 
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
)
WITH CHECK (
    (promoter_id = auth.uid() AND status = 'pending')
    OR 
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- DELETE: Admin only
CREATE POLICY "withdrawal_delete_policy" 
ON withdrawal_requests FOR DELETE 
TO authenticated
USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
);

-- Step 4: Grant permissions explicitly
GRANT ALL ON withdrawal_requests TO authenticated;
GRANT ALL ON withdrawal_requests TO service_role;

-- Step 5: Verify
SELECT 
    '✅ POLICIES CREATED' as status,
    policyname,
    CASE cmd
        WHEN 'r' THEN 'SELECT'
        WHEN 'a' THEN 'INSERT'
        WHEN 'w' THEN 'UPDATE'
        WHEN 'd' THEN 'DELETE'
        WHEN '*' THEN 'ALL'
    END as operation,
    roles::text as applies_to
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY policyname;

SELECT '✅ Withdrawal RLS policies are now MAXIMALLY PERMISSIVE while still secure!' as final_message;
