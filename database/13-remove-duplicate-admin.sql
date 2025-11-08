-- =====================================================
-- REMOVE DUPLICATE ADMIN - KEEP ONLY SYSTEM ADMINISTRATOR
-- =====================================================
-- This script removes the Test Admin and keeps only the System Administrator
-- Primary Admin: 211f48c8-441a-4663-90ec-b77178247cdb (System Administrator)
-- Duplicate Admin: 00000000-0000-0000-0000-000000000001 (Test Admin)
-- =====================================================

BEGIN;

-- Store the IDs for clarity
DO $$
DECLARE
    v_primary_admin_id UUID := '211f48c8-441a-4663-90ec-b77178247cdb';
    v_duplicate_admin_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- Step 1: Transfer any commissions from duplicate admin to primary admin
    UPDATE affiliate_commissions
    SET recipient_id = v_primary_admin_id
    WHERE recipient_id = v_duplicate_admin_id
    AND recipient_type = 'admin';
    
    RAISE NOTICE 'Transferred commissions from duplicate admin to primary admin';
    
    -- Step 2: Transfer PIN transactions from duplicate admin to primary admin
    UPDATE pin_transactions
    SET created_by = v_primary_admin_id
    WHERE created_by = v_duplicate_admin_id;
    
    RAISE NOTICE 'Transferred PIN transactions from duplicate admin to primary admin';
    
    -- Step 3: Delete duplicate admin wallet
    DELETE FROM admin_wallet
    WHERE admin_id = v_duplicate_admin_id;
    
    RAISE NOTICE 'Deleted duplicate admin wallet';
    
    -- Step 4: Delete duplicate admin profile
    DELETE FROM profiles
    WHERE id = v_duplicate_admin_id
    AND role = 'admin';
    
    RAISE NOTICE 'Deleted duplicate admin profile';
    
    -- Step 5: Delete from auth.users if exists
    DELETE FROM auth.users
    WHERE id = v_duplicate_admin_id;
    
    RAISE NOTICE 'Deleted duplicate admin from auth.users';
    
END $$;

-- Verify cleanup
SELECT 
    'Cleanup Verification' as check_type,
    COUNT(*) as remaining_admins,
    json_agg(json_build_object('name', name, 'email', email)) as admin_details
FROM profiles 
WHERE role = 'admin';

-- Verify admin wallet
SELECT 
    'Admin Wallet Verification' as check_type,
    COUNT(*) as wallet_count,
    json_agg(json_build_object('admin_id', admin_id, 'balance', balance, 'total_received', total_commission_received)) as wallet_details
FROM admin_wallet;

-- Success message
SELECT '✅ Cleanup completed! Only System Administrator remains.' as status;

COMMIT;

-- =====================================================
-- RESULT
-- =====================================================
-- After running this script:
-- ✅ Only 1 admin: System Administrator (211f48c8-441a-4663-90ec-b77178247cdb)
-- ✅ Only 1 admin wallet
-- ✅ All commissions consolidated to primary admin
-- ✅ Test Admin completely removed
-- =====================================================
