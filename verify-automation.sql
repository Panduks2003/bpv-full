-- Verify complete customer automation
SELECT 'AUTOMATION_VERIFICATION' as check_type,
       COUNT(DISTINCT p.id) as total_customers,
       COUNT(DISTINCT cp.customer_id) as customers_with_payments,
       COUNT(DISTINCT ac.customer_id) as customers_with_commissions,
       COUNT(cp.id) as total_payment_records,
       COUNT(ac.id) as total_commission_records
FROM profiles p
LEFT JOIN customer_payments cp ON p.id = cp.customer_id
LEFT JOIN affiliate_commissions ac ON p.id = ac.customer_id
WHERE p.role = 'customer';

-- Check recent customer automation
SELECT 'RECENT_CUSTOMERS' as check_type,
       p.name as customer_name,
       p.created_at::date as created_date,
       COUNT(DISTINCT cp.id) as payment_count,
       COUNT(DISTINCT ac.id) as commission_count,
       CASE 
           WHEN COUNT(DISTINCT cp.id) = 20 AND COUNT(DISTINCT ac.id) > 0 THEN '✅ FULLY_AUTOMATED'
           WHEN COUNT(DISTINCT cp.id) = 20 THEN '⚠️ PAYMENTS_ONLY'
           WHEN COUNT(DISTINCT ac.id) > 0 THEN '⚠️ COMMISSIONS_ONLY'
           ELSE '❌ NO_AUTOMATION'
       END as status
FROM profiles p
LEFT JOIN customer_payments cp ON p.id = cp.customer_id
LEFT JOIN affiliate_commissions ac ON p.id = ac.customer_id
WHERE p.role = 'customer'
  AND p.created_at > NOW() - INTERVAL '30 days'
GROUP BY p.id, p.name, p.created_at
ORDER BY p.created_at DESC
LIMIT 10;
