-- =====================================================
-- DEBUG COMMISSION SOURCE - FIND WHY ₹1000 STILL HAPPENING
-- =====================================================
-- Investigate the recent commission records to see the source
-- =====================================================

-- 1. Check the most recent commission records with transaction IDs
SELECT 
    'Recent Commission Analysis' as analysis_type,
    customer_id,
    level,
    recipient_type,
    amount,
    transaction_id,
    note,
    created_at,
    CASE 
        WHEN transaction_id LIKE 'COM-POOL-%' THEN 'Database Function (Pool Logic)'
        WHEN transaction_id LIKE 'COM-ADMIN-POOL-%' THEN 'Database Function (Admin Pool)'
        WHEN transaction_id LIKE 'COM-%-%-%' THEN 'Database Function (Old Logic)'
        WHEN transaction_id LIKE 'COM-%-ADMIN-%' THEN 'Fallback Calculation'
        ELSE 'Unknown Source'
    END as source_method
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '30 minutes'
ORDER BY customer_id, created_at, level;

-- 2. Check for duplicate commission calls (same customer, different transaction times)
SELECT 
    'Duplicate Call Analysis' as analysis_type,
    customer_id,
    COUNT(*) as total_records,
    COUNT(DISTINCT SUBSTRING(transaction_id, 1, 15)) as unique_transaction_groups,
    STRING_AGG(DISTINCT 
        CASE 
            WHEN transaction_id LIKE 'COM-POOL-%' THEN 'DB-Pool'
            WHEN transaction_id LIKE 'COM-%-%-%' THEN 'DB-Old'
            ELSE 'Fallback'
        END, ', ') as methods_used,
    MIN(created_at) as first_commission,
    MAX(created_at) as last_commission
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '30 minutes'
GROUP BY customer_id
HAVING COUNT(*) > 0
ORDER BY total_records DESC;

-- 3. Check the specific customer with ₹1000 total
SELECT 
    'Customer AAAAAAAA Analysis' as analysis_type,
    level,
    recipient_type,
    amount,
    transaction_id,
    note,
    created_at,
    EXTRACT(EPOCH FROM created_at) as timestamp_epoch
FROM affiliate_commissions 
WHERE customer_id IN (
    SELECT customer_id 
    FROM affiliate_commissions 
    WHERE created_at > NOW() - INTERVAL '30 minutes'
    GROUP BY customer_id 
    HAVING SUM(amount) = 1000
    LIMIT 1
)
ORDER BY level;

-- 4. Check if there are any triggers or other functions that might be creating extra commissions
SELECT 
    'Database Triggers Check' as check_type,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table IN ('profiles', 'affiliate_commissions', 'customers')
ORDER BY event_object_table, trigger_name;
