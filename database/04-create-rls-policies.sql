-- =====================================================
-- STEP 4: CREATE ROW LEVEL SECURITY POLICIES
-- =====================================================
-- Creates RLS policies for secure data access
-- Run this after steps 1, 2, and 3
-- =====================================================

-- =====================================================
-- RLS POLICIES FOR AFFILIATE_COMMISSIONS
-- =====================================================
-- Enable RLS
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

-- =====================================================
-- RLS POLICIES FOR PROMOTER_WALLET
-- =====================================================
-- Enable RLS
ALTER TABLE promoter_wallet ENABLE ROW LEVEL SECURITY;

-- Promoters can view their own wallet
CREATE POLICY "promoters_can_view_own_wallet" ON promoter_wallet
    FOR SELECT USING (auth.uid() = promoter_id);

-- Admins can view all wallets
CREATE POLICY "admins_can_view_all_wallets" ON promoter_wallet
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- =====================================================
-- RLS POLICIES FOR ADMIN_WALLET
-- =====================================================
-- Enable RLS
ALTER TABLE admin_wallet ENABLE ROW LEVEL SECURITY;

-- Only admins can access admin wallet
CREATE POLICY "admins_can_access_admin_wallet" ON admin_wallet
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Success message
SELECT 'Step 4 completed: RLS policies created successfully!' as status;
