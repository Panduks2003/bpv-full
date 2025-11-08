-- =====================================================
-- VERIFY PIN REQUESTS TABLE SCHEMA
-- =====================================================
-- This script checks the actual table structure

-- Check if table exists
SELECT 
    'Table Existence Check' as check_type,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'pin_requests'
    ) THEN 'EXISTS' ELSE 'MISSING' END as result;

-- Show all columns in the pin_requests table
SELECT 
    'Column Information' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'pin_requests'
ORDER BY ordinal_position;

-- Show table constraints
SELECT 
    'Constraints' as check_type,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'public' 
AND table_name = 'pin_requests';

-- Show indexes
SELECT 
    'Indexes' as check_type,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'pin_requests';

-- Show RLS policies
SELECT 
    'RLS Policies' as check_type,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'pin_requests';

-- Try a simple select to test access
SELECT 
    'Data Access Test' as check_type,
    COUNT(*) as row_count
FROM pin_requests;
