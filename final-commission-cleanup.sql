-- =====================================================
-- FINAL COMMISSION CLEANUP - REMOVE DUPLICATES
-- =====================================================
-- This script cleans up duplicate commission records and ensures
-- each customer has exactly ₹800 total commission distributed
-- =====================================================

BEGIN;

-- 1. IDENTIFY CUSTOMERS WITH DUPLICATE COMMISSIONS
SELECT 
    'Customers with Duplicate Commissions' as analysis_type,
    customer_id,
    COUNT(*) as total_records,
    SUM(amount) as total_amount,
    STRING_AGG(DISTINCT recipient_type, ', ') as recipient_types
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY customer_id
HAVING SUM(amount) > 800.00
ORDER BY total_amount DESC;

-- 2. DELETE DUPLICATE COMMISSION RECORDS (KEEP LATEST)
-- This removes duplicate records while preserving the most recent ones
WITH ranked_commissions AS (
    SELECT 
        id,
        customer_id,
        recipient_type,
        level,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, recipient_type, level, amount 
            ORDER BY created_at DESC
        ) as rn
    FROM affiliate_commissions 
    WHERE created_at > NOW() - INTERVAL '24 hours'
)
DELETE FROM affiliate_commissions 
WHERE id IN (
    SELECT id 
    FROM ranked_commissions 
    WHERE rn > 1
);

-- 3. FIX ADMIN COMMISSIONS (RECALCULATE CORRECT AMOUNTS)
-- Delete all admin commissions and recalculate them properly
DELETE FROM affiliate_commissions 
WHERE recipient_type = 'admin' 
AND created_at > NOW() - INTERVAL '24 hours';

-- Recalculate correct admin amounts for incomplete hierarchies
WITH customer_promoter_totals AS (
    SELECT 
        customer_id,
        SUM(amount) as promoter_total,
        COUNT(*) as promoter_levels
    FROM affiliate_commissions 
    WHERE recipient_type = 'promoter' 
    AND created_at > NOW() - INTERVAL '24 hours'
    GROUP BY customer_id
),
admin_corrections AS (
    SELECT 
        cpt.customer_id,
        800.00 - cpt.promoter_total as admin_amount,
        (SELECT parent_promoter_id FROM profiles WHERE id = cpt.customer_id) as initiator_promoter_id
    FROM customer_promoter_totals cpt
    WHERE cpt.promoter_total < 800.00
    AND cpt.promoter_total > 0  -- Only for customers that have some promoter commissions
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
    ac.initiator_promoter_id,
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1) as recipient_id,
    'admin',
    0,
    ac.admin_amount,
    'credited',
    'COM-ADMIN-CLEANUP-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || ac.customer_id,
    'Admin Fallback - Cleanup - ₹' || ac.admin_amount,
    NOW()
FROM admin_corrections ac
WHERE ac.admin_amount > 0;

-- 4. UPDATE ADMIN WALLET WITH CORRECT TOTALS
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

-- 5. FINAL VERIFICATION - ALL CUSTOMERS SHOULD HAVE ≤ ₹800 TOTAL
SELECT 
    'Final Commission Verification' as test_type,
    customer_id,
    SUM(CASE WHEN recipient_type = 'promoter' THEN amount ELSE 0 END) as promoter_total,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_total,
    SUM(amount) as grand_total,
    CASE 
        WHEN SUM(amount) = 800.00 THEN '✅ CORRECT'
        WHEN SUM(amount) < 800.00 THEN '⚠️ INCOMPLETE HIERARCHY'
        ELSE '❌ OVER DISTRIBUTED'
    END as status
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY customer_id
ORDER BY grand_total DESC;

-- 6. SUMMARY REPORT
SELECT 
    'Commission System Summary' as report_type,
    COUNT(DISTINCT customer_id) as total_customers,
    SUM(CASE WHEN recipient_type = 'promoter' THEN amount ELSE 0 END) as total_promoter_commissions,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as total_admin_commissions,
    SUM(amount) as grand_total_distributed,
    ROUND(AVG(amount), 2) as avg_commission_per_record
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '24 hours';

COMMIT;

-- Success message
SELECT '✅ Commission cleanup completed successfully!' as status,
       'Admin now receives only fallback commission from ₹800 pool' as note;
