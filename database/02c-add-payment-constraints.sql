-- =====================================================
-- 02C: ADD PAYMENT AND PIN CONSTRAINTS
-- =====================================================
-- This script adds constraints to customer_payments and pin_usage_log tables
-- =====================================================

BEGIN;

-- Add constraints to customer_payments table
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

-- Add constraints to pin_usage_log table
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
SELECT 'PAYMENT_PIN_CONSTRAINTS_ADDED' as status, 
       COUNT(*) as constraint_count
FROM pg_constraint 
WHERE conname LIKE 'customer_payments_%' OR conname LIKE 'pin_usage_log_%';

-- Report any remaining data issues
SELECT 'DATA_ISSUES_CHECK' as report_type,
       'customer_id' as field,
       COUNT(*) as issue_count
FROM profiles 
WHERE customer_id IS NOT NULL 
  AND customer_id !~ '^[A-Z0-9_]{3,25}$'
  AND role = 'customer'

UNION ALL

SELECT 'DATA_ISSUES_CHECK' as report_type,
       'phone' as field,
       COUNT(*) as issue_count
FROM profiles 
WHERE phone IS NOT NULL 
  AND phone !~ '^[6-9][0-9]{9}$'

UNION ALL

SELECT 'DATA_ISSUES_CHECK' as report_type,
       'pincode' as field,
       COUNT(*) as issue_count
FROM profiles 
WHERE pincode IS NOT NULL 
  AND pincode !~ '^[0-9]{6}$';
