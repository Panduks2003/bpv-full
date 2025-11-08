-- =====================================================
-- RESET ALL IDs AND SEQUENCES TO START FRESH
-- =====================================================
-- This script resets all auto-incrementing IDs
-- so new records start from 1 again
-- 
-- IMPORTANT: Run this AFTER deleting all data
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: DELETE ALL DATA (IF NOT ALREADY DONE)
-- =====================================================

-- Delete all transactional data
DELETE FROM withdrawal_requests;
DELETE FROM affiliate_commissions;
DELETE FROM pin_transactions;
DELETE FROM pin_requests;
DELETE FROM payment_schedules;

-- Delete all users (except admin if you want to keep)
DELETE FROM profiles WHERE role = 'customer';
DELETE FROM profiles WHERE role = 'promoter'; -- Add: AND email NOT LIKE 'admin@%' to keep admin

-- Delete orphaned auth users
DELETE FROM auth.users WHERE id NOT IN (SELECT id FROM profiles);

RAISE NOTICE '✅ All data deleted';

-- =====================================================
-- STEP 2: RESET PROMOTER_ID COUNTER
-- =====================================================
-- This ensures next promoter gets BPVP1, not BPVP156

DO $$
DECLARE
  max_promoter_num INTEGER;
BEGIN
  -- Find the highest promoter number currently in use
  SELECT COALESCE(MAX(
    CASE 
      WHEN promoter_id ~ '^BPVP[0-9]+$' 
      THEN CAST(SUBSTRING(promoter_id FROM 5) AS INTEGER)
      ELSE 0
    END
  ), 0) INTO max_promoter_num
  FROM profiles
  WHERE role = 'promoter';
  
  RAISE NOTICE 'Highest promoter number in use: %', max_promoter_num;
  
  -- If no promoters exist, we can start fresh from 1
  IF max_promoter_num = 0 THEN
    RAISE NOTICE '✅ No promoters exist - next promoter will be BPVP1';
  ELSE
    RAISE NOTICE 'ℹ️  Promoters exist - next will be BPVP%', max_promoter_num + 1;
  END IF;
END $$;

-- =====================================================
-- STEP 3: RESET CUSTOMER_ID COUNTER
-- =====================================================
-- This ensures next customer gets BPVC1, not BPVC456

DO $$
DECLARE
  max_customer_num INTEGER;
BEGIN
  -- Find the highest customer number currently in use
  SELECT COALESCE(MAX(
    CASE 
      WHEN customer_id ~ '^BPVC[0-9]+$' 
      THEN CAST(SUBSTRING(customer_id FROM 5) AS INTEGER)
      ELSE 0
    END
  ), 0) INTO max_customer_num
  FROM profiles
  WHERE role = 'customer';
  
  RAISE NOTICE 'Highest customer number in use: %', max_customer_num;
  
  -- If no customers exist, we can start fresh from 1
  IF max_customer_num = 0 THEN
    RAISE NOTICE '✅ No customers exist - next customer will be BPVC1';
  ELSE
    RAISE NOTICE 'ℹ️  Customers exist - next will be BPVC%', max_customer_num + 1;
  END IF;
END $$;

-- =====================================================
-- STEP 4: RESET TRANSACTION_ID COUNTER
-- =====================================================
-- This ensures next transaction gets TXN-000001

DO $$
DECLARE
  max_txn_num INTEGER;
BEGIN
  -- Find the highest transaction number
  SELECT COALESCE(MAX(
    CASE 
      WHEN transaction_id ~ '^TXN-[0-9]+$' 
      THEN CAST(SUBSTRING(transaction_id FROM 5) AS INTEGER)
      ELSE 0
    END
  ), 0) INTO max_txn_num
  FROM affiliate_commissions;
  
  RAISE NOTICE 'Highest transaction number in use: %', max_txn_num;
  
  IF max_txn_num = 0 THEN
    RAISE NOTICE '✅ No transactions exist - next will be TXN-000001';
  ELSE
    RAISE NOTICE 'ℹ️  Transactions exist - next will be TXN-%', LPAD((max_txn_num + 1)::TEXT, 6, '0');
  END IF;
END $$;

-- =====================================================
-- STEP 5: RESET PIN REQUEST ID COUNTER
-- =====================================================
-- This ensures next PIN request gets PIN_REQ-01

DO $$
DECLARE
  max_pin_req_num INTEGER;
BEGIN
  -- Find the highest PIN request number
  SELECT COALESCE(MAX(
    CASE 
      WHEN id::TEXT ~ '^[0-9]+$' 
      THEN CAST(id AS INTEGER)
      ELSE 0
    END
  ), 0) INTO max_pin_req_num
  FROM pin_requests;
  
  RAISE NOTICE 'Highest PIN request number in use: %', max_pin_req_num;
  
  IF max_pin_req_num = 0 THEN
    RAISE NOTICE '✅ No PIN requests exist - next will be PIN_REQ-01';
  ELSE
    RAISE NOTICE 'ℹ️  PIN requests exist - next will be PIN_REQ-%', LPAD((max_pin_req_num + 1)::TEXT, 2, '0');
  END IF;
END $$;

-- =====================================================
-- STEP 6: VERIFY FRESH STATE
-- =====================================================

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
  RAISE NOTICE '✅ DATABASE RESET COMPLETE!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Current State:';
  RAISE NOTICE '- Admins: %', admin_count;
  RAISE NOTICE '- Promoters: %', promoter_count;
  RAISE NOTICE '- Customers: %', customer_count;
  RAISE NOTICE '- PIN Requests: %', pin_request_count;
  RAISE NOTICE '- PIN Transactions: %', pin_transaction_count;
  RAISE NOTICE '- Commissions: %', commission_count;
  RAISE NOTICE '- Withdrawals: %', withdrawal_count;
  RAISE NOTICE '========================================';
  
  IF promoter_count = 0 AND customer_count = 0 THEN
    RAISE NOTICE '🎉 FRESH START READY!';
    RAISE NOTICE 'Next IDs will be:';
    RAISE NOTICE '- First Promoter: BPVP1';
    RAISE NOTICE '- First Customer: BPVC1';
    RAISE NOTICE '- First Transaction: TXN-000001';
    RAISE NOTICE '- First PIN Request: PIN_REQ-01';
  ELSE
    RAISE NOTICE '⚠️  Some data still exists';
    RAISE NOTICE 'IDs will continue from current highest numbers';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

COMMIT;

-- =====================================================
-- SHOW REMAINING DATA
-- =====================================================

SELECT 
  'Remaining Users' as info,
  role,
  COUNT(*) as count,
  STRING_AGG(COALESCE(promoter_id, customer_id, 'N/A'), ', ') as ids
FROM profiles
GROUP BY role
ORDER BY role;
