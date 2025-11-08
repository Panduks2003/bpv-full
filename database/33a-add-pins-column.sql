-- =====================================================
-- PART 1: ADD PINS COLUMN TO PROFILES TABLE
-- =====================================================
-- This script adds the pins column and basic pin management functions

BEGIN;

-- =====================================================
-- 1. ADD PINS FIELD TO PROFILES TABLE
-- =====================================================

-- Add pins column to profiles table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'pins'
    ) THEN
        ALTER TABLE profiles ADD COLUMN pins INTEGER DEFAULT 0;
        CREATE INDEX IF NOT EXISTS idx_profiles_pins ON profiles(pins);
        
        -- Initialize existing promoters with 0 pins
        UPDATE profiles SET pins = 0 WHERE role = 'promoter' AND pins IS NULL;
        
        RAISE NOTICE 'Added pins column to profiles table';
    END IF;
END $$;

COMMIT;

-- Verification
SELECT 'PINS_COLUMN_CHECK' as check_type, 
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'profiles' AND column_name = 'pins'
       ) THEN 'EXISTS' ELSE 'MISSING' END as status;
