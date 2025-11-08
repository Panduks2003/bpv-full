-- =====================================================
-- AFFILIATE COMMISSION SYSTEM - MASTER INSTALLER
-- =====================================================
-- This script runs all installation steps in the correct order
-- Execute this file to install the complete commission system
-- =====================================================

\echo '=========================================='
\echo 'AFFILIATE COMMISSION SYSTEM INSTALLATION'
\echo '=========================================='
\echo ''
\echo 'This will install the complete ₹800 commission distribution system'
\echo 'across 4 affiliate levels with admin fallback.'
\echo ''

-- =====================================================
-- STEP 1: CREATE COMMISSION TABLES
-- =====================================================
\echo 'Step 1/9: Creating commission tables...'
\i 01-create-commission-tables.sql
\echo ''

-- =====================================================
-- STEP 2: CREATE WALLET TABLES
-- =====================================================
\echo 'Step 2/9: Creating wallet tables...'
\i 02-create-wallet-tables.sql
\echo ''

-- =====================================================
-- STEP 3: CREATE INDEXES
-- =====================================================
\echo 'Step 3/9: Creating indexes for performance...'
\i 03-create-indexes.sql
\echo ''

-- =====================================================
-- STEP 4: CREATE RLS POLICIES
-- =====================================================
\echo 'Step 4/9: Creating Row Level Security policies...'
\i 04-create-rls-policies.sql
\echo ''

-- =====================================================
-- STEP 5: CREATE COMMISSION DISTRIBUTION FUNCTION
-- =====================================================
\echo 'Step 5/9: Creating commission distribution function...'
\i 05-create-commission-function.sql
\echo ''

-- =====================================================
-- STEP 6: CREATE UTILITY FUNCTIONS
-- =====================================================
\echo 'Step 6/9: Creating utility functions...'
\i 06-create-utility-functions.sql
\echo ''

-- =====================================================
-- STEP 7: CREATE TRIGGERS
-- =====================================================
\echo 'Step 7/9: Creating automatic triggers...'
\i 07-create-triggers.sql
\echo ''

-- =====================================================
-- STEP 8: INITIALIZE WALLETS
-- =====================================================
\echo 'Step 8/9: Initializing wallets for existing users...'
\i 08-initialize-wallets.sql
\echo ''

-- =====================================================
-- STEP 9: VERIFICATION
-- =====================================================
\echo 'Step 9/9: Running verification checks...'
\i 09-verification-queries.sql
\echo ''

-- =====================================================
-- INSTALLATION COMPLETE
-- =====================================================
\echo '=========================================='
\echo '✅ INSTALLATION COMPLETE!'
\echo '=========================================='
\echo ''
\echo 'The Affiliate Commission Distribution System is now installed.'
\echo ''
\echo 'Key Features:'
\echo '  • Automatic ₹800 commission distribution on customer creation'
\echo '  • 4-level affiliate hierarchy (₹500, ₹100, ₹100, ₹100)'
\echo '  • Admin fallback for missing affiliates'
\echo '  • Promoter and admin wallet management'
\echo '  • Complete audit trail and transaction history'
\echo '  • Row Level Security for data protection'
\echo ''
\echo 'Next Steps:'
\echo '  1. Test the system by creating a customer'
\echo '  2. Verify commission distribution in affiliate_commissions table'
\echo '  3. Check wallet balances in promoter_wallet and admin_wallet'
\echo '  4. Review the frontend integration in the application'
\echo ''
\echo 'For testing, you can run: test-commission-distribution.sql'
\echo ''
