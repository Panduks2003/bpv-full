-- =====================================================
-- STEP 4: CREATE BUILD HIERARCHY FUNCTION
-- =====================================================
-- This creates the main function to build hierarchy chains

CREATE OR REPLACE FUNCTION build_promoter_hierarchy_chain(p_promoter_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    promoter_rec RECORD;
    current_parent_id UUID;
    current_level INTEGER := 1;
    path_elements TEXT[] := ARRAY[]::TEXT[];
    full_path TEXT;
BEGIN
    -- Get promoter details
    SELECT id, promoter_id as code, parent_promoter_id, name
    INTO promoter_rec
    FROM profiles 
    WHERE id = p_promoter_id AND role = 'promoter';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Promoter not found: %', p_promoter_id;
    END IF;
    
    -- Clear existing hierarchy for this promoter
    DELETE FROM promoter_hierarchy WHERE promoter_id = p_promoter_id;
    
    -- Start with the promoter's code in the path
    path_elements := ARRAY[promoter_rec.code];
    current_parent_id := promoter_rec.parent_promoter_id;
    
    -- Build hierarchy chain by traversing up to root
    WHILE current_parent_id IS NOT NULL LOOP
        DECLARE
            parent_rec RECORD;
        BEGIN
            -- Get parent details
            SELECT id, promoter_id as code, parent_promoter_id, name
            INTO parent_rec
            FROM profiles 
            WHERE id = current_parent_id AND role IN ('promoter', 'admin');
            
            IF NOT FOUND THEN
                -- Parent not found, break the chain
                EXIT;
            END IF;
            
            -- Add parent to path
            path_elements := path_elements || parent_rec.code;
            
            -- Create hierarchy record
            INSERT INTO promoter_hierarchy (
                promoter_id,
                ancestor_id,
                promoter_code,
                ancestor_code,
                level,
                relationship_type,
                path_to_root,
                created_at,
                updated_at
            ) VALUES (
                p_promoter_id,
                parent_rec.id,
                promoter_rec.code,
                parent_rec.code,
                current_level,
                get_relationship_type(current_level),
                array_to_string(path_elements, '->'),
                NOW(),
                NOW()
            );
            
            -- Move up one level
            current_parent_id := parent_rec.parent_promoter_id;
            current_level := current_level + 1;
            
            -- Prevent infinite loops (safety check)
            IF current_level > 50 THEN
                RAISE WARNING 'Hierarchy depth exceeded 50 levels for promoter %', promoter_rec.code;
                EXIT;
            END IF;
        END;
    END LOOP;
    
    -- Log the hierarchy creation
    RAISE NOTICE 'Built hierarchy chain for promoter % with % levels', promoter_rec.code, current_level - 1;
END;
$$;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Step 4 Complete: Build hierarchy function created successfully';
END $$;
