-- =====================================================
-- FIX DUPLICATE COMMISSION ISSUE - ₹1000 INSTEAD OF ₹800
-- =====================================================
-- This script investigates and fixes the duplicate commission problem
-- =====================================================

BEGIN;

-- 1. INVESTIGATE: Check for duplicate commission records
SELECT 
    'Duplicate Investigation' as analysis_type,
    customer_id,
    recipient_type,
    level,
    amount,
    COUNT(*) as record_count,
    STRING_AGG(transaction_id, ', ') as transaction_ids
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '2 hours'
GROUP BY customer_id, recipient_type, level, amount
HAVING COUNT(*) > 1
ORDER BY customer_id, level;

-- 2. CHECK: See all commission records for problem customers
SELECT 
    'All Commission Records' as analysis_type,
    ac.customer_id,
    p.customer_id as customer_card_no,
    ac.recipient_type,
    ac.level,
    ac.amount,
    ac.transaction_id,
    ac.created_at,
    pp.promoter_id as recipient_promoter_id
FROM affiliate_commissions ac
JOIN profiles p ON ac.customer_id = p.id
LEFT JOIN profiles pp ON ac.recipient_id = pp.id
WHERE ac.customer_id IN (
    '2605af1b-56cf-4a1f-9199-677ca75d484e',
    '6ff5dc5b-7b15-4f8e-baf6-90aadc921206', 
    'e19db064-d28a-45ec-ae37-15af11ad0a21'
)
ORDER BY ac.customer_id, ac.level, ac.created_at;

-- 3. DELETE DUPLICATE COMMISSION RECORDS
-- Keep only the latest record for each customer/level combination
WITH ranked_commissions AS (
    SELECT 
        id,
        customer_id,
        recipient_type,
        level,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, recipient_type, level 
            ORDER BY created_at DESC
        ) as rn
    FROM affiliate_commissions 
    WHERE created_at > NOW() - INTERVAL '2 hours'
)
DELETE FROM affiliate_commissions 
WHERE id IN (
    SELECT id 
    FROM ranked_commissions 
    WHERE rn > 1
);

-- 4. RECALCULATE ADMIN COMMISSIONS CORRECTLY
-- Delete all admin commissions and recalculate them properly
DELETE FROM affiliate_commissions 
WHERE recipient_type = 'admin' 
AND created_at > NOW() - INTERVAL '2 hours';

-- 5. RECALCULATE CORRECT ADMIN AMOUNTS
-- For each customer with incomplete hierarchy, add correct admin commission
WITH customer_promoter_totals AS (
    SELECT 
        customer_id,
        SUM(amount) as promoter_total,
        COUNT(*) as promoter_levels
    FROM affiliate_commissions 
    WHERE recipient_type = 'promoter' 
    AND created_at > NOW() - INTERVAL '2 hours'
    GROUP BY customer_id
),
admin_corrections AS (
    SELECT 
        cpt.customer_id,
        800.00 - cpt.promoter_total as admin_amount
    FROM customer_promoter_totals cpt
    WHERE cpt.promoter_total < 800.00
)
INSERT INTO affiliate_commissions (
    customer_id,
    initiator_promoter_id,
    recipient_id,
    recipient_type,
    level,
    amount,
    status,
    transaction_id,
    note,
    created_at
)
SELECT 
    ac.customer_id,
    p.parent_promoter_id as initiator_promoter_id,
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1) as recipient_id,
    'admin',
    0,
    ac.admin_amount,
    'credited',
    'COM-ADMIN-CORRECTED-' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    'Admin Fallback - Corrected amount - ₹' || ac.admin_amount,
    NOW()
FROM admin_corrections ac
JOIN profiles p ON ac.customer_id = p.id
WHERE ac.admin_amount > 0;

-- 6. UPDATE ADMIN WALLET WITH CORRECT AMOUNTS
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
updated_at = NOW();

-- 7. FINAL VERIFICATION - Should show no records (all totals should be ₹800)
SELECT 
    'Final Verification' as test_type,
    customer_id,
    SUM(CASE WHEN recipient_type = 'promoter' THEN amount ELSE 0 END) as promoter_total,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_total,
    SUM(amount) as grand_total
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '2 hours'
GROUP BY customer_id
ORDER BY customer_id;

COMMIT;
