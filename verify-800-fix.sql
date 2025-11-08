-- =====================================================
-- VERIFY ₹800 FIX IS WORKING
-- =====================================================
-- Check recent commission distributions to ensure ₹800 total max
-- =====================================================

-- 1. Check recent commission totals per customer
SELECT 
    'Recent Commission Totals' as check_type,
    customer_id,
    SUM(amount) as total_amount,
    SUM(CASE WHEN recipient_type = 'promoter' THEN amount ELSE 0 END) as promoter_total,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_total,
    COUNT(*) as record_count,
    CASE 
        WHEN SUM(amount) = 800.00 THEN '✅ CORRECT'
        WHEN SUM(amount) > 800.00 THEN '❌ OVER ₹800'
        ELSE '⚠️ UNDER ₹800'
    END as status
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY customer_id
ORDER BY total_amount DESC;

-- 2. Show the most recent customer's commission breakdown
WITH latest_customer AS (
    SELECT customer_id
    FROM affiliate_commissions 
    WHERE created_at > NOW() - INTERVAL '1 hour'
    ORDER BY created_at DESC
    LIMIT 1
)
SELECT 
    'Latest Customer Breakdown' as breakdown_type,
    ac.level,
    ac.recipient_type,
    ac.amount,
    ac.note,
    ac.created_at
FROM affiliate_commissions ac
JOIN latest_customer lc ON ac.customer_id = lc.customer_id
ORDER BY ac.level;

-- 3. Summary of all commission distributions today
SELECT 
    'Today Summary' as summary_type,
    COUNT(DISTINCT customer_id) as customers_today,
    COUNT(*) as total_records,
    SUM(amount) as total_distributed,
    AVG(amount) as avg_per_record,
    COUNT(CASE WHEN recipient_type = 'admin' THEN 1 END) as admin_records,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_total
FROM affiliate_commissions 
WHERE DATE(created_at) = CURRENT_DATE;
