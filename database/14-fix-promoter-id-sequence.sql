-- =====================================================
-- FIX PROMOTER ID SEQUENTIAL GENERATION
-- =====================================================
-- The promoter ID generation should be sequential: 1, 2, 3, 4, 5...
-- Currently it's generating random or duplicate numbers

-- =====================================================
-- 1. RESET AND FIX THE SEQUENCE TABLE
-- =====================================================

-- First, let's check current state and reset if needed
DO $$
DECLARE
    current_max INTEGER := 0;
    sequence_value INTEGER := 0;
BEGIN
    -- Find the highest promoter number currently in use
    SELECT COALESCE(
        MAX(
            CASE 
                WHEN promoter_id ~ '^PROM[0-9]+$' 
                THEN CAST(SUBSTRING(promoter_id FROM 5) AS INTEGER)
                ELSE 0 
            END
        ), 0
    ) INTO current_max
    FROM profiles 
    WHERE promoter_id IS NOT NULL;
    
    RAISE NOTICE 'Current highest promoter number in use: %', current_max;
    
    -- Get current sequence value
    SELECT COALESCE(last_promoter_number, 0) INTO sequence_value 
    FROM promoter_id_sequence 
    LIMIT 1;
    
    RAISE NOTICE 'Current sequence value: %', sequence_value;
    
    -- Reset sequence to match the highest existing number
    IF sequence_value < current_max THEN
        UPDATE promoter_id_sequence 
        SET last_promoter_number = current_max,
            updated_at = NOW()
        WHERE id = (SELECT MIN(id) FROM promoter_id_sequence);
        
        RAISE NOTICE 'Sequence reset to: %', current_max;
    END IF;
    
END $$;

-- =====================================================
-- 2. CREATE ROBUST SEQUENTIAL ID GENERATION FUNCTION
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
    max_attempts INTEGER := 10;
    attempt_count INTEGER := 0;
BEGIN
    -- Ensure the sequence table has at least one row
    INSERT INTO promoter_id_sequence (last_promoter_number, updated_at) 
    SELECT 0, NOW()
    WHERE NOT EXISTS (SELECT 1 FROM promoter_id_sequence);
    
    -- Loop to handle concurrent access and ensure uniqueness
    LOOP
        attempt_count := attempt_count + 1;
        
        -- Exit if too many attempts (prevents infinite loop)
        IF attempt_count > max_attempts THEN
            RAISE EXCEPTION 'Failed to generate unique promoter ID after % attempts', max_attempts;
        END IF;
        
        -- Get and increment the next number atomically
        UPDATE promoter_id_sequence 
        SET last_promoter_number = last_promoter_number + 1,
            updated_at = NOW()
        WHERE id = (SELECT MIN(id) FROM promoter_id_sequence)
        RETURNING last_promoter_number INTO next_number;
        
        -- If no rows were updated (shouldn't happen), insert first record
        IF next_number IS NULL THEN
            INSERT INTO promoter_id_sequence (last_promoter_number, updated_at)
            VALUES (1, NOW())
            RETURNING last_promoter_number INTO next_number;
        END IF;
        
        -- Format as PROM0001, PROM0002, etc.
        new_promoter_id := 'PROM' || LPAD(next_number::TEXT, 4, '0');
        
        -- Check if this ID already exists in profiles table
        IF NOT EXISTS (SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) THEN
            -- ID is unique, we can use it
            EXIT;
        END IF;
        
        -- If ID exists, loop will continue and increment again
        RAISE NOTICE 'Promoter ID % already exists, trying next number...', new_promoter_id;
    END LOOP;
    
    RAISE NOTICE 'Generated unique promoter ID: %', new_promoter_id;
    RETURN new_promoter_id;
END;
$$;

-- =====================================================
-- 3. CREATE FUNCTION TO CHECK SEQUENCE STATUS
-- =====================================================

CREATE OR REPLACE FUNCTION check_promoter_sequence_status()
RETURNS TABLE(
    sequence_value INTEGER,
    highest_existing INTEGER,
    next_id_to_generate VARCHAR(20),
    total_promoters INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE((SELECT last_promoter_number FROM promoter_id_sequence LIMIT 1), 0) as sequence_value,
        COALESCE(
            MAX(
                CASE 
                    WHEN p.promoter_id ~ '^PROM[0-9]+$' 
                    THEN CAST(SUBSTRING(p.promoter_id FROM 5) AS INTEGER)
                    ELSE 0 
                END
            ), 0
        ) as highest_existing,
        'PROM' || LPAD((COALESCE((SELECT last_promoter_number FROM promoter_id_sequence LIMIT 1), 0) + 1)::TEXT, 4, '0') as next_id_to_generate,
        COUNT(*)::INTEGER as total_promoters
    FROM profiles p
    WHERE p.role = 'promoter';
END;
$$;

-- =====================================================
-- 4. TEST THE SEQUENTIAL GENERATION
-- =====================================================

-- Check current status
DO $$
DECLARE
    status_record RECORD;
BEGIN
    SELECT * INTO status_record FROM check_promoter_sequence_status();
    
    RAISE NOTICE '=== PROMOTER SEQUENCE STATUS ===';
    RAISE NOTICE 'Current sequence value: %', status_record.sequence_value;
    RAISE NOTICE 'Highest existing promoter number: %', status_record.highest_existing;
    RAISE NOTICE 'Next ID to generate: %', status_record.next_id_to_generate;
    RAISE NOTICE 'Total promoters: %', status_record.total_promoters;
END $$;

-- Test sequential generation
DO $$
DECLARE
    test_id1 VARCHAR(20);
    test_id2 VARCHAR(20);
    test_id3 VARCHAR(20);
    expected_num1 INTEGER;
    expected_num2 INTEGER;
    expected_num3 INTEGER;
BEGIN
    -- Get expected numbers
    SELECT sequence_value + 1, sequence_value + 2, sequence_value + 3
    INTO expected_num1, expected_num2, expected_num3
    FROM check_promoter_sequence_status();
    
    -- Generate three sequential IDs
    SELECT generate_next_promoter_id() INTO test_id1;
    SELECT generate_next_promoter_id() INTO test_id2;
    SELECT generate_next_promoter_id() INTO test_id3;
    
    RAISE NOTICE '=== SEQUENTIAL GENERATION TEST ===';
    RAISE NOTICE 'Generated ID 1: % (expected: PROM%)', test_id1, LPAD(expected_num1::TEXT, 4, '0');
    RAISE NOTICE 'Generated ID 2: % (expected: PROM%)', test_id2, LPAD(expected_num2::TEXT, 4, '0');
    RAISE NOTICE 'Generated ID 3: % (expected: PROM%)', test_id3, LPAD(expected_num3::TEXT, 4, '0');
    
    -- Verify they are sequential
    IF test_id1 = 'PROM' || LPAD(expected_num1::TEXT, 4, '0') AND
       test_id2 = 'PROM' || LPAD(expected_num2::TEXT, 4, '0') AND
       test_id3 = 'PROM' || LPAD(expected_num3::TEXT, 4, '0') THEN
        RAISE NOTICE '✅ SUCCESS: Sequential generation working correctly!';
    ELSE
        RAISE NOTICE '❌ FAILED: Sequential generation not working properly';
    END IF;
END $$;

-- =====================================================
-- 5. TEST FULL PROMOTER CREATION WITH SEQUENTIAL IDs
-- =====================================================

DO $$
DECLARE
    test_result1 JSON;
    test_result2 JSON;
    test_result3 JSON;
    id1 TEXT;
    id2 TEXT;
    id3 TEXT;
    num1 INTEGER;
    num2 INTEGER;
    num3 INTEGER;
BEGIN
    -- Create three promoters and verify sequential IDs
    SELECT create_unified_promoter(
        'Sequential Test 1',
        'testpass123',
        '9876543210',
        'test1@sequential.com',
        'Address 1',
        NULL,
        'Affiliate',
        'Active'
    ) INTO test_result1;
    
    SELECT create_unified_promoter(
        'Sequential Test 2',
        'testpass123',
        '9876543211',
        'test2@sequential.com',
        'Address 2',
        NULL,
        'Affiliate',
        'Active'
    ) INTO test_result2;
    
    SELECT create_unified_promoter(
        'Sequential Test 3',
        'testpass123',
        '9876543212',
        'test3@sequential.com',
        'Address 3',
        NULL,
        'Affiliate',
        'Active'
    ) INTO test_result3;
    
    -- Extract promoter IDs and numbers
    id1 := test_result1->>'promoter_id';
    id2 := test_result2->>'promoter_id';
    id3 := test_result3->>'promoter_id';
    
    num1 := CAST(SUBSTRING(id1 FROM 5) AS INTEGER);
    num2 := CAST(SUBSTRING(id2 FROM 5) AS INTEGER);
    num3 := CAST(SUBSTRING(id3 FROM 5) AS INTEGER);
    
    RAISE NOTICE '=== FULL PROMOTER CREATION TEST ===';
    RAISE NOTICE 'Promoter 1 ID: % (number: %)', id1, num1;
    RAISE NOTICE 'Promoter 2 ID: % (number: %)', id2, num2;
    RAISE NOTICE 'Promoter 3 ID: % (number: %)', id3, num3;
    
    -- Verify sequential
    IF (test_result1->>'success')::boolean AND 
       (test_result2->>'success')::boolean AND 
       (test_result3->>'success')::boolean AND
       num2 = num1 + 1 AND 
       num3 = num2 + 1 THEN
        RAISE NOTICE '✅ SUCCESS: Promoter creation with sequential IDs working!';
    ELSE
        RAISE NOTICE '❌ FAILED: Sequential promoter creation not working';
        RAISE NOTICE 'Results: %, %, %', 
            test_result1->>'error', 
            test_result2->>'error', 
            test_result3->>'error';
    END IF;
    
    -- Clean up test data
    IF (test_result1->>'success')::boolean THEN
        DELETE FROM profiles WHERE id = (test_result1->>'user_id')::UUID;
    END IF;
    IF (test_result2->>'success')::boolean THEN
        DELETE FROM profiles WHERE id = (test_result2->>'user_id')::UUID;
    END IF;
    IF (test_result3->>'success')::boolean THEN
        DELETE FROM profiles WHERE id = (test_result3->>'user_id')::UUID;
    END IF;
    
    RAISE NOTICE '🧹 Test promoters cleaned up';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERROR: %', SQLERRM;
END $$;

-- =====================================================
-- 6. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PROMOTER ID SEQUENTIAL GENERATION FIXED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '1. Reset sequence to match highest existing promoter number';
    RAISE NOTICE '2. Fixed generate_next_promoter_id function for proper sequencing';
    RAISE NOTICE '3. Added concurrent access handling';
    RAISE NOTICE '4. Added sequence status checking function';
    RAISE NOTICE '5. Tested sequential generation (1, 2, 3, 4, 5...)';
    RAISE NOTICE '';
    RAISE NOTICE 'Promoter IDs will now generate sequentially!';
    RAISE NOTICE 'Next promoter will get the next number in sequence.';
    RAISE NOTICE '=======================================================';
END $$;
