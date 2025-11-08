-- =====================================================
-- STEP 9: VERIFICATION QUERIES
-- =====================================================
-- Verifies that the commission system is set up correctly
-- Run this after step 8
-- =====================================================

-- =====================================================
-- VERIFY TABLES EXIST
-- =====================================================
SELECT 
    'Table Verification' as check_type,
    expected_tables.table_name,
    CASE WHEN t.table_name IS NOT NULL THEN '✅ Exists' ELSE '❌ Missing' END as status
FROM (
    VALUES 
        ('affiliate_commissions'),
        ('promoter_wallet'),
        ('admin_wallet')
) AS expected_tables(table_name)
LEFT JOIN information_schema.tables t 
    ON t.table_name = expected_tables.table_name 
    AND t.table_schema = 'public';

-- =====================================================
-- VERIFY INDEXES EXIST
-- =====================================================
SELECT 
    'Index Verification' as check_type,
    COUNT(*) as total_indexes
FROM pg_indexes 
WHERE tablename IN ('affiliate_commissions', 'promoter_wallet', 'admin_wallet');

-- =====================================================
-- VERIFY RLS POLICIES
-- =====================================================
SELECT 
    'RLS Policy Verification' as check_type,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename IN ('affiliate_commissions', 'promoter_wallet', 'admin_wallet')
GROUP BY tablename;

-- =====================================================
-- VERIFY FUNCTIONS EXIST
-- =====================================================
SELECT 
    'Function Verification' as check_type,
    proname as function_name,
    '✅ Exists' as status
FROM pg_proc 
WHERE proname IN (
    'distribute_affiliate_commission',
    'get_promoter_commission_summary',
    'get_admin_commission_summary',
    'trigger_commission_distribution'
);

-- =====================================================
-- VERIFY TRIGGERS EXIST
-- =====================================================
SELECT 
    'Trigger Verification' as check_type,
    trigger_name,
    event_object_table as table_name,
    '✅ Exists' as status
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_affiliate_commission';

-- =====================================================
-- VERIFY WALLET INITIALIZATION
-- =====================================================
SELECT 
    'Wallet Initialization' as check_type,
    'Admin Wallets' as wallet_type,
    COUNT(*) as count
FROM admin_wallet
UNION ALL
SELECT 
    'Wallet Initialization' as check_type,
    'Promoter Wallets' as wallet_type,
    COUNT(*) as count
FROM promoter_wallet;

-- =====================================================
-- SYSTEM READINESS CHECK
-- =====================================================
SELECT 
    '🎉 SYSTEM READINESS CHECK' as check_type,
    CASE 
        WHEN (
            (SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('affiliate_commissions', 'promoter_wallet', 'admin_wallet') AND table_schema = 'public') = 3
            AND (SELECT COUNT(*) FROM pg_proc WHERE proname = 'distribute_affiliate_commission') = 1
            AND (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name = 'trigger_affiliate_commission') = 1
            AND (SELECT COUNT(*) FROM admin_wallet) > 0
        )
        THEN '✅ ALL SYSTEMS READY - Commission system is fully operational!'
        ELSE '⚠️ INCOMPLETE SETUP - Please review missing components above'
    END as status;

-- Success message
SELECT 'Step 9 completed: Verification complete!' as status;
