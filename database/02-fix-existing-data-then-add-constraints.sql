-- =====================================================
-- 02: FIX EXISTING DATA THEN ADD DATABASE CONSTRAINTS
-- =====================================================
-- This script first fixes existing data to comply with new constraints
-- then adds the constraints for future data integrity
-- =====================================================

BEGIN;

-- =====================================================
-- FIRST: FIX EXISTING DATA TO COMPLY WITH CONSTRAINTS
-- =====================================================

-- Fix existing customer_id values that don't match the format
UPDATE profiles 
SET customer_id = upper(regexp_replace(customer_id, '[^A-Z0-9]', '', 'g'))
WHERE customer_id IS NOT NULL 
  AND customer_id !~ '^[A-Z0-9]{3,20}$'
  AND role = 'customer';

-- Fix customer_id values that are too short (pad with zeros)
UPDATE profiles 
SET customer_id = customer_id || '000'
WHERE customer_id IS NOT NULL 
  AND length(customer_id) < 3
  AND role = 'customer';

-- Fix customer_id values that are too long (truncate to 20 chars)
UPDATE profiles 
SET customer_id = left(customer_id, 20)
WHERE customer_id IS NOT NULL 
  AND length(customer_id) > 20
  AND role = 'customer';

-- Fix phone numbers that don't match format
UPDATE profiles 
SET phone = regexp_replace(phone, '[^0-9]', '', 'g')
WHERE phone IS NOT NULL 
  AND phone !~ '^[6-9][0-9]{9}$'
  AND length(regexp_replace(phone, '[^0-9]', '', 'g')) = 10
  AND left(regexp_replace(phone, '[^0-9]', '', 'g'), 1) IN ('6','7','8','9');

-- Set invalid phone numbers to NULL (will need manual correction)
UPDATE profiles 
SET phone = NULL
WHERE phone IS NOT NULL 
  AND phone !~ '^[6-9][0-9]{9}$'
  AND NOT (length(regexp_replace(phone, '[^0-9]', '', 'g')) = 10
           AND left(regexp_replace(phone, '[^0-9]', '', 'g'), 1) IN ('6','7','8','9'));

-- Fix pincode format
UPDATE profiles 
SET pincode = lpad(regexp_replace(pincode, '[^0-9]', '', 'g'), 6, '0')
WHERE pincode IS NOT NULL 
  AND pincode !~ '^[0-9]{6}$'
  AND length(regexp_replace(pincode, '[^0-9]', '', 'g')) <= 6
  AND length(regexp_replace(pincode, '[^0-9]', '', 'g')) > 0;

-- Set invalid pincodes to NULL (will need manual correction)
UPDATE profiles 
SET pincode = NULL
WHERE pincode IS NOT NULL 
  AND pincode !~ '^[0-9]{6}$'
  AND NOT (length(regexp_replace(pincode, '[^0-9]', '', 'g')) <= 6
           AND length(regexp_replace(pincode, '[^0-9]', '', 'g')) > 0);

-- Standardize role values
UPDATE profiles SET role = 'admin' WHERE role ILIKE 'admin%';
UPDATE profiles SET role = 'promoter' WHERE role ILIKE 'promoter%';
UPDATE profiles SET role = 'customer' WHERE role ILIKE 'customer%';

-- Standardize status values
UPDATE profiles SET status = 'active' WHERE status ILIKE 'active%' OR status = 'Active';
UPDATE profiles SET status = 'inactive' WHERE status ILIKE 'inactive%' OR status = 'Inactive';

-- Fix payment amounts that are out of range
UPDATE customer_payments 
SET payment_amount = 1000.00 
WHERE payment_amount <= 0 OR payment_amount > 100000;

-- Fix month numbers that are out of range
UPDATE customer_payments 
SET month_number = 1 
WHERE month_number < 1;

UPDATE customer_payments 
SET month_number = 60 
WHERE month_number > 60;

-- Standardize payment status
UPDATE customer_payments SET status = 'pending' WHERE status NOT IN ('pending', 'paid', 'overdue', 'cancelled');

-- Fix pin usage log values
UPDATE pin_usage_log 
SET pins_used = 1 
WHERE pins_used <= 0 OR pins_used > 1000;

-- Standardize action types
UPDATE pin_usage_log 
SET action_type = 'customer_creation' 
WHERE action_type NOT IN ('customer_creation', 'admin_allocation', 'promoter_creation', 'adjustment');

-- Report on data fixes
SELECT 'DATA_CLEANUP_REPORT' as report_type,
       'Fixed existing data to comply with new constraints' as message;

-- =====================================================
-- NOW ADD CONSTRAINTS TO PROFILES TABLE
-- =====================================================

DO $$
BEGIN
    -- Handle existing unique constraint and duplicates
    -- First, check if there's already a unique constraint (any name)
    IF EXISTS (SELECT 1 FROM pg_constraint c 
               JOIN pg_class t ON c.conrelid = t.oid 
               WHERE t.relname = 'profiles' 
               AND c.contype = 'u' 
               AND array_to_string(c.conkey, ',') = (
                   SELECT array_to_string(array_agg(attnum), ',')
                   FROM pg_attribute 
                   WHERE attrelid = t.oid AND attname = 'customer_id'
               )) THEN
        RAISE NOTICE 'Unique constraint on customer_id already exists, handling duplicates...';
        
        -- Temporarily drop the existing constraint to fix duplicates
        DECLARE
            constraint_name TEXT;
        BEGIN
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
            
            IF constraint_name IS NOT NULL THEN
                EXECUTE 'ALTER TABLE profiles DROP CONSTRAINT ' || constraint_name;
                RAISE NOTICE 'Temporarily dropped existing constraint: %', constraint_name;
            END IF;
        END;
    END IF;
    
    -- Now handle duplicates by adding suffix to duplicates
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
    
    -- Report on duplicates fixed
    GET DIAGNOSTICS duplicate_count = ROW_COUNT;
    IF duplicate_count > 0 THEN
        RAISE NOTICE 'Fixed % duplicate customer_id values', duplicate_count;
    END IF;
    
    -- Now add our standardized constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_customer_id_unique') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_unique UNIQUE (customer_id);
        RAISE NOTICE 'Added unique constraint on customer_id';
    END IF;
    
    -- Customer ID format validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_customer_id_format') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_format 
            CHECK (customer_id IS NULL OR (customer_id ~ '^[A-Z0-9_]{3,25}$'));
        RAISE NOTICE 'Added format constraint on customer_id (allowing underscores for duplicates)';
    END IF;
    
    -- Phone number format validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_phone_format') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_phone_format 
            CHECK (phone IS NULL OR (phone ~ '^[6-9][0-9]{9}$'));
        RAISE NOTICE 'Added phone format constraint';
    END IF;
    
    -- Pincode format validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_pincode_format') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_pincode_format 
            CHECK (pincode IS NULL OR (pincode ~ '^[0-9]{6}$'));
        RAISE NOTICE 'Added pincode format constraint';
    END IF;
    
    -- Role validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_role_check') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
            CHECK (role IN ('admin', 'promoter', 'customer'));
        RAISE NOTICE 'Added role validation constraint';
    END IF;
    
    -- Status validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_status_check') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_status_check 
            CHECK (status IN ('active', 'inactive', 'suspended'));
        RAISE NOTICE 'Added status validation constraint';
    END IF;
END $$;

-- =====================================================
-- ADD CONSTRAINTS TO CUSTOMER_PAYMENTS TABLE
-- =====================================================

DO $$
BEGIN
    -- Payment amount validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'customer_payments_amount_check') THEN
        ALTER TABLE customer_payments ADD CONSTRAINT customer_payments_amount_check 
            CHECK (payment_amount > 0 AND payment_amount <= 100000);
        RAISE NOTICE 'Added payment amount validation constraint';
    END IF;
    
    -- Month number validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'customer_payments_month_check') THEN
        ALTER TABLE customer_payments ADD CONSTRAINT customer_payments_month_check 
            CHECK (month_number >= 1 AND month_number <= 60);
        RAISE NOTICE 'Added month number validation constraint';
    END IF;
    
    -- Status validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'customer_payments_status_check') THEN
        ALTER TABLE customer_payments ADD CONSTRAINT customer_payments_status_check 
            CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled'));
        RAISE NOTICE 'Added payment status validation constraint';
    END IF;
END $$;

-- =====================================================
-- ADD CONSTRAINTS TO PIN_USAGE_LOG TABLE
-- =====================================================

DO $$
BEGIN
    -- Pins used validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pin_usage_log_pins_check') THEN
        ALTER TABLE pin_usage_log ADD CONSTRAINT pin_usage_log_pins_check 
            CHECK (pins_used > 0 AND pins_used <= 1000);
        RAISE NOTICE 'Added pins used validation constraint';
    END IF;
    
    -- Action type validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pin_usage_log_action_check') THEN
        ALTER TABLE pin_usage_log ADD CONSTRAINT pin_usage_log_action_check 
            CHECK (action_type IN ('customer_creation', 'admin_allocation', 'promoter_creation', 'adjustment'));
        RAISE NOTICE 'Added action type validation constraint';
    END IF;
END $$;

COMMIT;

-- =====================================================
-- VERIFICATION AND REPORTING
-- =====================================================

-- Report any remaining data issues
SELECT 'DATA_ISSUES_REPORT' as report_type,
       'customer_id' as field,
       COUNT(*) as issue_count
FROM profiles 
WHERE customer_id IS NOT NULL 
  AND customer_id !~ '^[A-Z0-9_]{3,25}$'
  AND role = 'customer'

UNION ALL

SELECT 'DATA_ISSUES_REPORT' as report_type,
       'phone' as field,
       COUNT(*) as issue_count
FROM profiles 
WHERE phone IS NOT NULL 
  AND phone !~ '^[6-9][0-9]{9}$'

UNION ALL

SELECT 'DATA_ISSUES_REPORT' as report_type,
       'pincode' as field,
       COUNT(*) as issue_count
FROM profiles 
WHERE pincode IS NOT NULL 
  AND pincode !~ '^[0-9]{6}$';

-- Verification of constraints
SELECT 'CONSTRAINTS_ADDED' as status,
       COUNT(*) as constraint_count
FROM pg_constraint 
WHERE conname LIKE 'profiles_%' OR conname LIKE 'customer_payments_%' OR conname LIKE 'pin_usage_log_%';
