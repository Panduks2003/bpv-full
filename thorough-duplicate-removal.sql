-- =====================================================
-- THOROUGH DUPLICATE REMOVAL
-- =====================================================
-- Remove ALL duplicates including the specific problematic record
-- =====================================================

BEGIN;

-- 1. Show the specific problematic record
SELECT 
    'Problematic Record Details' as analysis_type,
    *
FROM affiliate_commissions 
WHERE customer_id = '77beb2a4-d801-4968-a066-eba34ae8101d'
AND initiator_promoter_id = '4cc11266-e008-4b20-af7d-69b026200d2b'
ORDER BY created_at;

-- 2. Show ALL customers with ANY duplicates (more comprehensive check)
SELECT 
    'All Duplicate Customers' as analysis_type,
    customer_id,
    initiator_promoter_id,
    COUNT(*) as record_count,
    SUM(amount) as total_amount,
    STRING_AGG(DISTINCT recipient_type, ', ') as recipient_types,
    MIN(created_at) as first_created,
    MAX(created_at) as last_created
FROM affiliate_commissions 
GROUP BY customer_id, initiator_promoter_id
HAVING COUNT(*) > 1  -- Any customer with more than 1 record per initiator
ORDER BY record_count DESC, total_amount DESC;

-- 3. Delete ALL duplicate records (keep only the most recent one per customer-initiator pair)
WITH ranked_records AS (
    SELECT 
        id,
        customer_id,
        initiator_promoter_id,
        created_at,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id, initiator_promoter_id 
            ORDER BY created_at DESC
        ) as rn
    FROM affiliate_commissions
),
records_to_delete AS (
    SELECT id 
    FROM ranked_records 
    WHERE rn > 1  -- Keep only the most recent record (rn = 1)
)
DELETE FROM affiliate_commissions 
WHERE id IN (SELECT id FROM records_to_delete);

-- 4. Alternative approach: Delete ALL records for customers with ANY duplicates
-- Then they can be redistributed correctly
DELETE FROM affiliate_commissions 
WHERE customer_id IN (
    SELECT customer_id
    FROM (
        SELECT 
            customer_id,
            COUNT(*) as record_count
        FROM affiliate_commissions 
        GROUP BY customer_id
        HAVING COUNT(*) > 4  -- More than 4 records indicates duplicates
    ) duplicate_customers
);

-- 5. Show what's left after cleanup
SELECT 
    'After Thorough Cleanup' as analysis_type,
    customer_id,
    initiator_promoter_id,
    COUNT(*) as record_count,
    SUM(amount) as total_amount,
    STRING_AGG(DISTINCT recipient_type, ', ') as recipient_types
FROM affiliate_commissions 
GROUP BY customer_id, initiator_promoter_id
ORDER BY record_count DESC, total_amount DESC;

-- 6. Verify the problematic record is gone
SELECT 
    'Problematic Record Check' as verification_type,
    COUNT(*) as remaining_records
FROM affiliate_commissions 
WHERE customer_id = '77beb2a4-d801-4968-a066-eba34ae8101d'
AND initiator_promoter_id = '4cc11266-e008-4b20-af7d-69b026200d2b';

COMMIT;

SELECT '✅ Thorough duplicate removal completed!' as status;
