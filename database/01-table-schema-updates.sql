-- =====================================================
-- UNIFIED PROMOTER SYSTEM - TABLE SCHEMA UPDATES
-- =====================================================
-- This file updates the profiles table with new promoter fields

-- =====================================================
-- 1. UPDATE PROFILES TABLE FOR PROMOTER FIELDS
-- =====================================================

-- Add promoter_id field to profiles table if it doesn't exist
DO $$
BEGIN
    -- Add promoter_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'promoter_id'
    ) THEN
        ALTER TABLE profiles ADD COLUMN promoter_id VARCHAR(20) UNIQUE;
        CREATE INDEX IF NOT EXISTS idx_profiles_promoter_id ON profiles(promoter_id);
    END IF;

    -- Add address column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'address'
    ) THEN
        ALTER TABLE profiles ADD COLUMN address TEXT;
    END IF;

    -- Add role_level column for promoter hierarchy if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'role_level'
    ) THEN
        ALTER TABLE profiles ADD COLUMN role_level VARCHAR(50) DEFAULT 'Affiliate';
    END IF;

    -- Add status column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'status'
    ) THEN
        ALTER TABLE profiles ADD COLUMN status VARCHAR(20) DEFAULT 'Active';
    END IF;

    -- Add parent_promoter_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'parent_promoter_id'
    ) THEN
        ALTER TABLE profiles ADD COLUMN parent_promoter_id UUID REFERENCES profiles(id);
        CREATE INDEX IF NOT EXISTS idx_profiles_parent_promoter_id ON profiles(parent_promoter_id);
    END IF;
END $$;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Table schema updates completed successfully!';
END $$;
