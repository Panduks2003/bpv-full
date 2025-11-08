-- =====================================================
-- SIMPLE DUPLICATE FIX FOR CUSTOMER_ID
-- =====================================================
-- This script directly fixes the duplicate customer_id issue
-- =====================================================

BEGIN;

-- Step 1: Drop existing unique constraint if it exists
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Find any unique constraint on customer_id
    FOR constraint_name IN 
        SELECT c.conname
        FROM pg_constraint c 
        JOIN pg_class t ON c.conrelid = t.oid 
        WHERE t.relname = 'profiles' 
        AND c.contype = 'u' 
        AND EXISTS (
            SELECT 1 FROM pg_attribute a
            WHERE a.attrelid = t.oid 
            AND a.attname = 'customer_id'
            AND a.attnum = ANY(c.conkey)
        )
    LOOP
        EXECUTE 'ALTER TABLE profiles DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    END LOOP;
END $$;

-- Step 2: Show current duplicates
SELECT 'CURRENT_DUPLICATES' as status, customer_id, COUNT(*) as count
FROM profiles 
WHERE customer_id IS NOT NULL 
GROUP BY customer_id 
HAVING COUNT(*) > 1
ORDER BY customer_id;

-- Step 3: Fix duplicates by adding sequential numbers
DO $$
DECLARE
    rec RECORD;
    counter INTEGER;
BEGIN
    -- For each duplicate customer_id, add sequential suffix
    FOR rec IN 
        SELECT customer_id, COUNT(*) as dup_count
        FROM profiles 
        WHERE customer_id IS NOT NULL 
        GROUP BY customer_id 
        HAVING COUNT(*) > 1
    LOOP
        counter := 2; -- Start from 2 (keep first one as is)
        
        -- Update duplicates with sequential numbers
        UPDATE profiles 
        SET customer_id = rec.customer_id || '_' || counter
        WHERE id IN (
            SELECT id 
            FROM profiles 
            WHERE customer_id = rec.customer_id 
            ORDER BY created_at 
            OFFSET 1 LIMIT 1
        );
        
        counter := counter + 1;
        
        -- Handle any remaining duplicates
        WHILE EXISTS (
            SELECT 1 FROM profiles 
            WHERE customer_id = rec.customer_id 
            GROUP BY customer_id 
            HAVING COUNT(*) > 1
        ) LOOP
            UPDATE profiles 
            SET customer_id = rec.customer_id || '_' || counter
            WHERE id IN (
                SELECT id 
                FROM profiles 
                WHERE customer_id = rec.customer_id 
                ORDER BY created_at 
                LIMIT 1 OFFSET 1
            );
            counter := counter + 1;
        END LOOP;
        
        RAISE NOTICE 'Fixed duplicates for customer_id: %', rec.customer_id;
    END LOOP;
END $$;

-- Step 4: Verify no duplicates remain
SELECT 'REMAINING_DUPLICATES' as status, customer_id, COUNT(*) as count
FROM profiles 
WHERE customer_id IS NOT NULL 
GROUP BY customer_id 
HAVING COUNT(*) > 1;

-- Step 5: Add back the unique constraint
ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_unique UNIQUE (customer_id);

COMMIT;

-- Final verification
SELECT 'DUPLICATE_FIX_COMPLETE' as status, 
       'Unique constraint added successfully' as message;
