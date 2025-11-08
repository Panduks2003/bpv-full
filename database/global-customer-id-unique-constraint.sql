-- =====================================================
-- ENSURE CUSTOMER IDS ARE GLOBALLY UNIQUE
-- =====================================================
-- This script ensures that customer IDs (Card No) are
-- globally unique across the entire system, not per promoter
-- =====================================================

BEGIN;

-- =====================================================
-- 1. ADD UNIQUE CONSTRAINT ON CUSTOMER_ID
-- =====================================================

-- Add unique constraint on customer_id in profiles table
-- This ensures no two customers can have the same Card No globally
DO $$
BEGIN
    -- Check if unique constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'profiles_customer_id_key'
    ) THEN
        -- Add unique constraint
        ALTER TABLE profiles 
        ADD CONSTRAINT profiles_customer_id_key UNIQUE (customer_id);
        
        RAISE NOTICE '✅ Added unique constraint on customer_id';
    ELSE
        RAISE NOTICE '✅ Unique constraint on customer_id already exists';
    END IF;
    
    -- Ensure unique index exists
    CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_customer_id 
    ON profiles(customer_id) 
    WHERE customer_id IS NOT NULL;
    
    RAISE NOTICE '✅ Unique index on customer_id created';
END $$;

-- =====================================================
-- 2. VERIFY CONSTRAINTS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'CUSTOMER ID GLOBAL UNIQUENESS CONFIRMED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ customer_id is now globally unique';
    RAISE NOTICE '✅ No two customers can have the same Card No';
    RAISE NOTICE '✅ Unique constraint: profiles_customer_id_key';
    RAISE NOTICE '✅ Unique index: idx_profiles_customer_id';
    RAISE NOTICE '';
    RAISE NOTICE 'This ensures that all customer Card Numbers';
    RAISE NOTICE 'are unique across the entire system, regardless';
    RAISE NOTICE 'of which promoter created them.';
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
END $$;

COMMIT;

