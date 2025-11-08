-- =====================================================
-- STEP 2: CREATE INDEXES FOR PERFORMANCE
-- =====================================================
-- This creates indexes to optimize hierarchy queries

-- Check if table exists first
DO $$
BEGIN
    -- Check if promoter_hierarchy table exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'promoter_hierarchy'
    ) THEN
        RAISE EXCEPTION 'Table promoter_hierarchy does not exist. Please run 01-hierarchy-table-creation.sql first.';
    END IF;
    
    -- Check if ancestor_id column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'promoter_hierarchy' AND column_name = 'ancestor_id'
    ) THEN
        RAISE EXCEPTION 'Column ancestor_id does not exist in promoter_hierarchy table.';
    END IF;
    
    RAISE NOTICE 'Table and columns verified. Creating indexes...';
END $$;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_promoter_hierarchy_promoter_id ON promoter_hierarchy(promoter_id);
CREATE INDEX IF NOT EXISTS idx_promoter_hierarchy_ancestor_id ON promoter_hierarchy(ancestor_id);
CREATE INDEX IF NOT EXISTS idx_promoter_hierarchy_level ON promoter_hierarchy(promoter_id, level);
CREATE INDEX IF NOT EXISTS idx_promoter_hierarchy_codes ON promoter_hierarchy(promoter_code, ancestor_code);

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Step 2 Complete: Hierarchy indexes created successfully';
END $$;
