-- =====================================================
-- THOROUGH DUPLICATE FIX FOR CUSTOMER_ID
-- =====================================================
-- This script completely resolves all duplicate customer_id issues
-- =====================================================

BEGIN;

-- Step 1: Drop ALL unique constraints on customer_id
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    FOR constraint_name IN 
        SELECT c.conname
        FROM pg_constraint c 
        JOIN pg_class t ON c.conrelid = t.oid 
        WHERE t.relname = 'profiles' 
        AND c.contype = 'u'
    LOOP
        BEGIN
            EXECUTE 'ALTER TABLE profiles DROP CONSTRAINT ' || constraint_name;
            RAISE NOTICE 'Dropped constraint: %', constraint_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not drop constraint: % (may not exist)', constraint_name;
        END;
    END LOOP;
END $$;

-- Step 2: Show all current duplicates
\echo 'Current duplicates before fix:'
SELECT customer_id, COUNT(*) as duplicate_count, 
       array_agg(id ORDER BY created_at) as profile_ids
FROM profiles 
WHERE customer_id IS NOT NULL 
GROUP BY customer_id 
HAVING COUNT(*) > 1
ORDER BY customer_id;

-- Step 3: Create a temporary table to track changes
CREATE TEMP TABLE duplicate_fixes AS
SELECT 
    id,
    customer_id as original_customer_id,
    customer_id || '_' || row_number() OVER (PARTITION BY customer_id ORDER BY created_at) as new_customer_id,
    row_number() OVER (PARTITION BY customer_id ORDER BY created_at) as row_num
FROM profiles 
WHERE customer_id IS NOT NULL;

-- Step 4: Update all duplicates (keep first one unchanged, modify others)
UPDATE profiles 
SET customer_id = df.new_customer_id
FROM duplicate_fixes df
WHERE profiles.id = df.id 
AND df.row_num > 1;

-- Step 5: Show what was fixed
\echo 'Duplicates that were fixed:'
SELECT original_customer_id, new_customer_id, row_num
FROM duplicate_fixes 
WHERE row_num > 1
ORDER BY original_customer_id, row_num;

-- Step 6: Verify no duplicates remain
\echo 'Remaining duplicates (should be empty):'
SELECT customer_id, COUNT(*) as count
FROM profiles 
WHERE customer_id IS NOT NULL 
GROUP BY customer_id 
HAVING COUNT(*) > 1;

-- Step 7: Clean up any NULL or empty customer_ids for customers
UPDATE profiles 
SET customer_id = 'CUST_' || EXTRACT(EPOCH FROM created_at)::bigint || '_' || substring(id::text, 1, 8)
WHERE role = 'customer' 
AND (customer_id IS NULL OR trim(customer_id) = '');

-- Step 8: Add the unique constraint back
ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_unique UNIQUE (customer_id);

-- Step 9: Add format constraint (allowing underscores for fixed duplicates)
ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_format 
    CHECK (customer_id IS NULL OR (customer_id ~ '^[A-Z0-9_]{3,30}$'));

COMMIT;

-- Final verification
SELECT 'THOROUGH_FIX_COMPLETE' as status,
       COUNT(DISTINCT customer_id) as unique_customer_ids,
       COUNT(*) as total_profiles_with_customer_id
FROM profiles 
WHERE customer_id IS NOT NULL;
