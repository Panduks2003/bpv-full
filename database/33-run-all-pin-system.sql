-- =====================================================
-- MASTER SCRIPT: PIN-BASED CUSTOMER CREATION SYSTEM
-- =====================================================
-- This script runs all parts of the pin system implementation
-- Run this file to execute all parts in the correct order

-- IMPORTANT: Run each part separately if you encounter any errors
-- Part 1: \i 33a-add-pins-column.sql
-- Part 2: \i 33b-pin-management-functions.sql  
-- Part 3: \i 33c-create-support-tables.sql
-- Part 4: \i 33d-customer-creation-function.sql

\echo 'Starting Pin-Based Customer Creation System Installation...'

\echo 'Part 1: Adding pins column to profiles table...'
\i 33a-add-pins-column.sql

\echo 'Part 2: Creating pin management functions...'
\i 33b-pin-management-functions.sql

\echo 'Part 3: Creating support tables (pin_usage_log, customer_payments)...'
\i 33c-create-support-tables.sql

\echo 'Part 4: Creating customer creation function with pin deduction...'
\i 33d-customer-creation-function.sql

\echo 'Pin-Based Customer Creation System Installation Complete!'

-- Final verification
\echo 'Running final verification...'

SELECT 'FINAL_VERIFICATION' as check_type, 'Pin System Installation' as component, 'COMPLETE' as status;

-- Check all components
SELECT 'PINS_COLUMN' as component, 
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'profiles' AND column_name = 'pins'
       ) THEN 'OK' ELSE 'MISSING' END as status
UNION ALL
SELECT 'PIN_FUNCTIONS' as component,
       CASE WHEN (
           SELECT COUNT(*) FROM pg_proc 
           WHERE proname IN ('check_promoter_pins', 'deduct_promoter_pins', 'add_promoter_pins')
       ) = 3 THEN 'OK' ELSE 'MISSING' END as status
UNION ALL
SELECT 'SUPPORT_TABLES' as component,
       CASE WHEN (
           SELECT COUNT(*) FROM pg_tables 
           WHERE tablename IN ('pin_usage_log', 'customer_payments') AND schemaname = 'public'
       ) = 2 THEN 'OK' ELSE 'MISSING' END as status
UNION ALL
SELECT 'CUSTOMER_FUNCTION' as component,
       CASE WHEN EXISTS (
           SELECT 1 FROM pg_proc WHERE proname = 'create_customer_with_pin_deduction'
       ) THEN 'OK' ELSE 'MISSING' END as status;

\echo 'Verification complete. All components should show OK status.'
