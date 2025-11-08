-- =====================================================
-- QUICK WITHDRAWAL FIX - FOCUSED
-- =====================================================

-- 1. Update profiles to match auth UIDs
UPDATE profiles p
SET id = au.id
FROM auth.users au
WHERE p.email = au.email
AND p.id != au.id
AND p.promoter_id = 'BPVP36';

-- 2. Drop old policies
DROP POLICY IF EXISTS "withdrawal_select_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_insert_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_update_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_delete_policy" ON withdrawal_requests;

-- 3. Create new policies
CREATE POLICY "withdrawal_select_policy" ON withdrawal_requests
FOR SELECT USING (auth.uid() = promoter_id OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "withdrawal_insert_policy" ON withdrawal_requests
FOR INSERT WITH CHECK (auth.uid() = promoter_id);

CREATE POLICY "withdrawal_update_policy" ON withdrawal_requests
FOR UPDATE USING (auth.uid() = promoter_id OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "withdrawal_delete_policy" ON withdrawal_requests
FOR DELETE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- 4. Verify
SELECT p.id, au.id, CASE WHEN p.id = au.id THEN '✅ FIXED' ELSE '❌ FAILED' END as status
FROM profiles p
JOIN auth.users au ON p.email = au.email
WHERE p.promoter_id = 'BPVP36';
