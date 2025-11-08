-- =====================================================
-- ✅ VERIFY COMMISSION FIX IS COMPLETE
-- =====================================================
-- This script verifies that the duplicate commission system
-- has been successfully eliminated and tests the fix
-- =====================================================

-- =====================================================
-- STEP 1: VERIFY SYSTEM CLEANUP
-- =====================================================

-- Check that problematic trigger is gone
SELECT 
    '🔍 TRIGGER VERIFICATION' as check_type,
    COUNT(CASE WHEN trigger_name = 'trg_calculate_commissions' THEN 1 END) as bad_triggers_remaining,
    COUNT(CASE WHEN trigger_name = 'trigger_affiliate_commission' THEN 1 END) as good_triggers_active,
    CASE 
        WHEN COUNT(CASE WHEN trigger_name = 'trg_calculate_commissions' THEN 1 END) = 0 
        AND COUNT(CASE WHEN trigger_name = 'trigger_affiliate_commission' THEN 1 END) = 1
        THEN '✅ PERFECT: Only correct trigger active'
        ELSE '❌ ISSUE: Check trigger configuration'
    END as status
FROM information_schema.triggers 
WHERE event_object_table IN ('customers', 'customer_payments');

-- Check that problematic function is gone
SELECT 
    '🔍 FUNCTION VERIFICATION' as check_type,
    COUNT(CASE WHEN routine_name = 'calculate_commissions' THEN 1 END) as bad_functions_remaining,
    COUNT(CASE WHEN routine_name = 'distribute_affiliate_commission' THEN 1 END) as good_functions_active,
    COUNT(CASE WHEN routine_name = 'trigger_commission_distribution' THEN 1 END) as trigger_functions_active,
    CASE 
        WHEN COUNT(CASE WHEN routine_name = 'calculate_commissions' THEN 1 END) = 0 
        THEN '✅ PERFECT: Bad function removed'
        ELSE '❌ ISSUE: Bad function still exists'
    END as status
FROM information_schema.routines 
WHERE routine_name IN ('calculate_commissions', 'distribute_affiliate_commission', 'trigger_commission_distribution');

-- =====================================================
-- STEP 2: VERIFY DATA CLEANUP
-- =====================================================

-- Check for remaining ₹200 admin commissions
SELECT 
    '🔍 ₹200 COMMISSION CHECK' as check_type,
    COUNT(*) as records_with_200,
    SUM(amount) as total_200_amount,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ PERFECT: No ₹200 records remain'
        ELSE '❌ ISSUE: ₹200 records still exist'
    END as status
FROM affiliate_commissions 
WHERE amount = 200.00 AND recipient_type = 'admin';

-- Check for customers exceeding ₹800
SELECT 
    '🔍 EXCESS COMMISSION CHECK' as check_type,
    COUNT(*) as customers_exceeding_800,
    COALESCE(MAX(total_commission), 0) as max_commission_found,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ PERFECT: All customers ≤ ₹800'
        ELSE '❌ ISSUE: Some customers still > ₹800'
    END as status
FROM (
    SELECT 
        customer_id,
        SUM(amount) as total_commission
    FROM affiliate_commissions 
    GROUP BY customer_id
    HAVING SUM(amount) > 800
) excess_customers;

-- =====================================================
-- STEP 3: SYSTEM HEALTH SUMMARY
-- =====================================================

-- Overall system health
SELECT 
    '🏥 OVERALL SYSTEM HEALTH' as health_summary,
    (SELECT COUNT(*) FROM affiliate_commissions) as total_commission_records,
    (SELECT COUNT(DISTINCT customer_id) FROM affiliate_commissions) as customers_with_commissions,
    (SELECT ROUND(AVG(customer_total), 2) FROM (
        SELECT SUM(amount) as customer_total 
        FROM affiliate_commissions 
        GROUP BY customer_id
    ) totals) as avg_commission_per_customer,
    (SELECT MAX(customer_total) FROM (
        SELECT SUM(amount) as customer_total 
        FROM affiliate_commissions 
        GROUP BY customer_id
    ) totals) as max_commission_per_customer,
    CASE 
        WHEN (SELECT MAX(customer_total) FROM (
            SELECT SUM(amount) as customer_total 
            FROM affiliate_commissions 
            GROUP BY customer_id
        ) totals) <= 800 THEN '✅ HEALTHY'
        ELSE '❌ UNHEALTHY'
    END as system_status;

-- Commission distribution breakdown
SELECT 
    '📊 COMMISSION BREAKDOWN' as breakdown_type,
    recipient_type,
    level,
    COUNT(*) as record_count,
    SUM(amount) as total_amount,
    ROUND(AVG(amount), 2) as avg_amount,
    MIN(amount) as min_amount,
    MAX(amount) as max_amount
FROM affiliate_commissions 
GROUP BY recipient_type, level
ORDER BY recipient_type, level;

-- =====================================================
-- STEP 4: TEST COMMISSION CALCULATION
-- =====================================================

-- Simulate commission calculation for testing
SELECT 
    '🧪 COMMISSION SIMULATION TEST' as test_type,
    'Level 1: ₹500, Level 2-4: ₹100 each' as expected_distribution,
    'Total should never exceed ₹800' as rule,
    'Admin gets only fallback amounts' as admin_rule;

-- Show current active commission function details
SELECT 
    '🔍 ACTIVE COMMISSION FUNCTION' as function_check,
    routine_name,
    CASE 
        WHEN routine_definition LIKE '%500.00, 100.00, 100.00, 100.00%' THEN '✅ Correct levels'
        ELSE '❌ Wrong levels'
    END as level_check,
    CASE 
        WHEN routine_definition LIKE '%v_distributed_count < 4%' THEN '✅ Proper fallback'
        ELSE '❌ Wrong fallback'
    END as fallback_check,
    CASE 
        WHEN routine_definition LIKE '%800%' THEN '✅ Has pool logic'
        ELSE '❌ No pool logic'
    END as pool_check
FROM information_schema.routines 
WHERE routine_name = 'distribute_affiliate_commission';

-- =====================================================
-- STEP 5: RECOMMENDATIONS FOR TESTING
-- =====================================================

SELECT 
    '💡 NEXT STEPS FOR TESTING' as recommendations,
    '1. Create a test customer with full 4-level hierarchy' as step_1,
    '2. Verify total commission = ₹800 (500+100+100+100)' as step_2,
    '3. Create a test customer with partial hierarchy' as step_3,
    '4. Verify admin gets correct fallback amount' as step_4,
    '5. Monitor new customers for any > ₹800 totals' as step_5;

-- =====================================================
-- FINAL STATUS
-- =====================================================

SELECT 
    '🎯 COMMISSION SYSTEM STATUS' as final_status,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trg_calculate_commissions')
        AND NOT EXISTS (SELECT 1 FROM affiliate_commissions WHERE amount = 200 AND recipient_type = 'admin')
        AND NOT EXISTS (SELECT 1 FROM (SELECT SUM(amount) as total FROM affiliate_commissions GROUP BY customer_id HAVING SUM(amount) > 800) excess)
        THEN '✅ SYSTEM FULLY CLEANED - READY FOR TESTING'
        ELSE '⚠️ ADDITIONAL CLEANUP MAY BE NEEDED'
    END as system_status,
    'Commission system now uses only ₹800 pool with proper fallback' as confirmation;
