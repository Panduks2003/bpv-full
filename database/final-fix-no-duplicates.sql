-- =====================================================
-- PERMANENT FIX - HANDLES DUPLICATES
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

-- 2. Update withdrawal_requests
UPDATE withdrawal_requests wr SET promoter_id = au.id
FROM auth.users au JOIN profiles p ON p.email = au.email
WHERE wr.promoter_id = p.id AND p.id != au.id;

-- 3. Update affiliate_commissions
UPDATE affiliate_commissions ac SET recipient_id = au.id
FROM auth.users au JOIN profiles p ON p.email = au.email
WHERE ac.recipient_id = p.id AND p.id != au.id;

UPDATE affiliate_commissions ac SET initiator_promoter_id = au.id
FROM auth.users au JOIN profiles p ON p.email = au.email
WHERE ac.initiator_promoter_id = p.id AND p.id != au.id;

-- 4. Update parent_promoter_id references in profiles
UPDATE profiles child SET parent_promoter_id = au.id
FROM auth.users au JOIN profiles parent ON parent.email = au.email
WHERE child.parent_promoter_id = parent.id AND parent.id != au.id;

-- 5. Delete old profile records (that don't match auth)
DELETE FROM profiles p
WHERE EXISTS (
    SELECT 1 FROM auth.users au 
    WHERE au.email = p.email AND au.id != p.id
);

-- 6. Drop ALL old policies
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

-- 7. Create 4 clean policies
CREATE POLICY "withdrawal_select_policy" ON withdrawal_requests
FOR SELECT USING (auth.uid() = promoter_id OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "withdrawal_insert_policy" ON withdrawal_requests
FOR INSERT WITH CHECK (auth.uid() = promoter_id);

CREATE POLICY "withdrawal_update_policy" ON withdrawal_requests
FOR UPDATE USING (auth.uid() = promoter_id OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "withdrawal_delete_policy" ON withdrawal_requests
FOR DELETE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- 8. Verify
SELECT 
    '✅ FIXED' as status,
    COUNT(*) as total_promoters,
    COUNT(*) FILTER (WHERE p.id = au.id) as matching_ids,
    COUNT(*) FILTER (WHERE p.id != au.id) as mismatched_ids
FROM profiles p
JOIN auth.users au ON p.email = au.email
WHERE p.role = 'promoter';

SELECT '🔒 POLICIES' as status, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'withdrawal_requests' 
ORDER BY cmd;
