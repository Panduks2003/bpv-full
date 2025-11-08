-- =====================================================
-- UNIFIED PROMOTER SYSTEM - INDEXES AND SECURITY
-- =====================================================
-- This file creates performance indexes and security policies

-- =====================================================
-- 8. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_profiles_role_status ON profiles(role, status);
CREATE INDEX IF NOT EXISTS idx_profiles_promoter_id_role ON profiles(promoter_id, role);
CREATE INDEX IF NOT EXISTS idx_profiles_parent_hierarchy ON profiles(parent_promoter_id, role);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at DESC);

-- =====================================================
-- 9. ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "promoters_can_view_hierarchy" ON profiles;
    DROP POLICY IF EXISTS "admins_can_view_all_promoters" ON profiles;
    DROP POLICY IF EXISTS "authorized_users_can_create_promoters" ON profiles;
    DROP POLICY IF EXISTS "authorized_users_can_update_promoters" ON profiles;
EXCEPTION WHEN OTHERS THEN
    -- Ignore errors if policies don't exist
    NULL;
END $$;

-- Policy for promoters to see their hierarchy
CREATE POLICY "promoters_can_view_hierarchy" ON profiles
    FOR SELECT
    USING (
        role = 'promoter' 
        AND (
            -- Can see self
            id = auth.uid()
            -- Can see direct children
            OR parent_promoter_id = auth.uid()
            -- Can see parent
            OR id = (SELECT parent_promoter_id FROM profiles WHERE id = auth.uid())
        )
    );

-- Policy for admins to see all promoters
CREATE POLICY "admins_can_view_all_promoters" ON profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Policy for creating promoters (admins and authorized promoters)
CREATE POLICY "authorized_users_can_create_promoters" ON profiles
    FOR INSERT
    WITH CHECK (
        role = 'promoter'
        AND EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'promoter')
        )
    );

-- Policy for updating promoters
CREATE POLICY "authorized_users_can_update_promoters" ON profiles
    FOR UPDATE
    USING (
        role = 'promoter'
        AND (
            -- Admins can update any promoter
            EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
            -- Promoters can update themselves
            OR id = auth.uid()
            -- Promoters can update their direct children
            OR parent_promoter_id = auth.uid()
        )
    );

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Indexes and security policies created successfully!';
END $$;
