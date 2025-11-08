-- =====================================================
-- 🎯 CREATE TEST CUSTOMER NOW - COMMISSION TEST
-- =====================================================
-- Using the correct table structure to create test customer
-- =====================================================

-- =====================================================
-- CREATE TEST CUSTOMER WITH CORRECT COLUMNS
-- =====================================================

-- Create test customer under Level 1 promoter
INSERT INTO profiles (
    id, 
    email, 
    name, 
    role, 
    customer_id,  -- This seems to be the card/customer number
    parent_promoter_id, 
    created_at
)
VALUES (
    '55555555-5555-5555-5555-555555555555',
    'test-customer@example.com',
    'Test Customer for Commission',
    'customer',
    'TEST001',  -- Customer ID/Card number
    '44444444-4444-4444-4444-444444444444', -- Level 1 promoter
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    updated_at = NOW();

SELECT '🎯 TEST CUSTOMER CREATED SUCCESSFULLY' as customer_status;

-- Show customer details
SELECT 
    '👤 CUSTOMER DETAILS' as customer_info,
    name,
    customer_id,
    role,
    (SELECT name FROM profiles p2 WHERE p2.id = profiles.parent_promoter_id) as parent_promoter_name,
    (SELECT promoter_id FROM profiles p2 WHERE p2.id = profiles.parent_promoter_id) as parent_promoter_id
FROM profiles 
WHERE id = '55555555-5555-5555-5555-555555555555';

-- =====================================================
-- TRIGGER COMMISSION DISTRIBUTION
-- =====================================================

SELECT 
    '🔥 TRIGGERING COMMISSION DISTRIBUTION' as trigger_status;

-- Use the distribute_affiliate_commission function
SELECT 
    '💰 COMMISSION DISTRIBUTION RESULT' as result_type,
    distribute_affiliate_commission(
        '55555555-5555-5555-5555-555555555555'::UUID, -- customer_id
        '44444444-4444-4444-4444-444444444444'::UUID  -- initiator_promoter_id (Level 1)
    ) as commission_result;

-- =====================================================
-- SHOW COMMISSION RESULTS
-- =====================================================

-- Show commissions for our test customer
SELECT 
    '💰 COMMISSIONS FOR TEST CUSTOMER' as commission_check,
    ac.level,
    ac.recipient_type,
    ac.amount,
    ac.status,
    ac.note,
    ac.transaction_id,
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

-- Show commission breakdown by level with validation
SELECT 
    '📈 COMMISSION BREAKDOWN BY LEVEL' as breakdown_type,
    level,
    recipient_type,
    amount,
    CASE 
        WHEN level = 1 AND amount = 500 THEN '✅ Level 1 Correct (₹500)'
        WHEN level = 2 AND amount = 100 THEN '✅ Level 2 Correct (₹100)'
        WHEN level = 3 AND amount = 100 THEN '✅ Level 3 Correct (₹100)'
        WHEN level = 4 AND amount = 100 THEN '✅ Level 4 Correct (₹100)'
        WHEN level = 0 AND recipient_type = 'admin' THEN '✅ Admin Fallback (₹' || amount || ')'
        ELSE '❌ UNEXPECTED: Level ' || level || ' = ₹' || amount
    END as validation,
    note
FROM affiliate_commissions 
WHERE customer_id = '55555555-5555-5555-5555-555555555555'
ORDER BY level;

-- =====================================================
-- SYSTEM HEALTH CHECK AFTER TEST
-- =====================================================

-- Check overall system health after new customer
SELECT 
    '🏥 SYSTEM HEALTH AFTER TEST CUSTOMER' as health_check,
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

-- Show the promoter hierarchy that received commissions
SELECT 
    '🏗️ PROMOTER HIERARCHY THAT RECEIVED COMMISSIONS' as hierarchy_info,
    p.name,
    p.promoter_id,
    ac.level,
    ac.amount,
    ac.status
FROM affiliate_commissions ac
JOIN profiles p ON ac.recipient_id = p.id
WHERE ac.customer_id = '55555555-5555-5555-5555-555555555555'
AND ac.recipient_type = 'promoter'
ORDER BY ac.level;

-- =====================================================
-- FINAL TEST RESULTS
-- =====================================================

SELECT 
    '🎉 COMMISSION TEST COMPLETED!' as final_status,
    'Test customer created and commission distributed' as action,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM affiliate_commissions 
            WHERE customer_id = '55555555-5555-5555-5555-555555555555'
            GROUP BY customer_id 
            HAVING SUM(amount) = 800
        ) THEN '✅ SUCCESS: Commission system working perfectly'
        ELSE '❌ ISSUE: Commission total not ₹800'
    END as test_result,
    'Check the breakdown above for detailed verification' as instruction;
