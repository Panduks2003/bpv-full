-- =====================================================
-- Reset Promoter ID Script
-- Purpose: Add new top-level promoter "Brightplanet" with ID "01"
--          and reassign existing promoter IDs
-- =====================================================

-- Start a transaction to ensure all operations complete successfully
BEGIN;

-- Create a temporary table to store the current promoter data
CREATE TEMPORARY TABLE temp_promoters AS
SELECT * FROM promoters;

-- Add the new top-level promoter "Brightplanet" with ID "01"
INSERT INTO promoters (
    promoter_id,
    name,
    email,
    phone,
    parent_promoter_id,
    status
) VALUES (
    'BPVP01',
    'Brightplanet',
    'brightplanetventures11@gmail.com',
    '7353297211',
    NULL,
    'active'
) ON CONFLICT (promoter_id) DO UPDATE SET
    name = 'Brightplanet',
    email = 'brightplanetventures11@gmail.com',
    phone = '7353297211',
    parent_promoter_id = NULL,
    status = 'active';

-- Update existing promoter IDs
-- Update Kaveri Bedasur to BPVP02 (was BPVP01)
UPDATE promoters
SET promoter_id = 'BPVP02',
    parent_promoter_id = 'BPVP01'
WHERE promoter_id = 'BPVP01' 
AND name = 'Kaveri Bedasur';

-- Update Ramesh Kuragund to BPVP03 (was BPVP02)
UPDATE promoters
SET promoter_id = 'BPVP03',
    parent_promoter_id = 'BPVP02'
WHERE promoter_id = 'BPVP02'
AND name = 'Ramesh Kuragund';

-- Update Shankar Shinobi to BPVP04 (was BPVP03)
UPDATE promoters
SET promoter_id = 'BPVP04',
    parent_promoter_id = 'BPVP02'
WHERE promoter_id = 'BPVP03'
AND name = 'Shankar Shinobi';

-- Update any references to the old promoter IDs in other tables
-- Example: Update parent_promoter_id references in the promoters table
UPDATE promoters
SET parent_promoter_id = 'BPVP02'
WHERE parent_promoter_id = 'BPVP01'
AND promoter_id != 'BPVP02';

UPDATE promoters
SET parent_promoter_id = 'BPVP03'
WHERE parent_promoter_id = 'BPVP02'
AND promoter_id != 'BPVP03';

UPDATE promoters
SET parent_promoter_id = 'BPVP04'
WHERE parent_promoter_id = 'BPVP03'
AND promoter_id != 'BPVP04';

-- Update the promoter_id sequence if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_sequences WHERE sequencename = 'promoter_id_seq') THEN
        ALTER SEQUENCE promoter_id_seq RESTART WITH 5;
    END IF;
END $$;

-- Verify the changes
SELECT promoter_id, name, email, phone, parent_promoter_id, status
FROM promoters
ORDER BY promoter_id;

-- If everything looks good, commit the transaction
COMMIT;