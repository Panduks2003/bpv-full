-- =====================================================
-- RESET DATABASE TO FRESH START
-- =====================================================
-- This script deletes ALL test data while preserving:
-- - Database structure (tables, functions, triggers)
-- - Admin user (if you want to keep it)
-- 
-- WARNING: This will DELETE ALL:
-- - Promoters
-- - Customers
-- - PIN Requests
-- - PIN Transactions
-- - Commissions
-- - Withdrawals
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: DELETE ALL TRANSACTIONAL DATA
-- =====================================================

-- Delete all withdrawal requests
DELETE FROM withdrawal_requests;
RAISE NOTICE '✅ Deleted all withdrawal requests';

-- Delete all affiliate commissions
DELETE FROM affiliate_commissions;
RAISE NOTICE '✅ Deleted all affiliate commissions';

-- Delete all PIN transactions
DELETE FROM pin_transactions;
RAISE NOTICE '✅ Deleted all PIN transactions';

-- Delete all PIN requests
DELETE FROM pin_requests;
RAISE NOTICE '✅ Deleted all PIN requests';

-- Delete all payment schedules
DELETE FROM payment_schedules;
RAISE NOTICE '✅ Deleted all payment schedules';

-- =====================================================
-- STEP 2: DELETE ALL CUSTOMERS
-- =====================================================

-- Get count before deletion
DO $$
DECLARE
  customer_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO customer_count FROM profiles WHERE role = 'customer';
  RAISE NOTICE 'Found % customers to delete', customer_count;
END $$;

-- Delete customer profiles
DELETE FROM profiles WHERE role = 'customer';
RAISE NOTICE '✅ Deleted all customer profiles';

-- Delete customer auth users (from auth.users)
-- Note: This requires admin privileges
DELETE FROM auth.users 
WHERE id IN (
  SELECT id FROM auth.users 
  WHERE email LIKE '%@customer.brightplanet.com'
  OR email LIKE 'cust%@brightplanet.com'
);
RAISE NOTICE '✅ Deleted all customer auth users';

-- =====================================================
-- STEP 3: DELETE ALL PROMOTERS (EXCEPT ADMIN)
-- =====================================================

-- Get count before deletion
DO $$
DECLARE
  promoter_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO promoter_count FROM profiles WHERE role = 'promoter';
  RAISE NOTICE 'Found % promoters to delete', promoter_count;
END $$;

-- Delete promoter profiles (keep admin)
DELETE FROM profiles 
WHERE role = 'promoter' 
AND email NOT LIKE 'admin@%';
RAISE NOTICE '✅ Deleted all promoter profiles (kept admin)';

-- Delete promoter auth users (keep admin)
DELETE FROM auth.users 
WHERE id IN (
  SELECT id FROM auth.users 
  WHERE (email LIKE '%@brightplanet.com' OR email LIKE 'promo%@brightplanet.com')
  AND email NOT LIKE 'admin@%'
);
RAISE NOTICE '✅ Deleted all promoter auth users (kept admin)';

-- =====================================================
-- STEP 4: RESET ADMIN USER (OPTIONAL)
-- =====================================================

-- Reset admin PIN balance to 0
UPDATE profiles 
SET available_pins = 0,
    wallet_balance = 0
WHERE role = 'admin';
RAISE NOTICE '✅ Reset admin PIN balance and wallet to 0';

-- =====================================================
-- STEP 5: VERIFY CLEANUP
-- =====================================================

-- Show final counts
DO $$
DECLARE
  admin_count INTEGER;
  promoter_count INTEGER;
  customer_count INTEGER;
  pin_request_count INTEGER;
  pin_transaction_count INTEGER;
  commission_count INTEGER;
  withdrawal_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO admin_count FROM profiles WHERE role = 'admin';
  SELECT COUNT(*) INTO promoter_count FROM profiles WHERE role = 'promoter';
  SELECT COUNT(*) INTO customer_count FROM profiles WHERE role = 'customer';
  SELECT COUNT(*) INTO pin_request_count FROM pin_requests;
  SELECT COUNT(*) INTO pin_transaction_count FROM pin_transactions;
  SELECT COUNT(*) INTO commission_count FROM affiliate_commissions;
  SELECT COUNT(*) INTO withdrawal_count FROM withdrawal_requests;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'DATABASE RESET COMPLETE!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Remaining Records:';
  RAISE NOTICE '- Admins: %', admin_count;
  RAISE NOTICE '- Promoters: %', promoter_count;
  RAISE NOTICE '- Customers: %', customer_count;
  RAISE NOTICE '- PIN Requests: %', pin_request_count;
  RAISE NOTICE '- PIN Transactions: %', pin_transaction_count;
  RAISE NOTICE '- Commissions: %', commission_count;
  RAISE NOTICE '- Withdrawals: %', withdrawal_count;
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Database is now fresh and ready!';
  RAISE NOTICE '========================================';
END $$;

COMMIT;

-- =====================================================
-- OPTIONAL: DELETE ADMIN TOO (UNCOMMENT IF NEEDED)
-- =====================================================
-- If you want to delete admin and start completely fresh:
-- 
-- BEGIN;
-- DELETE FROM profiles WHERE role = 'admin';
-- DELETE FROM auth.users WHERE email LIKE 'admin@%';
-- RAISE NOTICE '✅ Deleted admin user - completely fresh start!';
-- COMMIT;
