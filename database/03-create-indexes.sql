-- =====================================================
-- STEP 3: CREATE INDEXES FOR PERFORMANCE
-- =====================================================
-- Creates indexes for better query performance
-- Run this after steps 1 and 2
-- =====================================================

-- =====================================================
-- INDEXES FOR AFFILIATE_COMMISSIONS TABLE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_customer ON affiliate_commissions(customer_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_initiator ON affiliate_commissions(initiator_promoter_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_recipient ON affiliate_commissions(recipient_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_level ON affiliate_commissions(level);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_status ON affiliate_commissions(status);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_created ON affiliate_commissions(created_at);
CREATE INDEX IF NOT EXISTS idx_affiliate_commissions_transaction ON affiliate_commissions(transaction_id);

-- =====================================================
-- INDEXES FOR WALLET TABLES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_promoter_wallet_balance ON promoter_wallet(balance);
CREATE INDEX IF NOT EXISTS idx_promoter_wallet_updated ON promoter_wallet(updated_at);
CREATE INDEX IF NOT EXISTS idx_admin_wallet_balance ON admin_wallet(balance);
CREATE INDEX IF NOT EXISTS idx_admin_wallet_updated ON admin_wallet(updated_at);

-- =====================================================
-- ADDITIONAL INDEXES FOR BETTER PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_profiles_parent_promoter_id ON profiles(parent_promoter_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_customers_promoter_id ON customers(promoter_id);

-- Success message
SELECT 'Step 3 completed: Indexes created successfully!' as status;
