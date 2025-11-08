-- Simple check to find which Pandu Shirabur has commissions

-- 1. Show all Pandu Shirabur users
SELECT 
    p.id,
    p.name,
    p.promoter_id,
    p.wallet_balance
FROM profiles p
WHERE p.name = 'Pandu Shirabur'
  AND p.role = 'promoter'
ORDER BY p.promoter_id;

-- 2. Count commissions for each Pandu Shirabur
SELECT 
    p.promoter_id,
    p.id,
    COUNT(ac.id) as commission_count,
    COALESCE(SUM(ac.amount), 0) as total_amount
FROM profiles p
LEFT JOIN affiliate_commissions ac ON ac.recipient_id = p.id AND ac.status = 'credited'
WHERE p.name = 'Pandu Shirabur'
  AND p.role = 'promoter'
GROUP BY p.id, p.promoter_id
ORDER BY commission_count DESC;

-- 3. Check specifically BPVP15
SELECT 
    'BPVP15_CHECK' as type,
    p.id,
    p.promoter_id,
    p.wallet_balance,
    COUNT(ac.id) as commission_count
FROM profiles p
LEFT JOIN affiliate_commissions ac ON ac.recipient_id = p.id AND ac.status = 'credited'
WHERE p.promoter_id = 'BPVP15'
GROUP BY p.id, p.promoter_id, p.wallet_balance;
