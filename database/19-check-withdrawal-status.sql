-- =====================================================
-- CHECK WITHDRAWAL REQUEST STATUS
-- =====================================================
-- This script checks the current status of withdrawal requests
-- to verify if the approval process is working correctly
-- =====================================================

-- Check all withdrawal requests with their current status
SELECT 
    'Current Withdrawal Requests' as check_type,
    id,
    promoter_id,
    amount,
    status,
    reason,
    processed_at,
    processed_by,
    admin_notes,
    transaction_id,
    created_at,
    updated_at
FROM withdrawal_requests
ORDER BY created_at DESC
LIMIT 10;

-- Check if there are any approved requests
SELECT 
    'Status Summary' as check_type,
    status,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM withdrawal_requests
GROUP BY status
ORDER BY status;

-- Check for recent status changes
SELECT 
    'Recent Updates' as check_type,
    id,
    status,
    processed_at,
    updated_at,
    EXTRACT(EPOCH FROM (updated_at - created_at))/60 as minutes_to_process
FROM withdrawal_requests
WHERE updated_at > created_at
ORDER BY updated_at DESC
LIMIT 5;

-- Check if processed_by field is being set correctly
SELECT 
    'Processing Info' as check_type,
    wr.id,
    wr.status,
    wr.processed_by,
    p.name as processed_by_name,
    p.role as processor_role
FROM withdrawal_requests wr
LEFT JOIN profiles p ON wr.processed_by = p.id
WHERE wr.processed_by IS NOT NULL
ORDER BY wr.updated_at DESC
LIMIT 5;
