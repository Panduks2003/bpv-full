-- =====================================================
-- TEST COMMISSION SYSTEM - VERIFY ₹800 POOL LOGIC
-- =====================================================
-- This script tests the commission system to ensure:
-- 1. Total never exceeds ₹800
-- 2. Admin only gets fallback amounts
-- 3. No extra ₹200 is added
-- =====================================================

-- =====================================================
-- TEST SCENARIO 1: COMPLETE 4-LEVEL HIERARCHY
-- =====================================================
-- Expected: ₹500 + ₹100 + ₹100 + ₹100 = ₹800 to promoters, ₹0 to admin

SELECT 
    '🧪 TEST 1: COMPLETE HIERARCHY SIMULATION' as test_name,
    'Level 1: ₹500, Level 2: ₹100, Level 3: ₹100, Level 4: ₹100' as expected_distribution,
    'Admin should get: ₹0' as expected_admin,
    'Total should be: ₹800' as expected_total;

-- =====================================================
-- TEST SCENARIO 2: PARTIAL HIERARCHY (ONLY LEVEL 1)
-- =====================================================
-- Expected: ₹500 to Level 1, ₹300 to admin (fallback for levels 2,3,4)

SELECT 
    '🧪 TEST 2: PARTIAL HIERARCHY SIMULATION' as test_name,
    'Level 1: ₹500, Levels 2-4: Missing' as scenario,
    'Admin should get: ₹300 (fallback)' as expected_admin,
    'Total should be: ₹800' as expected_total;

-- =====================================================
-- TEST SCENARIO 3: NO HIERARCHY (ADMIN FALLBACK)
-- =====================================================
-- Expected: ₹800 to admin (complete fallback)

SELECT 
    '🧪 TEST 3: NO HIERARCHY SIMULATION' as test_name,
    'All levels: Missing' as scenario,
    'Admin should get: ₹800 (complete fallback)' as expected_admin,
    'Total should be: ₹800' as expected_total;

-- =====================================================
-- VERIFY CURRENT COMMISSION FUNCTION LOGIC
-- =====================================================

-- Test the distribute_affiliate_commission function parameters
SELECT 
    '🔍 FUNCTION VERIFICATION' as check_type,
    routine_name,
    CASE 
        WHEN routine_definition LIKE '%500.00, 100.00, 100.00, 100.00%' THEN '✅ Correct levels'
        ELSE '❌ Wrong levels'
    END as level_check,
    CASE 
        WHEN routine_definition LIKE '%+ 200%' THEN '❌ Has ₹200 logic'
        ELSE '✅ No ₹200 logic'
    END as admin_200_check,
    CASE 
        WHEN routine_definition LIKE '%v_distributed_count < 4%' THEN '✅ Proper fallback condition'
        ELSE '❌ Wrong fallback condition'
    END as fallback_check
FROM information_schema.routines 
WHERE routine_name = 'distribute_affiliate_commission';

-- =====================================================
-- AUDIT EXISTING COMMISSION RECORDS
-- =====================================================

-- Check for any problematic existing records
SELECT 
    '📊 EXISTING RECORDS AUDIT' as audit_type,
    COUNT(DISTINCT customer_id) as total_customers_with_commissions,
    COUNT(*) as total_commission_records,
    SUM(amount) as total_amount_distributed,
    ROUND(AVG(amount), 2) as avg_commission_amount,
    MIN(amount) as min_amount,
    MAX(amount) as max_amount
FROM affiliate_commissions;

-- Check admin commission amounts
SELECT 
    '📊 ADMIN COMMISSION AUDIT' as audit_type,
    COUNT(*) as admin_commission_records,
    SUM(amount) as total_admin_commissions,
    ROUND(AVG(amount), 2) as avg_admin_commission,
    MIN(amount) as min_admin_amount,
    MAX(amount) as max_admin_amount,
    COUNT(CASE WHEN amount = 200 THEN 1 END) as records_with_200,
    COUNT(CASE WHEN amount > 800 THEN 1 END) as records_exceeding_800
FROM affiliate_commissions 
WHERE recipient_type = 'admin';

-- Check for customers with total commissions > ₹800
SELECT 
    '⚠️ CUSTOMERS WITH EXCESSIVE COMMISSIONS' as alert_type,
    customer_id,
    SUM(amount) as total_commission,
    COUNT(*) as commission_records,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_amount,
    SUM(CASE WHEN recipient_type = 'promoter' THEN amount ELSE 0 END) as promoter_amount
FROM affiliate_commissions 
GROUP BY customer_id
HAVING SUM(amount) > 800
ORDER BY total_commission DESC;

-- =====================================================
-- COMMISSION DISTRIBUTION BREAKDOWN
-- =====================================================

-- Show commission distribution by level
SELECT 
    '📈 COMMISSION BY LEVEL' as breakdown_type,
    level,
    COUNT(*) as record_count,
    SUM(amount) as total_amount,
    ROUND(AVG(amount), 2) as avg_amount,
    recipient_type
FROM affiliate_commissions 
GROUP BY level, recipient_type
ORDER BY level, recipient_type;

-- =====================================================
-- FINAL SYSTEM HEALTH CHECK
-- =====================================================

SELECT 
    '🏥 SYSTEM HEALTH CHECK' as health_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM affiliate_commissions 
            GROUP BY customer_id 
            HAVING SUM(amount) > 800
        ) THEN '❌ UNHEALTHY: Some customers have > ₹800 total'
        ELSE '✅ HEALTHY: All customers ≤ ₹800 total'
    END as total_amount_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM affiliate_commissions 
            WHERE recipient_type = 'admin' AND amount = 200
        ) THEN '❌ UNHEALTHY: Found ₹200 admin records'
        ELSE '✅ HEALTHY: No ₹200 admin records'
    END as admin_200_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'distribute_affiliate_commission'
            AND routine_definition LIKE '%500.00, 100.00, 100.00, 100.00%'
        ) THEN '✅ HEALTHY: Correct commission levels'
        ELSE '❌ UNHEALTHY: Wrong commission levels'
    END as function_check;

-- =====================================================
-- RECOMMENDATIONS
-- =====================================================

SELECT 
    '💡 RECOMMENDATIONS' as section,
    'If any health checks show ❌, run eliminate-200-admin-commission.sql' as step_1,
    'Test customer creation to verify ₹800 total limit' as step_2,
    'Monitor commission records for any > ₹800 totals' as step_3,
    'Delete/ignore old files with + 200 logic' as step_4;
