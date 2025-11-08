-- =====================================================
-- STEP 8: INITIALIZE WALLETS
-- =====================================================
-- Creates wallet entries for existing users
-- Run this after step 7
-- =====================================================

-- =====================================================
-- CREATE ADMIN WALLET FOR EXISTING ADMIN
-- =====================================================
INSERT INTO admin_wallet (admin_id, balance, total_commission_received, unclaimed_commissions)
SELECT id, 0.00, 0.00, 0.00
FROM profiles 
WHERE role = 'admin'
ON CONFLICT (admin_id) DO NOTHING;

-- Success message for admin wallet
SELECT 'Admin wallet initialized for ' || COUNT(*) || ' admin(s)' as status
FROM profiles WHERE role = 'admin';

-- =====================================================
-- CREATE PROMOTER WALLETS FOR EXISTING PROMOTERS
-- =====================================================
INSERT INTO promoter_wallet (promoter_id, balance, total_earned)
SELECT id, 0.00, 0.00
FROM profiles 
WHERE role = 'promoter'
ON CONFLICT (promoter_id) DO NOTHING;

-- Success message for promoter wallets
SELECT 'Promoter wallets initialized for ' || COUNT(*) || ' promoter(s)' as status
FROM profiles WHERE role = 'promoter';

-- =====================================================
-- VERIFICATION
-- =====================================================
-- Verify admin wallet
SELECT 
    'Admin Wallet Verification' as check_type,
    COUNT(*) as admin_wallets_created
FROM admin_wallet;

-- Verify promoter wallets
SELECT 
    'Promoter Wallet Verification' as check_type,
    COUNT(*) as promoter_wallets_created
FROM promoter_wallet;

-- Success message
SELECT 'Step 8 completed: Wallets initialized successfully!' as status;
