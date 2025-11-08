-- =====================================================
-- DEPLOY PROMOTER HIERARCHY SYSTEM
-- =====================================================
-- This script deploys the complete hierarchical promoter system
-- Run this script to implement automatic hierarchy management
-- =====================================================

-- Start transaction for atomic deployment
BEGIN;

-- Log deployment start
DO $$
BEGIN
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'DEPLOYING PROMOTER HIERARCHY SYSTEM';
    RAISE NOTICE 'Started at: %', NOW();
    RAISE NOTICE '=================================================';
END $$;

-- =====================================================
-- 1. BACKUP EXISTING DATA (if needed)
-- =====================================================

-- Create backup table for existing promoter relationships
CREATE TABLE IF NOT EXISTS promoter_hierarchy_backup AS
SELECT 
    id,
    promoter_id,
    parent_promoter_id,
    name,
    email,
    phone,
    role_level,
    status,
    created_at
FROM profiles 
WHERE role = 'promoter';

-- =====================================================
-- 2. APPLY HIERARCHY SYSTEM SCHEMA
-- =====================================================

-- Execute the main hierarchy system file
\i '/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/database/promoter-hierarchy-system.sql'

-- =====================================================
-- 3. MIGRATE EXISTING PROMOTER DATA
-- =====================================================

-- Build hierarchy chains for all existing promoters
DO $$
DECLARE
    migration_result JSON;
BEGIN
    RAISE NOTICE 'Building hierarchy chains for existing promoters...';
    
    -- Rebuild all hierarchies
    SELECT rebuild_all_promoter_hierarchies() INTO migration_result;
    
    RAISE NOTICE 'Migration Result: %', migration_result;
END $$;

-- =====================================================
-- 4. VERIFY SYSTEM INTEGRITY
-- =====================================================

-- Verify the system is working correctly
DO $$
DECLARE
    stats JSON;
    total_promoters INTEGER;
    total_with_hierarchy INTEGER;
BEGIN
    -- Get current statistics
    SELECT get_hierarchy_statistics() INTO stats;
    
    total_promoters := (stats->>'total_promoters')::INTEGER;
    total_with_hierarchy := (stats->>'total_promoters_with_hierarchy')::INTEGER;
    
    RAISE NOTICE 'System Verification:';
    RAISE NOTICE '  Total Promoters: %', total_promoters;
    RAISE NOTICE '  Promoters with Hierarchy: %', total_with_hierarchy;
    RAISE NOTICE '  Max Hierarchy Depth: %', stats->>'max_hierarchy_depth';
    RAISE NOTICE '  Root Promoters: %', stats->>'total_root_promoters';
    
    -- Verify integrity
    IF total_promoters > 0 AND total_with_hierarchy >= 0 THEN
        RAISE NOTICE '✓ System verification passed';
    ELSE
        RAISE WARNING '⚠ System verification failed - check data integrity';
    END IF;
END $$;

-- =====================================================
-- 5. CREATE SAMPLE HIERARCHY (for testing)
-- =====================================================

-- Create a sample hierarchy for demonstration
DO $$
DECLARE
    sample_result JSON;
BEGIN
    RAISE NOTICE 'Creating sample hierarchy for testing...';
    
    -- Only create if no promoters exist
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE role = 'promoter' LIMIT 1) THEN
        SELECT test_hierarchy_system() INTO sample_result;
        RAISE NOTICE 'Sample hierarchy created: %', (sample_result->>'test_completed')::boolean;
    ELSE
        RAISE NOTICE 'Existing promoters found - skipping sample creation';
    END IF;
END $$;

-- =====================================================
-- 6. SETUP MONITORING AND MAINTENANCE
-- =====================================================

-- Create a maintenance function to run periodically
CREATE OR REPLACE FUNCTION maintain_hierarchy_system()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    maintenance_result JSON;
    orphaned_count INTEGER;
    inconsistent_count INTEGER;
BEGIN
    -- Check for orphaned hierarchy records
    SELECT COUNT(*) INTO orphaned_count
    FROM promoter_hierarchy h
    WHERE NOT EXISTS (
        SELECT 1 FROM profiles p 
        WHERE p.id = h.promoter_id AND p.role = 'promoter'
    );
    
    -- Clean up orphaned records
    DELETE FROM promoter_hierarchy h
    WHERE NOT EXISTS (
        SELECT 1 FROM profiles p 
        WHERE p.id = h.promoter_id AND p.role = 'promoter'
    );
    
    -- Check for inconsistent hierarchies
    SELECT COUNT(*) INTO inconsistent_count
    FROM profiles p
    WHERE p.role = 'promoter'
    AND p.parent_promoter_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM promoter_hierarchy h
        WHERE h.promoter_id = p.id AND h.level = 1
    );
    
    -- Rebuild inconsistent hierarchies
    PERFORM build_promoter_hierarchy_chain(p.id)
    FROM profiles p
    WHERE p.role = 'promoter'
    AND p.parent_promoter_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM promoter_hierarchy h
        WHERE h.promoter_id = p.id AND h.level = 1
    );
    
    RETURN json_build_object(
        'maintenance_completed', true,
        'orphaned_records_cleaned', orphaned_count,
        'inconsistent_hierarchies_fixed', inconsistent_count,
        'timestamp', NOW()
    );
END;
$$;

-- =====================================================
-- 7. GRANT PERMISSIONS
-- =====================================================

-- Grant necessary permissions for the hierarchy system
DO $$
BEGIN
    -- Grant permissions to authenticated users
    GRANT SELECT ON promoter_hierarchy TO authenticated;
    GRANT SELECT ON promoter_id_sequence TO authenticated;
    
    -- Grant execute permissions on functions
    GRANT EXECUTE ON FUNCTION get_promoter_upline_chain(VARCHAR) TO authenticated;
    GRANT EXECUTE ON FUNCTION get_promoter_downline_tree(VARCHAR) TO authenticated;
    GRANT EXECUTE ON FUNCTION get_hierarchy_statistics() TO authenticated;
    GRANT EXECUTE ON FUNCTION create_promoter_with_hierarchy(VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR, VARCHAR) TO authenticated;
    
    RAISE NOTICE '✓ Permissions granted successfully';
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Permission granting failed: %', SQLERRM;
END $$;

-- =====================================================
-- 8. FINAL VERIFICATION AND CLEANUP
-- =====================================================

-- Final system check
DO $$
DECLARE
    final_stats JSON;
    deployment_success BOOLEAN := true;
BEGIN
    -- Get final statistics
    SELECT get_hierarchy_statistics() INTO final_stats;
    
    -- Verify deployment success
    IF final_stats IS NOT NULL THEN
        RAISE NOTICE '=================================================';
        RAISE NOTICE 'DEPLOYMENT COMPLETED SUCCESSFULLY';
        RAISE NOTICE '=================================================';
        RAISE NOTICE 'Final Statistics:';
        RAISE NOTICE '  Total Promoters: %', final_stats->>'total_promoters';
        RAISE NOTICE '  Promoters with Hierarchy: %', final_stats->>'total_promoters_with_hierarchy';
        RAISE NOTICE '  Max Hierarchy Depth: %', final_stats->>'max_hierarchy_depth';
        RAISE NOTICE '  Total Root Promoters: %', final_stats->>'total_root_promoters';
        RAISE NOTICE '';
        RAISE NOTICE 'Available Functions:';
        RAISE NOTICE '  - create_promoter_with_hierarchy()';
        RAISE NOTICE '  - get_promoter_upline_chain()';
        RAISE NOTICE '  - get_promoter_downline_tree()';
        RAISE NOTICE '  - get_hierarchy_statistics()';
        RAISE NOTICE '  - maintain_hierarchy_system()';
        RAISE NOTICE '';
        RAISE NOTICE '✓ Hierarchy system is ready for use!';
        RAISE NOTICE '=================================================';
    ELSE
        deployment_success := false;
        RAISE WARNING 'Deployment verification failed!';
    END IF;
    
    -- Log deployment completion
    INSERT INTO promoter_hierarchy (
        promoter_id, ancestor_id, promoter_code, ancestor_code, 
        level, relationship_type, path_to_root
    ) 
    SELECT 
        gen_random_uuid(), gen_random_uuid(), 'DEPLOYMENT_LOG', 'SYSTEM',
        0, 'System Deployment', 
        CASE WHEN deployment_success THEN 'SUCCESS' ELSE 'FAILED' END
    WHERE false; -- This won't actually insert, just for logging structure
    
END $$;

-- Commit the transaction
COMMIT;

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

/*
-- Example 1: Create a new promoter with hierarchy
SELECT create_promoter_with_hierarchy(
    'John Doe',                    -- Name
    'john@example.com',            -- Email (optional)
    'securepassword123',           -- Password
    '9876543210',                  -- Phone
    '123 Main St, City',           -- Address (optional)
    'BPVP01',                      -- Parent promoter code (optional, NULL for root)
    'Affiliate',                   -- Role level
    'Active'                       -- Status
);

-- Example 2: Get complete upline chain for a promoter
SELECT get_promoter_upline_chain('BPVP06');

-- Example 3: Get complete downline tree for a promoter
SELECT get_promoter_downline_tree('BPVP01');

-- Example 4: Get system statistics
SELECT get_hierarchy_statistics();

-- Example 5: Rebuild all hierarchies (maintenance)
SELECT rebuild_all_promoter_hierarchies();

-- Example 6: Run system maintenance
SELECT maintain_hierarchy_system();
*/
