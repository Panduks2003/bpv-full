-- =====================================================
-- CHECK ADMIN COUNT IN SYSTEM
-- =====================================================
-- This script checks how many admins exist in the system
-- There should only be ONE admin for commission fallback
-- =====================================================

-- Check total admins in profiles table
SELECT 
    'Total Admins in Profiles' as check_type,
    COUNT(*) as admin_count,
    json_agg(json_build_object('id', id, 'name', name, 'email', email)) as admin_details
FROM profiles 
WHERE role = 'admin';

-- Check admin wallets
SELECT 
    'Total Admin Wallets' as check_type,
    COUNT(*) as wallet_count,
    json_agg(json_build_object('admin_id', admin_id, 'balance', balance)) as wallet_details
FROM admin_wallet;

-- Check commission recipients with admin type
SELECT 
    'Admin Commission Recipients' as check_type,
    COUNT(DISTINCT recipient_id) as unique_admin_recipients,
    json_agg(DISTINCT recipient_id) as admin_ids
FROM affiliate_commissions
WHERE recipient_type = 'admin';

-- Detailed admin information
SELECT 
    p.id,
    p.name,
    p.email,
    p.role,
    p.created_at,
    aw.balance as wallet_balance,
    aw.total_commission_received
FROM profiles p
LEFT JOIN admin_wallet aw ON p.id = aw.admin_id
WHERE p.role = 'admin'
ORDER BY p.created_at;

-- =====================================================
-- RECOMMENDATION
-- =====================================================
-- If you see more than 1 admin:
-- 1. Identify which admin should be the primary one
-- 2. Run the cleanup script to remove duplicate admins
-- 3. Keep only ONE admin for the system
-- =====================================================
