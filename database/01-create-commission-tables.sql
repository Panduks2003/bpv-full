-- =====================================================
-- STEP 1: CREATE COMMISSION TABLES
-- =====================================================
-- Creates the basic tables for affiliate commission system
-- Run this first before other scripts
-- =====================================================

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS affiliate_commissions CASCADE;
DROP TABLE IF EXISTS promoter_wallet CASCADE;
DROP TABLE IF EXISTS admin_wallet CASCADE;

-- =====================================================
-- 1. AFFILIATE COMMISSIONS TABLE
-- =====================================================
-- Tracks all commission distributions with complete audit trail
CREATE TABLE affiliate_commissions (
    id SERIAL PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    initiator_promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('promoter', 'admin')),
    level INTEGER NOT NULL CHECK (level BETWEEN 0 AND 4),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'credited', 'failed')),
    transaction_id VARCHAR(50) UNIQUE,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure no duplicate commissions for same customer-level combination
    UNIQUE(customer_id, level)
);

-- Add comments
COMMENT ON TABLE affiliate_commissions IS 'Tracks all affiliate commission distributions with complete audit trail';
COMMENT ON COLUMN affiliate_commissions.level IS 'Commission level: 1-4 for promoters, 0 for admin fallback';
COMMENT ON COLUMN affiliate_commissions.recipient_type IS 'Type of recipient: promoter or admin';
COMMENT ON COLUMN affiliate_commissions.amount IS 'Commission amount in rupees';

-- Success message
SELECT 'Step 1 completed: affiliate_commissions table created successfully!' as status;
