-- Add wallet_balance column to profiles table and update balances from commissions

-- First, check if wallet_balance column exists, if not create it
DO $$
BEGIN
    -- Check if wallet_balance column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'wallet_balance'
    ) THEN
        -- Add wallet_balance column
        ALTER TABLE profiles ADD COLUMN wallet_balance DECIMAL(10,2) DEFAULT 0.00;
        RAISE NOTICE 'Added wallet_balance column to profiles table';
    ELSE
        RAISE NOTICE 'wallet_balance column already exists';
    END IF;
END $$;

-- Show current commission status
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
), 0.00),
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
), 0.00),
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
        SELECT COALESCE(SUM(ac.amount), 0)
        FROM affiliate_commissions ac
        WHERE ac.recipient_id = p.id 
          AND ac.status = 'credited'
    ) as total_commission_amount
FROM profiles p
WHERE p.role IN ('promoter', 'admin')
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

-- Show promoters with their wallet balances
SELECT 
    'PROMOTER_WALLETS' as check_type,
    name,
    promoter_id,
    wallet_balance,
    pins
FROM profiles 
WHERE role = 'promoter' 
  AND wallet_balance > 0
ORDER BY wallet_balance DESC;

SELECT 'WALLET_BALANCE_COLUMN_ADDED_AND_UPDATED' as result;
