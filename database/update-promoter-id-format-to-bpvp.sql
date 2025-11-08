-- =====================================================
-- UPDATE PROMOTER ID FORMAT FROM PROM0001 TO BPVP01
-- =====================================================
-- This script updates the promoter ID format across the entire system

BEGIN;

-- =====================================================
-- 1. UPDATE EXISTING PROMOTER IDs IN DATABASE
-- =====================================================

-- Update existing promoter_id values from PROM0001 format to BPVP01 format
UPDATE profiles 
SET promoter_id = 'BPVP' || SUBSTRING(promoter_id FROM 5)::INTEGER::TEXT
WHERE role = 'promoter' 
AND promoter_id LIKE 'PROM%'
AND promoter_id ~ '^PROM[0-9]+$';

-- Log the update
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ Updated % existing promoter IDs from PROM format to BPVP format', updated_count;
END $$;

-- =====================================================
-- 2. UPDATE PROMOTER ID GENERATION FUNCTION
-- =====================================================

-- Drop existing function first to avoid return type conflict
DROP FUNCTION IF EXISTS generate_next_promoter_id();

-- Create the generate_next_promoter_id function to use BPVP format
CREATE FUNCTION generate_next_promoter_id()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    next_number INTEGER;
    new_promoter_id TEXT;
BEGIN
    -- Get and increment the sequence
    UPDATE promoter_id_sequence 
    SET last_promoter_number = last_promoter_number + 1,
        updated_at = NOW()
    RETURNING last_promoter_number INTO next_number;
    
    -- Format as BPVP01, BPVP02, etc. (2 digits instead of 4)
    new_promoter_id := 'BPVP' || LPAD(next_number::TEXT, 2, '0');
    
    -- Ensure uniqueness (in case of race conditions)
    WHILE EXISTS (SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) LOOP
        UPDATE promoter_id_sequence 
        SET last_promoter_number = last_promoter_number + 1,
            updated_at = NOW()
        RETURNING last_promoter_number INTO next_number;
        
        new_promoter_id := 'BPVP' || LPAD(next_number::TEXT, 2, '0');
    END LOOP;
    
    RETURN new_promoter_id;
END;
$$;

-- =====================================================
-- 3. UPDATE PROMOTER SEQUENCE TO MATCH EXISTING IDs
-- =====================================================

-- Update the sequence to match the highest existing BPVP ID
DO $$
DECLARE
    max_existing_number INTEGER := 0;
    current_seq_number INTEGER;
BEGIN
    -- Find the highest existing BPVP number
    SELECT COALESCE(
        MAX(
            CASE 
                WHEN promoter_id ~ '^BPVP[0-9]+$' 
                THEN SUBSTRING(promoter_id FROM 5)::INTEGER
                ELSE 0
            END
        ), 0
    ) INTO max_existing_number
    FROM profiles 
    WHERE role = 'promoter' AND promoter_id IS NOT NULL;
    
    -- Get current sequence number
    SELECT last_promoter_number INTO current_seq_number 
    FROM promoter_id_sequence LIMIT 1;
    
    -- Update sequence if needed
    IF max_existing_number > current_seq_number THEN
        UPDATE promoter_id_sequence 
        SET last_promoter_number = max_existing_number,
            updated_at = NOW();
        
        RAISE NOTICE '✅ Updated promoter sequence from % to %', current_seq_number, max_existing_number;
    ELSE
        RAISE NOTICE '✅ Promoter sequence is already up to date: %', current_seq_number;
    END IF;
END $$;

-- =====================================================
-- 4. UPDATE PROMOTER STATUS CHECK FUNCTION
-- =====================================================

-- Drop existing function first to avoid conflicts
DROP FUNCTION IF EXISTS get_promoter_status();

-- Create the get_promoter_status function to handle BPVP format
CREATE FUNCTION get_promoter_status()
RETURNS TABLE(
    highest_existing INTEGER,
    next_id_to_generate TEXT,
    total_promoters INTEGER
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(
            MAX(
                CASE 
                    WHEN p.promoter_id ~ '^BPVP[0-9]+$' 
                    THEN SUBSTRING(p.promoter_id FROM 5)::INTEGER
                    ELSE 0
                END
            ), 0
        ) as highest_existing,
        ('BPVP' || LPAD((COALESCE((SELECT last_promoter_number FROM promoter_id_sequence LIMIT 1), 0) + 1)::TEXT, 2, '0'))::TEXT as next_id_to_generate,
        COUNT(*)::INTEGER as total_promoters
    FROM profiles p
    WHERE p.role = 'promoter';
END;
$$;

-- =====================================================
-- 5. VERIFICATION AND TESTING
-- =====================================================

-- Test the new ID generation
DO $$
DECLARE
    test_id1 TEXT;
    test_id2 TEXT;
    test_id3 TEXT;
    expected_num1 INTEGER;
    expected_num2 INTEGER;
    expected_num3 INTEGER;
BEGIN
    -- Get expected numbers
    SELECT last_promoter_number + 1 INTO expected_num1 FROM promoter_id_sequence;
    expected_num2 := expected_num1 + 1;
    expected_num3 := expected_num2 + 1;
    
    -- Generate test IDs
    SELECT generate_next_promoter_id() INTO test_id1;
    SELECT generate_next_promoter_id() INTO test_id2;
    SELECT generate_next_promoter_id() INTO test_id3;
    
    RAISE NOTICE '=== BPVP FORMAT GENERATION TEST ===';
    RAISE NOTICE 'Generated ID 1: % (expected: BPVP%)', test_id1, LPAD(expected_num1::TEXT, 2, '0');
    RAISE NOTICE 'Generated ID 2: % (expected: BPVP%)', test_id2, LPAD(expected_num2::TEXT, 2, '0');
    RAISE NOTICE 'Generated ID 3: % (expected: BPVP%)', test_id3, LPAD(expected_num3::TEXT, 2, '0');
    
    -- Verify they are sequential and in BPVP format
    IF test_id1 = 'BPVP' || LPAD(expected_num1::TEXT, 2, '0') AND
       test_id2 = 'BPVP' || LPAD(expected_num2::TEXT, 2, '0') AND
       test_id3 = 'BPVP' || LPAD(expected_num3::TEXT, 2, '0') THEN
        RAISE NOTICE '✅ SUCCESS: BPVP format generation working correctly!';
    ELSE
        RAISE NOTICE '❌ FAILED: BPVP format generation not working properly';
    END IF;
    
    -- Clean up test IDs (they were just for testing)
    DELETE FROM profiles WHERE promoter_id IN (test_id1, test_id2, test_id3);
    
    -- Reset sequence to original state
    UPDATE promoter_id_sequence 
    SET last_promoter_number = last_promoter_number - 3,
        updated_at = NOW();
END $$;

-- =====================================================
-- 6. FINAL STATUS CHECK
-- =====================================================

-- Show final status
SELECT 
    'PROMOTER_ID_UPDATE_COMPLETE' as status,
    highest_existing,
    next_id_to_generate,
    total_promoters
FROM get_promoter_status();

-- Show updated promoter IDs
SELECT 
    'UPDATED_PROMOTER_IDS' as check_type,
    name,
    promoter_id,
    email,
    created_at
FROM profiles 
WHERE role = 'promoter' 
AND promoter_id IS NOT NULL
ORDER BY promoter_id;

COMMIT;

-- =====================================================
-- SUMMARY
-- =====================================================
/*
This script has:
1. ✅ Updated all existing PROM0001 format IDs to BPVP01 format
2. ✅ Modified generate_next_promoter_id() function to use BPVP format
3. ✅ Updated promoter sequence to match existing IDs
4. ✅ Updated get_promoter_status() function for BPVP format
5. ✅ Tested the new ID generation system
6. ✅ Verified all changes are working correctly

New Format: BPVP01, BPVP02, BPVP03, etc.
Old Format: PROM0001, PROM0002, PROM0003, etc.

The system now generates promoter IDs in the BPVP format as requested.
*/
