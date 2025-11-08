-- =====================================================
-- 02: ADD MISSING DATABASE CONSTRAINTS
-- =====================================================
-- This script adds comprehensive database constraints for data integrity
-- =====================================================

BEGIN;

-- =====================================================
-- ADD CONSTRAINTS TO PROFILES TABLE
-- =====================================================

DO $$
BEGIN
    -- Customer ID uniqueness constraint (if not exists)
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_customer_id_unique') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_unique UNIQUE (customer_id);
        RAISE NOTICE 'Added unique constraint on customer_id';
    END IF;
    
    -- Customer ID format validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_customer_id_format') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_format 
            CHECK (customer_id IS NULL OR (customer_id ~ '^[A-Z0-9]{3,20}$'));
        RAISE NOTICE 'Added format constraint on customer_id';
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
            CHECK (status IN ('active', 'inactive', 'suspended', 'Active', 'Inactive'));
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

-- Verification
SELECT 'CONSTRAINTS_ADDED' as status,
       COUNT(*) as constraint_count
FROM pg_constraint 
WHERE conname LIKE 'profiles_%' OR conname LIKE 'customer_payments_%' OR conname LIKE 'pin_usage_log_%';
