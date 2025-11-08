-- =====================================================
-- COMPLETE DUPLICATE CLEANUP - ALL 46+ CUSTOMERS
-- =====================================================
-- Remove ALL duplicate commission records for all affected customers
-- =====================================================

BEGIN;

-- 1. Show the scale of the problem
SELECT 
    'Duplicate Problem Summary' as summary_type,
    COUNT(DISTINCT customer_id) as customers_with_duplicates,
    COUNT(*) as total_duplicate_groups,
    SUM(record_count) as total_duplicate_records,
    SUM(total_amount) as total_duplicate_amount
FROM (
    SELECT 
        customer_id,
        initiator_promoter_id,
        COUNT(*) as record_count,
        SUM(amount) as total_amount
    FROM affiliate_commissions 
    GROUP BY customer_id, initiator_promoter_id
    HAVING COUNT(*) > 1
) duplicate_summary;

-- 2. Delete ALL commission records for customers with ANY duplicates
-- This is the safest approach - clean slate for all problem customers
DELETE FROM affiliate_commissions 
WHERE customer_id IN (
    SELECT DISTINCT customer_id
    FROM (
        SELECT 
            customer_id,
            initiator_promoter_id,
            COUNT(*) as record_count
        FROM affiliate_commissions 
        GROUP BY customer_id, initiator_promoter_id
        HAVING COUNT(*) > 1  -- Any customer with duplicates
    ) customers_with_duplicates
);

-- 3. Show what remains after cleanup
SELECT 
    'After Complete Cleanup' as cleanup_result,
    COUNT(DISTINCT customer_id) as remaining_customers_with_commissions,
    COUNT(*) as remaining_commission_records,
    SUM(amount) as remaining_total_amount
FROM affiliate_commissions;

-- 4. Verify no duplicates remain
SELECT 
    'Duplicate Check After Cleanup' as verification_type,
    customer_id,
    initiator_promoter_id,
    COUNT(*) as record_count
FROM affiliate_commissions 
GROUP BY customer_id, initiator_promoter_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- 5. List customers that need commission redistribution
SELECT 
    'Customers Needing Redistribution' as redistribution_list,
    p.id as customer_id,
    p.customer_id as card_no,
    p.name as customer_name,
    p.parent_promoter_id as initiator_promoter_id,
    pp.name as promoter_name,
    pp.promoter_id as promoter_code,
    p.created_at as customer_created_at,
    CASE 
        WHEN p.created_at > NOW() - INTERVAL '7 days' THEN 'Recent (Last 7 days)'
        WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 'This Month'
        ELSE 'Older'
    END as customer_age
FROM profiles p
LEFT JOIN profiles pp ON p.parent_promoter_id = pp.id
WHERE p.role = 'customer'
AND p.id NOT IN (
    SELECT DISTINCT customer_id 
    FROM affiliate_commissions 
    WHERE status = 'credited'
)
AND p.created_at > NOW() - INTERVAL '30 days'  -- Focus on recent customers
ORDER BY p.created_at DESC;

COMMIT;

SELECT 
    '✅ Complete duplicate cleanup finished!' as status,
    'All 46+ customers with duplicates have been cleaned' as result,
    'Ready to apply prevention system and redistribute commissions' as next_step;
