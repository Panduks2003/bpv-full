-- =====================================================
-- STEP 5: CREATE REBUILD ALL HIERARCHIES FUNCTION
-- =====================================================
-- This creates the function to rebuild all promoter hierarchies

CREATE OR REPLACE FUNCTION rebuild_all_promoter_hierarchies()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    promoter_rec RECORD;
    processed_count INTEGER := 0;
    error_count INTEGER := 0;
    start_time TIMESTAMP := NOW();
BEGIN
    -- Clear all existing hierarchy data
    DELETE FROM promoter_hierarchy;
    
    -- Rebuild hierarchy for each promoter
    FOR promoter_rec IN 
        SELECT id, promoter_id, name 
        FROM profiles 
        WHERE role = 'promoter' 
        ORDER BY created_at ASC
    LOOP
        BEGIN
            PERFORM build_promoter_hierarchy_chain(promoter_rec.id);
            processed_count := processed_count + 1;
        EXCEPTION WHEN OTHERS THEN
            error_count := error_count + 1;
            RAISE WARNING 'Failed to build hierarchy for promoter %: %', promoter_rec.promoter_id, SQLERRM;
        END;
    END LOOP;
    
    RETURN json_build_object(
        'success', true,
        'processed_count', processed_count,
        'error_count', error_count,
        'duration_seconds', EXTRACT(EPOCH FROM (NOW() - start_time)),
        'message', format('Rebuilt hierarchies for %s promoters with %s errors', processed_count, error_count)
    );
END;
$$;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Step 5 Complete: Rebuild all hierarchies function created successfully';
END $$;
