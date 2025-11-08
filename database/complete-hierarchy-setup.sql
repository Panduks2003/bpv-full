-- =====================================================
-- COMPLETE PROMOTER HIERARCHY SYSTEM SETUP
-- =====================================================
-- This single script creates the entire hierarchy system
-- Execute this file to set up everything at once
-- =====================================================

-- Start transaction for atomic setup
BEGIN;

-- Log setup start
DO $$
BEGIN
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'STARTING PROMOTER HIERARCHY SYSTEM SETUP';
    RAISE NOTICE 'Time: %', NOW();
    RAISE NOTICE '=================================================';
END $$;

-- =====================================================
-- STEP 1: DROP EXISTING OBJECTS (if they exist)
-- =====================================================

-- Drop existing objects to ensure clean setup
DROP TABLE IF EXISTS promoter_hierarchy CASCADE;
DROP FUNCTION IF EXISTS get_relationship_type(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS build_promoter_hierarchy_chain(UUID) CASCADE;
DROP FUNCTION IF EXISTS rebuild_all_promoter_hierarchies() CASCADE;

-- =====================================================
-- STEP 2: CREATE PROMOTER HIERARCHY TABLE
-- =====================================================

-- Table to store the complete hierarchy chain for each promoter
CREATE TABLE promoter_hierarchy (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promoter_id UUID NOT NULL,
    ancestor_id UUID NOT NULL,
    promoter_code VARCHAR(20) NOT NULL, -- BPVP01, BPVP02, etc.
    ancestor_code VARCHAR(20) NOT NULL, -- BPVP01, BPVP02, etc.
    level INTEGER NOT NULL, -- 1=Level 1, 2=Level 2, 3=Level 3, etc.
    relationship_type VARCHAR(50) NOT NULL, -- 'Level 1', 'Level 2', 'Level 3', etc.
    path_to_root TEXT NOT NULL, -- Full path from promoter to root (e.g., "BPVP29->BPVP23->BPVP06->BPVP01")
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(promoter_id, ancestor_id),
    UNIQUE(promoter_id, level),
    CHECK(level > 0),
    CHECK(promoter_id != ancestor_id)
);

RAISE NOTICE 'Table promoter_hierarchy created successfully';

-- =====================================================
-- STEP 3: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for performance
CREATE INDEX idx_promoter_hierarchy_promoter_id ON promoter_hierarchy(promoter_id);
CREATE INDEX idx_promoter_hierarchy_ancestor_id ON promoter_hierarchy(ancestor_id);
CREATE INDEX idx_promoter_hierarchy_level ON promoter_hierarchy(promoter_id, level);
CREATE INDEX idx_promoter_hierarchy_codes ON promoter_hierarchy(promoter_code, ancestor_code);

RAISE NOTICE 'Indexes created successfully';

-- =====================================================
-- STEP 4: ADD FOREIGN KEY CONSTRAINTS (OPTIONAL)
-- =====================================================

-- Try to add foreign key constraints (will skip if profiles table doesn't exist)
DO $$
BEGIN
    -- Add foreign key for promoter_id
    ALTER TABLE promoter_hierarchy 
    ADD CONSTRAINT fk_promoter_hierarchy_promoter_id 
    FOREIGN KEY (promoter_id) REFERENCES profiles(id) ON DELETE CASCADE;
    
    -- Add foreign key for ancestor_id
    ALTER TABLE promoter_hierarchy 
    ADD CONSTRAINT fk_promoter_hierarchy_ancestor_id 
    FOREIGN KEY (ancestor_id) REFERENCES profiles(id) ON DELETE CASCADE;
    
    RAISE NOTICE 'Foreign key constraints added successfully';
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Foreign key constraints could not be added (profiles table may not exist): %', SQLERRM;
END $$;

-- =====================================================
-- STEP 5: CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to get relationship type by level
CREATE OR REPLACE FUNCTION get_relationship_type(level_num INTEGER)
RETURNS VARCHAR(50)
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    RETURN 'Level ' || level_num::TEXT;
END;
$$;

RAISE NOTICE 'Helper functions created successfully';

-- =====================================================
-- STEP 6: CREATE BUILD HIERARCHY FUNCTION
-- =====================================================

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

RAISE NOTICE 'Build hierarchy function created successfully';

-- =====================================================
-- STEP 7: CREATE REBUILD ALL HIERARCHIES FUNCTION
-- =====================================================

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

RAISE NOTICE 'Rebuild all hierarchies function created successfully';

-- =====================================================
-- STEP 8: CREATE QUERY FUNCTIONS
-- =====================================================

-- Function to get promoter upline chain
CREATE OR REPLACE FUNCTION get_promoter_upline_chain(p_promoter_code VARCHAR(20))
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    promoter_id UUID;
    result JSON;
BEGIN
    -- Get promoter ID from code
    SELECT p.id INTO promoter_id 
    FROM profiles p 
    WHERE p.promoter_id = p_promoter_code AND p.role = 'promoter';
    
    IF promoter_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Promoter not found: ' || p_promoter_code
        );
    END IF;
    
    -- Get complete upline chain
    WITH upline_chain AS (
        SELECT 
            h.level,
            h.relationship_type,
            h.ancestor_code,
            h.path_to_root,
            p.name as ancestor_name,
            p.email as ancestor_email,
            p.phone as ancestor_phone,
            p.role_level,
            p.status,
            p.created_at as ancestor_created_at
        FROM promoter_hierarchy h
        JOIN profiles p ON h.ancestor_id = p.id
        WHERE h.promoter_id = promoter_id
        ORDER BY h.level ASC
    )
    SELECT json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'upline_chain', json_agg(
            json_build_object(
                'level', level,
                'relationship_type', relationship_type,
                'ancestor_code', ancestor_code,
                'ancestor_name', ancestor_name,
                'ancestor_email', ancestor_email,
                'ancestor_phone', ancestor_phone,
                'role_level', role_level,
                'status', status,
                'created_at', ancestor_created_at,
                'path_to_root', path_to_root
            ) ORDER BY level
        ),
        'total_levels', COUNT(*)
    ) INTO result
    FROM upline_chain;
    
    RETURN COALESCE(result, json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'upline_chain', '[]'::json,
        'total_levels', 0,
        'message', 'No upline found - this is a root promoter'
    ));
END;
$$;

-- Function to get hierarchy statistics
CREATE OR REPLACE FUNCTION get_hierarchy_statistics()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    WITH stats AS (
        SELECT 
            COUNT(DISTINCT promoter_id) as total_promoters_with_hierarchy,
            COUNT(*) as total_hierarchy_relationships,
            MAX(level) as max_hierarchy_depth,
            AVG(level) as avg_hierarchy_depth,
            COUNT(DISTINCT CASE WHEN level = 1 THEN ancestor_id END) as total_direct_parents,
            COUNT(CASE WHEN level = 1 THEN 1 END) as total_direct_relationships
        FROM promoter_hierarchy
    ),
    root_promoters AS (
        SELECT COUNT(*) as root_count
        FROM profiles 
        WHERE role = 'promoter' AND parent_promoter_id IS NULL
    ),
    level_distribution AS (
        SELECT 
            level,
            COUNT(*) as count,
            get_relationship_type(level) as relationship_type
        FROM promoter_hierarchy
        GROUP BY level
        ORDER BY level
    )
    SELECT json_build_object(
        'total_promoters', (SELECT COUNT(*) FROM profiles WHERE role = 'promoter'),
        'total_promoters_with_hierarchy', stats.total_promoters_with_hierarchy,
        'total_hierarchy_relationships', stats.total_hierarchy_relationships,
        'max_hierarchy_depth', stats.max_hierarchy_depth,
        'avg_hierarchy_depth', ROUND(stats.avg_hierarchy_depth, 2),
        'total_root_promoters', root_promoters.root_count,
        'total_direct_parents', stats.total_direct_parents,
        'level_distribution', (
            SELECT json_agg(
                json_build_object(
                    'level', level,
                    'relationship_type', relationship_type,
                    'count', count
                ) ORDER BY level
            ) FROM level_distribution
        ),
        'generated_at', NOW()
    ) INTO result
    FROM stats, root_promoters;
    
    RETURN result;
END;
$$;

RAISE NOTICE 'Query functions created successfully';

-- =====================================================
-- STEP 9: BUILD HIERARCHIES FOR EXISTING PROMOTERS
-- =====================================================

-- Build hierarchies for existing promoters
DO $$
DECLARE
    rebuild_result JSON;
BEGIN
    RAISE NOTICE 'Building hierarchies for existing promoters...';
    
    -- Check if profiles table exists and has promoters
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
        IF EXISTS (SELECT 1 FROM profiles WHERE role = 'promoter' LIMIT 1) THEN
            SELECT rebuild_all_promoter_hierarchies() INTO rebuild_result;
            RAISE NOTICE 'Hierarchy rebuild result: %', rebuild_result;
        ELSE
            RAISE NOTICE 'No existing promoters found to build hierarchies for';
        END IF;
    ELSE
        RAISE NOTICE 'Profiles table not found - hierarchies will be built when promoters are created';
    END IF;
END $$;

-- =====================================================
-- STEP 10: FINAL VERIFICATION
-- =====================================================

-- Verify setup completion
DO $$
DECLARE
    table_exists BOOLEAN;
    function_count INTEGER;
    stats JSON;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'promoter_hierarchy'
    ) INTO table_exists;
    
    -- Count functions created
    SELECT COUNT(*) INTO function_count
    FROM information_schema.routines 
    WHERE routine_name IN (
        'get_relationship_type',
        'build_promoter_hierarchy_chain',
        'rebuild_all_promoter_hierarchies',
        'get_promoter_upline_chain',
        'get_hierarchy_statistics'
    );
    
    -- Get statistics
    SELECT get_hierarchy_statistics() INTO stats;
    
    -- Log results
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'PROMOTER HIERARCHY SYSTEM SETUP COMPLETE';
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'Table created: %', table_exists;
    RAISE NOTICE 'Functions created: %/5', function_count;
    RAISE NOTICE 'Total promoters: %', stats->>'total_promoters';
    RAISE NOTICE 'Promoters with hierarchy: %', stats->>'total_promoters_with_hierarchy';
    RAISE NOTICE 'Max hierarchy depth: %', COALESCE(stats->>'max_hierarchy_depth', '0');
    RAISE NOTICE '';
    RAISE NOTICE 'Available Functions:';
    RAISE NOTICE '  - build_promoter_hierarchy_chain(promoter_uuid)';
    RAISE NOTICE '  - rebuild_all_promoter_hierarchies()';
    RAISE NOTICE '  - get_promoter_upline_chain(promoter_code)';
    RAISE NOTICE '  - get_hierarchy_statistics()';
    RAISE NOTICE '';
    RAISE NOTICE '✓ System is ready for use!';
    RAISE NOTICE '=================================================';
END $$;

-- Commit the transaction
COMMIT;

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

/*
-- Example 1: Get upline chain for a promoter
SELECT get_promoter_upline_chain('BPVP01');

-- Example 2: Get system statistics
SELECT get_hierarchy_statistics();

-- Example 3: Rebuild all hierarchies (maintenance)
SELECT rebuild_all_promoter_hierarchies();

-- Example 4: Build hierarchy for a specific promoter
SELECT build_promoter_hierarchy_chain('promoter-uuid-here');
*/
