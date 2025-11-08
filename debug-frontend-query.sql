-- Debug the exact query the frontend is using

-- Test the exact query from the frontend
SELECT 
    'FRONTEND_QUERY_TEST' as test_type,
    *
FROM affiliate_commissions 
WHERE recipient_id = 'fc5deb02-1b33-4779-990d-ac89f3863e19' 
  AND status = 'credited';

-- Check all statuses for this user
SELECT 
    'ALL_STATUSES_FOR_BPVP15' as test_type,
    status,
    COUNT(*) as count,
    SUM(amount) as total
FROM affiliate_commissions 
WHERE recipient_id = 'fc5deb02-1b33-4779-990d-ac89f3863e19'
GROUP BY status;

-- Check if there are any records at all for this user
SELECT 
    'ALL_RECORDS_FOR_BPVP15' as test_type,
    *
FROM affiliate_commissions 
WHERE recipient_id = 'fc5deb02-1b33-4779-990d-ac89f3863e19'
ORDER BY created_at DESC;

-- Check the exact status values (might have extra spaces or different case)
SELECT 
    'STATUS_VALUES_CHECK' as test_type,
    DISTINCT status,
    LENGTH(status) as status_length,
    COUNT(*) as count
FROM affiliate_commissions 
WHERE recipient_id = 'fc5deb02-1b33-4779-990d-ac89f3863e19'
GROUP BY status;
