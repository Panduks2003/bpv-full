-- =====================================================
-- STEP 1: CREATE PROMOTER HIERARCHY TABLE
-- =====================================================
-- This creates the main table to store hierarchical relationships

-- Table to store the complete hierarchy chain for each promoter
CREATE TABLE IF NOT EXISTS promoter_hierarchy (
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

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Step 1 Complete: Promoter hierarchy table created successfully';
END $$;
