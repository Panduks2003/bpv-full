-- =====================================================
-- FIX GENERATE_NEXT_PROMOTER_ID UPDATE WHERE CLAUSE
-- =====================================================
-- The current generate_next_promoter_id function has UPDATE statements
-- without WHERE clauses, which causes "UPDATE requires a WHERE clause" error

-- =====================================================
-- 1. FIX THE GENERATE_NEXT_PROMOTER_ID FUNCTION
-- =====================================================

-- Drop the existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS generate_next_promoter_id();

CREATE OR REPLACE FUNCTION generate_next_promoter_id()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    next_number INTEGER;
    new_promoter_id TEXT;
BEGIN
    -- Ensure the sequence table has at least one row
    INSERT INTO promoter_id_sequence (last_promoter_number, updated_at) 
    SELECT 0, NOW()
    WHERE NOT EXISTS (SELECT 1 FROM promoter_id_sequence);
    
    -- Get and increment the sequence with proper WHERE clause
    UPDATE promoter_id_sequence 
    SET last_promoter_number = last_promoter_number + 1,
        updated_at = NOW()
    WHERE id = (SELECT MIN(id) FROM promoter_id_sequence)  -- Add WHERE clause
    RETURNING last_promoter_number INTO next_number;
    
    -- If no rows were updated (empty table), insert first record
    IF next_number IS NULL THEN
        INSERT INTO promoter_id_sequence (last_promoter_number, updated_at)
        VALUES (1, NOW())
        RETURNING last_promoter_number INTO next_number;
    END IF;
    
    -- Format as BPVP01, BPVP02, etc. (2 digits)
    new_promoter_id := 'BPVP' || LPAD(next_number::TEXT, 2, '0');
    
    -- Ensure uniqueness (in case of race conditions)
    WHILE EXISTS (SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) LOOP
        UPDATE promoter_id_sequence 
        SET last_promoter_number = last_promoter_number + 1,
            updated_at = NOW()
        WHERE id = (SELECT MIN(id) FROM promoter_id_sequence)  -- Add WHERE clause
        RETURNING last_promoter_number INTO next_number;
        
        new_promoter_id := 'BPVP' || LPAD(next_number::TEXT, 2, '0');
    END LOOP;
    
    RETURN new_promoter_id;
END;
$$;

-- =====================================================
-- 2. TEST THE FIXED FUNCTION
-- =====================================================

DO $$
DECLARE
    test_id TEXT;
BEGIN
    -- Test ID generation
    SELECT generate_next_promoter_id() INTO test_id;
    RAISE NOTICE '✅ SUCCESS: Generated promoter ID: %', test_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR in generate_next_promoter_id: %', SQLERRM;
END $$;

-- =====================================================
-- 3. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'GENERATE_NEXT_PROMOTER_ID FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Fixed the UPDATE without WHERE clause issue';
    RAISE NOTICE 'The generate_next_promoter_id function now has proper WHERE clauses';
    RAISE NOTICE 'Promoter creation should now work without errors!';
    RAISE NOTICE '=======================================================';
END $$;
