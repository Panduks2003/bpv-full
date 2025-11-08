-- =====================================================
-- CHECK LATEST CUSTOMER COMMISSION - VERIFY FIX
-- =====================================================
-- Check the commission for the latest customer created
-- =====================================================

-- 1. Check the latest customer's commission (from console: e5269918-56a9-4df3-9bc1-bcbfb24ffc50)
SELECT 
    'Latest Customer Commission' as analysis_type,
    level,
    recipient_type,
    amount,
    transaction_id,
    note,
    created_at,
    CASE 
        WHEN transaction_id LIKE 'TRIGGER-POOL-%' THEN '✅ New Trigger (Pool Logic)'
        WHEN transaction_id LIKE 'TRIGGER-ADMIN-POOL-%' THEN '✅ New Trigger (Admin Pool)'
        WHEN transaction_id IS NULL THEN '❌ Old Trigger (No Transaction ID)'
        ELSE '❓ Other Source'
    END as source_analysis
FROM affiliate_commissions 
WHERE customer_id = 'e5269918-56a9-4df3-9bc1-bcbfb24ffc50'
ORDER BY level;

-- 2. Check total for latest customer
SELECT 
    'Latest Customer Total' as check_type,
    customer_id,
    SUM(amount) as total_amount,
    COUNT(*) as record_count,
    SUM(CASE WHEN recipient_type = 'promoter' THEN amount ELSE 0 END) as promoter_total,
    SUM(CASE WHEN recipient_type = 'admin' THEN amount ELSE 0 END) as admin_total,
    CASE 
        WHEN SUM(amount) = 800.00 THEN '✅ CORRECT (₹800)'
        WHEN SUM(amount) = 1000.00 THEN '❌ OLD LOGIC (₹1000)'
        ELSE '❓ UNEXPECTED TOTAL'
    END as status
FROM affiliate_commissions 
WHERE customer_id = 'e5269918-56a9-4df3-9bc1-bcbfb24ffc50'
GROUP BY customer_id;

-- 3. Check the most recent 3 customers to see the pattern
SELECT 
    'Recent Customers Pattern' as analysis_type,
    customer_id,
    SUM(amount) as total_amount,
    COUNT(*) as record_count,
    MIN(created_at) as commission_created_at,
    STRING_AGG(DISTINCT 
        CASE 
            WHEN transaction_id LIKE 'TRIGGER-POOL-%' THEN 'New-Trigger'
            WHEN transaction_id IS NULL THEN 'Old-Trigger'
            ELSE 'Other'
        END, ', ') as source_types,
    CASE 
        WHEN SUM(amount) = 800.00 THEN '✅ FIXED'
        WHEN SUM(amount) = 1000.00 THEN '❌ OLD'
        ELSE '❓ OTHER'
    END as fix_status
FROM affiliate_commissions 
WHERE created_at > NOW() - INTERVAL '2 hours'
GROUP BY customer_id
ORDER BY commission_created_at DESC
LIMIT 3;

-- 4. Check if trigger function was actually updated
SELECT 
    'Trigger Function Status' as check_type,
    routine_name,
    CASE 
        WHEN routine_definition LIKE '%v_remaining_pool%' THEN '✅ UPDATED (Pool Logic)'
        WHEN routine_definition LIKE '%800.00%' THEN '✅ HAS POOL REFERENCE'
        ELSE '❌ OLD VERSION'
    END as function_status,
    LENGTH(routine_definition) as definition_length
FROM information_schema.routines 
WHERE routine_name = 'trigger_commission_distribution';
