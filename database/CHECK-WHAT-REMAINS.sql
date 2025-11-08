-- =====================================================
-- CHECK WHAT REMAINS IN DATABASE
-- =====================================================
-- Run this to see exactly what data is still there
-- =====================================================

-- Show all profiles by role
SELECT 
  '=== PROFILES BY ROLE ===' as info;

SELECT 
  role,
  COUNT(*) as count,
  STRING_AGG(DISTINCT email, ', ' ORDER BY email) as sample_emails
FROM profiles
GROUP BY role
ORDER BY role;

-- Show all promoters in detail
SELECT 
  '=== ALL PROMOTERS DETAIL ===' as info;

SELECT 
  id,
  email,
  name,
  promoter_id,
  available_pins,
  wallet_balance,
  created_at
FROM profiles
WHERE role = 'promoter'
ORDER BY created_at DESC
LIMIT 20;

-- Show all customers
SELECT 
  '=== CUSTOMERS COUNT ===' as info;

SELECT COUNT(*) as customer_count
FROM profiles
WHERE role = 'customer';

-- Show PIN requests
SELECT 
  '=== PIN REQUESTS COUNT ===' as info;

SELECT COUNT(*) as pin_request_count
FROM pin_requests;

-- Show PIN transactions
SELECT 
  '=== PIN TRANSACTIONS COUNT ===' as info;

SELECT COUNT(*) as pin_transaction_count
FROM pin_transactions;

-- Show commissions
SELECT 
  '=== COMMISSIONS COUNT ===' as info;

SELECT COUNT(*) as commission_count
FROM affiliate_commissions;

-- Show withdrawals
SELECT 
  '=== WITHDRAWALS COUNT ===' as info;

SELECT COUNT(*) as withdrawal_count
FROM withdrawal_requests;

-- Show auth users count
SELECT 
  '=== AUTH USERS COUNT ===' as info;

SELECT COUNT(*) as total_auth_users
FROM auth.users;

-- Show auth users without profiles
SELECT 
  '=== ORPHANED AUTH USERS ===' as info;

SELECT 
  au.id,
  au.email,
  au.created_at
FROM auth.users au
WHERE au.id NOT IN (SELECT id FROM profiles)
LIMIT 10;

-- Summary
SELECT 
  '=== SUMMARY ===' as info;

SELECT 
  'Profiles' as table_name,
  role,
  COUNT(*) as count
FROM profiles
GROUP BY role

UNION ALL

SELECT 'PIN Requests', 'all', COUNT(*) FROM pin_requests
UNION ALL
SELECT 'PIN Transactions', 'all', COUNT(*) FROM pin_transactions
UNION ALL
SELECT 'Commissions', 'all', COUNT(*) FROM affiliate_commissions
UNION ALL
SELECT 'Withdrawals', 'all', COUNT(*) FROM withdrawal_requests
UNION ALL
SELECT 'Auth Users', 'all', COUNT(*) FROM auth.users

ORDER BY table_name, role;
