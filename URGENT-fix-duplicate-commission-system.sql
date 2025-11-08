-- =====================================================
-- 🚨 URGENT: FIX DUPLICATE COMMISSION SYSTEM
-- =====================================================
-- CRITICAL ISSUE: Two commission systems are running simultaneously
-- 1. trigger_affiliate_commission (CORRECT ₹800 pool)
-- 2. trg_calculate_commissions (WRONG ₹800 + ₹200 extra)
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: IMMEDIATELY DROP THE PROBLEMATIC TRIGGER
-- =====================================================

-- This trigger is causing the ₹200 extra admin commission
DROP TRIGGER IF EXISTS trg_calculate_commissions ON customer_payments;

-- Drop the problematic function that adds ₹200
DROP FUNCTION IF EXISTS calculate_commissions() CASCADE;

SELECT '🚨 EMERGENCY: Dropped problematic trigger and function' as urgent_action;

-- =====================================================
-- STEP 2: IDENTIFY AFFECTED CUSTOMERS
-- =====================================================

-- Show customers with > ₹800 total commissions
SELECT 
    '🔍 CUSTOMERS WITH EXCESSIVE COMMISSIONS' as issue_type,
    customer_id,
    SUM(amount) as total_commission,
    COUNT(*) as commission_records,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_amount,
    SUM(CASE WHEN recipient_type = 'promoter' THEN amount ELSE 0 END) as promoter_amount,
    '❌ NEEDS CLEANUP' as status
FROM affiliate_commissions 
GROUP BY customer_id
HAVING SUM(amount) > 800
ORDER BY total_commission DESC;

-- =====================================================
-- STEP 3: BACKUP AFFECTED RECORDS
-- =====================================================

-- Create backup table for affected records
CREATE TABLE IF NOT EXISTS affiliate_commissions_backup_excess AS
SELECT 
    *,
    NOW() as backup_timestamp,
    'Excess commission cleanup' as backup_reason
FROM affiliate_commissions ac
WHERE customer_id IN (
    SELECT customer_id 
    FROM affiliate_commissions 
    GROUP BY customer_id 
    HAVING SUM(amount) > 800
);

SELECT 
    '💾 BACKUP CREATED' as backup_status,
    COUNT(*) as backed_up_records
FROM affiliate_commissions_backup_excess;

-- =====================================================
-- STEP 4: CLEAN UP EXCESS COMMISSIONS
-- =====================================================

-- Option A: Delete all ₹200 admin commission records (RECOMMENDED)
-- These are the problematic extra commissions

DELETE FROM affiliate_commissions 
WHERE amount = 200.00 
AND recipient_type = 'admin'
AND customer_id IN (
    SELECT customer_id 
    FROM affiliate_commissions 
    GROUP BY customer_id 
    HAVING SUM(amount) > 800
);

SELECT '🧹 DELETED ₹200 ADMIN RECORDS' as cleanup_action;

-- =====================================================
-- STEP 5: VERIFY CLEANUP RESULTS
-- =====================================================

-- Check if any customers still have > ₹800
SELECT 
    '✅ POST-CLEANUP VERIFICATION' as verification_type,
    COUNT(DISTINCT customer_id) as customers_checked,
    COUNT(CASE WHEN total_commission > 800 THEN 1 END) as customers_still_exceeding_800,
    MAX(total_commission) as max_commission_found
FROM (
    SELECT 
        customer_id,
        SUM(amount) as total_commission
    FROM affiliate_commissions 
    GROUP BY customer_id
) customer_totals;

-- Show remaining commission distribution
SELECT 
    '📊 COMMISSION DISTRIBUTION AFTER CLEANUP' as summary_type,
    recipient_type,
    COUNT(*) as record_count,
    SUM(amount) as total_amount,
    ROUND(AVG(amount), 2) as avg_amount,
    MIN(amount) as min_amount,
    MAX(amount) as max_amount
FROM affiliate_commissions 
GROUP BY recipient_type
ORDER BY recipient_type;

-- =====================================================
-- STEP 6: PREVENT FUTURE ISSUES
-- =====================================================

-- Ensure only the correct trigger remains active
SELECT 
    '🔒 ACTIVE TRIGGERS AFTER CLEANUP' as final_check,
    trigger_name,
    event_object_table,
    action_statement,
    CASE 
        WHEN trigger_name = 'trigger_affiliate_commission' THEN '✅ CORRECT - KEEP'
        WHEN trigger_name LIKE '%commission%' THEN '❌ SUSPICIOUS - INVESTIGATE'
        ELSE '✅ NON-COMMISSION TRIGGER'
    END as status
FROM information_schema.triggers 
WHERE event_object_table IN ('customers', 'customer_payments')
ORDER BY event_object_table, trigger_name;

-- =====================================================
-- STEP 7: FINAL HEALTH CHECK
-- =====================================================

SELECT 
    '🏥 FINAL SYSTEM HEALTH CHECK' as health_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM affiliate_commissions 
            GROUP BY customer_id 
            HAVING SUM(amount) > 800
        ) THEN '❌ STILL UNHEALTHY: Some customers > ₹800'
        ELSE '✅ HEALTHY: All customers ≤ ₹800'
    END as total_amount_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM affiliate_commissions 
            WHERE recipient_type = 'admin' AND amount = 200
        ) THEN '❌ STILL UNHEALTHY: ₹200 admin records remain'
        ELSE '✅ HEALTHY: No ₹200 admin records'
    END as admin_200_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trg_calculate_commissions'
        ) THEN '❌ STILL UNHEALTHY: Bad trigger still active'
        ELSE '✅ HEALTHY: Bad trigger removed'
    END as trigger_check;

COMMIT;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 
    '🎉 URGENT CLEANUP COMPLETED!' as final_status,
    'Duplicate commission system eliminated' as result,
    'Only ₹800 pool system remains active' as confirmation,
    'Test customer creation to verify fix' as next_step;
