-- =====================================================
-- FIX CUSTOMER PAYMENT MANAGEMENT SYSTEM
-- =====================================================
-- This script fixes common issues with the payment management system

BEGIN;

-- =====================================================
-- 1. ENSURE CUSTOMER_PAYMENTS TABLE EXISTS
-- =====================================================

CREATE TABLE IF NOT EXISTS customer_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    month_number INTEGER NOT NULL,
    amount INTEGER NOT NULL DEFAULT 1000,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'paid', 'overdue', 'cancelled'
    payment_date TIMESTAMP WITH TIME ZONE,
    marked_by UUID REFERENCES profiles(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(customer_id, month_number)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_customer_payments_customer ON customer_payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_payments_status ON customer_payments(status);
CREATE INDEX IF NOT EXISTS idx_customer_payments_month ON customer_payments(month_number);

-- =====================================================
-- 2. ENABLE RLS AND SET POLICIES
-- =====================================================

ALTER TABLE customer_payments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view related payments" ON customer_payments;
DROP POLICY IF EXISTS "payment_access_policy" ON customer_payments;

-- Create comprehensive RLS policy
CREATE POLICY "payment_access_policy" ON customer_payments
    FOR ALL USING (
        -- Customer can see their own payments
        customer_id = auth.uid() OR
        -- Admin can see all payments
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') OR
        -- Promoter can see payments of their customers
        EXISTS (
            SELECT 1 FROM profiles p1, profiles p2 
            WHERE p1.id = auth.uid() 
            AND p1.role = 'promoter'
            AND p2.id = customer_payments.customer_id
            AND p2.role = 'customer'
            AND p2.parent_promoter_id = p1.id
        )
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON customer_payments TO authenticated;
GRANT USAGE ON SEQUENCE customer_payments_id_seq TO authenticated;

-- =====================================================
-- 3. CREATE PAYMENT SCHEDULES FOR EXISTING CUSTOMERS
-- =====================================================

-- Function to create payment schedule for a customer
CREATE OR REPLACE FUNCTION create_payment_schedule(p_customer_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Check if customer already has payments
    IF EXISTS (SELECT 1 FROM customer_payments WHERE customer_id = p_customer_id) THEN
        RAISE NOTICE 'Customer % already has payment schedule', p_customer_id;
        RETURN;
    END IF;
    
    -- Create 20-month payment schedule
    INSERT INTO customer_payments (
        customer_id,
        month_number,
        amount,
        status,
        created_at,
        updated_at
    )
    SELECT 
        p_customer_id,
        generate_series(1, 20),
        1000,
        'pending',
        NOW(),
        NOW();
    
    RAISE NOTICE 'Created 20-month payment schedule for customer %', p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create payment schedules for all existing customers who don't have them
DO $$
DECLARE
    customer_record RECORD;
    created_count INTEGER := 0;
BEGIN
    FOR customer_record IN 
        SELECT p.id, p.name, p.email
        FROM profiles p
        LEFT JOIN customer_payments cp ON p.id = cp.customer_id
        WHERE p.role = 'customer' 
        AND cp.customer_id IS NULL
    LOOP
        -- Create payment schedule for this customer
        PERFORM create_payment_schedule(customer_record.id);
        created_count := created_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Created payment schedules for % customers', created_count;
END $$;

-- =====================================================
-- 4. ADD MISSING COLUMNS IF THEY DON'T EXIST
-- =====================================================

DO $$
BEGIN
    -- Add payment_amount column if it exists (for compatibility)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'customer_payments' AND column_name = 'payment_amount'
    ) THEN
        -- Update amount from payment_amount if amount is null/zero
        UPDATE customer_payments 
        SET amount = COALESCE(payment_amount, 1000)
        WHERE amount IS NULL OR amount = 0;
        
        -- Drop payment_amount column to avoid confusion
        ALTER TABLE customer_payments DROP COLUMN payment_amount;
        RAISE NOTICE 'Migrated payment_amount to amount column';
    END IF;
    
    -- Ensure updated_at column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'customer_payments' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE customer_payments ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column';
    END IF;
END $$;

-- =====================================================
-- 5. ADD CONSTRAINTS FOR DATA INTEGRITY
-- =====================================================

-- Payment amount validation
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'customer_payments_amount_check') THEN
        ALTER TABLE customer_payments ADD CONSTRAINT customer_payments_amount_check 
            CHECK (amount > 0 AND amount <= 100000);
        RAISE NOTICE 'Added payment amount validation constraint';
    END IF;
END $$;

-- Month number validation
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'customer_payments_month_check') THEN
        ALTER TABLE customer_payments ADD CONSTRAINT customer_payments_month_check 
            CHECK (month_number >= 1 AND month_number <= 60);
        RAISE NOTICE 'Added month number validation constraint';
    END IF;
END $$;

-- Status validation
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'customer_payments_status_check') THEN
        ALTER TABLE customer_payments ADD CONSTRAINT customer_payments_status_check 
            CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled'));
        RAISE NOTICE 'Added payment status validation constraint';
    END IF;
END $$;

-- =====================================================
-- 6. CREATE TRIGGER FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_customer_payments_updated_at ON customer_payments;
CREATE TRIGGER update_customer_payments_updated_at
    BEFORE UPDATE ON customer_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 7. CLEAN UP AND STANDARDIZE EXISTING DATA
-- =====================================================

-- Fix any invalid amounts
UPDATE customer_payments 
SET amount = 1000 
WHERE amount IS NULL OR amount <= 0 OR amount > 100000;

-- Fix any invalid month numbers
UPDATE customer_payments 
SET month_number = 1 
WHERE month_number < 1;

UPDATE customer_payments 
SET month_number = 60 
WHERE month_number > 60;

-- Standardize payment status
UPDATE customer_payments 
SET status = 'pending' 
WHERE status NOT IN ('pending', 'paid', 'overdue', 'cancelled');

-- Set updated_at for existing records
UPDATE customer_payments 
SET updated_at = COALESCE(updated_at, created_at, NOW())
WHERE updated_at IS NULL;

COMMIT;

-- =====================================================
-- 8. VERIFICATION QUERIES
-- =====================================================

-- Check table structure
SELECT 'TABLE_STRUCTURE' as check_type, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'customer_payments' 
ORDER BY ordinal_position;

-- Check customer count and payment records
SELECT 'SUMMARY' as check_type,
       (SELECT COUNT(*) FROM profiles WHERE role = 'customer') as total_customers,
       (SELECT COUNT(DISTINCT customer_id) FROM customer_payments) as customers_with_payments,
       (SELECT COUNT(*) FROM customer_payments) as total_payment_records;

-- Check sample data
SELECT 'SAMPLE_DATA' as check_type,
       cp.customer_id,
       p.name as customer_name,
       COUNT(*) as payment_count,
       SUM(CASE WHEN cp.status = 'paid' THEN 1 ELSE 0 END) as paid_count,
       SUM(CASE WHEN cp.status = 'pending' THEN 1 ELSE 0 END) as pending_count
FROM customer_payments cp
JOIN profiles p ON cp.customer_id = p.id
GROUP BY cp.customer_id, p.name
ORDER BY p.name
LIMIT 5;
