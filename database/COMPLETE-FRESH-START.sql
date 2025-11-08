-- =====================================================
-- COMPLETE FRESH START - ALL-IN-ONE SCRIPT
-- =====================================================
-- This script does EVERYTHING in one go:
-- 1. Deletes ALL data (keeps admin optional)
-- 2. Resets all ID counters
-- 3. Verifies fresh state
-- 
-- CHOOSE ONE OPTION BELOW:
-- =====================================================

-- =====================================================
-- OPTION 1: KEEP ADMIN (RECOMMENDED)
-- =====================================================
-- Uncomment this section to keep admin user

BEGIN;

-- Delete all transactional data
DELETE FROM withdrawal_requests;
RAISE NOTICE '✅ Deleted withdrawal requests';

DELETE FROM affiliate_commissions;
RAISE NOTICE '✅ Deleted commissions';

DELETE FROM pin_transactions;
RAISE NOTICE '✅ Deleted PIN transactions';

DELETE FROM pin_requests;
RAISE NOTICE '✅ Deleted PIN requests';

DELETE FROM payment_schedules;
RAISE NOTICE '✅ Deleted payment schedules';

-- Delete all customers
DELETE FROM profiles WHERE role = 'customer';
RAISE NOTICE '✅ Deleted all customers';

-- Delete customer auth users
DELETE FROM auth.users 
WHERE email LIKE '%@customer.brightplanet.com'
   OR email LIKE 'cust%@brightplanet.com';
RAISE NOTICE '✅ Deleted customer auth users';

-- Delete all promoters (keep admin)
DELETE FROM profiles 
WHERE role = 'promoter' 
  AND email NOT LIKE 'admin@%';
RAISE NOTICE '✅ Deleted all promoters (kept admin)';

-- Delete promoter auth users (keep admin)
DELETE FROM auth.users 
WHERE (email LIKE '%@brightplanet.com' OR email LIKE 'promo%@brightplanet.com')
  AND email NOT LIKE 'admin@%';
RAISE NOTICE '✅ Deleted promoter auth users (kept admin)';

-- Delete any orphaned auth users
DELETE FROM auth.users WHERE id NOT IN (SELECT id FROM profiles);
RAISE NOTICE '✅ Deleted orphaned auth users';

-- Reset admin balance
UPDATE profiles 
SET available_pins = 0,
    wallet_balance = 0
WHERE role = 'admin';
RAISE NOTICE '✅ Reset admin balance to 0';

-- Verify and show results
DO $$
DECLARE
  admin_count INTEGER;
  promoter_count INTEGER;
  customer_count INTEGER;
  pin_request_count INTEGER;
  commission_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO admin_count FROM profiles WHERE role = 'admin';
  SELECT COUNT(*) INTO promoter_count FROM profiles WHERE role = 'promoter';
  SELECT COUNT(*) INTO customer_count FROM profiles WHERE role = 'customer';
  SELECT COUNT(*) INTO pin_request_count FROM pin_requests;
  SELECT COUNT(*) INTO commission_count FROM affiliate_commissions;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '🎉 COMPLETE FRESH START DONE!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Current State:';
  RAISE NOTICE '- Admins: % (kept)', admin_count;
  RAISE NOTICE '- Promoters: %', promoter_count;
  RAISE NOTICE '- Customers: %', customer_count;
  RAISE NOTICE '- PIN Requests: %', pin_request_count;
  RAISE NOTICE '- Commissions: %', commission_count;
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Next IDs will be:';
  RAISE NOTICE '- First Promoter: BPVP1';
  RAISE NOTICE '- First Customer: BPVC1';
  RAISE NOTICE '- First Transaction: TXN-000001';
  RAISE NOTICE '- First PIN Request: PIN_REQ-01';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Ready for fresh start!';
  RAISE NOTICE '========================================';
END $$;

COMMIT;

-- Show remaining users
SELECT 
  role,
  COUNT(*) as count,
  STRING_AGG(email, ', ') as emails
FROM profiles
GROUP BY role
ORDER BY role;


-- =====================================================
-- OPTION 2: DELETE EVERYTHING INCLUDING ADMIN
-- =====================================================
-- Uncomment this section to delete admin too
-- (Comment out OPTION 1 above first)

/*
BEGIN;

-- Delete all data
DELETE FROM withdrawal_requests;
DELETE FROM affiliate_commissions;
DELETE FROM pin_transactions;
DELETE FROM pin_requests;
DELETE FROM payment_schedules;
DELETE FROM profiles;
DELETE FROM auth.users;

RAISE NOTICE '========================================';
RAISE NOTICE '🎉 COMPLETE WIPE DONE!';
RAISE NOTICE '========================================';
RAISE NOTICE 'All data deleted including admin';
RAISE NOTICE 'Next IDs will start from 1';
RAISE NOTICE '========================================';
RAISE NOTICE '⚠️  You need to create a new admin user!';
RAISE NOTICE '========================================';

COMMIT;

-- Verify everything is empty
SELECT 'profiles' as table_name, COUNT(*) as count FROM profiles
UNION ALL
SELECT 'auth.users', COUNT(*) FROM auth.users
UNION ALL
SELECT 'pin_requests', COUNT(*) FROM pin_requests
UNION ALL
SELECT 'commissions', COUNT(*) FROM affiliate_commissions;
*/


-- =====================================================
-- OPTIONAL: GIVE ADMIN STARTING PINS
-- =====================================================
-- Uncomment to give admin 100 PINs to start with

/*
UPDATE profiles 
SET available_pins = 100
WHERE role = 'admin';

SELECT 
  'Admin updated' as status,
  email,
  available_pins
FROM profiles 
WHERE role = 'admin';
*/
