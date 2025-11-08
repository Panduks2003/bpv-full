-- Debug commission data to see what's actually in the database

-- 1. Check if wallet_balance column exists and has data
SELECT 
    'WALLET_BALANCE_CHECK' as check_type,
    name,
    role,
    wallet_balance,
    promoter_id
FROM profiles 
WHERE role = 'promoter' 
ORDER BY name;

-- 2. Check commission records for your promoter
SELECT 
    'COMMISSION_RECORDS' as check_type,
    ac.recipient_id,
    p.name as recipient_name,
    ac.amount,
    ac.status,
    ac.level,
    ac.created_at
FROM affiliate_commissions ac
LEFT JOIN profiles p ON ac.recipient_id = p.id
WHERE ac.status = 'credited'
ORDER BY ac.created_at DESC;

-- 3. Calculate totals per promoter
SELECT 
    'COMMISSION_TOTALS' as check_type,
    ac.recipient_id,
    p.name as promoter_name,
    COUNT(*) as commission_count,
    SUM(ac.amount) as total_earned,
    p.wallet_balance as current_wallet_balance
FROM affiliate_commissions ac
LEFT JOIN profiles p ON ac.recipient_id = p.id
WHERE ac.status = 'credited'
GROUP BY ac.recipient_id, p.name, p.wallet_balance
ORDER BY total_earned DESC;

-- 4. Check if there are any commission records at all
SELECT 
    'ALL_COMMISSIONS' as check_type,
    status,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM affiliate_commissions
GROUP BY status;

-- 5. Show recent commission details
SELECT 
    'RECENT_COMMISSIONS' as check_type,
    ac.*,
    p.name as recipient_name
FROM affiliate_commissions ac
LEFT JOIN profiles p ON ac.recipient_id = p.id
ORDER BY ac.created_at DESC
LIMIT 10;

SELECT 'DEBUG_COMMISSION_DATA_COMPLETE' as result;
