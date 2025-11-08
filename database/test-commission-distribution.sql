-- =====================================================
-- COMMISSION DISTRIBUTION SYSTEM TEST SCRIPT
-- =====================================================
-- Tests the complete affiliate commission distribution workflow
-- Verifies ₹800 distribution across 4 levels with admin fallback
-- =====================================================

-- Enable detailed output
\set ECHO all
\set ON_ERROR_STOP on

BEGIN;

-- =====================================================
-- 1. SETUP TEST DATA
-- =====================================================

-- Clean up any existing test data
DELETE FROM affiliate_commissions WHERE note LIKE '%TEST%';
DELETE FROM promoter_wallet WHERE promoter_id IN (
    SELECT id FROM profiles WHERE email LIKE '%test%commission%'
);
DELETE FROM customers WHERE email LIKE '%test%commission%';

-- Create test promoter hierarchy (4 levels)
INSERT INTO profiles (id, name, email, role, parent_promoter, created_at) VALUES
    ('test-promoter-1', 'Test Promoter Level 1', 'test1@commission.test', 'promoter', NULL, NOW()),
    ('test-promoter-2', 'Test Promoter Level 2', 'test2@commission.test', 'promoter', 'test-promoter-1', NOW()),
    ('test-promoter-3', 'Test Promoter Level 3', 'test3@commission.test', 'promoter', 'test-promoter-2', NOW()),
    ('test-promoter-4', 'Test Promoter Level 4', 'test4@commission.test', 'promoter', 'test-promoter-3', NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    parent_promoter = EXCLUDED.parent_promoter;

-- Initialize wallets for test promoters
INSERT INTO promoter_wallet (promoter_id, balance, total_earned) VALUES
    ('test-promoter-1', 0, 0),
    ('test-promoter-2', 0, 0),
    ('test-promoter-3', 0, 0),
    ('test-promoter-4', 0, 0)
ON CONFLICT (promoter_id) DO UPDATE SET
    balance = 0,
    total_earned = 0,
    commission_count = 0;

-- Create test customer
INSERT INTO customers (id, customer_id, name, email, promoter_id, created_at) VALUES
    ('test-customer-1', 'TEST001', 'Test Customer Commission', 'customer@commission.test', 'test-promoter-4', NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    promoter_id = EXCLUDED.promoter_id;

-- Get admin ID for testing
DO $$
DECLARE
    v_admin_id UUID;
BEGIN
    SELECT id INTO v_admin_id FROM profiles WHERE role = 'admin' LIMIT 1;
    
    -- Initialize admin wallet if needed
    INSERT INTO admin_wallet (admin_id, balance, total_commission_received, unclaimed_commissions)
    VALUES (v_admin_id, 0, 0, 0)
    ON CONFLICT (admin_id) DO NOTHING;
END $$;

-- =====================================================
-- 2. TEST SCENARIO 1: FULL 4-LEVEL DISTRIBUTION
-- =====================================================

SELECT '=== TEST SCENARIO 1: Full 4-Level Distribution ===' as test_scenario;

-- Distribute commission for test customer
SELECT distribute_affiliate_commission('test-customer-1', 'test-promoter-4') as distribution_result_1;

-- Verify commission records
SELECT 
    'Commission Records' as verification,
    level,
    recipient_id,
    amount,
    status,
    note
FROM affiliate_commissions 
WHERE customer_id = 'test-customer-1'
ORDER BY level;

-- Verify wallet balances
SELECT 
    'Wallet Balances' as verification,
    p.name,
    pw.balance,
    pw.total_earned,
    pw.commission_count
FROM promoter_wallet pw
JOIN profiles p ON pw.promoter_id = p.id
WHERE pw.promoter_id IN ('test-promoter-1', 'test-promoter-2', 'test-promoter-3', 'test-promoter-4')
ORDER BY p.name;

-- Verify total distributed
SELECT 
    'Total Verification' as verification,
    SUM(amount) as total_distributed,
    COUNT(*) as commission_count
FROM affiliate_commissions 
WHERE customer_id = 'test-customer-1';

-- =====================================================
-- 3. TEST SCENARIO 2: PARTIAL HIERARCHY (2 LEVELS ONLY)
-- =====================================================

SELECT '=== TEST SCENARIO 2: Partial Hierarchy (2 levels only) ===' as test_scenario;

-- Clean up previous test
DELETE FROM affiliate_commissions WHERE customer_id = 'test-customer-2';

-- Create promoter with only 2 levels
INSERT INTO profiles (id, name, email, role, parent_promoter, created_at) VALUES
    ('test-promoter-5', 'Test Promoter Level 5', 'test5@commission.test', 'promoter', NULL, NOW()),
    ('test-promoter-6', 'Test Promoter Level 6', 'test6@commission.test', 'promoter', 'test-promoter-5', NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    parent_promoter = EXCLUDED.parent_promoter;

-- Initialize wallets
INSERT INTO promoter_wallet (promoter_id, balance, total_earned) VALUES
    ('test-promoter-5', 0, 0),
    ('test-promoter-6', 0, 0)
ON CONFLICT (promoter_id) DO UPDATE SET
    balance = 0,
    total_earned = 0,
    commission_count = 0;

-- Create customer with limited hierarchy
INSERT INTO customers (id, customer_id, name, email, promoter_id, created_at) VALUES
    ('test-customer-2', 'TEST002', 'Test Customer Limited', 'customer2@commission.test', 'test-promoter-6', NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    promoter_id = EXCLUDED.promoter_id;

-- Get admin balance before
DO $$
DECLARE
    v_admin_balance_before DECIMAL(10,2);
    v_admin_id UUID;
BEGIN
    SELECT id INTO v_admin_id FROM profiles WHERE role = 'admin' LIMIT 1;
    SELECT balance INTO v_admin_balance_before FROM admin_wallet WHERE admin_id = v_admin_id;
    RAISE NOTICE 'Admin balance before: %', v_admin_balance_before;
END $$;

-- Distribute commission (should go to admin for missing levels)
SELECT distribute_affiliate_commission('test-customer-2', 'test-promoter-6') as distribution_result_2;

-- Verify commission records
SELECT 
    'Commission Records (Partial)' as verification,
    level,
    recipient_type,
    amount,
    status,
    note
FROM affiliate_commissions 
WHERE customer_id = 'test-customer-2'
ORDER BY level;

-- Verify admin got the fallback amount
SELECT 
    'Admin Fallback Verification' as verification,
    aw.balance as admin_balance,
    aw.unclaimed_commissions,
    aw.commission_count as admin_commission_count
FROM admin_wallet aw
JOIN profiles p ON aw.admin_id = p.id
WHERE p.role = 'admin';

-- =====================================================
-- 4. TEST SCENARIO 3: NO HIERARCHY (ADMIN GETS ALL)
-- =====================================================

SELECT '=== TEST SCENARIO 3: No Hierarchy (Admin gets all) ===' as test_scenario;

-- Create standalone promoter with no parent
INSERT INTO profiles (id, name, email, role, parent_promoter, created_at) VALUES
    ('test-promoter-7', 'Test Promoter Standalone', 'test7@commission.test', 'promoter', NULL, NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    parent_promoter = NULL;

-- Initialize wallet
INSERT INTO promoter_wallet (promoter_id, balance, total_earned) VALUES
    ('test-promoter-7', 0, 0)
ON CONFLICT (promoter_id) DO UPDATE SET
    balance = 0,
    total_earned = 0,
    commission_count = 0;

-- Create customer
INSERT INTO customers (id, customer_id, name, email, promoter_id, created_at) VALUES
    ('test-customer-3', 'TEST003', 'Test Customer Standalone', 'customer3@commission.test', 'test-promoter-7', NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    promoter_id = EXCLUDED.promoter_id;

-- Distribute commission (should mostly go to admin)
SELECT distribute_affiliate_commission('test-customer-3', 'test-promoter-7') as distribution_result_3;

-- Verify commission records
SELECT 
    'Commission Records (Standalone)' as verification,
    level,
    recipient_type,
    amount,
    status,
    note
FROM affiliate_commissions 
WHERE customer_id = 'test-customer-3'
ORDER BY level;

-- =====================================================
-- 5. COMPREHENSIVE VERIFICATION
-- =====================================================

SELECT '=== COMPREHENSIVE VERIFICATION ===' as test_scenario;

-- Total commissions distributed
SELECT 
    'Total System Stats' as verification,
    COUNT(*) as total_commission_records,
    SUM(amount) as total_amount_distributed,
    COUNT(DISTINCT customer_id) as customers_processed
FROM affiliate_commissions
WHERE customer_id IN ('test-customer-1', 'test-customer-2', 'test-customer-3');

-- Verify each customer got exactly ₹800
SELECT 
    'Per Customer Verification' as verification,
    customer_id,
    SUM(amount) as total_per_customer,
    COUNT(*) as commission_count
FROM affiliate_commissions
WHERE customer_id IN ('test-customer-1', 'test-customer-2', 'test-customer-3')
GROUP BY customer_id
ORDER BY customer_id;

-- Verify commission levels distribution
SELECT 
    'Level Distribution' as verification,
    level,
    COUNT(*) as count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM affiliate_commissions
WHERE customer_id IN ('test-customer-1', 'test-customer-2', 'test-customer-3')
GROUP BY level
ORDER BY level;

-- Verify recipient types
SELECT 
    'Recipient Type Distribution' as verification,
    recipient_type,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM affiliate_commissions
WHERE customer_id IN ('test-customer-1', 'test-customer-2', 'test-customer-3')
GROUP BY recipient_type;

-- Verify all commissions are credited
SELECT 
    'Status Verification' as verification,
    status,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM affiliate_commissions
WHERE customer_id IN ('test-customer-1', 'test-customer-2', 'test-customer-3')
GROUP BY status;

-- =====================================================
-- 6. PERFORMANCE TEST
-- =====================================================

SELECT '=== PERFORMANCE TEST ===' as test_scenario;

-- Time the commission distribution function
DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
BEGIN
    start_time := clock_timestamp();
    
    -- Run distribution function
    PERFORM distribute_affiliate_commission('test-customer-1', 'test-promoter-4');
    
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    RAISE NOTICE 'Commission distribution took: %', duration;
END $$;

-- =====================================================
-- 7. CLEANUP (OPTIONAL)
-- =====================================================

-- Uncomment the following lines to clean up test data
/*
DELETE FROM affiliate_commissions WHERE customer_id IN ('test-customer-1', 'test-customer-2', 'test-customer-3');
DELETE FROM customers WHERE id IN ('test-customer-1', 'test-customer-2', 'test-customer-3');
DELETE FROM promoter_wallet WHERE promoter_id LIKE 'test-promoter-%';
DELETE FROM profiles WHERE id LIKE 'test-promoter-%';
*/

-- =====================================================
-- TEST RESULTS SUMMARY
-- =====================================================

SELECT '=== TEST RESULTS SUMMARY ===' as summary;

SELECT 
    'PASS/FAIL CHECK' as check_type,
    CASE 
        WHEN (SELECT COUNT(DISTINCT customer_id) FROM affiliate_commissions WHERE customer_id IN ('test-customer-1', 'test-customer-2', 'test-customer-3')) = 3
        AND (SELECT SUM(amount) FROM affiliate_commissions WHERE customer_id IN ('test-customer-1', 'test-customer-2', 'test-customer-3')) = 2400 -- 3 customers × ₹800
        AND (SELECT COUNT(*) FROM affiliate_commissions WHERE status != 'credited' AND customer_id IN ('test-customer-1', 'test-customer-2', 'test-customer-3')) = 0
        THEN '✅ ALL TESTS PASSED'
        ELSE '❌ SOME TESTS FAILED'
    END as result;

COMMIT;

-- Success message
SELECT '🎉 Commission Distribution System Test Completed Successfully!' as final_message;
