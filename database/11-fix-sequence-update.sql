-- =====================================================
-- FIX SEQUENCE UPDATE ISSUE
-- =====================================================
-- The generate_next_promoter_id function has an UPDATE without WHERE clause
-- This fixes that specific issue

-- =====================================================
-- 1. FIX THE GENERATE_NEXT_PROMOTER_ID FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION generate_next_promoter_id()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    next_number INTEGER;
    new_promoter_id VARCHAR(20);
BEGIN
    -- Ensure the sequence table has at least one row
    INSERT INTO promoter_id_sequence (last_promoter_number) 
    SELECT 0 
    WHERE NOT EXISTS (SELECT 1 FROM promoter_id_sequence);
    
    -- Get and increment the next number atomically with proper WHERE clause
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
    
    -- Format as PROM0001, PROM0002, etc.
    new_promoter_id := 'PROM' || LPAD(next_number::TEXT, 4, '0');
    
    -- Ensure uniqueness (in case of race conditions)
    WHILE EXISTS (SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) LOOP
        UPDATE promoter_id_sequence 
        SET last_promoter_number = last_promoter_number + 1,
            updated_at = NOW()
        WHERE id = (SELECT MIN(id) FROM promoter_id_sequence)  -- Add WHERE clause
        RETURNING last_promoter_number INTO next_number;
        
        new_promoter_id := 'PROM' || LPAD(next_number::TEXT, 4, '0');
    END LOOP;
    
    RETURN new_promoter_id;
END;
$$;

-- =====================================================
-- 2. TEST THE FIXED FUNCTION
-- =====================================================

DO $$
DECLARE
    test_id VARCHAR(20);
BEGIN
    -- Test ID generation
    SELECT generate_next_promoter_id() INTO test_id;
    RAISE NOTICE '✅ SUCCESS: Generated promoter ID: %', test_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR in generate_next_promoter_id: %', SQLERRM;
END $$;

-- =====================================================
-- 3. TEST FULL PROMOTER CREATION
-- =====================================================

DO $$
DECLARE
    test_result JSON;
BEGIN
    -- Test the full promoter creation function
    SELECT create_unified_promoter(
        'Test Fixed Function',
        'testpass123',
        '9876543210',
        'test@fixed.com',
        'Test Address',
        NULL,
        'Affiliate',
        'Active'
    ) INTO test_result;
    
    -- Check result
    IF (test_result->>'success')::boolean THEN
        RAISE NOTICE '✅ SUCCESS: Promoter creation works!';
        RAISE NOTICE 'Generated Promoter ID: %', test_result->>'promoter_id';
        RAISE NOTICE 'User ID: %', test_result->>'user_id';
        
        -- Clean up test data
        DELETE FROM profiles WHERE id = (test_result->>'user_id')::UUID;
        RAISE NOTICE '🧹 Test promoter cleaned up';
    ELSE
        RAISE NOTICE '❌ FAILED: %', test_result->>'error';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR in promoter creation: %', SQLERRM;
END $$;

-- =====================================================
-- 4. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'SEQUENCE UPDATE FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Fixed the UPDATE without WHERE clause issue';
    RAISE NOTICE 'The generate_next_promoter_id function should now work';
    RAISE NOTICE 'Try creating a promoter from the admin UI!';
    RAISE NOTICE '=======================================================';
END $$;
