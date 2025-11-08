-- Update promoter wallet balances based on credited commissions
-- This will calculate and update wallet balances from commission records

-- First, let's see current commission status
SELECT 
    'BEFORE_UPDATE' as phase,
    status,
    COUNT(*) as commission_count,
    SUM(amount) as total_amount
FROM affiliate_commissions 
GROUP BY status
ORDER BY status;

-- Update wallet balances for all promoters based on their credited commissions
UPDATE profiles 
SET wallet_balance = COALESCE((
    SELECT SUM(ac.amount)
    FROM affiliate_commissions ac
    WHERE ac.recipient_id = profiles.id 
      AND ac.recipient_type = 'promoter'
      AND ac.status = 'credited'
), 0),
updated_at = NOW()
WHERE role = 'promoter';

-- Update admin wallet balance
UPDATE profiles 
SET wallet_balance = COALESCE((
    SELECT SUM(ac.amount)
    FROM affiliate_commissions ac
    WHERE ac.recipient_id = profiles.id 
      AND ac.recipient_type = 'admin'
      AND ac.status = 'credited'
), 0),
updated_at = NOW()
WHERE role = 'admin';

-- Verify wallet balances have been updated
SELECT 
    'WALLET_BALANCES_UPDATED' as check_type,
    p.name,
    p.role,
    p.wallet_balance,
    (
        SELECT COUNT(*)
        FROM affiliate_commissions ac
        WHERE ac.recipient_id = p.id 
          AND ac.status = 'credited'
    ) as credited_commissions,
    (
        SELECT SUM(ac.amount)
        FROM affiliate_commissions ac
        WHERE ac.recipient_id = p.id 
          AND ac.status = 'credited'
    ) as total_commission_amount
FROM profiles p
WHERE p.role IN ('promoter', 'admin')
  AND EXISTS (
      SELECT 1 
      FROM affiliate_commissions ac 
      WHERE ac.recipient_id = p.id
  )
ORDER BY p.role, p.name;

-- Show commission summary after update
SELECT 
    'AFTER_UPDATE' as phase,
    status,
    COUNT(*) as commission_count,
    SUM(amount) as total_amount
FROM affiliate_commissions 
GROUP BY status
ORDER BY status;

SELECT 'WALLET_BALANCES_UPDATED_FROM_COMMISSIONS' as result;
