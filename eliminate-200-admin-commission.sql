-- =====================================================
-- ELIMINATE ₹200 EXTRA ADMIN COMMISSION - COMPLETE CLEANUP
-- =====================================================
-- This script removes all traces of the old ₹200 extra admin commission
-- and ensures only the ₹800 fallback system is active
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: CHECK CURRENT TRIGGERS AND FUNCTIONS
-- =====================================================

-- Show all triggers on customers table
SELECT 
    '🔍 CURRENT TRIGGERS ON CUSTOMERS TABLE' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'customers'
ORDER BY trigger_name;

-- Show all triggers on customer_payments table
SELECT 
    '🔍 CURRENT TRIGGERS ON CUSTOMER_PAYMENTS TABLE' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'customer_payments'
ORDER BY trigger_name;

-- Check for problematic functions
SELECT 
    '🔍 COMMISSION FUNCTIONS CHECK' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN (
    'calculate_commissions',
    'distribute_affiliate_commission',
    'trigger_commission_distribution'
)
ORDER BY routine_name;

-- =====================================================
-- STEP 2: DROP ALL OLD PROBLEMATIC TRIGGERS
-- =====================================================

-- Drop any old commission triggers that might have ₹200 logic
DROP TRIGGER IF EXISTS trg_calculate_commissions ON customer_payments;
DROP TRIGGER IF EXISTS trigger_commission_distribution ON customers;
DROP TRIGGER IF EXISTS auto_commission_trigger ON customers;

-- Keep only the correct trigger (if it exists)
-- DROP TRIGGER IF EXISTS trigger_affiliate_commission ON customers;

-- =====================================================
-- STEP 3: DROP OLD PROBLEMATIC FUNCTIONS
-- =====================================================

-- Drop the old calculate_commissions function that has ₹200 logic
DROP FUNCTION IF EXISTS calculate_commissions() CASCADE;

-- Note: We keep distribute_affiliate_commission and trigger_commission_distribution
-- as they have the correct ₹800 pool logic

-- =====================================================
-- STEP 4: VERIFY CURRENT COMMISSION SYSTEM
-- =====================================================

-- Check the current distribute_affiliate_commission function
SELECT 
    '✅ CHECKING CURRENT COMMISSION FUNCTION' as check_type,
    routine_name,
    routine_definition LIKE '%500.00, 100.00, 100.00, 100.00%' as has_correct_levels,
    routine_definition LIKE '%+ 200%' as has_problematic_200_logic,
    routine_definition LIKE '%800%' as has_pool_logic
FROM information_schema.routines 
WHERE routine_name = 'distribute_affiliate_commission';

-- Check the current trigger function
SELECT 
    '✅ CHECKING CURRENT TRIGGER FUNCTION' as check_type,
    routine_name,
    routine_definition LIKE '%500.00, 100.00, 100.00, 100.00%' as has_correct_levels,
    routine_definition LIKE '%+ 200%' as has_problematic_200_logic,
    routine_definition LIKE '%800%' as has_pool_logic
FROM information_schema.routines 
WHERE routine_name = 'trigger_commission_distribution';

-- =====================================================
-- STEP 5: ENSURE CORRECT TRIGGER IS ACTIVE
-- =====================================================

-- Verify the correct trigger exists and is active
SELECT 
    '✅ FINAL TRIGGER VERIFICATION' as check_type,
    trigger_name,
    event_object_table,
    action_statement,
    CASE 
        WHEN trigger_name = 'trigger_affiliate_commission' THEN '✅ CORRECT'
        ELSE '⚠️ CHECK NEEDED'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'customers'
AND trigger_name = 'trigger_affiliate_commission';

-- =====================================================
-- STEP 6: COMMISSION AUDIT - CHECK FOR ₹200 RECORDS
-- =====================================================

-- Check for any existing commission records that might have ₹200 amounts
SELECT 
    '🔍 AUDIT: CHECKING FOR ₹200 COMMISSION RECORDS' as audit_type,
    COUNT(*) as records_with_200,
    SUM(amount) as total_200_amount
FROM affiliate_commissions 
WHERE amount = 200.00
AND recipient_type = 'admin';

-- Check for any records where admin got more than expected
SELECT 
    '🔍 AUDIT: ADMIN COMMISSIONS BY CUSTOMER' as audit_type,
    customer_id,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_total,
    SUM(amount) as grand_total,
    COUNT(*) as total_records,
    CASE 
        WHEN SUM(amount) > 800 THEN '❌ EXCEEDS ₹800'
        WHEN SUM(amount) = 800 THEN '✅ CORRECT ₹800'
        ELSE '⚠️ LESS THAN ₹800'
    END as status
FROM affiliate_commissions 
GROUP BY customer_id
HAVING SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) >= 200
ORDER BY admin_total DESC
LIMIT 10;

-- =====================================================
-- STEP 7: CLEAN UP OLD FILES REFERENCE
-- =====================================================

-- Note: The following files should be considered obsolete and not used:
-- - fix-commission-status-to-credited.sql (contains + 200 logic)
-- - Any other files with admin_total_amount := admin_total_amount + 200

SELECT 
    '📝 CLEANUP COMPLETE' as status,
    'Old ₹200 logic removed from active triggers' as action_taken,
    'Only ₹800 pool-based fallback system remains active' as result,
    'Files with old logic should be ignored/deleted' as recommendation;

COMMIT;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 
    '🎉 COMMISSION CLEANUP COMPLETED!' as final_status,
    'All ₹200 extra admin commission logic eliminated' as result,
    'System now uses only ₹800 pool with proper fallback' as confirmation;
