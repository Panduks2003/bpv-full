-- =====================================================
-- PROMOTER HIERARCHICAL RELATIONSHIP SYSTEM
-- =====================================================
-- This system automatically establishes and maintains hierarchical 
-- relationships between promoters with complete upline traceability
-- 
-- Features:
-- 1. Automatic hierarchy chain generation (Parent, Super Parent, Grand Parent, etc.)
-- 2. Dynamic upline tracking to root promoter
-- 3. Triggers for automatic maintenance
-- 4. Performance optimized with materialized hierarchy paths
-- 5. Comprehensive hierarchy queries and analytics
-- =====================================================

-- =====================================================
-- 1. CREATE PROMOTER HIERARCHY TABLE
-- =====================================================

-- Table to store the complete hierarchy chain for each promoter
CREATE TABLE IF NOT EXISTS promoter_hierarchy (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    ancestor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    promoter_code VARCHAR(20) NOT NULL, -- BPVP01, BPVP02, etc.
    ancestor_code VARCHAR(20) NOT NULL, -- BPVP01, BPVP02, etc.
    level INTEGER NOT NULL, -- 1=Parent, 2=Super Parent, 3=Grand Parent, etc.
    relationship_type VARCHAR(50) NOT NULL, -- 'Parent', 'Super Parent', 'Grand Parent', etc.
    path_to_root TEXT NOT NULL, -- Full path from promoter to root (e.g., "BPVP29->BPVP23->BPVP06->BPVP01")
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(promoter_id, ancestor_id),
    UNIQUE(promoter_id, level),
    CHECK(level > 0),
    CHECK(promoter_id != ancestor_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_promoter_hierarchy_promoter_id ON promoter_hierarchy(promoter_id);
CREATE INDEX IF NOT EXISTS idx_promoter_hierarchy_ancestor_id ON promoter_hierarchy(ancestor_id);
CREATE INDEX IF NOT EXISTS idx_promoter_hierarchy_level ON promoter_hierarchy(promoter_id, level);
CREATE INDEX IF NOT EXISTS idx_promoter_hierarchy_codes ON promoter_hierarchy(promoter_code, ancestor_code);

-- =====================================================
-- 2. FUNCTION: GET RELATIONSHIP TYPE BY LEVEL
-- =====================================================

CREATE OR REPLACE FUNCTION get_relationship_type(level_num INTEGER)
RETURNS VARCHAR(50)
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    RETURN 'Level ' || level_num::TEXT;
END;
$$;

-- =====================================================
-- 3. FUNCTION: BUILD HIERARCHY CHAIN
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

-- =====================================================
-- 4. FUNCTION: REBUILD ALL HIERARCHIES
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

-- =====================================================
-- 5. FUNCTION: GET PROMOTER UPLINE CHAIN
-- =====================================================

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
    SELECT id INTO promoter_id 
    FROM profiles 
    WHERE promoter_id = p_promoter_code AND role = 'promoter';
    
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

-- =====================================================
-- 6. FUNCTION: GET PROMOTER DOWNLINE TREE
-- =====================================================

CREATE OR REPLACE FUNCTION get_promoter_downline_tree(p_promoter_code VARCHAR(20))
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    promoter_id UUID;
    result JSON;
BEGIN
    -- Get promoter ID from code
    SELECT id INTO promoter_id 
    FROM profiles 
    WHERE promoter_id = p_promoter_code AND role = 'promoter';
    
    IF promoter_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Promoter not found: ' || p_promoter_code
        );
    END IF;
    
    -- Get complete downline tree
    WITH RECURSIVE downline_tree AS (
        -- Base case: direct children
        SELECT 
            p.id,
            p.promoter_id as code,
            p.name,
            p.email,
            p.phone,
            p.role_level,
            p.status,
            p.created_at,
            1 as level,
            ARRAY[p.promoter_id] as path
        FROM profiles p
        WHERE p.parent_promoter_id = promoter_id 
        AND p.role = 'promoter'
        
        UNION ALL
        
        -- Recursive case: children of children
        SELECT 
            p.id,
            p.promoter_id as code,
            p.name,
            p.email,
            p.phone,
            p.role_level,
            p.status,
            p.created_at,
            dt.level + 1,
            dt.path || p.promoter_id
        FROM profiles p
        JOIN downline_tree dt ON p.parent_promoter_id = dt.id
        WHERE p.role = 'promoter'
        AND NOT (p.promoter_id = ANY(dt.path)) -- Prevent cycles
        AND dt.level < 20 -- Limit depth for performance
    )
    SELECT json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'downline_tree', json_agg(
            json_build_object(
                'code', code,
                'name', name,
                'email', email,
                'phone', phone,
                'role_level', role_level,
                'status', status,
                'level', level,
                'path', path,
                'created_at', created_at
            ) ORDER BY level, code
        ),
        'total_downline', COUNT(*)
    ) INTO result
    FROM downline_tree;
    
    RETURN COALESCE(result, json_build_object(
        'success', true,
        'promoter_code', p_promoter_code,
        'downline_tree', '[]'::json,
        'total_downline', 0,
        'message', 'No downline found'
    ));
END;
$$;

-- =====================================================
-- 7. TRIGGER: AUTO-MAINTAIN HIERARCHY ON PROMOTER CHANGES
-- =====================================================

-- Function to handle hierarchy updates
CREATE OR REPLACE FUNCTION trigger_maintain_promoter_hierarchy()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Handle INSERT (new promoter created)
    IF TG_OP = 'INSERT' AND NEW.role = 'promoter' THEN
        -- Build hierarchy chain for new promoter
        PERFORM build_promoter_hierarchy_chain(NEW.id);
        
        -- Also rebuild hierarchy for any existing children (in case this is a re-parent)
        PERFORM build_promoter_hierarchy_chain(child.id)
        FROM profiles child 
        WHERE child.parent_promoter_id = NEW.id AND child.role = 'promoter';
        
        RETURN NEW;
    END IF;
    
    -- Handle UPDATE (promoter parent changed)
    IF TG_OP = 'UPDATE' AND NEW.role = 'promoter' THEN
        -- Check if parent_promoter_id changed
        IF OLD.parent_promoter_id IS DISTINCT FROM NEW.parent_promoter_id THEN
            -- Rebuild hierarchy chain for this promoter
            PERFORM build_promoter_hierarchy_chain(NEW.id);
            
            -- Rebuild hierarchy for all descendants (they inherit the new chain)
            WITH RECURSIVE descendants AS (
                SELECT id FROM profiles 
                WHERE parent_promoter_id = NEW.id AND role = 'promoter'
                
                UNION ALL
                
                SELECT p.id FROM profiles p
                JOIN descendants d ON p.parent_promoter_id = d.id
                WHERE p.role = 'promoter'
            )
            SELECT build_promoter_hierarchy_chain(id) FROM descendants;
        END IF;
        
        RETURN NEW;
    END IF;
    
    -- Handle DELETE (promoter removed)
    IF TG_OP = 'DELETE' AND OLD.role = 'promoter' THEN
        -- Hierarchy records will be automatically deleted due to CASCADE
        -- But we need to update children to point to the deleted promoter's parent
        UPDATE profiles 
        SET parent_promoter_id = OLD.parent_promoter_id,
            updated_at = NOW()
        WHERE parent_promoter_id = OLD.id AND role = 'promoter';
        
        -- Rebuild hierarchy for affected children
        PERFORM build_promoter_hierarchy_chain(child.id)
        FROM profiles child 
        WHERE child.parent_promoter_id = OLD.parent_promoter_id AND child.role = 'promoter';
        
        RETURN OLD;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Create the trigger
DROP TRIGGER IF EXISTS trigger_promoter_hierarchy_maintenance ON profiles;
CREATE TRIGGER trigger_promoter_hierarchy_maintenance
    AFTER INSERT OR UPDATE OR DELETE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_maintain_promoter_hierarchy();

-- =====================================================
-- 8. ENHANCED PROMOTER CREATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION create_promoter_with_hierarchy(
    p_name VARCHAR(255),
    p_email VARCHAR(255) DEFAULT NULL,
    p_password VARCHAR(255),
    p_phone VARCHAR(20),
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_code VARCHAR(20) DEFAULT NULL, -- Use promoter code instead of UUID
    p_role_level VARCHAR(50) DEFAULT 'Affiliate',
    p_status VARCHAR(20) DEFAULT 'Active'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    parent_promoter_id UUID := NULL;
    creation_result JSON;
    new_promoter_id UUID;
    new_promoter_code VARCHAR(20);
BEGIN
    -- Resolve parent promoter ID from code if provided
    IF p_parent_promoter_code IS NOT NULL THEN
        SELECT id INTO parent_promoter_id 
        FROM profiles 
        WHERE promoter_id = p_parent_promoter_code AND role IN ('promoter', 'admin');
        
        IF parent_promoter_id IS NULL THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Parent promoter not found: ' || p_parent_promoter_code
            );
        END IF;
    END IF;
    
    -- Create promoter using existing function
    SELECT create_unified_promoter(
        p_name,
        p_email,
        p_password,
        p_phone,
        p_address,
        parent_promoter_id,
        p_role_level,
        p_status
    ) INTO creation_result;
    
    -- Check if creation was successful
    IF (creation_result->>'success')::boolean = false THEN
        RETURN creation_result;
    END IF;
    
    -- Extract new promoter details
    new_promoter_id := (creation_result->>'user_id')::UUID;
    new_promoter_code := creation_result->>'promoter_id';
    
    -- Build hierarchy chain (trigger should handle this, but ensure it's done)
    PERFORM build_promoter_hierarchy_chain(new_promoter_id);
    
    -- Get the complete hierarchy information
    DECLARE
        hierarchy_info JSON;
    BEGIN
        SELECT get_promoter_upline_chain(new_promoter_code) INTO hierarchy_info;
        
        -- Enhance the creation result with hierarchy information
        RETURN json_build_object(
            'success', true,
            'promoter_id', new_promoter_code,
            'user_id', new_promoter_id,
            'name', p_name,
            'phone', p_phone,
            'email', COALESCE(p_email, 'Not provided'),
            'parent_promoter_code', p_parent_promoter_code,
            'role_level', p_role_level,
            'status', p_status,
            'hierarchy_chain', hierarchy_info->'upline_chain',
            'total_upline_levels', hierarchy_info->'total_levels',
            'created_at', NOW()
        );
    END;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Failed to create promoter with hierarchy: ' || SQLERRM
    );
END;
$$;

-- =====================================================
-- 9. HIERARCHY ANALYTICS FUNCTIONS
-- =====================================================

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

-- =====================================================
-- 10. SYSTEM VERIFICATION AND TESTING
-- =====================================================

-- Function to test the hierarchy system
CREATE OR REPLACE FUNCTION test_hierarchy_system()
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    test_results JSON;
    root_promoter JSON;
    child_promoter JSON;
    grandchild_promoter JSON;
BEGIN
    -- Test 1: Create root promoter
    SELECT create_promoter_with_hierarchy(
        'Root Promoter Test',
        'root@test.com',
        'password123',
        '9876543210',
        'Root Address',
        NULL, -- No parent (root)
        'Manager',
        'Active'
    ) INTO root_promoter;
    
    -- Test 2: Create child promoter
    SELECT create_promoter_with_hierarchy(
        'Child Promoter Test',
        'child@test.com',
        'password123',
        '9876543211',
        'Child Address',
        root_promoter->>'promoter_id', -- Parent is root
        'Affiliate',
        'Active'
    ) INTO child_promoter;
    
    -- Test 3: Create grandchild promoter
    SELECT create_promoter_with_hierarchy(
        'Grandchild Promoter Test',
        'grandchild@test.com',
        'password123',
        '9876543212',
        'Grandchild Address',
        child_promoter->>'promoter_id', -- Parent is child
        'Affiliate',
        'Active'
    ) INTO grandchild_promoter;
    
    -- Compile test results
    RETURN json_build_object(
        'test_completed', true,
        'root_promoter', root_promoter,
        'child_promoter', child_promoter,
        'grandchild_promoter', grandchild_promoter,
        'hierarchy_stats', get_hierarchy_statistics(),
        'grandchild_upline', get_promoter_upline_chain(grandchild_promoter->>'promoter_id'),
        'root_downline', get_promoter_downline_tree(root_promoter->>'promoter_id')
    );
END;
$$;

-- =====================================================
-- SYSTEM SETUP COMPLETE
-- =====================================================

-- Log completion
DO $$
BEGIN
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'PROMOTER HIERARCHICAL RELATIONSHIP SYSTEM SETUP COMPLETE';
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'Available Functions:';
    RAISE NOTICE '  - create_promoter_with_hierarchy()';
    RAISE NOTICE '  - get_promoter_upline_chain()';
    RAISE NOTICE '  - get_promoter_downline_tree()';
    RAISE NOTICE '  - build_promoter_hierarchy_chain()';
    RAISE NOTICE '  - rebuild_all_promoter_hierarchies()';
    RAISE NOTICE '  - get_hierarchy_statistics()';
    RAISE NOTICE '  - test_hierarchy_system()';
    RAISE NOTICE '';
    RAISE NOTICE 'Features:';
    RAISE NOTICE '  ✓ Automatic hierarchy chain generation';
    RAISE NOTICE '  ✓ Dynamic upline tracking to root';
    RAISE NOTICE '  ✓ Triggers for automatic maintenance';
    RAISE NOTICE '  ✓ Complete relationship mapping';
    RAISE NOTICE '  ✓ Performance optimized queries';
    RAISE NOTICE '=================================================';
END $$;
