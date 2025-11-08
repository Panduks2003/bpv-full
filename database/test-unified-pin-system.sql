-- =====================================================
-- UNIFIED PIN TRANSACTION SYSTEM - COMPREHENSIVE TESTING
-- =====================================================
-- End-to-end testing of the unified PIN system

BEGIN;

-- =====================================================
-- 1. SETUP TEST DATA
-- =====================================================

-- Create test admin user
INSERT INTO profiles (id, name, email, role, pins, created_at) 
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Test Admin',
    'admin@test.com',
    'admin',
    0,
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    pins = EXCLUDED.pins;

-- Create test promoter
INSERT INTO profiles (id, name, email, role, pins, created_at) 
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'Test Promoter',
    'promoter@test.com',
    'promoter',
    5,
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    pins = EXCLUDED.pins;

-- Create test customer
INSERT INTO profiles (id, name, email, role, created_at) 
VALUES (
    '00000000-0000-0000-0000-000000000003',
    'Test Customer',
    'customer@test.com',
    'customer',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    role = EXCLUDED.role;

-- =====================================================
-- 2. TEST ADMIN PIN ALLOCATION
-- =====================================================

SELECT 'TEST_1: Admin PIN Allocation' as test_name;

-- Test admin allocating 10 PINs to promoter
SELECT admin_allocate_pins(
    '00000000-0000-0000-0000-000000000002'::UUID, -- promoter
    10, -- amount
    '00000000-0000-0000-0000-000000000001'::UUID  -- admin
) as allocation_result;

-- Verify promoter balance increased
SELECT 'Promoter balance after allocation:' as check_type, pins 
FROM profiles 
WHERE id = '00000000-0000-0000-0000-000000000002';

-- Verify transaction was logged
SELECT 'Transaction logged:' as check_type, 
       transaction_id, action_type, pin_change_value, balance_after, note
FROM pin_transactions 
WHERE user_id = '00000000-0000-0000-0000-000000000002' 
  AND action_type = 'admin_allocation'
ORDER BY created_at DESC 
LIMIT 1;

-- =====================================================
-- 3. TEST CUSTOMER CREATION PIN DEDUCTION
-- =====================================================

SELECT 'TEST_2: Customer Creation PIN Deduction' as test_name;

-- Test PIN deduction for customer creation
SELECT deduct_pin_for_customer_creation(
    '00000000-0000-0000-0000-000000000002'::UUID, -- promoter
    '00000000-0000-0000-0000-000000000003'::UUID, -- customer
    'Test Customer'
) as deduction_result;

-- Verify promoter balance decreased
SELECT 'Promoter balance after customer creation:' as check_type, pins 
FROM profiles 
WHERE id = '00000000-0000-0000-0000-000000000002';

-- Verify transaction was logged
SELECT 'Customer creation transaction:' as check_type,
       transaction_id, action_type, pin_change_value, balance_after, note
FROM pin_transactions 
WHERE user_id = '00000000-0000-0000-0000-000000000002' 
  AND action_type = 'customer_creation'
ORDER BY created_at DESC 
LIMIT 1;

-- =====================================================
-- 4. TEST ADMIN PIN DEDUCTION
-- =====================================================

SELECT 'TEST_3: Admin PIN Deduction' as test_name;

-- Test admin deducting 3 PINs from promoter
SELECT admin_deduct_pins(
    '00000000-0000-0000-0000-000000000002'::UUID, -- promoter
    3, -- amount
    '00000000-0000-0000-0000-000000000001'::UUID  -- admin
) as deduction_result;

-- Verify promoter balance decreased
SELECT 'Promoter balance after deduction:' as check_type, pins 
FROM profiles 
WHERE id = '00000000-0000-0000-0000-000000000002';

-- Verify transaction was logged
SELECT 'Deduction transaction:' as check_type,
       transaction_id, action_type, pin_change_value, balance_after, note
FROM pin_transactions 
WHERE user_id = '00000000-0000-0000-0000-000000000002' 
  AND action_type = 'admin_deduction'
ORDER BY created_at DESC 
LIMIT 1;

-- =====================================================
-- 5. TEST INSUFFICIENT BALANCE HANDLING
-- =====================================================

SELECT 'TEST_4: Insufficient Balance Handling' as test_name;

-- Try to deduct more PINs than available (should fail)
SELECT admin_deduct_pins(
    '00000000-0000-0000-0000-000000000002'::UUID, -- promoter
    100, -- amount (more than available)
    '00000000-0000-0000-0000-000000000001'::UUID  -- admin
) as insufficient_balance_test;

-- =====================================================
-- 6. TEST NOTE GENERATION
-- =====================================================

SELECT 'TEST_5: Note Generation' as test_name;

-- Test note generation for different action types
SELECT 'Customer creation note:' as note_type,
       generate_pin_transaction_note('customer_creation', -1, 'John Doe') as generated_note
UNION ALL
SELECT 'Admin allocation note:' as note_type,
       generate_pin_transaction_note('admin_allocation', 5, NULL) as generated_note
UNION ALL
SELECT 'Admin deduction note:' as note_type,
       generate_pin_transaction_note('admin_deduction', -3, NULL) as generated_note;

-- =====================================================
-- 7. TEST TRANSACTION HISTORY
-- =====================================================

SELECT 'TEST_6: Transaction History' as test_name;

-- Get all transactions for the test promoter
SELECT 'All promoter transactions:' as summary,
       COUNT(*) as total_transactions,
       SUM(CASE WHEN action_type = 'admin_allocation' THEN 1 ELSE 0 END) as allocations,
       SUM(CASE WHEN action_type = 'customer_creation' THEN 1 ELSE 0 END) as customer_creations,
       SUM(CASE WHEN action_type = 'admin_deduction' THEN 1 ELSE 0 END) as deductions
FROM pin_transactions 
WHERE user_id = '00000000-0000-0000-0000-000000000002';

-- Show detailed transaction history
SELECT 'Transaction History:' as detail_type,
       transaction_id,
       action_type,
       pin_change_value,
       balance_before,
       balance_after,
       note,
       created_at
FROM pin_transactions 
WHERE user_id = '00000000-0000-0000-0000-000000000002'
ORDER BY created_at ASC;

-- =====================================================
-- 8. TEST BALANCE CONSISTENCY
-- =====================================================

SELECT 'TEST_7: Balance Consistency Check' as test_name;

-- Calculate expected balance from transactions
WITH balance_calculation AS (
    SELECT 
        5 as initial_balance, -- Starting balance
        COALESCE(SUM(pin_change_value), 0) as total_changes
    FROM pin_transactions 
    WHERE user_id = '00000000-0000-0000-0000-000000000002'
),
current_balance AS (
    SELECT pins as actual_balance
    FROM profiles 
    WHERE id = '00000000-0000-0000-0000-000000000002'
)
SELECT 
    'Balance consistency:' as check_type,
    bc.initial_balance,
    bc.total_changes,
    (bc.initial_balance + bc.total_changes) as calculated_balance,
    cb.actual_balance,
    CASE 
        WHEN (bc.initial_balance + bc.total_changes) = cb.actual_balance 
        THEN '✅ CONSISTENT' 
        ELSE '❌ INCONSISTENT' 
    END as status
FROM balance_calculation bc, current_balance cb;

-- =====================================================
-- 9. TEST RLS POLICIES
-- =====================================================

SELECT 'TEST_8: Row Level Security' as test_name;

-- Test that RLS policies are working (this would need to be run with different user contexts)
SELECT 'RLS Policy Check:' as check_type,
       COUNT(*) as visible_transactions
FROM pin_transactions;

-- =====================================================
-- 10. PERFORMANCE TEST
-- =====================================================

SELECT 'TEST_9: Performance Test' as test_name;

-- Test bulk operations performance
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    i INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    -- Perform 10 rapid transactions
    FOR i IN 1..10 LOOP
        PERFORM admin_allocate_pins(
            '00000000-0000-0000-0000-000000000002'::UUID,
            1,
            '00000000-0000-0000-0000-000000000001'::UUID
        );
    END LOOP;
    
    end_time := clock_timestamp();
    
    RAISE NOTICE 'Performance Test: 10 transactions completed in % ms', 
        EXTRACT(MILLISECONDS FROM (end_time - start_time));
END $$;

-- =====================================================
-- 11. FINAL SYSTEM STATUS
-- =====================================================

SELECT 'FINAL_SYSTEM_STATUS' as status_type;

-- Show final balances
SELECT 'Final Balances:' as summary_type,
       name,
       role,
       pins as current_balance
FROM profiles 
WHERE id IN (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000003'
)
ORDER BY role, name;

-- Show transaction summary
SELECT 'Transaction Summary:' as summary_type,
       action_type,
       COUNT(*) as count,
       SUM(ABS(pin_change_value)) as total_pins,
       MIN(created_at) as first_transaction,
       MAX(created_at) as last_transaction
FROM pin_transactions
GROUP BY action_type
ORDER BY action_type;

-- Show system health
SELECT 'System Health:' as health_type,
       'pin_transactions' as table_name,
       COUNT(*) as record_count,
       COUNT(DISTINCT user_id) as unique_users,
       COUNT(DISTINCT action_type) as action_types,
       MIN(created_at) as oldest_transaction,
       MAX(created_at) as newest_transaction
FROM pin_transactions;

COMMIT;

-- =====================================================
-- 12. CLEANUP (OPTIONAL)
-- =====================================================

-- Uncomment the following to clean up test data
/*
DELETE FROM pin_transactions WHERE user_id IN (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000003'
);

DELETE FROM profiles WHERE id IN (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000003'
);
*/

SELECT '🎉 UNIFIED PIN SYSTEM TESTING COMPLETED! 🎉' as final_message;
