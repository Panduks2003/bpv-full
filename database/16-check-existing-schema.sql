-- =====================================================
-- CHECK EXISTING DATABASE SCHEMA
-- =====================================================
-- This script checks what tables and columns actually exist
-- =====================================================

-- Check what tables exist
SELECT 
    'Existing Tables' as check_type,
    table_name,
    '✅ Exists' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('payments', 'commissions', 'withdrawal_requests', 'profiles', 'affiliate_commissions', 'promoter_wallet', 'admin_wallet')
ORDER BY table_name;

-- Check columns in commissions table (if it exists)
SELECT 
    'Commissions Columns' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'commissions'
ORDER BY ordinal_position;

-- Check columns in payments table (if it exists)
SELECT 
    'Payments Columns' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'payments'
ORDER BY ordinal_position;

-- Check columns in affiliate_commissions table (if it exists)
SELECT 
    'Affiliate Commissions Columns' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'affiliate_commissions'
ORDER BY ordinal_position;

-- Check columns in withdrawal_requests table
SELECT 
    'Withdrawal Requests Columns' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'withdrawal_requests'
ORDER BY ordinal_position;

-- Check columns in profiles table
SELECT 
    'Profiles Columns' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;
