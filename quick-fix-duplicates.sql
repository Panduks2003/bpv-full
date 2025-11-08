-- =====================================================
-- QUICK FIX FOR DUPLICATE COMMISSIONS
-- =====================================================
-- Simple approach: Delete all records for problem customers
-- and let the system recreate them correctly
-- =====================================================

BEGIN;

-- 1. SHOW CURRENT PROBLEM STATE
SELECT 
    'Before Cleanup' as status,
    customer_id,
    COUNT(*) as total_records,
    SUM(amount) as total_amount,
    STRING_AGG(DISTINCT recipient_type, ', ') as types
FROM affiliate_commissions 
WHERE customer_id IN (
    '2605af1b-56cf-4a1f-9199-677ca75d484e',
    '6ff5dc5b-7b15-4f8e-baf6-90aadc921206', 
    'afd92a94-4728-47d5-b248-af808177a80a',
    'e19db064-d28a-45ec-ae37-15af11ad0a21'
)
GROUP BY customer_id
ORDER BY customer_id;

-- 2. DELETE ALL COMMISSION RECORDS FOR THESE CUSTOMERS
DELETE FROM affiliate_commissions 
WHERE customer_id IN (
    '2605af1b-56cf-4a1f-9199-677ca75d484e',
    '6ff5dc5b-7b15-4f8e-baf6-90aadc921206', 
    'afd92a94-4728-47d5-b248-af808177a80a',
    'e19db064-d28a-45ec-ae37-15af11ad0a21'
);

-- 3. UPDATE ADMIN WALLET TO REMOVE INCORRECT AMOUNTS
UPDATE admin_wallet 
SET balance = (
    SELECT COALESCE(SUM(amount), 0) 
    FROM affiliate_commissions 
    WHERE recipient_type = 'admin'
),
total_earned = (
    SELECT COALESCE(SUM(amount), 0) 
    FROM affiliate_commissions 
    WHERE recipient_type = 'admin'
),
commission_count = (
    SELECT COUNT(*) 
    FROM affiliate_commissions 
    WHERE recipient_type = 'admin'
),
updated_at = NOW()
WHERE EXISTS (SELECT 1 FROM admin_wallet);

-- 4. SHOW CUSTOMER INFO FOR MANUAL REDISTRIBUTION
SELECT 
    'Customer Info for Redistribution' as info_type,
    p.id as customer_id,
    p.customer_id as card_no,
    p.name as customer_name,
    p.parent_promoter_id as initiator_promoter_id,
    pp.name as promoter_name,
    pp.promoter_id as promoter_code
FROM profiles p
LEFT JOIN profiles pp ON p.parent_promoter_id = pp.id
WHERE p.id IN (
    '2605af1b-56cf-4a1f-9199-677ca75d484e',
    '6ff5dc5b-7b15-4f8e-baf6-90aadc921206', 
    'afd92a94-4728-47d5-b248-af808177a80a',
    'e19db064-d28a-45ec-ae37-15af11ad0a21'
)
ORDER BY p.customer_id;

COMMIT;

-- Instructions for next step
SELECT 
    '📋 NEXT STEPS' as instruction_type,
    'Use the frontend to redistribute commissions for these customers' as action,
    'Or call distribute_affiliate_commission function for each customer' as alternative;
