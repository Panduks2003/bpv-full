-- =====================================================
-- CHECK PIN SYSTEM STATUS
-- =====================================================
-- This script checks if the pin system is properly installed

-- Check if pins column exists in profiles table
SELECT 'PINS_COLUMN_CHECK' as check_type, 
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'profiles' AND column_name = 'pins'
       ) THEN 'EXISTS' ELSE 'MISSING' END as status;

-- Check if pin_usage_log table exists
SELECT 'PIN_USAGE_LOG_TABLE' as check_type,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.tables 
           WHERE table_name = 'pin_usage_log'
       ) THEN 'EXISTS' ELSE 'MISSING' END as status;

-- Check if customer_payments table exists
SELECT 'CUSTOMER_PAYMENTS_TABLE' as check_type,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.tables 
           WHERE table_name = 'customer_payments'
       ) THEN 'EXISTS' ELSE 'MISSING' END as status;

-- Check current pin balances
SELECT 'PROMOTER_PIN_BALANCES' as check_type, 
       COUNT(*) as promoter_count,
       SUM(COALESCE(pins, 0)) as total_pins
FROM profiles 
WHERE role = 'promoter';

-- Check pin usage log entries
SELECT 'PIN_USAGE_LOG_ENTRIES' as check_type,
       COUNT(*) as total_entries,
       COUNT(CASE WHEN action_type = 'customer_creation' THEN 1 END) as customer_creation,
       COUNT(CASE WHEN action_type = 'admin_allocation' THEN 1 END) as admin_allocation,
       COUNT(CASE WHEN action_type = 'admin_deduction' THEN 1 END) as admin_deduction
FROM pin_usage_log;

-- Show sample pin usage log entries
SELECT 'SAMPLE_PIN_ENTRIES' as check_type,
       action_type,
       pins_used,
       notes,
       created_at
FROM pin_usage_log 
ORDER BY created_at DESC 
LIMIT 5;
