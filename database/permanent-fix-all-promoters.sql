-- =====================================================
-- PERMANENT FIX FOR ALL PROMOTERS
-- =====================================================

-- 1. Merge duplicate promoter_wallet records
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT p.id as old_id, au.id as new_id
        FROM profiles p
        JOIN auth.users au ON p.email = au.email
        WHERE p.id != au.id AND p.role = 'promoter'
    LOOP
        -- If both wallets exist, merge them
        IF EXISTS (SELECT 1 FROM promoter_wallet WHERE promoter_id = rec.old_id)
           AND EXISTS (SELECT 1 FROM promoter_wallet WHERE promoter_id = rec.new_id) THEN
            UPDATE promoter_wallet 
            SET balance = balance + (SELECT balance FROM promoter_wallet WHERE promoter_id = rec.old_id),
                total_earned = total_earned + (SELECT total_earned FROM promoter_wallet WHERE promoter_id = rec.old_id)
            WHERE promoter_id = rec.new_id;
            DELETE FROM promoter_wallet WHERE promoter_id = rec.old_id;
        ELSIF EXISTS (SELECT 1 FROM promoter_wallet WHERE promoter_id = rec.old_id) THEN
            UPDATE promoter_wallet SET promoter_id = rec.new_id WHERE promoter_id = rec.old_id;
        END IF;
    END LOOP;
END $$;

-- 2. Update all tables with promoter references
UPDATE withdrawal_requests wr SET promoter_id = au.id
FROM auth.users au JOIN profiles p ON p.email = au.email
WHERE wr.promoter_id = p.id AND p.id != au.id;

UPDATE affiliate_commissions ac SET promoter_id = au.id
FROM auth.users au JOIN profiles p ON p.email = au.email
WHERE ac.promoter_id = p.id AND p.id != au.id;

UPDATE affiliate_commissions ac SET recipient_id = au.id
FROM auth.users au JOIN profiles p ON p.email = au.email
WHERE ac.recipient_id = p.id AND p.id != au.id;

-- 3. Update profiles to match auth UIDs (ALL promoters)
UPDATE profiles p SET id = au.id
FROM auth.users au
WHERE p.email = au.email AND p.id != au.id AND p.role IN ('promoter', 'admin', 'customer');

-- 4. Drop ALL old withdrawal policies
DROP POLICY IF EXISTS "withdrawal_select_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_insert_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_update_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_delete_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_create_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "Promoters can view own withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "Promoters can create withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "Users can view own withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "allow_function_updates" ON withdrawal_requests;

-- 5. Create 4 clean policies for ALL users
CREATE POLICY "withdrawal_select_policy" ON withdrawal_requests
FOR SELECT USING (auth.uid() = promoter_id OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "withdrawal_insert_policy" ON withdrawal_requests
FOR INSERT WITH CHECK (auth.uid() = promoter_id);

CREATE POLICY "withdrawal_update_policy" ON withdrawal_requests
FOR UPDATE USING (auth.uid() = promoter_id OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "withdrawal_delete_policy" ON withdrawal_requests
FOR DELETE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- 6. Verify ALL promoters are fixed
SELECT 
    COUNT(*) as total_promoters,
    COUNT(*) FILTER (WHERE p.id = au.id) as fixed,
    COUNT(*) FILTER (WHERE p.id != au.id) as still_broken
FROM profiles p
JOIN auth.users au ON p.email = au.email
WHERE p.role = 'promoter';

-- 7. Show policies
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'withdrawal_requests' ORDER BY cmd;
