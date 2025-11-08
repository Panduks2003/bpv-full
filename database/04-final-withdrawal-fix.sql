-- =====================================================
-- FINAL SAFE WITHDRAWAL SYSTEM FIX
-- =====================================================
-- Handles duplicate keys by merging/deleting old records
-- =====================================================

-- =====================================================
-- STEP 1: ANALYZE ID MISMATCHES
-- =====================================================

DO $$
DECLARE
    mismatch_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO mismatch_count
    FROM profiles p
    INNER JOIN auth.users au ON p.email = au.email
    WHERE p.id != au.id AND p.role IN ('promoter', 'admin', 'customer');
    
    IF mismatch_count > 0 THEN
        RAISE NOTICE '⚠️ Found % ID mismatches that need fixing', mismatch_count;
    ELSE
        RAISE NOTICE '✅ No ID mismatches found';
    END IF;
END $$;

-- =====================================================
-- STEP 2: FIX WITHDRAWAL_REQUESTS (Handle Duplicates)
-- =====================================================

-- Update withdrawal_requests to use auth user IDs
UPDATE withdrawal_requests wr
SET promoter_id = au.id
FROM auth.users au
INNER JOIN profiles p ON p.email = au.email
WHERE wr.promoter_id = p.id
AND p.id != au.id
AND p.role = 'promoter'
AND NOT EXISTS (
    -- Only update if there's no existing record with the auth UID
    SELECT 1 FROM withdrawal_requests wr2 
    WHERE wr2.promoter_id = au.id
);

-- =====================================================
-- STEP 3: FIX PROMOTER_WALLET (Merge Duplicates)
-- =====================================================

-- For promoter_wallet, we need to merge balances if both records exist
DO $$
DECLARE
    rec RECORD;
    old_balance DECIMAL(10,2);
    new_balance DECIMAL(10,2);
BEGIN
    FOR rec IN 
        SELECT p.id as old_id, au.id as new_id, p.email, p.promoter_id
        FROM profiles p
        INNER JOIN auth.users au ON p.email = au.email
        WHERE p.id != au.id AND p.role = 'promoter'
    LOOP
        -- Check if both records exist
        IF EXISTS (SELECT 1 FROM promoter_wallet WHERE promoter_id = rec.old_id)
           AND EXISTS (SELECT 1 FROM promoter_wallet WHERE promoter_id = rec.new_id) THEN
            
            -- Get old balance
            SELECT balance INTO old_balance FROM promoter_wallet WHERE promoter_id = rec.old_id;
            
            -- Add to new balance (merge)
            UPDATE promoter_wallet 
            SET balance = balance + old_balance,
                total_earned = total_earned + old_balance
            WHERE promoter_id = rec.new_id;
            
            -- Delete old record
            DELETE FROM promoter_wallet WHERE promoter_id = rec.old_id;
            
            RAISE NOTICE '✅ Merged wallet for % (old: %, new: %)', rec.promoter_id, rec.old_id, rec.new_id;
            
        ELSIF EXISTS (SELECT 1 FROM promoter_wallet WHERE promoter_id = rec.old_id) THEN
            -- Only old record exists, just update the ID
            UPDATE promoter_wallet 
            SET promoter_id = rec.new_id 
            WHERE promoter_id = rec.old_id;
            
            RAISE NOTICE '✅ Updated wallet ID for %', rec.promoter_id;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- STEP 4: FIX AFFILIATE_COMMISSIONS (Handle Duplicates)
-- =====================================================

-- Update promoter_id in affiliate_commissions
UPDATE affiliate_commissions ac
SET promoter_id = au.id
FROM auth.users au
INNER JOIN profiles p ON p.email = au.email
WHERE ac.promoter_id = p.id
AND p.id != au.id
AND p.role = 'promoter';

-- Update recipient_id in affiliate_commissions
UPDATE affiliate_commissions ac
SET recipient_id = au.id
FROM auth.users au
INNER JOIN profiles p ON p.email = au.email
WHERE ac.recipient_id = p.id
AND p.id != au.id
AND p.role = 'promoter';

-- Update initiator_promoter_id if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'affiliate_commissions' 
               AND column_name = 'initiator_promoter_id') THEN
        UPDATE affiliate_commissions ac
        SET initiator_promoter_id = au.id
        FROM auth.users au
        INNER JOIN profiles p ON p.email = au.email
        WHERE ac.initiator_promoter_id = p.id
        AND p.id != au.id
        AND p.role = 'promoter';
    END IF;
END $$;

-- =====================================================
-- STEP 5: FIX OTHER TABLES WITH PROMOTER REFERENCES
-- =====================================================

-- Update commissions table if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'commissions') THEN
        UPDATE commissions c
        SET promoter_id = au.id
        FROM auth.users au
        INNER JOIN profiles p ON p.email = au.email
        WHERE c.promoter_id = p.id
        AND p.id != au.id
        AND p.role = 'promoter';
    END IF;
END $$;

-- Update payments table if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payments') THEN
        UPDATE payments pay
        SET promoter_id = au.id
        FROM auth.users au
        INNER JOIN profiles p ON p.email = au.email
        WHERE pay.promoter_id = p.id
        AND p.id != au.id
        AND p.role = 'promoter';
    END IF;
END $$;

-- Update pin_requests table if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pin_requests') THEN
        UPDATE pin_requests pr
        SET promoter_id = au.id
        FROM auth.users au
        INNER JOIN profiles p ON p.email = au.email
        WHERE pr.promoter_id = p.id
        AND p.id != au.id
        AND p.role = 'promoter';
    END IF;
END $$;

-- =====================================================
-- STEP 6: UPDATE PROFILES TABLE (FINAL STEP)
-- =====================================================

-- Now update the profiles table itself
UPDATE profiles p
SET id = au.id
FROM auth.users au
WHERE p.email = au.email
AND p.id != au.id
AND p.role IN ('promoter', 'admin', 'customer');

-- =====================================================
-- STEP 7: ENSURE WITHDRAWAL_REQUESTS TABLE IS CORRECT
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'request_number') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN request_number VARCHAR(50) UNIQUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'bank_details') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN bank_details JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'withdrawal_requests' AND column_name = 'admin_notes') THEN
        ALTER TABLE withdrawal_requests ADD COLUMN admin_notes TEXT;
    END IF;
END $$;

-- =====================================================
-- STEP 8: CREATE INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_promoter_id ON withdrawal_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_created_at ON withdrawal_requests(created_at DESC);

-- =====================================================
-- STEP 9: DROP ALL OLD RLS POLICIES
-- =====================================================

DROP POLICY IF EXISTS "withdrawal_select_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_insert_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_update_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "withdrawal_delete_policy" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_create_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_update_own_pending_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_all_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "Promoters can view own withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "Promoters can create withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "Users can view own withdrawal requests" ON withdrawal_requests;
DROP POLICY IF EXISTS "allow_function_updates" ON withdrawal_requests;

-- =====================================================
-- STEP 10: ENABLE RLS
-- =====================================================

ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 11: CREATE PERMANENT RLS POLICIES
-- =====================================================

CREATE POLICY "withdrawal_select_policy" 
ON withdrawal_requests
FOR SELECT 
USING (
    auth.uid() = promoter_id 
    OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "withdrawal_insert_policy" 
ON withdrawal_requests
FOR INSERT 
WITH CHECK (
    auth.uid() = promoter_id
    AND
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'promoter'
    )
);

CREATE POLICY "withdrawal_update_policy" 
ON withdrawal_requests
FOR UPDATE 
USING (
    (auth.uid() = promoter_id AND status = 'pending')
    OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
)
WITH CHECK (
    (auth.uid() = promoter_id AND status = 'pending')
    OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "withdrawal_delete_policy" 
ON withdrawal_requests
FOR DELETE 
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- =====================================================
-- STEP 12: GRANT PERMISSIONS
-- =====================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON withdrawal_requests TO authenticated;

-- =====================================================
-- STEP 13: VERIFICATION
-- =====================================================

-- Verify BPVP36 specifically
SELECT 
    '🔍 BPVP36 VERIFICATION' as check_type,
    p.id as profile_id,
    au.id as auth_uid,
    p.email,
    p.promoter_id,
    CASE 
        WHEN p.id = au.id THEN '✅ IDs MATCH - FIXED!'
        ELSE '❌ Still mismatched'
    END as status
FROM profiles p
INNER JOIN auth.users au ON p.email = au.email
WHERE p.promoter_id = 'BPVP36';

-- Verify all promoters
SELECT 
    '🔍 ALL PROMOTERS' as check_type,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE p.id = au.id) as matching,
    COUNT(*) FILTER (WHERE p.id != au.id) as mismatched
FROM profiles p
INNER JOIN auth.users au ON p.email = au.email
WHERE p.role = 'promoter';

-- Verify RLS policies
SELECT 
    '🔒 RLS POLICIES' as check_type,
    policyname,
    cmd,
    CASE cmd 
        WHEN 'SELECT' THEN '✅ Read'
        WHEN 'INSERT' THEN '✅ Create'
        WHEN 'UPDATE' THEN '✅ Update'
        WHEN 'DELETE' THEN '✅ Delete'
    END as description
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY cmd;

-- Success message
SELECT 
    '✅ COMPLETE!' as status,
    'Withdrawal system is now fully functional' as message,
    'Try submitting a withdrawal request now!' as action;
