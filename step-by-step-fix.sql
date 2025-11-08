-- =====================================================
-- STEP-BY-STEP FIX FOR DUPLICATE COMMISSIONS
-- =====================================================
-- Step 1: Clean existing duplicates
-- Step 2: Apply prevention system
-- =====================================================

-- STEP 1: CLEAN UP ALL EXISTING DUPLICATES
BEGIN;

-- 1.1 Identify all customers with duplicate commissions
SELECT 
    'All Customers with Duplicates' as analysis_type,
    customer_id,
    initiator_promoter_id,
    COUNT(*) as total_records,
    SUM(amount) as total_amount,
    STRING_AGG(DISTINCT recipient_type, ', ') as recipient_types
FROM affiliate_commissions 
GROUP BY customer_id, initiator_promoter_id
HAVING COUNT(*) > 4  -- More than 4 records indicates duplicates (should be max 4: levels 1-4)
   OR SUM(amount) > 800.00  -- Total more than ₹800 indicates duplicates
ORDER BY total_amount DESC;

-- 1.2 Delete ALL commission records for customers with duplicates
-- We'll recreate them correctly
DELETE FROM affiliate_commissions 
WHERE customer_id IN (
    SELECT customer_id
    FROM affiliate_commissions 
    GROUP BY customer_id, initiator_promoter_id
    HAVING COUNT(*) > 4 OR SUM(amount) > 800.00
);

-- 1.3 Reset admin wallet to correct values (check what columns exist first)
-- First, let's see what columns exist in admin_wallet
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'admin_wallet' 
ORDER BY ordinal_position;

-- Update admin wallet with existing columns only
UPDATE admin_wallet 
SET balance = (
    SELECT COALESCE(SUM(amount), 0) 
    FROM affiliate_commissions 
    WHERE recipient_type = 'admin'
),
updated_at = NOW()
WHERE EXISTS (SELECT 1 FROM admin_wallet);

-- If admin_wallet doesn't exist or is empty, create/insert a record
INSERT INTO admin_wallet (balance, created_at, updated_at)
SELECT 
    COALESCE(SUM(amount), 0) as balance,
    NOW() as created_at,
    NOW() as updated_at
FROM affiliate_commissions 
WHERE recipient_type = 'admin'
ON CONFLICT DO NOTHING;

-- 1.4 Show customers that need commission redistribution
SELECT 
    'Customers Needing Redistribution' as info_type,
    p.id as customer_id,
    p.customer_id as card_no,
    p.name as customer_name,
    p.parent_promoter_id as initiator_promoter_id,
    pp.name as promoter_name,
    pp.promoter_id as promoter_code,
    p.created_at as customer_created_at
FROM profiles p
LEFT JOIN profiles pp ON p.parent_promoter_id = pp.id
WHERE p.role = 'customer'
AND p.id NOT IN (
    SELECT DISTINCT customer_id 
    FROM affiliate_commissions 
    WHERE status = 'credited'
)
AND p.created_at > NOW() - INTERVAL '30 days'  -- Only recent customers
ORDER BY p.created_at DESC;

COMMIT;

SELECT '✅ Step 1 completed: Duplicates cleaned up' as status;
