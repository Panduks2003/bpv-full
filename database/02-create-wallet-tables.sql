-- =====================================================
-- STEP 2: CREATE WALLET TABLES
-- =====================================================
-- Creates promoter and admin wallet tables
-- Run this after step 1
-- =====================================================

-- =====================================================
-- 1. PROMOTER WALLET TABLE
-- =====================================================
-- Manages promoter wallet balances with commission tracking
CREATE TABLE promoter_wallet (
    promoter_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    total_earned DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (total_earned >= 0),
    total_withdrawn DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (total_withdrawn >= 0),
    commission_count INTEGER NOT NULL DEFAULT 0 CHECK (commission_count >= 0),
    last_commission_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comments
COMMENT ON TABLE promoter_wallet IS 'Manages promoter wallet balances and commission earnings';
COMMENT ON COLUMN promoter_wallet.balance IS 'Current available balance for withdrawal';
COMMENT ON COLUMN promoter_wallet.total_earned IS 'Lifetime total commission earned';

-- =====================================================
-- 2. ADMIN WALLET TABLE
-- =====================================================
-- Manages admin wallet for unclaimed commissions
CREATE TABLE admin_wallet (
    admin_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    total_commission_received DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    unclaimed_commissions DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    commission_count INTEGER NOT NULL DEFAULT 0 CHECK (commission_count >= 0),
    last_commission_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comments
COMMENT ON TABLE admin_wallet IS 'Manages admin wallet for unclaimed commission fallbacks';
COMMENT ON COLUMN admin_wallet.unclaimed_commissions IS 'Total commissions received due to missing affiliates';

-- Success message
SELECT 'Step 2 completed: Wallet tables created successfully!' as status;
