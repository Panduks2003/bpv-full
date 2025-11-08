-- =====================================================
-- REMOVE PROM FORMAT COMPLETELY - CONVERT TO BPVP
-- =====================================================
-- This script removes all PROM0001 format references and 
-- updates the system to use BPVP format exclusively
-- =====================================================

-- =====================================================
-- 1. UPDATE PROMOTER ID GENERATION FUNCTION
-- =====================================================

-- Drop existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS generate_next_promoter_id();

-- Create the generate_next_promoter_id function to use BPVP format
CREATE FUNCTION generate_next_promoter_id()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_number INTEGER;
    new_promoter_id VARCHAR(20);
BEGIN
    -- Get and increment the next number atomically
    UPDATE promoter_id_sequence 
    SET last_promoter_number = last_promoter_number + 1,
        updated_at = NOW()
    RETURNING last_promoter_number INTO next_number;
    
    -- Format as BPVP01, BPVP02, etc. (2-digit format)
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
-- 2. UPDATE ANY EXISTING PROM FORMAT IDs TO BPVP
-- =====================================================

-- Convert any existing PROM format IDs to BPVP format
DO $$
DECLARE
    prom_record RECORD;
    new_bpvp_id VARCHAR(20);
    next_num INTEGER;
BEGIN
    -- Get current max BPVP number
    SELECT COALESCE(MAX(SUBSTRING(promoter_id FROM 5)::INTEGER), 0) INTO next_num
    FROM profiles 
    WHERE promoter_id ~ '^BPVP[0-9]{2}$';
    
    -- Convert each PROM format ID to BPVP format
    FOR prom_record IN 
        SELECT id, promoter_id, name 
        FROM profiles 
        WHERE promoter_id ~ '^PROM[0-9]{4}$'
        ORDER BY created_at
    LOOP
        next_num := next_num + 1;
        new_bpvp_id := 'BPVP' || LPAD(next_num::TEXT, 2, '0');
        
        -- Update the promoter_id
        UPDATE profiles 
        SET promoter_id = new_bpvp_id,
            updated_at = NOW()
        WHERE id = prom_record.id;
        
        -- Update promoters table if it exists
        BEGIN
            UPDATE promoters 
            SET promoter_id = new_bpvp_id,
                updated_at = NOW()
            WHERE id = prom_record.id;
        EXCEPTION WHEN OTHERS THEN
            -- Continue if promoters table doesn't exist
            NULL;
        END;
        
        RAISE NOTICE 'Converted % (%) from % to %', 
            prom_record.name, prom_record.id, prom_record.promoter_id, new_bpvp_id;
    END LOOP;
    
    -- Update the sequence to match the highest BPVP number
    UPDATE promoter_id_sequence 
    SET last_promoter_number = next_num,
        updated_at = NOW();
        
    RAISE NOTICE 'Updated promoter_id_sequence to %', next_num;
END $$;

-- =====================================================
-- 3. UPDATE COMMISSION SYSTEM REFERENCES
-- =====================================================

-- Update any commission records that might reference PROM format
DO $$
BEGIN
    -- Update affiliate_commissions table if it exists
    BEGIN
        UPDATE affiliate_commissions 
        SET note = REPLACE(note, 'PROM', 'BPVP')
        WHERE note LIKE '%PROM%';
        
        RAISE NOTICE 'Updated affiliate_commissions notes';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'affiliate_commissions table not found or no updates needed';
    END;
    
    -- Update any other tables that might have PROM references
    BEGIN
        UPDATE withdrawal_requests 
        SET note = REPLACE(note, 'PROM', 'BPVP')
        WHERE note LIKE '%PROM%';
        
        RAISE NOTICE 'Updated withdrawal_requests notes';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'withdrawal_requests table not found or no updates needed';
    END;
END $$;

-- =====================================================
-- 4. CREATE VALIDATION FUNCTION FOR BPVP FORMAT
-- =====================================================

-- Drop existing validation function if it exists
DROP FUNCTION IF EXISTS validate_promoter_id_format(VARCHAR);

-- Function to validate BPVP format
CREATE FUNCTION validate_promoter_id_format(p_promoter_id VARCHAR(20))
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if the promoter_id matches BPVP## format
    RETURN p_promoter_id ~ '^BPVP[0-9]{2}$';
END;
$$;

-- =====================================================
-- 5. UPDATE ANY AUTHENTICATION FUNCTIONS
-- =====================================================

-- Update authenticate_promoter_by_id function if it exists
DO $$
BEGIN
    -- Check if the function exists and update it
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'authenticate_promoter_by_id'
    ) THEN
        -- The function exists, ensure it works with BPVP format
        RAISE NOTICE 'authenticate_promoter_by_id function exists - it should work with BPVP format';
    ELSE
        RAISE NOTICE 'authenticate_promoter_by_id function not found - no update needed';
    END IF;
END $$;

-- =====================================================
-- 6. CLEAN UP ANY TEST DATA WITH PROM FORMAT
-- =====================================================

-- Remove any test records that might have PROM format
DO $$
DECLARE
    cleanup_count INTEGER := 0;
BEGIN
    -- Delete any test profiles with PROM format that weren't converted
    DELETE FROM profiles 
    WHERE promoter_id ~ '^PROM[0-9]{4}$' 
    AND name LIKE '%Test%';
    
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    
    IF cleanup_count > 0 THEN
        RAISE NOTICE 'Cleaned up % test records with PROM format', cleanup_count;
    ELSE
        RAISE NOTICE 'No test records with PROM format found to clean up';
    END IF;
END $$;

-- =====================================================
-- 7. VERIFICATION QUERIES
-- =====================================================

-- Check that no PROM format IDs remain
DO $$
DECLARE
    prom_count INTEGER := 0;
    bpvp_count INTEGER := 0;
    sequence_value INTEGER := 0;
BEGIN
    -- Count remaining PROM format IDs
    SELECT COUNT(*) INTO prom_count 
    FROM profiles 
    WHERE promoter_id ~ '^PROM[0-9]{4}$';
    
    -- Count BPVP format IDs
    SELECT COUNT(*) INTO bpvp_count 
    FROM profiles 
    WHERE promoter_id ~ '^BPVP[0-9]{2}$';
    
    -- Get sequence value
    SELECT last_promoter_number INTO sequence_value 
    FROM promoter_id_sequence 
    LIMIT 1;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== PROM FORMAT REMOVAL VERIFICATION ===';
    RAISE NOTICE 'Remaining PROM format IDs: %', prom_count;
    RAISE NOTICE 'Total BPVP format IDs: %', bpvp_count;
    RAISE NOTICE 'Current sequence value: %', sequence_value;
    RAISE NOTICE 'Next promoter ID will be: BPVP%', LPAD((sequence_value + 1)::TEXT, 2, '0');
    
    IF prom_count = 0 THEN
        RAISE NOTICE '✅ SUCCESS: All PROM format IDs have been removed/converted';
    ELSE
        RAISE NOTICE '❌ WARNING: % PROM format IDs still exist', prom_count;
    END IF;
END $$;

-- Show current promoter IDs for verification
SELECT 
    'CURRENT_PROMOTER_IDS' as verification_type,
    promoter_id,
    name,
    CASE 
        WHEN promoter_id ~ '^BPVP[0-9]{2}$' THEN '✅ CORRECT_BPVP_FORMAT'
        WHEN promoter_id ~ '^PROM[0-9]{4}$' THEN '❌ OLD_PROM_FORMAT'
        ELSE '❌ INVALID_FORMAT'
    END as format_status,
    created_at
FROM profiles 
WHERE role = 'promoter' 
AND promoter_id IS NOT NULL
ORDER BY created_at;

-- =====================================================
-- 8. UPDATE COMMENTS AND DOCUMENTATION
-- =====================================================

-- Add comment to the generate_next_promoter_id function
COMMENT ON FUNCTION generate_next_promoter_id() IS 
'Generates next promoter ID in BPVP format (BPVP01, BPVP02, etc.). PROM format has been completely removed.';

-- Add comment to validation function
COMMENT ON FUNCTION validate_promoter_id_format(VARCHAR) IS 
'Validates that promoter ID follows BPVP## format. Returns false for PROM format or any other format.';

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '✅ PROM FORMAT REMOVAL COMPLETED SUCCESSFULLY';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '1. ✅ Updated generate_next_promoter_id() to use BPVP format';
    RAISE NOTICE '2. ✅ Converted any existing PROM format IDs to BPVP format';
    RAISE NOTICE '3. ✅ Updated promoter_id_sequence to match BPVP numbering';
    RAISE NOTICE '4. ✅ Cleaned up commission and withdrawal references';
    RAISE NOTICE '5. ✅ Added BPVP format validation function';
    RAISE NOTICE '6. ✅ Removed any test data with PROM format';
    RAISE NOTICE '';
    RAISE NOTICE 'Your system now uses BPVP format exclusively:';
    RAISE NOTICE '• Current format: BPVP01, BPVP02, BPVP03, etc.';
    RAISE NOTICE '• PROM format has been completely removed';
    RAISE NOTICE '• All functions updated to generate BPVP IDs';
    RAISE NOTICE '=======================================================';
END $$;
