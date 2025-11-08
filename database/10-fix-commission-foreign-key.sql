-- =====================================================
-- FIX COMMISSION FOREIGN KEY CONSTRAINT
-- =====================================================
-- Changes customer_id to reference profiles(id) instead of customers(id)
-- This fixes the foreign key constraint error during commission distribution
-- =====================================================

-- Drop the existing table
DROP TABLE IF EXISTS affiliate_commissions CASCADE;

-- Recreate with correct foreign key
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
COMMENT ON COLUMN affiliate_commissions.customer_id IS 'References profiles.id (customer profile UUID)';
COMMENT ON COLUMN affiliate_commissions.level IS 'Commission level: 1-4 for promoters, 0 for admin fallback';

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_customer ON affiliate_commissions(customer_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_initiator ON affiliate_commissions(initiator_promoter_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_recipient ON affiliate_commissions(recipient_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_level ON affiliate_commissions(level);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_status ON affiliate_commissions(status);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_created ON affiliate_commissions(created_at);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_transaction ON affiliate_commissions(transaction_id);

-- Recreate RLS policies
ALTER TABLE affiliate_commissions ENABLE ROW LEVEL SECURITY;

-- Promoters can view commissions where they are recipient or initiator
CREATE POLICY "promoters_can_view_own_commissions" ON affiliate_commissions
    FOR SELECT USING (
        auth.uid() = recipient_id OR 
        auth.uid() = initiator_promoter_id OR
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'promoter'
        )
    );

-- Admins can view all commissions
CREATE POLICY "admins_can_view_all_commissions" ON affiliate_commissions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Success message
SELECT 'Step 10 completed: Commission foreign key fixed! customer_id now references profiles(id)' as status;
