-- =====================================================
-- FIX WITHDRAWAL REQUESTS - UUID & RLS
-- =====================================================
-- Ensures UUID generation and proper RLS policies
-- =====================================================

-- Step 1: Ensure UUID extension is enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Step 2: Set default UUID generation for id column
ALTER TABLE withdrawal_requests 
ALTER COLUMN id SET DEFAULT uuid_generate_v4();

-- Step 3: Drop all existing policies
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'withdrawal_requests')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON withdrawal_requests';
    END LOOP;
END $$;

-- Step 4: Enable RLS
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Step 5: Create simple, permissive policies

-- SELECT: View own requests or admin views all
CREATE POLICY "withdrawal_select_policy" 
ON withdrawal_requests FOR SELECT 
USING (
    promoter_id = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- INSERT: Promoters can create with their own ID
CREATE POLICY "withdrawal_insert_policy" 
ON withdrawal_requests FOR INSERT 
WITH CHECK (
    promoter_id = auth.uid()
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'promoter')
);

-- UPDATE: Update own pending or admin updates all
CREATE POLICY "withdrawal_update_policy" 
ON withdrawal_requests FOR UPDATE 
USING (
    (promoter_id = auth.uid() AND status = 'pending')
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- DELETE: Admin only
CREATE POLICY "withdrawal_delete_policy" 
ON withdrawal_requests FOR DELETE 
USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Step 6: Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON withdrawal_requests TO authenticated;

-- Step 7: Verify setup
SELECT '✅ UUID Extension' as check_type, extname as name
FROM pg_extension WHERE extname = 'uuid-ossp';

SELECT '✅ Default Value' as check_type, column_default
FROM information_schema.columns
WHERE table_name = 'withdrawal_requests' AND column_name = 'id';

SELECT '✅ RLS Policies' as check_type, COUNT(*) as policy_count
FROM pg_policies WHERE tablename = 'withdrawal_requests';

SELECT '✅ Withdrawal system ready! UUID auto-generation enabled and RLS policies set.' as status;
