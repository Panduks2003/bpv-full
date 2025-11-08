-- =====================================================
-- COMPREHENSIVE PIN-RELATED DATABASE CHECK
-- =====================================================
-- This query checks everything related to "pin" in the database

-- 1. CHECK ALL TABLES WITH "PIN" IN THE NAME
SELECT 
    '1. TABLES WITH PIN' as section,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND LOWER(table_name) LIKE '%pin%'
ORDER BY table_name;

-- 2. CHECK ALL COLUMNS WITH "PIN" IN THE NAME (ANY TABLE)
SELECT 
    '2. COLUMNS WITH PIN' as section,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND LOWER(column_name) LIKE '%pin%'
ORDER BY table_name, column_name;

-- 3. CHECK ALL FUNCTIONS/PROCEDURES WITH "PIN" IN THE NAME
SELECT 
    '3. FUNCTIONS WITH PIN' as section,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND LOWER(routine_name) LIKE '%pin%'
ORDER BY routine_name;

-- 4. CHECK SPECIFIC PIN_REQUESTS TABLE STRUCTURE (IF EXISTS)
SELECT 
    '4. PIN_REQUESTS COLUMNS' as section,
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'pin_requests'
ORDER BY ordinal_position;

-- 5. CHECK PIN_TRANSACTIONS TABLE STRUCTURE (IF EXISTS)
SELECT 
    '5. PIN_TRANSACTIONS COLUMNS' as section,
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'pin_transactions'
ORDER BY ordinal_position;

-- 6. CHECK ALL CONSTRAINTS ON PIN-RELATED TABLES
SELECT 
    '6. PIN TABLE CONSTRAINTS' as section,
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'public' 
AND LOWER(table_name) LIKE '%pin%'
ORDER BY table_name, constraint_name;

-- 7. CHECK ALL INDEXES ON PIN-RELATED TABLES
SELECT 
    '7. PIN TABLE INDEXES' as section,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
AND LOWER(tablename) LIKE '%pin%'
ORDER BY tablename, indexname;

-- 8. CHECK RLS POLICIES ON PIN-RELATED TABLES
SELECT 
    '8. PIN TABLE RLS POLICIES' as section,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
AND LOWER(tablename) LIKE '%pin%'
ORDER BY tablename, policyname;

-- 9. CHECK FOREIGN KEY RELATIONSHIPS INVOLVING PIN TABLES
SELECT 
    '9. PIN TABLE FOREIGN KEYS' as section,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
AND (LOWER(tc.table_name) LIKE '%pin%' OR LOWER(ccu.table_name) LIKE '%pin%')
ORDER BY tc.table_name, kcu.column_name;

-- 10. CHECK TRIGGERS ON PIN-RELATED TABLES
SELECT 
    '10. PIN TABLE TRIGGERS' as section,
    event_object_table as table_name,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND LOWER(event_object_table) LIKE '%pin%'
ORDER BY event_object_table, trigger_name;

-- 11. SAMPLE DATA FROM PIN TABLES (IF THEY EXIST AND HAVE DATA)
-- PIN_REQUESTS sample
SELECT 
    '11A. PIN_REQUESTS SAMPLE' as section,
    COUNT(*) as total_rows,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
    COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_count,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_count
FROM pin_requests
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pin_requests');

-- PIN_TRANSACTIONS sample
SELECT 
    '11B. PIN_TRANSACTIONS SAMPLE' as section,
    COUNT(*) as total_rows,
    COUNT(CASE WHEN action_type = 'CUSTOMER_CREATION' THEN 1 END) as customer_creation_count,
    COUNT(CASE WHEN action_type = 'ADMIN_ALLOCATION' THEN 1 END) as admin_allocation_count,
    COUNT(CASE WHEN action_type = 'ADMIN_DEDUCTION' THEN 1 END) as admin_deduction_count
FROM pin_transactions
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pin_transactions');

-- 12. CHECK CURRENT USER PERMISSIONS
SELECT 
    '12. CURRENT USER INFO' as section,
    current_user as username,
    session_user as session_user,
    current_database() as database_name;
