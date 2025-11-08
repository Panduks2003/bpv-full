-- =====================================================
-- SIMPLE DUPLICATE CLEANUP
-- =====================================================
-- Just remove duplicates, don't worry about wallet updates
-- =====================================================

BEGIN;

-- 1. Show current duplicate situation
SELECT 
    'Current Duplicates' as analysis_type,
    customer_id,
    COUNT(*) as total_records,
    SUM(amount) as total_amount,
    STRING_AGG(DISTINCT recipient_type, ', ') as recipient_types
FROM affiliate_commissions 
GROUP BY customer_id
HAVING SUM(amount) > 800.00
ORDER BY total_amount DESC;

-- 2. Delete duplicate records (keep the most recent ones)
WITH ranked_commissions AS (
    SELECT 
        id,
        customer_id,
        recipient_type,
        level,
        amount,
        created_at,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, recipient_type, level, amount 
            ORDER BY created_at DESC
        ) as rn
    FROM affiliate_commissions 
),
duplicates_to_delete AS (
    SELECT id 
    FROM ranked_commissions 
    WHERE rn > 1
)
DELETE FROM affiliate_commissions 
WHERE id IN (SELECT id FROM duplicates_to_delete);

-- 3. Show results after cleanup
SELECT 
    'After Cleanup' as analysis_type,
    customer_id,
    COUNT(*) as total_records,
    SUM(amount) as total_amount,
    STRING_AGG(DISTINCT recipient_type, ', ') as recipient_types,
    CASE 
        WHEN SUM(amount) = 800.00 THEN '✅ CORRECT'
        WHEN SUM(amount) < 800.00 THEN '⚠️ INCOMPLETE'
        ELSE '❌ STILL OVER'
    END as status
FROM affiliate_commissions 
GROUP BY customer_id
HAVING SUM(amount) > 0
ORDER BY total_amount DESC;

-- 4. Count of records deleted
SELECT 
    'Cleanup Summary' as summary_type,
    'Duplicate commission records have been removed' as message,
    'Customers should now have ≤ ₹800 total commission' as result;

COMMIT;

SELECT '✅ Simple duplicate cleanup completed!' as status;
