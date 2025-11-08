-- Setup Promoter Hierarchy for Testing
-- This creates a 4-level hierarchy: BPVP15 -> BPVP17 -> BPVP18 -> BPVP19

-- First, let's see current promoter structure
SELECT id, name, promoter_id, parent_promoter_id 
FROM profiles 
WHERE role = 'promoter' 
ORDER BY promoter_id;

-- Setup hierarchy: BPVP19 (Level 1) -> BPVP18 (Level 2) -> BPVP17 (Level 3) -> BPVP15 (Level 4)
-- This means when a customer is created by BPVP19:
-- Level 1: ₹500 goes to BPVP19 (creator)
-- Level 2: ₹100 goes to BPVP18 (BPVP19's parent)
-- Level 3: ₹100 goes to BPVP17 (BPVP18's parent)  
-- Level 4: ₹100 goes to BPVP15 (BPVP17's parent)

-- Update BPVP19 to have BPVP18 as parent
UPDATE profiles 
SET parent_promoter_id = (
  SELECT id FROM profiles WHERE promoter_id = 'BPVP18' AND role = 'promoter'
)
WHERE promoter_id = 'BPVP19' AND role = 'promoter';

-- Update BPVP18 to have BPVP17 as parent
UPDATE profiles 
SET parent_promoter_id = (
  SELECT id FROM profiles WHERE promoter_id = 'BPVP17' AND role = 'promoter'
)
WHERE promoter_id = 'BPVP18' AND role = 'promoter';

-- Update BPVP17 to have BPVP15 as parent
UPDATE profiles 
SET parent_promoter_id = (
  SELECT id FROM profiles WHERE promoter_id = 'BPVP15' AND role = 'promoter'
)
WHERE promoter_id = 'BPVP17' AND role = 'promoter';

-- BPVP15 remains at the top (no parent)

-- Verify the hierarchy
SELECT 
  p1.promoter_id as promoter,
  p1.name as promoter_name,
  p2.promoter_id as parent_promoter,
  p2.name as parent_name
FROM profiles p1
LEFT JOIN profiles p2 ON p1.parent_promoter_id = p2.id
WHERE p1.role = 'promoter'
ORDER BY p1.promoter_id;
