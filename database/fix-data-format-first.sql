-- =====================================================
-- FIX DATA FORMAT BEFORE ADDING CONSTRAINTS
-- =====================================================
-- This script fixes all data format issues first
-- =====================================================

BEGIN;

-- Step 1: Drop ALL constraints that might be causing issues
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    FOR constraint_name IN 
        SELECT c.conname
        FROM pg_constraint c 
        JOIN pg_class t ON c.conrelid = t.oid 
        WHERE t.relname = 'profiles' 
        AND (c.contype = 'u' OR c.contype = 'c')
        AND c.conname LIKE '%customer_id%'
    LOOP
        BEGIN
            EXECUTE 'ALTER TABLE profiles DROP CONSTRAINT ' || constraint_name;
            RAISE NOTICE 'Dropped constraint: %', constraint_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not drop constraint: %', constraint_name;
        END;
    END LOOP;
END $$;

-- Step 2: Show problematic customer_id values
SELECT customer_id, COUNT(*) as count
FROM profiles 
WHERE customer_id IS NOT NULL 
AND customer_id !~ '^[A-Z0-9_]{3,30}$'
GROUP BY customer_id
ORDER BY customer_id;

-- Step 3: Fix customer_id format issues
UPDATE profiles 
SET customer_id = upper(regexp_replace(customer_id, '[^A-Z0-9]', '', 'g'))
WHERE customer_id IS NOT NULL 
AND customer_id !~ '^[A-Z0-9_]{3,30}$';

-- Step 4: Handle customer_ids that are too short
UPDATE profiles 
SET customer_id = customer_id || '001'
WHERE customer_id IS NOT NULL 
AND length(customer_id) < 3;

-- Step 5: Handle customer_ids that are too long
UPDATE profiles 
SET customer_id = left(customer_id, 30)
WHERE customer_id IS NOT NULL 
AND length(customer_id) > 30;

-- Step 6: Handle NULL customer_ids for customers
UPDATE profiles 
SET customer_id = 'CUST' || EXTRACT(EPOCH FROM created_at)::bigint::text
WHERE role = 'customer' 
AND customer_id IS NULL;

-- Step 7: Now handle duplicates with a simple approach
DO $$
DECLARE
    rec RECORD;
    profile_rec RECORD;
    counter INTEGER;
BEGIN
    FOR rec IN 
        SELECT customer_id 
        FROM profiles 
        WHERE customer_id IS NOT NULL 
        GROUP BY customer_id 
        HAVING COUNT(*) > 1
    LOOP
        counter := 1;
        
        -- Update all but the first occurrence
        FOR profile_rec IN 
            SELECT id 
            FROM profiles 
            WHERE customer_id = rec.customer_id 
            ORDER BY created_at 
            OFFSET 1
        LOOP
            counter := counter + 1;
            UPDATE profiles 
            SET customer_id = rec.customer_id || '_' || counter
            WHERE id = profile_rec.id;
        END LOOP;
        
        RAISE NOTICE 'Fixed duplicates for: %', rec.customer_id;
    END LOOP;
END $$;

-- Step 8: Verify all customer_ids now match the required format
SELECT customer_id, COUNT(*) as count
FROM profiles 
WHERE customer_id IS NOT NULL 
AND customer_id !~ '^[A-Z0-9_]{3,30}$'
GROUP BY customer_id;

-- Step 9: Verify no duplicates remain
SELECT customer_id, COUNT(*) as count
FROM profiles 
WHERE customer_id IS NOT NULL 
GROUP BY customer_id 
HAVING COUNT(*) > 1;

COMMIT;

-- Final status
SELECT 'DATA_FORMAT_FIX_COMPLETE' as status,
       'Ready for constraint addition' as message;
