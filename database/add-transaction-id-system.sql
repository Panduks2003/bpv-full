-- =====================================================
-- ADD TRANSACTION ID SYSTEM TO PIN_USAGE_LOG
-- =====================================================
-- This script adds proper BPV transaction ID system with sequential numbering

BEGIN;

-- =====================================================
-- 1. ADD TRANSACTION_ID COLUMN TO PIN_USAGE_LOG
-- =====================================================

-- Add transaction_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pin_usage_log' AND column_name = 'transaction_id'
    ) THEN
        ALTER TABLE pin_usage_log ADD COLUMN transaction_id VARCHAR(20) UNIQUE;
        CREATE INDEX IF NOT EXISTS idx_pin_usage_log_transaction_id ON pin_usage_log(transaction_id);
        
        RAISE NOTICE 'Added transaction_id column to pin_usage_log table';
    END IF;
END $$;

-- =====================================================
-- 2. CREATE TRANSACTION COUNTER TABLE
-- =====================================================

-- Create table to track transaction counters for each type
CREATE TABLE IF NOT EXISTS transaction_counters (
    id SERIAL PRIMARY KEY,
    transaction_type VARCHAR(10) NOT NULL UNIQUE, -- 'CC', 'AA', 'AD'
    counter INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Initialize counters for each transaction type
INSERT INTO transaction_counters (transaction_type, counter) 
VALUES 
    ('CC', 0),  -- Customer Creation
    ('AA', 0),  -- Admin Allocation  
    ('AD', 0)   -- Admin Deduction
ON CONFLICT (transaction_type) DO NOTHING;

-- =====================================================
-- 3. CREATE FUNCTION TO GENERATE TRANSACTION ID
-- =====================================================

CREATE OR REPLACE FUNCTION generate_transaction_id(p_action_type VARCHAR)
RETURNS VARCHAR
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_transaction_type VARCHAR(10);
    v_counter INTEGER;
    v_transaction_id VARCHAR(20);
BEGIN
    -- Map action_type to transaction_type
    CASE p_action_type
        WHEN 'customer_creation' THEN v_transaction_type := 'CC';
        WHEN 'admin_allocation' THEN v_transaction_type := 'AA';
        WHEN 'admin_deduction' THEN v_transaction_type := 'AD';
        ELSE v_transaction_type := 'TX';
    END CASE;
    
    -- Get and increment counter atomically
    UPDATE transaction_counters 
    SET counter = counter + 1, updated_at = NOW()
    WHERE transaction_type = v_transaction_type
    RETURNING counter INTO v_counter;
    
    -- If transaction type doesn't exist, create it
    IF v_counter IS NULL THEN
        INSERT INTO transaction_counters (transaction_type, counter)
        VALUES (v_transaction_type, 1)
        ON CONFLICT (transaction_type) DO UPDATE SET counter = counter + 1
        RETURNING counter INTO v_counter;
    END IF;
    
    -- Generate BPV transaction ID with zero-padded counter
    v_transaction_id := 'BPV-' || v_transaction_type || LPAD(v_counter::TEXT, 2, '0');
    
    RETURN v_transaction_id;
END;
$$;

-- =====================================================
-- 4. CREATE TRIGGER TO AUTO-GENERATE TRANSACTION IDS
-- =====================================================

CREATE OR REPLACE FUNCTION set_transaction_id()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only generate transaction_id if it's not already set
    IF NEW.transaction_id IS NULL THEN
        NEW.transaction_id := generate_transaction_id(NEW.action_type);
    END IF;
    
    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_set_transaction_id ON pin_usage_log;

-- Create trigger to auto-generate transaction IDs
CREATE TRIGGER trigger_set_transaction_id
    BEFORE INSERT ON pin_usage_log
    FOR EACH ROW
    EXECUTE FUNCTION set_transaction_id();

-- =====================================================
-- 5. UPDATE EXISTING RECORDS WITH TRANSACTION IDS
-- =====================================================

-- Update existing records that don't have transaction_id
DO $$
DECLARE
    rec RECORD;
    v_transaction_id VARCHAR(20);
BEGIN
    FOR rec IN 
        SELECT id, action_type 
        FROM pin_usage_log 
        WHERE transaction_id IS NULL 
        ORDER BY created_at ASC
    LOOP
        v_transaction_id := generate_transaction_id(rec.action_type);
        UPDATE pin_usage_log 
        SET transaction_id = v_transaction_id 
        WHERE id = rec.id;
    END LOOP;
    
    RAISE NOTICE 'Updated existing pin_usage_log records with transaction IDs';
END $$;

COMMIT;

-- =====================================================
-- 6. VERIFICATION
-- =====================================================

-- Check transaction_id column exists
SELECT 'TRANSACTION_ID_COLUMN_CHECK' as check_type, 
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'pin_usage_log' AND column_name = 'transaction_id'
       ) THEN 'EXISTS' ELSE 'MISSING' END as status;

-- Check transaction counters
SELECT 'TRANSACTION_COUNTERS' as check_type, 
       transaction_type, 
       counter 
FROM transaction_counters 
ORDER BY transaction_type;

-- Show sample transaction IDs
SELECT 'SAMPLE_TRANSACTION_IDS' as check_type,
       transaction_id,
       action_type,
       pins_used,
       created_at
FROM pin_usage_log 
WHERE transaction_id IS NOT NULL
ORDER BY created_at DESC 
LIMIT 5;
