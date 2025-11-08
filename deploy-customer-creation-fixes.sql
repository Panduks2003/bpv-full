-- =====================================================
-- DEPLOY CUSTOMER CREATION HARDENING FIXES
-- =====================================================
-- This script deploys all the customer creation workflow fixes
-- Run this to apply the hardening improvements
-- =====================================================

\echo '🚀 Starting Customer Creation Workflow Hardening...'

-- Check if we're connected to the right database
SELECT 'DATABASE_CHECK' as check_type, current_database() as database_name;

-- Apply the hardening scripts in sequence
\echo '📋 Step 1: Fixing schema inconsistencies...'
\i database/01-fix-schema-inconsistencies.sql

\echo '📋 Step 2: Fixing duplicates (already completed)...'
-- \i database/fix-duplicates-simple.sql  -- Already run successfully

\echo '📋 Step 3: Fixing existing data...'
\i database/02a-fix-existing-data.sql

\echo '📋 Step 4: Adding remaining constraints...'
\i database/02c-add-payment-constraints.sql

\echo '📋 Step 5: Adding performance indexes...'
\i database/03-add-performance-indexes.sql

\echo '📋 Step 6: Hardening admin customer function...'
\i database/04-harden-admin-customer-function.sql

-- Verify the deployment
\echo '✅ Verifying deployment...'

-- Check constraints
SELECT 'CONSTRAINT_VERIFICATION' as check_type,
       conname as constraint_name,
       contype as constraint_type
FROM pg_constraint 
WHERE conname LIKE 'profiles_%' 
   OR conname LIKE 'customer_payments_%' 
   OR conname LIKE 'pin_usage_log_%'
ORDER BY conname;

-- Check functions
SELECT 'FUNCTION_VERIFICATION' as check_type,
       proname as function_name,
       pronargs as arg_count
FROM pg_proc 
WHERE proname IN ('create_customer_final', 'create_customer_with_pin_deduction', 'audit_customer_creation')
ORDER BY proname;

-- Check triggers
SELECT 'TRIGGER_VERIFICATION' as check_type,
       tgname as trigger_name,
       tgrelid::regclass as table_name
FROM pg_trigger 
WHERE tgname LIKE '%customer%'
ORDER BY tgname;

-- Check indexes
SELECT 'INDEX_VERIFICATION' as check_type,
       indexname as index_name,
       tablename as table_name
FROM pg_indexes 
WHERE indexname LIKE 'idx_%'
  AND (tablename = 'profiles' OR tablename = 'customer_payments' OR tablename = 'pin_usage_log')
ORDER BY tablename, indexname;

-- Test the functions with invalid data to ensure they reject properly
\echo '🧪 Testing function validation...'

-- Test create_customer_final with invalid data
SELECT 'VALIDATION_TEST_1' as test_name,
       CASE 
           WHEN (SELECT create_customer_final('', '', '', '', '', '', '', '', '00000000-0000-0000-0000-000000000000', NULL)::json->>'success')::boolean = false 
           THEN 'PASS - Function rejects empty name'
           ELSE 'FAIL - Function should reject empty name'
       END as result;

-- Test create_customer_final with invalid mobile
SELECT 'VALIDATION_TEST_2' as test_name,
       CASE 
           WHEN (SELECT create_customer_final('Test Name', '123', 'State', 'City', '123456', 'Address', 'TEST123', 'password', '00000000-0000-0000-0000-000000000000', NULL)::json->>'success')::boolean = false 
           THEN 'PASS - Function rejects invalid mobile'
           ELSE 'FAIL - Function should reject invalid mobile'
       END as result;

-- Test create_customer_final with invalid customer ID
SELECT 'VALIDATION_TEST_3' as test_name,
       CASE 
           WHEN (SELECT create_customer_final('Test Name', '9876543210', 'State', 'City', '123456', 'Address', 'x', 'password', '00000000-0000-0000-0000-000000000000', NULL)::json->>'success')::boolean = false 
           THEN 'PASS - Function rejects invalid customer ID'
           ELSE 'FAIL - Function should reject invalid customer ID'
       END as result;

\echo '✅ Customer Creation Workflow Hardening Complete!'
\echo ''
\echo '📋 Summary of Changes Applied:'
\echo '  ✓ Added database constraints for data validation'
\echo '  ✓ Enhanced password security with proper hashing'
\echo '  ✓ Implemented atomic transactions for data consistency'
\echo '  ✓ Added comprehensive input validation'
\echo '  ✓ Created audit triggers for customer creation tracking'
\echo '  ✓ Improved error handling and logging'
\echo '  ✓ Added performance indexes'
\echo '  ✓ Standardized column naming in customer_payments table'
\echo ''
\echo '🔒 Security Improvements:'
\echo '  ✓ SQL injection prevention through parameterized queries'
\echo '  ✓ Input sanitization and validation'
\echo '  ✓ Proper constraint enforcement'
\echo '  ✓ Enhanced password hashing with bcrypt'
\echo '  ✓ Atomic operations to prevent race conditions'
\echo ''
\echo '⚡ Performance Improvements:'
\echo '  ✓ Optimized database indexes'
\echo '  ✓ Efficient query patterns'
\echo '  ✓ Reduced transaction overhead'
\echo ''
\echo '🎯 Next Steps:'
\echo '  1. Test customer creation in both Admin and Promoter interfaces'
\echo '  2. Verify PIN deduction works correctly'
\echo '  3. Check commission distribution functionality'
\echo '  4. Monitor system performance and error logs'
\echo ''
