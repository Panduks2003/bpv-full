-- =====================================================
-- FIX: Add promoter_id column to affiliate_commissions table
-- =====================================================
-- This script fixes the error: "column "promoter_id" of relation "affiliate_commissions" does not exist"
-- by adding the missing column and updating references in functions
-- =====================================================

-- Check if the column already exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'affiliate_commissions' 
        AND column_name = 'promoter_id'
    ) THEN
        -- Add the promoter_id column
        ALTER TABLE affiliate_commissions 
        ADD COLUMN promoter_id UUID REFERENCES profiles(id) ON DELETE CASCADE;
        
        -- Update existing records to set promoter_id = initiator_promoter_id
        UPDATE affiliate_commissions 
        SET promoter_id = initiator_promoter_id;
        
        RAISE NOTICE 'Successfully added promoter_id column to affiliate_commissions table';
    ELSE
        RAISE NOTICE 'Column promoter_id already exists in affiliate_commissions table';
    END IF;
END $$;

-- Create index on the new column for better performance
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE tablename = 'affiliate_commissions'
        AND indexname = 'idx_affiliate_commissions_promoter_id'
    ) THEN
        CREATE INDEX idx_affiliate_commissions_promoter_id ON affiliate_commissions(promoter_id);
        RAISE NOTICE 'Created index on promoter_id column';
    END IF;
END $$;

-- Verify the fix
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns 
WHERE 
    table_name = 'affiliate_commissions' 
    AND column_name = 'promoter_id';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'FIX COMPLETED: promoter_id column added to affiliate_commissions table';
    RAISE NOTICE '========================================';
END $$;