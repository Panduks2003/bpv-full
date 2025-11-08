-- =====================================================
-- 02B: FIX DUPLICATES AND ADD CONSTRAINTS
-- =====================================================
-- This script handles duplicates and adds database constraints
-- =====================================================

BEGIN;

-- Handle existing unique constraint and duplicates
DO $$
DECLARE
    constraint_name TEXT;
    duplicate_count INTEGER;
BEGIN
    -- Check if there's already a unique constraint on customer_id
    SELECT c.conname INTO constraint_name
    FROM pg_constraint c 
    JOIN pg_class t ON c.conrelid = t.oid 
    WHERE t.relname = 'profiles' 
    AND c.contype = 'u' 
    AND array_to_string(c.conkey, ',') = (
        SELECT array_to_string(array_agg(attnum), ',')
        FROM pg_attribute 
        WHERE attrelid = t.oid AND attname = 'customer_id'
    )
    LIMIT 1;
    
    -- Drop existing constraint if found
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE profiles DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Dropped existing constraint: %', constraint_name;
    END IF;
    
    -- Fix duplicates by adding suffix to duplicates
    WITH duplicates AS (
        SELECT id, customer_id, 
               row_number() OVER (PARTITION BY customer_id ORDER BY created_at) as rn
        FROM profiles 
        WHERE customer_id IS NOT NULL 
          AND role = 'customer'
    )
    UPDATE profiles 
    SET customer_id = duplicates.customer_id || '_' || duplicates.rn
    FROM duplicates 
    WHERE profiles.id = duplicates.id 
      AND duplicates.rn > 1;
    
    GET DIAGNOSTICS duplicate_count = ROW_COUNT;
    IF duplicate_count > 0 THEN
        RAISE NOTICE 'Fixed % duplicate customer_id values', duplicate_count;
    END IF;
    
    -- Add unique constraint
    ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_unique UNIQUE (customer_id);
    RAISE NOTICE 'Added unique constraint on customer_id';
    
    -- Add format constraint
    ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_format 
        CHECK (customer_id IS NULL OR (customer_id ~ '^[A-Z0-9_]{3,25}$'));
    RAISE NOTICE 'Added format constraint on customer_id';
    
    -- Add phone format constraint
    ALTER TABLE profiles ADD CONSTRAINT profiles_phone_format 
        CHECK (phone IS NULL OR (phone ~ '^[6-9][0-9]{9}$'));
    RAISE NOTICE 'Added phone format constraint';
    
    -- Add pincode format constraint
    ALTER TABLE profiles ADD CONSTRAINT profiles_pincode_format 
        CHECK (pincode IS NULL OR (pincode ~ '^[0-9]{6}$'));
    RAISE NOTICE 'Added pincode format constraint';
    
    -- Add role constraint
    ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
        CHECK (role IN ('admin', 'promoter', 'customer'));
    RAISE NOTICE 'Added role validation constraint';
    
    -- Add status constraint
    ALTER TABLE profiles ADD CONSTRAINT profiles_status_check 
        CHECK (status IN ('active', 'inactive', 'suspended'));
    RAISE NOTICE 'Added status validation constraint';
END $$;

COMMIT;

-- Verification
SELECT 'PROFILES_CONSTRAINTS_ADDED' as status, COUNT(*) as constraint_count
FROM pg_constraint WHERE conname LIKE 'profiles_%';
