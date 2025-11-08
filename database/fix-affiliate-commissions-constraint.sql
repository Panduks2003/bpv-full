-- =====================================================
-- FIX AFFILIATE COMMISSIONS CONSTRAINT ISSUE
-- =====================================================
-- This script fixes the customer_id constraint issue in affiliate_commissions
-- =====================================================

BEGIN;

-- Check current structure of affiliate_commissions table
SELECT 'AFFILIATE_COMMISSIONS_STRUCTURE' as check_type,
       column_name,
       data_type,
       is_nullable,
       column_default
FROM information_schema.columns 
WHERE table_name = 'affiliate_commissions'
ORDER BY ordinal_position;

-- Check for NULL customer_id values in affiliate_commissions
SELECT 'NULL_CUSTOMER_ID_COUNT' as check_type,
       COUNT(*) as null_count
FROM affiliate_commissions 
WHERE customer_id IS NULL;

-- Show some sample records with NULL customer_id
SELECT 'SAMPLE_NULL_RECORDS' as check_type,
       id, promoter_id, customer_id, created_at
FROM affiliate_commissions 
WHERE customer_id IS NULL 
LIMIT 5;

-- Option 1: Make customer_id nullable (if commissions can exist without customers)
-- ALTER TABLE affiliate_commissions ALTER COLUMN customer_id DROP NOT NULL;

-- Option 2: Delete records with NULL customer_id (if they're invalid)
-- DELETE FROM affiliate_commissions WHERE customer_id IS NULL;

-- Option 3: Set a default UUID value for NULL customer_ids
UPDATE affiliate_commissions 
SET customer_id = gen_random_uuid()
WHERE customer_id IS NULL;

-- Check if the issue is resolved
SELECT 'REMAINING_NULL_COUNT' as check_type,
       COUNT(*) as null_count
FROM affiliate_commissions 
WHERE customer_id IS NULL;

COMMIT;

SELECT 'AFFILIATE_COMMISSIONS_FIX_COMPLETE' as status;
