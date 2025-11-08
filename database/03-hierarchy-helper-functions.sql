-- =====================================================
-- STEP 3: CREATE HELPER FUNCTIONS
-- =====================================================
-- This creates utility functions for the hierarchy system

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

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Step 3 Complete: Helper functions created successfully';
END $$;
