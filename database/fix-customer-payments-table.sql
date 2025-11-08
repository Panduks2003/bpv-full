-- =====================================================
-- FIX CUSTOMER PAYMENTS TABLE STRUCTURE
-- =====================================================
-- This script checks and fixes the customer_payments table structure

-- Check current structure of customer_payments table
SELECT 'CUSTOMER_PAYMENTS_COLUMNS' as check_type, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'customer_payments' 
ORDER BY ordinal_position;

-- Check if the table exists
SELECT 'TABLE_EXISTS_CHECK' as check_type,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.tables 
           WHERE table_name = 'customer_payments'
       ) THEN 'EXISTS' ELSE 'MISSING' END as status;

-- Add missing columns if they don't exist
DO $$
BEGIN
    -- Add amount column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'customer_payments' AND column_name = 'amount'
    ) THEN
        ALTER TABLE customer_payments ADD COLUMN amount INTEGER DEFAULT 1000;
        RAISE NOTICE 'Added amount column to customer_payments table';
    END IF;
    
    -- Add other potentially missing columns
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'customer_payments' AND column_name = 'month_number'
    ) THEN
        ALTER TABLE customer_payments ADD COLUMN month_number INTEGER NOT NULL DEFAULT 1;
        RAISE NOTICE 'Added month_number column to customer_payments table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'customer_payments' AND column_name = 'status'
    ) THEN
        ALTER TABLE customer_payments ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
        RAISE NOTICE 'Added status column to customer_payments table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'customer_payments' AND column_name = 'payment_date'
    ) THEN
        ALTER TABLE customer_payments ADD COLUMN payment_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added payment_date column to customer_payments table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'customer_payments' AND column_name = 'marked_by'
    ) THEN
        ALTER TABLE customer_payments ADD COLUMN marked_by UUID REFERENCES profiles(id);
        RAISE NOTICE 'Added marked_by column to customer_payments table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'customer_payments' AND column_name = 'notes'
    ) THEN
        ALTER TABLE customer_payments ADD COLUMN notes TEXT;
        RAISE NOTICE 'Added notes column to customer_payments table';
    END IF;
END $$;

-- Verify the table structure after fixes
SELECT 'FIXED_TABLE_STRUCTURE' as check_type, column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'customer_payments' 
ORDER BY ordinal_position;
