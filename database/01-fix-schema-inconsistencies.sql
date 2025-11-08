-- =====================================================
-- 01: FIX DATABASE SCHEMA INCONSISTENCIES
-- =====================================================
-- This script fixes schema inconsistencies in customer_payments table
-- =====================================================

BEGIN;

-- =====================================================
-- FIX CUSTOMER_PAYMENTS TABLE COLUMNS
-- =====================================================

-- Standardize customer_payments table columns
DO $$
BEGIN
    -- Check if both amount and payment_amount columns exist
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customer_payments' AND column_name = 'amount')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customer_payments' AND column_name = 'payment_amount') THEN
        
        -- Copy data from amount to payment_amount if payment_amount is empty
        UPDATE customer_payments SET payment_amount = amount WHERE payment_amount IS NULL OR payment_amount = 0;
        
        -- Drop the duplicate amount column
        ALTER TABLE customer_payments DROP COLUMN amount;
        RAISE NOTICE 'Removed duplicate amount column from customer_payments';
    END IF;
    
    -- Ensure payment_amount column exists and has proper constraints
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customer_payments' AND column_name = 'payment_amount') THEN
        ALTER TABLE customer_payments ADD COLUMN payment_amount DECIMAL(10,2) NOT NULL DEFAULT 1000.00;
        RAISE NOTICE 'Added payment_amount column to customer_payments';
    END IF;
END $$;

COMMIT;

-- Verification
SELECT 'SCHEMA_FIX_COMPLETE' as status, 
       'customer_payments table standardized' as message;
