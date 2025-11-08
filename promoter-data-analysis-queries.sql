-- =====================================================
-- COMPREHENSIVE PROMOTER DATA ANALYSIS QUERIES
-- =====================================================
-- Use these queries to examine all promoter-related data in Supabase
-- and verify alignment between database and application logic
-- =====================================================

-- =====================================================
-- 1. CORE PROMOTER DATA OVERVIEW
-- =====================================================

-- Check all promoter records in profiles table
SELECT 
    'PROMOTER_PROFILES' as data_type,
    id,
    promoter_id,
    name,
    email,
    phone,
    role,
    role_level,
    status,
    address,
    parent_promoter_id,
    created_at,
    updated_at
FROM profiles 
WHERE role = 'promoter'
ORDER BY created_at DESC;

-- Check promoters table (if exists)
SELECT 
    'PROMOTERS_TABLE' as data_type,
    p.id,
    p.promoter_id,
    p.parent_promoter_id,
    p.status,
    p.commission_rate,
    p.can_create_promoters,
    p.can_create_customers,
    p.created_at,
    p.updated_at,
    -- Join with profiles for additional info
    pr.name,
    pr.email,
    pr.phone,
    pr.role_level
FROM promoters p
LEFT JOIN profiles pr ON p.id = pr.id
ORDER BY p.created_at DESC;

-- =====================================================
-- 2. PROMOTER HIERARCHY ANALYSIS
-- =====================================================

-- Get complete promoter hierarchy with levels
WITH RECURSIVE promoter_hierarchy AS (
    -- Root promoters (no parent)
    SELECT 
        id,
        promoter_id,
        name,
        email,
        phone,
        role_level,
        status,
        parent_promoter_id,
        0 as hierarchy_level,
        promoter_id as root_promoter,
        ARRAY[promoter_id]::VARCHAR[] as path,
        promoter_id::VARCHAR as hierarchy_path
    FROM profiles 
    WHERE role = 'promoter' 
    AND parent_promoter_id IS NULL
    
    UNION ALL
    
    -- Child promoters
    SELECT 
        p.id,
        p.promoter_id,
        p.name,
        p.email,
        p.phone,
        p.role_level,
        p.status,
        p.parent_promoter_id,
        ph.hierarchy_level + 1,
        ph.root_promoter,
        ph.path || p.promoter_id,
        ph.hierarchy_path || ' -> ' || p.promoter_id
    FROM profiles p
    INNER JOIN promoter_hierarchy ph ON p.parent_promoter_id = ph.id
    WHERE p.role = 'promoter'
    AND NOT (p.promoter_id = ANY(ph.path)) -- Prevent cycles
)
SELECT 
    'PROMOTER_HIERARCHY' as data_type,
    hierarchy_level,
    promoter_id,
    name,
    email,
    phone,
    role_level,
    status,
    root_promoter,
    hierarchy_path,
    parent_promoter_id
FROM promoter_hierarchy
ORDER BY hierarchy_level, promoter_id;

-- Count promoters by hierarchy level
WITH RECURSIVE promoter_hierarchy AS (
    SELECT 
        id, promoter_id, parent_promoter_id, 0 as level
    FROM profiles 
    WHERE role = 'promoter' AND parent_promoter_id IS NULL
    
    UNION ALL
    
    SELECT 
        p.id, p.promoter_id, p.parent_promoter_id, ph.level + 1
    FROM profiles p
    INNER JOIN promoter_hierarchy ph ON p.parent_promoter_id = ph.id
    WHERE p.role = 'promoter'
)
SELECT 
    'HIERARCHY_SUMMARY' as data_type,
    level as hierarchy_level,
    COUNT(*) as promoter_count
FROM promoter_hierarchy
GROUP BY level
ORDER BY level;

-- =====================================================
-- 3. PROMOTER AUTHENTICATION DATA
-- =====================================================

-- Check auth.users records for promoters
SELECT 
    'PROMOTER_AUTH_USERS' as data_type,
    au.id,
    au.email as auth_email,
    au.email_confirmed_at,
    au.created_at as auth_created_at,
    au.updated_at as auth_updated_at,
    au.last_sign_in_at,
    au.role as auth_role,
    -- Profile info
    p.promoter_id,
    p.name,
    p.email as display_email,
    p.phone,
    p.role_level,
    p.status
FROM auth.users au
INNER JOIN profiles p ON au.id = p.id
WHERE p.role = 'promoter'
ORDER BY au.created_at DESC;

-- Check for promoters without auth records
SELECT 
    'PROMOTERS_WITHOUT_AUTH' as data_type,
    p.id,
    p.promoter_id,
    p.name,
    p.email,
    p.phone,
    p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter' 
AND au.id IS NULL
ORDER BY p.created_at DESC;

-- =====================================================
-- 4. PROMOTER ID SEQUENCE AND GENERATION
-- =====================================================

-- Check promoter ID sequence status
SELECT 
    'PROMOTER_ID_SEQUENCE' as data_type,
    id,
    last_promoter_number,
    updated_at,
    'BPVP' || LPAD(last_promoter_number::TEXT, 2, '0') as last_generated_id,
    'BPVP' || LPAD((last_promoter_number + 1)::TEXT, 2, '0') as next_id
FROM promoter_id_sequence;

-- Check for promoter ID gaps or duplicates
SELECT 
    'PROMOTER_ID_ANALYSIS' as data_type,
    promoter_id,
    COUNT(*) as occurrence_count,
    CASE 
        WHEN COUNT(*) > 1 THEN 'DUPLICATE'
        ELSE 'UNIQUE'
    END as status
FROM profiles 
WHERE promoter_id IS NOT NULL
GROUP BY promoter_id
HAVING COUNT(*) > 1
ORDER BY promoter_id;

-- Check promoter ID format consistency
SELECT 
    'PROMOTER_ID_FORMAT_CHECK' as data_type,
    promoter_id,
    name,
    CASE 
        WHEN promoter_id ~ '^BPVP[0-9]{2}$' THEN 'CORRECT_FORMAT'
        WHEN promoter_id ~ '^PROM[0-9]{4}$' THEN 'INVALID_PROM_FORMAT'
        ELSE 'INVALID_FORMAT'
    END as format_status,
    created_at
FROM profiles 
WHERE role = 'promoter' 
AND promoter_id IS NOT NULL
ORDER BY created_at DESC;

-- =====================================================
-- 5. PROMOTER COMMISSION AND WALLET DATA
-- =====================================================

-- Check promoter wallet balances
SELECT 
    'PROMOTER_WALLETS' as data_type,
    pw.promoter_id as wallet_promoter_id,
    pw.balance,
    pw.total_earned,
    pw.total_withdrawn,
    pw.commission_count,
    pw.last_commission_at,
    pw.created_at as wallet_created_at,
    -- Profile info
    p.promoter_id,
    p.name,
    p.email,
    p.phone,
    p.status
FROM promoter_wallet pw
LEFT JOIN profiles p ON pw.promoter_id = p.id
ORDER BY pw.total_earned DESC;

-- Check affiliate commissions for promoters
SELECT 
    'AFFILIATE_COMMISSIONS' as data_type,
    ac.id as commission_id,
    ac.customer_id,
    ac.initiator_promoter_id,
    ac.recipient_id,
    ac.recipient_type,
    ac.level,
    ac.amount,
    ac.status,
    ac.transaction_id,
    ac.created_at,
    -- Initiator promoter info
    ip.promoter_id as initiator_promoter_code,
    ip.name as initiator_name,
    -- Recipient promoter info (if promoter)
    rp.promoter_id as recipient_promoter_code,
    rp.name as recipient_name
FROM affiliate_commissions ac
LEFT JOIN profiles ip ON ac.initiator_promoter_id = ip.id
LEFT JOIN profiles rp ON ac.recipient_id = rp.id AND ac.recipient_type = 'promoter'
ORDER BY ac.created_at DESC;

-- Commission summary by promoter
SELECT 
    'COMMISSION_SUMMARY' as data_type,
    p.promoter_id,
    p.name,
    p.email,
    COUNT(ac.id) as total_commissions,
    SUM(ac.amount) as total_commission_amount,
    COUNT(CASE WHEN ac.status = 'credited' THEN 1 END) as credited_commissions,
    SUM(CASE WHEN ac.status = 'credited' THEN ac.amount ELSE 0 END) as credited_amount,
    COUNT(CASE WHEN ac.status = 'pending' THEN 1 END) as pending_commissions,
    SUM(CASE WHEN ac.status = 'pending' THEN ac.amount ELSE 0 END) as pending_amount
FROM profiles p
LEFT JOIN affiliate_commissions ac ON p.id = ac.recipient_id
WHERE p.role = 'promoter'
GROUP BY p.id, p.promoter_id, p.name, p.email
ORDER BY total_commission_amount DESC NULLS LAST;

-- =====================================================
-- 6. PROMOTER-CUSTOMER RELATIONSHIPS
-- =====================================================

-- Check customers created by each promoter
SELECT 
    'PROMOTER_CUSTOMERS' as data_type,
    p.promoter_id,
    p.name as promoter_name,
    p.email as promoter_email,
    COUNT(c.id) as customer_count,
    COUNT(CASE WHEN c.status = 'Active' THEN 1 END) as active_customers,
    COUNT(CASE WHEN c.status = 'Inactive' THEN 1 END) as inactive_customers,
    MIN(c.created_at) as first_customer_created,
    MAX(c.created_at) as last_customer_created
FROM profiles p
LEFT JOIN profiles c ON p.id = c.parent_promoter_id AND c.role = 'customer'
WHERE p.role = 'promoter'
GROUP BY p.id, p.promoter_id, p.name, p.email
ORDER BY customer_count DESC;

-- Check customer profiles linked to promoters
SELECT 
    'CUSTOMER_PROMOTER_LINKS' as data_type,
    cp.id as customer_profile_id,
    cp.name as customer_name,
    cp.email as customer_email,
    cp.phone as customer_phone,
    cp.customer_id,
    cp.status as customer_status,
    cp.created_at as customer_created_at,
    -- Promoter info
    pp.promoter_id,
    pp.name as promoter_name,
    pp.email as promoter_email
FROM profiles cp
LEFT JOIN profiles pp ON cp.parent_promoter_id = pp.id
WHERE cp.role = 'customer'
ORDER BY cp.created_at DESC;

-- =====================================================
-- 7. PROMOTER PERMISSIONS AND CAPABILITIES
-- =====================================================

-- Check promoter capabilities (from promoters table if exists)
SELECT 
    'PROMOTER_CAPABILITIES' as data_type,
    p.promoter_id,
    pr.name,
    pr.role_level,
    pr.status,
    p.can_create_promoters,
    p.can_create_customers,
    p.commission_rate,
    p.created_at
FROM promoters p
INNER JOIN profiles pr ON p.id = pr.id
ORDER BY p.created_at DESC;

-- =====================================================
-- 8. PROMOTER ACTIVITY AND ENGAGEMENT
-- =====================================================

-- Check withdrawal requests by promoters
SELECT 
    'PROMOTER_WITHDRAWALS' as data_type,
    wr.id as withdrawal_id,
    wr.amount,
    wr.status,
    wr.request_id,
    wr.created_at as withdrawal_requested_at,
    wr.updated_at as withdrawal_updated_at,
    -- Promoter info
    p.promoter_id,
    p.name,
    p.email,
    p.phone
FROM withdrawal_requests wr
INNER JOIN profiles p ON wr.promoter_id = p.id
WHERE p.role = 'promoter'
ORDER BY wr.created_at DESC;

-- Check pin requests involving promoters
SELECT 
    'PROMOTER_PIN_REQUESTS' as data_type,
    pr.id as pin_request_id,
    pr.customer_id,
    pr.promoter_id as requesting_promoter_id,
    pr.amount,
    pr.status,
    pr.request_id,
    pr.created_at as pin_requested_at,
    pr.approved_at,
    pr.approved_by,
    -- Customer info
    cp.name as customer_name,
    cp.customer_id as customer_code,
    -- Promoter info
    pp.promoter_id as promoter_code,
    pp.name as promoter_name
FROM pin_requests pr
LEFT JOIN profiles cp ON pr.customer_id = cp.id
LEFT JOIN profiles pp ON pr.promoter_id = pp.id
ORDER BY pr.created_at DESC;

-- =====================================================
-- 9. DATA CONSISTENCY CHECKS
-- =====================================================

-- Check for orphaned promoter records
SELECT 
    'ORPHANED_PROMOTER_RECORDS' as data_type,
    'profiles_without_auth' as issue_type,
    p.id,
    p.promoter_id,
    p.name,
    p.email,
    p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'promoter' 
AND au.id IS NULL

UNION ALL

SELECT 
    'ORPHANED_PROMOTER_RECORDS' as data_type,
    'promoters_without_profiles' as issue_type,
    pr.id,
    pr.promoter_id,
    NULL as name,
    NULL as email,
    pr.created_at
FROM promoters pr
LEFT JOIN profiles p ON pr.id = p.id
WHERE p.id IS NULL

UNION ALL

SELECT 
    'ORPHANED_PROMOTER_RECORDS' as data_type,
    'invalid_parent_references' as issue_type,
    p.id,
    p.promoter_id,
    p.name,
    p.email,
    p.created_at
FROM profiles p
LEFT JOIN profiles parent ON p.parent_promoter_id = parent.id
WHERE p.role = 'promoter' 
AND p.parent_promoter_id IS NOT NULL 
AND parent.id IS NULL

ORDER BY created_at DESC;

-- Check for data inconsistencies
SELECT 
    'DATA_INCONSISTENCIES' as data_type,
    'missing_promoter_id' as issue_type,
    COUNT(*) as count
FROM profiles 
WHERE role = 'promoter' AND promoter_id IS NULL

UNION ALL

SELECT 
    'DATA_INCONSISTENCIES' as data_type,
    'duplicate_promoter_ids' as issue_type,
    COUNT(*) as count
FROM (
    SELECT promoter_id
    FROM profiles 
    WHERE promoter_id IS NOT NULL
    GROUP BY promoter_id
    HAVING COUNT(*) > 1
) duplicates

UNION ALL

SELECT 
    'DATA_INCONSISTENCIES' as data_type,
    'promoters_without_wallets' as issue_type,
    COUNT(*) as count
FROM profiles p
LEFT JOIN promoter_wallet pw ON p.id = pw.promoter_id
WHERE p.role = 'promoter' AND pw.promoter_id IS NULL;

-- =====================================================
-- 10. SUMMARY STATISTICS
-- =====================================================

-- Overall promoter statistics
SELECT 
    'PROMOTER_STATISTICS' as data_type,
    'total_promoters' as metric,
    COUNT(*) as value
FROM profiles WHERE role = 'promoter'

UNION ALL

SELECT 
    'PROMOTER_STATISTICS' as data_type,
    'active_promoters' as metric,
    COUNT(*) as value
FROM profiles WHERE role = 'promoter' AND status = 'Active'

UNION ALL

SELECT 
    'PROMOTER_STATISTICS' as data_type,
    'promoters_with_customers' as metric,
    COUNT(DISTINCT p.id) as value
FROM profiles p
INNER JOIN profiles c ON p.id = c.parent_promoter_id
WHERE p.role = 'promoter' AND c.role = 'customer'

UNION ALL

SELECT 
    'PROMOTER_STATISTICS' as data_type,
    'promoters_with_commissions' as metric,
    COUNT(DISTINCT ac.recipient_id) as value
FROM affiliate_commissions ac
INNER JOIN profiles p ON ac.recipient_id = p.id
WHERE p.role = 'promoter'

UNION ALL

SELECT 
    'PROMOTER_STATISTICS' as data_type,
    'total_commission_amount' as metric,
    COALESCE(SUM(ac.amount), 0) as value
FROM affiliate_commissions ac
INNER JOIN profiles p ON ac.recipient_id = p.id
WHERE p.role = 'promoter';

-- =====================================================
-- USAGE INSTRUCTIONS
-- =====================================================

/*
HOW TO USE THESE QUERIES:

1. Run each section individually to examine specific aspects of promoter data
2. Look for data_type column to identify which query results you're viewing
3. Pay attention to:
   - Orphaned records (data without proper relationships)
   - Inconsistencies (missing IDs, duplicates, format issues)
   - Hierarchy problems (circular references, invalid parents)
   - Commission and wallet discrepancies

4. Key areas to verify alignment with application logic:
   - Promoter ID generation and format (BPVP01, BPVP02, etc.)
   - Hierarchy relationships and permissions
   - Commission calculations and distributions
   - Authentication and authorization data
   - Customer-promoter relationships

5. If you find issues, use the specific queries to drill down into problems
6. Cross-reference with your application code to ensure database structure matches expectations
*/
