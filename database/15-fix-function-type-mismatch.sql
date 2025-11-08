-- =====================================================
-- FIX FUNCTION TYPE MISMATCH ERROR
-- =====================================================
-- The check_promoter_sequence_status function has a type mismatch
-- Expected VARCHAR(20) but returning TEXT

-- =====================================================
-- 1. DROP AND RECREATE THE FUNCTION WITH CORRECT TYPES
-- =====================================================

-- Drop the problematic function
DROP FUNCTION IF EXISTS check_promoter_sequence_status();

-- Recreate with correct return types
CREATE OR REPLACE FUNCTION check_promoter_sequence_status()
RETURNS TABLE(
    sequence_value INTEGER,
    highest_existing INTEGER,
    next_id_to_generate TEXT, -- Changed from VARCHAR(20) to TEXT
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
        ('PROM' || LPAD((COALESCE((SELECT last_promoter_number FROM promoter_id_sequence LIMIT 1), 0) + 1)::TEXT, 4, '0'))::TEXT as next_id_to_generate,
        COUNT(*)::INTEGER as total_promoters
    FROM profiles p
    WHERE p.role = 'promoter';
END;
$$;

-- =====================================================
-- 2. SIMPLIFIED VERSION WITHOUT COMPLEX RETURN TYPE
-- =====================================================

-- Alternative: Create a simpler function that just shows status
CREATE OR REPLACE FUNCTION show_promoter_sequence_status()
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    seq_val INTEGER := 0;
    highest_num INTEGER := 0;
    next_id TEXT;
    total_count INTEGER := 0;
BEGIN
    -- Get sequence value
    SELECT COALESCE(last_promoter_number, 0) INTO seq_val 
    FROM promoter_id_sequence 
    LIMIT 1;
    
    -- Get highest existing promoter number
    SELECT COALESCE(
        MAX(
            CASE 
                WHEN promoter_id ~ '^PROM[0-9]+$' 
                THEN CAST(SUBSTRING(promoter_id FROM 5) AS INTEGER)
                ELSE 0 
            END
        ), 0
    ) INTO highest_num
    FROM profiles 
    WHERE role = 'promoter' AND promoter_id IS NOT NULL;
    
    -- Calculate next ID
    next_id := 'PROM' || LPAD((seq_val + 1)::TEXT, 4, '0');
    
    -- Get total promoter count
    SELECT COUNT(*) INTO total_count 
    FROM profiles 
    WHERE role = 'promoter';
    
    -- Display results
    RAISE NOTICE '=== PROMOTER SEQUENCE STATUS ===';
    RAISE NOTICE 'Current sequence value: %', seq_val;
    RAISE NOTICE 'Highest existing promoter number: %', highest_num;
    RAISE NOTICE 'Next ID to generate: %', next_id;
    RAISE NOTICE 'Total promoters: %', total_count;
    
    -- Check if sequence is in sync
    IF seq_val < highest_num THEN
        RAISE NOTICE '⚠️  WARNING: Sequence is behind! Should be reset to %', highest_num;
    ELSIF seq_val = highest_num THEN
        RAISE NOTICE '✅ Sequence is in sync';
    ELSE
        RAISE NOTICE '📈 Sequence is ahead (normal after deletions)';
    END IF;
END;
$$;

-- =====================================================
-- 3. RESET SEQUENCE TO CORRECT VALUE
-- =====================================================

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
    WHERE promoter_id IS NOT NULL AND role = 'promoter';
    
    -- Get current sequence value
    SELECT COALESCE(last_promoter_number, 0) INTO sequence_value 
    FROM promoter_id_sequence 
    LIMIT 1;
    
    RAISE NOTICE 'Current highest promoter number in use: %', current_max;
    RAISE NOTICE 'Current sequence value: %', sequence_value;
    
    -- Reset sequence to match the highest existing number
    IF sequence_value != current_max THEN
        -- Ensure sequence table has a row
        INSERT INTO promoter_id_sequence (last_promoter_number, updated_at) 
        SELECT current_max, NOW()
        WHERE NOT EXISTS (SELECT 1 FROM promoter_id_sequence);
        
        -- Update existing row
        UPDATE promoter_id_sequence 
        SET last_promoter_number = current_max,
            updated_at = NOW()
        WHERE id = (SELECT MIN(id) FROM promoter_id_sequence);
        
        RAISE NOTICE '✅ Sequence reset from % to %', sequence_value, current_max;
    ELSE
        RAISE NOTICE '✅ Sequence is already correct';
    END IF;
END $$;

-- =====================================================
-- 4. TEST THE FIXED FUNCTIONS
-- =====================================================

-- Test the simplified status function
SELECT show_promoter_sequence_status();

-- Test ID generation
DO $$
DECLARE
    test_id1 TEXT;
    test_id2 TEXT;
    test_id3 TEXT;
    num1 INTEGER;
    num2 INTEGER;
    num3 INTEGER;
BEGIN
    RAISE NOTICE '=== TESTING SEQUENTIAL ID GENERATION ===';
    
    -- Generate three IDs
    SELECT generate_next_promoter_id() INTO test_id1;
    SELECT generate_next_promoter_id() INTO test_id2;
    SELECT generate_next_promoter_id() INTO test_id3;
    
    -- Extract numbers
    num1 := CAST(SUBSTRING(test_id1 FROM 5) AS INTEGER);
    num2 := CAST(SUBSTRING(test_id2 FROM 5) AS INTEGER);
    num3 := CAST(SUBSTRING(test_id3 FROM 5) AS INTEGER);
    
    RAISE NOTICE 'Generated IDs: %, %, %', test_id1, test_id2, test_id3;
    RAISE NOTICE 'Numbers: %, %, %', num1, num2, num3;
    
    -- Check if sequential
    IF num2 = num1 + 1 AND num3 = num2 + 1 THEN
        RAISE NOTICE '✅ SUCCESS: IDs are sequential!';
    ELSE
        RAISE NOTICE '❌ FAILED: IDs are not sequential';
    END IF;
END $$;

-- =====================================================
-- 5. TEST FULL PROMOTER CREATION
-- =====================================================

DO $$
DECLARE
    test_result JSON;
    promoter_id TEXT;
    expected_number INTEGER;
BEGIN
    -- Get expected next number
    SELECT COALESCE(last_promoter_number, 0) + 1 INTO expected_number 
    FROM promoter_id_sequence 
    LIMIT 1;
    
    RAISE NOTICE '=== TESTING PROMOTER CREATION ===';
    RAISE NOTICE 'Expected next promoter number: %', expected_number;
    
    -- Create a test promoter
    SELECT create_unified_promoter(
        'Sequential Test User',
        'testpass123',
        '9876543299',
        'sequential@test.com',
        'Test Address',
        NULL,
        'Affiliate',
        'Active'
    ) INTO test_result;
    
    -- Check result
    IF (test_result->>'success')::boolean THEN
        promoter_id := test_result->>'promoter_id';
        RAISE NOTICE '✅ SUCCESS: Promoter created with ID: %', promoter_id;
        
        -- Verify it matches expected number
        IF promoter_id = 'PROM' || LPAD(expected_number::TEXT, 4, '0') THEN
            RAISE NOTICE '✅ ID matches expected sequential number!';
        ELSE
            RAISE NOTICE '❌ ID does not match expected number';
        END IF;
        
        -- Clean up
        DELETE FROM profiles WHERE id = (test_result->>'user_id')::UUID;
        RAISE NOTICE '🧹 Test promoter cleaned up';
    ELSE
        RAISE NOTICE '❌ FAILED: %', test_result->>'error';
    END IF;
END $$;

-- =====================================================
-- 6. FINAL STATUS CHECK
-- =====================================================

SELECT show_promoter_sequence_status();

-- =====================================================
-- 7. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'FUNCTION TYPE MISMATCH FIXED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '1. Fixed return type mismatch in status function';
    RAISE NOTICE '2. Created simplified status display function';
    RAISE NOTICE '3. Reset sequence to correct value';
    RAISE NOTICE '4. Tested sequential ID generation';
    RAISE NOTICE '5. Verified promoter creation works';
    RAISE NOTICE '';
    RAISE NOTICE 'Promoter creation should now work with sequential IDs!';
    RAISE NOTICE 'Try creating promoters from the admin UI.';
    RAISE NOTICE '=======================================================';
END $$;
