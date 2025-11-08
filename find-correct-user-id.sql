-- Find which Pandu Shirabur user ID has the commission records

-- Check all Pandu Shirabur users and their commission counts
SELECT 
    'PANDU_SHIRABUR_USERS' as check_type,
    p.id,
    p.name,
    p.promoter_id,
    p.wallet_balance,
    (
        SELECT COUNT(*)
        FROM affiliate_commissions ac
        WHERE ac.recipient_id = p.id 
          AND ac.status = 'credited'
    ) as commission_count,
    (
        SELECT SUM(ac.amount)
        FROM affiliate_commissions ac
        WHERE ac.recipient_id = p.id 
          AND ac.status = 'credited'
    ) as total_commissions
FROM profiles p
WHERE p.name = 'Pandu Shirabur'
  AND p.role = 'promoter'
ORDER BY commission_count DESC;

-- Show recent commissions for the user with most commissions
SELECT 
    'RECENT_COMMISSIONS_FOR_ACTIVE_USER' as check_type,
    ac.recipient_id,
    p.promoter_id,
    ac.amount,
    ac.level,
    ac.created_at,
    ac.customer_id
FROM affiliate_commissions ac
LEFT JOIN profiles p ON ac.recipient_id = p.id
WHERE p.name = 'Pandu Shirabur'
  AND ac.status = 'credited'
ORDER BY ac.created_at DESC
LIMIT 10;

-- Check if the logged-in user (BPVP15) has any commissions at all
SELECT 
    'BPVP15_COMMISSION_CHECK' as check_type,
    p.id,
    p.name,
    p.promoter_id,
    COUNT(ac.id) as commission_count,
    SUM(ac.amount) as total_amount
FROM profiles p
LEFT JOIN affiliate_commissions ac ON ac.recipient_id = p.id AND ac.status = 'credited'
WHERE p.promoter_id = 'BPVP15'
GROUP BY p.id, p.name, p.promoter_id;

SELECT 'USER_ID_MISMATCH_INVESTIGATION_COMPLETE' as result;
