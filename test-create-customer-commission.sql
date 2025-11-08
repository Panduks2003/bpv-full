-- =====================================================
-- 🧪 TEST: CREATE CUSTOMER AND VERIFY COMMISSION
-- =====================================================
-- This script creates a test customer and monitors the
-- commission distribution to verify ₹800 pool logic
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: SHOW CURRENT COMMISSION STATE (BEFORE)
-- =====================================================

SELECT '📊 COMMISSION STATE BEFORE CUSTOMER CREATION' as status;

-- Show current commission totals
SELECT 
    '📈 CURRENT TOTALS' as summary_type,
    COUNT(*) as total_commission_records,
    COUNT(DISTINCT customer_id) as customers_with_commissions,
    SUM(amount) as total_amount_distributed,
    ROUND(AVG(amount), 2) as avg_commission_amount
FROM affiliate_commissions;

-- Show breakdown by recipient type
SELECT 
    '📊 BY RECIPIENT TYPE' as breakdown,
    recipient_type,
    COUNT(*) as record_count,
    SUM(amount) as total_amount
FROM affiliate_commissions 
GROUP BY recipient_type
ORDER BY recipient_type;

-- =====================================================
-- STEP 2: CREATE TEST PROMOTER HIERARCHY
-- =====================================================

-- Create test promoters for 4-level hierarchy
INSERT INTO profiles (id, email, name, role, promoter_id, parent_promoter_id, created_at)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'test-level4@example.com', 'Test Level 4 Promoter', 'promoter', 'BPVP99', NULL, NOW()),
    ('22222222-2222-2222-2222-222222222222', 'test-level3@example.com', 'Test Level 3 Promoter', 'promoter', 'BPVP98', '11111111-1111-1111-1111-111111111111', NOW()),
    ('33333333-3333-3333-3333-333333333333', 'test-level2@example.com', 'Test Level 2 Promoter', 'promoter', 'BPVP97', '22222222-2222-2222-2222-222222222222', NOW()),
    ('44444444-4444-4444-4444-444444444444', 'test-level1@example.com', 'Test Level 1 Promoter', 'promoter', 'BPVP96', '33333333-3333-3333-3333-333333333333', NOW())
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    updated_at = NOW();

SELECT '✅ TEST PROMOTER HIERARCHY CREATED' as setup_status;

-- Show the hierarchy
SELECT 
    '🏗️ PROMOTER HIERARCHY' as hierarchy_check,
    name,
    promoter_id,
    CASE 
        WHEN parent_promoter_id IS NULL THEN 'Level 4 (Top)'
        WHEN parent_promoter_id = '11111111-1111-1111-1111-111111111111' THEN 'Level 3'
        WHEN parent_promoter_id = '22222222-2222-2222-2222-222222222222' THEN 'Level 2'
        WHEN parent_promoter_id = '33333333-3333-3333-3333-333333333333' THEN 'Level 1'
    END as hierarchy_level
FROM profiles 
WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222', 
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444'
)
ORDER BY hierarchy_level DESC;

-- =====================================================
-- STEP 3: CREATE TEST CUSTOMER
-- =====================================================

-- Create test customer under Level 1 promoter
INSERT INTO profiles (id, email, name, role, card_no, parent_promoter_id, created_at)
VALUES (
    '55555555-5555-5555-5555-555555555555',
    'test-customer@example.com',
    'Test Customer for Commission',
    'customer',
    'TEST001',
    '44444444-4444-4444-4444-444444444444', -- Level 1 promoter
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    updated_at = NOW();

SELECT '🎯 TEST CUSTOMER CREATED' as customer_status;

-- Show customer details
SELECT 
    '👤 CUSTOMER DETAILS' as customer_info,
    name,
    card_no,
    role,
    (SELECT name FROM profiles p2 WHERE p2.id = profiles.parent_promoter_id) as parent_promoter_name,
    (SELECT promoter_id FROM profiles p2 WHERE p2.id = profiles.parent_promoter_id) as parent_promoter_id
FROM profiles 
WHERE id = '55555555-5555-5555-5555-555555555555';

-- =====================================================
-- STEP 4: TRIGGER COMMISSION DISTRIBUTION
-- =====================================================

-- The commission should be automatically triggered by the customer creation
-- Let's wait a moment and then check the results

-- Manual trigger if needed (using the distribute_affiliate_commission function)
SELECT 
    '🔥 TRIGGERING COMMISSION DISTRIBUTION' as trigger_status,
    distribute_affiliate_commission(
        '55555555-5555-5555-5555-555555555555'::UUID, -- customer_id
        '44444444-4444-4444-4444-444444444444'::UUID  -- initiator_promoter_id (Level 1)
    ) as commission_result;

-- =====================================================
-- STEP 5: VERIFY COMMISSION DISTRIBUTION
-- =====================================================

-- Show commissions for our test customer
SELECT 
    '💰 COMMISSIONS FOR TEST CUSTOMER' as commission_check,
    ac.*,
    p.name as recipient_name,
    p.promoter_id as recipient_promoter_id
FROM affiliate_commissions ac
LEFT JOIN profiles p ON ac.recipient_id = p.id
WHERE ac.customer_id = '55555555-5555-5555-5555-555555555555'
ORDER BY ac.level;

-- Verify total commission for test customer
SELECT 
    '📊 COMMISSION TOTAL VERIFICATION' as total_check,
    customer_id,
    COUNT(*) as commission_records,
    SUM(amount) as total_commission,
    SUM(CASE WHEN recipient_type = 'promoter' THEN amount ELSE 0 END) as promoter_total,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_total,
    CASE 
        WHEN SUM(amount) = 800 THEN '✅ PERFECT: Exactly ₹800'
        WHEN SUM(amount) > 800 THEN '❌ ERROR: Exceeds ₹800'
        WHEN SUM(amount) < 800 THEN '⚠️ WARNING: Less than ₹800'
    END as status
FROM affiliate_commissions 
WHERE customer_id = '55555555-5555-5555-5555-555555555555'
GROUP BY customer_id;

-- Show commission breakdown by level
SELECT 
    '📈 COMMISSION BREAKDOWN BY LEVEL' as breakdown_type,
    level,
    recipient_type,
    amount,
    note,
    CASE 
        WHEN level = 1 AND amount = 500 THEN '✅ Level 1 Correct'
        WHEN level IN (2,3,4) AND amount = 100 THEN '✅ Level ' || level || ' Correct'
        WHEN level = 0 AND recipient_type = 'admin' THEN '✅ Admin Fallback'
        ELSE '❌ Unexpected Amount'
    END as validation
FROM affiliate_commissions 
WHERE customer_id = '55555555-5555-5555-5555-555555555555'
ORDER BY level;

-- =====================================================
-- STEP 6: SYSTEM HEALTH CHECK AFTER CREATION
-- =====================================================

-- Check overall system health after new customer
SELECT 
    '🏥 SYSTEM HEALTH AFTER CUSTOMER CREATION' as health_check,
    COUNT(*) as total_commission_records,
    COUNT(DISTINCT customer_id) as total_customers,
    SUM(amount) as total_amount_distributed,
    ROUND(AVG(customer_total), 2) as avg_per_customer,
    MAX(customer_total) as max_per_customer,
    CASE 
        WHEN MAX(customer_total) <= 800 THEN '✅ HEALTHY: All ≤ ₹800'
        ELSE '❌ UNHEALTHY: Some > ₹800'
    END as system_status
FROM (
    SELECT 
        customer_id,
        SUM(amount) as customer_total
    FROM affiliate_commissions 
    GROUP BY customer_id
) customer_totals;

-- =====================================================
-- STEP 7: CLEANUP TEST DATA (OPTIONAL)
-- =====================================================

-- Uncomment the following lines if you want to clean up test data
/*
DELETE FROM affiliate_commissions WHERE customer_id = '55555555-5555-5555-5555-555555555555';
DELETE FROM profiles WHERE id IN (
    '55555555-5555-5555-5555-555555555555',
    '44444444-4444-4444-4444-444444444444',
    '33333333-3333-3333-3333-333333333333',
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111'
);
SELECT '🧹 TEST DATA CLEANED UP' as cleanup_status;
*/

COMMIT;

-- =====================================================
-- FINAL RESULTS
-- =====================================================

SELECT 
    '🎉 CUSTOMER CREATION TEST COMPLETED!' as final_status,
    'Check the commission records above to verify ₹800 total' as instruction,
    'Expected: Level 1=₹500, Level 2-4=₹100 each, Total=₹800' as expected_result;
