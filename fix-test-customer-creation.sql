-- =====================================================
-- 🔧 FIX TEST CUSTOMER CREATION
-- =====================================================
-- Fix the column issue and create test customer properly
-- =====================================================

-- First, let's check the profiles table structure
SELECT 
    '🔍 PROFILES TABLE STRUCTURE' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- =====================================================
-- CREATE TEST CUSTOMER (FIXED VERSION)
-- =====================================================

-- Create test customer under Level 1 promoter (without card_no)
INSERT INTO profiles (id, email, name, role, parent_promoter_id, created_at)
VALUES (
    '55555555-5555-5555-5555-555555555555',
    'test-customer@example.com',
    'Test Customer for Commission',
    'customer',
    '44444444-4444-4444-4444-444444444444', -- Level 1 promoter
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    updated_at = NOW();

SELECT '🎯 TEST CUSTOMER CREATED (FIXED)' as customer_status;

-- Show customer details
SELECT 
    '👤 CUSTOMER DETAILS' as customer_info,
    name,
    role,
    (SELECT name FROM profiles p2 WHERE p2.id = profiles.parent_promoter_id) as parent_promoter_name,
    (SELECT promoter_id FROM profiles p2 WHERE p2.id = profiles.parent_promoter_id) as parent_promoter_id
FROM profiles 
WHERE id = '55555555-5555-5555-5555-555555555555';

-- =====================================================
-- TRIGGER COMMISSION DISTRIBUTION
-- =====================================================

SELECT 
    '🔥 TRIGGERING COMMISSION DISTRIBUTION' as trigger_status,
    distribute_affiliate_commission(
        '55555555-5555-5555-5555-555555555555'::UUID, -- customer_id
        '44444444-4444-4444-4444-444444444444'::UUID  -- initiator_promoter_id (Level 1)
    ) as commission_result;

-- =====================================================
-- VERIFY COMMISSION DISTRIBUTION
-- =====================================================

-- Show commissions for our test customer
SELECT 
    '💰 COMMISSIONS FOR TEST CUSTOMER' as commission_check,
    ac.level,
    ac.recipient_type,
    ac.amount,
    ac.status,
    ac.note,
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
        WHEN level = 1 AND amount = 500 THEN '✅ Level 1 Correct (₹500)'
        WHEN level IN (2,3,4) AND amount = 100 THEN '✅ Level ' || level || ' Correct (₹100)'
        WHEN level = 0 AND recipient_type = 'admin' THEN '✅ Admin Fallback (₹' || amount || ')'
        ELSE '❌ Unexpected: Level ' || level || ' = ₹' || amount
    END as validation
FROM affiliate_commissions 
WHERE customer_id = '55555555-5555-5555-5555-555555555555'
ORDER BY level;

-- =====================================================
-- FINAL VERIFICATION
-- =====================================================

SELECT 
    '🎉 TEST RESULTS SUMMARY' as final_status,
    'Customer created and commission distributed' as action,
    'Check above for ₹800 total verification' as instruction,
    'Expected: Level 1=₹500, Level 2-4=₹100 each' as expected;
