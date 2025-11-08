-- =====================================================
-- STEP 2A: ADD FOREIGN KEY CONSTRAINTS
-- =====================================================
-- This adds foreign key constraints after table creation

-- Add foreign key constraints
DO $$
BEGIN
    -- Add foreign key for promoter_id if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_promoter_hierarchy_promoter_id'
    ) THEN
        ALTER TABLE promoter_hierarchy 
        ADD CONSTRAINT fk_promoter_hierarchy_promoter_id 
        FOREIGN KEY (promoter_id) REFERENCES profiles(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key for ancestor_id if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_promoter_hierarchy_ancestor_id'
    ) THEN
        ALTER TABLE promoter_hierarchy 
        ADD CONSTRAINT fk_promoter_hierarchy_ancestor_id 
        FOREIGN KEY (ancestor_id) REFERENCES profiles(id) ON DELETE CASCADE;
    END IF;
    
    RAISE NOTICE 'Step 2A Complete: Foreign key constraints added successfully';
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Foreign key constraints could not be added: %', SQLERRM;
END $$;
