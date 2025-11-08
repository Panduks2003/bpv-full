-- =====================================================
-- SAFE WITHDRAWAL SYSTEM FIX
-- =====================================================
-- This script only adds missing columns to existing tables
-- and creates minimal tables if they don't exist
-- =====================================================

-- =====================================================
-- 1. FIX WITHDRAWAL_REQUESTS TABLE
-- =====================================================

-- Add missing columns to withdrawal_requests table
DO $$
BEGIN
    -- Add bank_details column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'bank_details'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN bank_details JSONB;
        RAISE NOTICE 'Added bank_details column to withdrawal_requests';
    END IF;
    
    -- Add admin_notes column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'admin_notes'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN admin_notes TEXT;
        RAISE NOTICE 'Added admin_notes column to withdrawal_requests';
    END IF;
    
    -- Add processed_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'processed_at'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN processed_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added processed_at column to withdrawal_requests';
    END IF;
    
    -- Add transaction_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'transaction_id'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN transaction_id VARCHAR(100);
        RAISE NOTICE 'Added transaction_id column to withdrawal_requests';
    END IF;
    
    -- Add rejection_reason column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'rejection_reason'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN rejection_reason TEXT;
        RAISE NOTICE 'Added rejection_reason column to withdrawal_requests';
    END IF;
END $$;

-- =====================================================
-- 2. FIX PROFILES TABLE
-- =====================================================

-- Add bank_accounts column to profiles table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'bank_accounts'
    ) THEN
        ALTER TABLE profiles ADD COLUMN bank_accounts JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added bank_accounts column to profiles';
    END IF;
END $$;

-- =====================================================
-- 3. FIX EXISTING COMMISSIONS TABLE (ADD MISSING COLUMNS)
-- =====================================================

DO $$
BEGIN
    -- Check if commissions table exists
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'commissions' 
        AND table_schema = 'public'
    ) THEN
        -- Add amount column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'commissions' 
            AND column_name = 'amount'
        ) THEN
            ALTER TABLE commissions ADD COLUMN amount DECIMAL(10,2) DEFAULT 0.00;
            RAISE NOTICE 'Added amount column to existing commissions table';
        END IF;
        
        -- Add status column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'commissions' 
            AND column_name = 'status'
        ) THEN
            ALTER TABLE commissions ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
            RAISE NOTICE 'Added status column to existing commissions table';
        END IF;
        
        -- Add promoter_id column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'commissions' 
            AND column_name = 'promoter_id'
        ) THEN
            ALTER TABLE commissions ADD COLUMN promoter_id UUID REFERENCES profiles(id);
            RAISE NOTICE 'Added promoter_id column to existing commissions table';
        END IF;
    ELSE
        -- Create commissions table if it doesn't exist
        CREATE TABLE commissions (
            id SERIAL PRIMARY KEY,
            promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
            amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            status VARCHAR(20) NOT NULL DEFAULT 'pending',
            commission_type VARCHAR(50) DEFAULT 'affiliate',
            customer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
            level INTEGER DEFAULT 1,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Enable RLS
        ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;
        
        -- Create RLS policies
        CREATE POLICY "promoters_can_view_own_commissions" ON commissions
            FOR SELECT USING (
                auth.uid() = promoter_id OR 
                EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
            );
        
        RAISE NOTICE 'Created new commissions table';
    END IF;
END $$;

-- =====================================================
-- 4. FIX EXISTING PAYMENTS TABLE (ADD MISSING COLUMNS)
-- =====================================================

DO $$
BEGIN
    -- Check if payments table exists
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'payments' 
        AND table_schema = 'public'
    ) THEN
        -- Add amount column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'payments' 
            AND column_name = 'amount'
        ) THEN
            ALTER TABLE payments ADD COLUMN amount DECIMAL(10,2) DEFAULT 0.00;
            RAISE NOTICE 'Added amount column to existing payments table';
        END IF;
        
        -- Add payment_type column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'payments' 
            AND column_name = 'payment_type'
        ) THEN
            ALTER TABLE payments ADD COLUMN payment_type VARCHAR(20) DEFAULT 'credit';
            RAISE NOTICE 'Added payment_type column to existing payments table';
        END IF;
        
        -- Add status column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'payments' 
            AND column_name = 'status'
        ) THEN
            ALTER TABLE payments ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
            RAISE NOTICE 'Added status column to existing payments table';
        END IF;
        
        -- Add promoter_id column if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'payments' 
            AND column_name = 'promoter_id'
        ) THEN
            ALTER TABLE payments ADD COLUMN promoter_id UUID REFERENCES profiles(id);
            RAISE NOTICE 'Added promoter_id column to existing payments table';
        END IF;
    ELSE
        -- Create payments table if it doesn't exist
        CREATE TABLE payments (
            id SERIAL PRIMARY KEY,
            promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
            amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            payment_type VARCHAR(20) NOT NULL DEFAULT 'credit',
            status VARCHAR(20) NOT NULL DEFAULT 'pending',
            description TEXT,
            reference_id VARCHAR(100),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Enable RLS
        ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
        
        -- Create RLS policies
        CREATE POLICY "promoters_can_view_own_payments" ON payments
            FOR SELECT USING (
                auth.uid() = promoter_id OR 
                EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
            );
        
        RAISE NOTICE 'Created new payments table';
    END IF;
END $$;

-- =====================================================
-- 5. VERIFICATION ONLY (NO DATA INSERTION)
-- =====================================================

-- Verify all required columns exist
SELECT 
    'Column Check' as check_type,
    table_name || '.' || column_name as column_name,
    '✅ Exists' as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND (
    (table_name = 'withdrawal_requests' AND column_name IN ('bank_details', 'admin_notes', 'processed_at', 'transaction_id', 'rejection_reason')) OR
    (table_name = 'profiles' AND column_name = 'bank_accounts') OR
    (table_name = 'commissions' AND column_name IN ('amount', 'status', 'promoter_id')) OR
    (table_name = 'payments' AND column_name IN ('amount', 'payment_type', 'status', 'promoter_id'))
)
ORDER BY table_name, column_name;

-- Check table existence
SELECT 
    'Table Check' as check_type,
    table_name,
    '✅ Exists' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('payments', 'commissions', 'withdrawal_requests', 'profiles')
ORDER BY table_name;

-- Success message
SELECT '✅ Safe withdrawal fix applied successfully! No data insertion attempted.' as status;
