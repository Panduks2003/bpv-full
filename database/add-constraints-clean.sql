-- =====================================================
-- ADD CONSTRAINTS TO CLEAN DATA
-- =====================================================
-- Run this ONLY after fix-data-format-first.sql completes successfully
-- =====================================================

BEGIN;

-- Add unique constraint
ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_unique UNIQUE (customer_id);

-- Add format constraint (allowing underscores for fixed duplicates)
ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_format 
    CHECK (customer_id IS NULL OR (customer_id ~ '^[A-Z0-9_]{3,30}$'));

COMMIT;

SELECT 'CONSTRAINTS_ADDED_SUCCESSFULLY' as status;
