-- =====================================================
-- TARGETED WITHDRAWAL SYSTEM FIX
-- =====================================================
-- Based on actual database schema analysis
-- Only adds the missing columns that the frontend expects
-- =====================================================

-- =====================================================
-- 1. ADD MISSING COLUMNS TO WITHDRAWAL_REQUESTS
-- =====================================================

-- The withdrawal_requests table is missing bank_details column
-- (it has individual bank columns but frontend expects bank_details JSONB)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'withdrawal_requests' 
        AND column_name = 'bank_details'
    ) THEN
        ALTER TABLE withdrawal_requests ADD COLUMN bank_details JSONB;
        RAISE NOTICE 'Added bank_details column to withdrawal_requests';
        
        -- Migrate existing bank data to bank_details JSONB
        UPDATE withdrawal_requests 
        SET bank_details = jsonb_build_object(
            'bankName', bank_name,
            'accountNumber', bank_account_number,
            'routingNumber', bank_routing_number
        )
        WHERE bank_name IS NOT NULL OR bank_account_number IS NOT NULL;
        
        RAISE NOTICE 'Migrated existing bank data to bank_details JSONB';
    END IF;
END $$;

-- =====================================================
-- 2. ADD MISSING COLUMNS TO PROFILES
-- =====================================================

-- Add bank_accounts column to profiles table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'bank_accounts'
    ) THEN
        ALTER TABLE profiles ADD COLUMN bank_accounts JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added bank_accounts column to profiles';
    END IF;
END $$;

-- =====================================================
-- 3. FIX COMMISSIONS TABLE FOR FRONTEND COMPATIBILITY
-- =====================================================

-- The commissions table has commission_amount but frontend expects amount
-- Add an amount column that maps to commission_amount
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'commissions' 
        AND column_name = 'amount'
    ) THEN
        -- Add amount column
        ALTER TABLE commissions ADD COLUMN amount DECIMAL(10,2);
        
        -- Copy data from commission_amount to amount
        UPDATE commissions SET amount = commission_amount;
        
        RAISE NOTICE 'Added amount column to commissions table and copied data from commission_amount';
    END IF;
END $$;

-- =====================================================
-- 4. CREATE VIEW FOR EASIER FRONTEND ACCESS
-- =====================================================

-- Create a view that makes withdrawal_requests more frontend-friendly
CREATE OR REPLACE VIEW withdrawal_requests_view AS
SELECT 
    id,
    promoter_id,
    amount,
    status,
    reason,
    -- Use bank_details if available, otherwise build from individual columns
    COALESCE(
        bank_details,
        jsonb_build_object(
            'bankName', bank_name,
            'accountNumber', bank_account_number,
            'routingNumber', bank_routing_number
        )
    ) as bank_details,
    admin_notes,
    processed_at,
    transaction_id,
    rejection_reason,
    created_at,
    updated_at,
    completed_at,
    requested_date
FROM withdrawal_requests;

-- =====================================================
-- 5. CREATE FUNCTION FOR PROMOTER BALANCE CALCULATION
-- =====================================================

-- Function to calculate promoter balance from existing data
CREATE OR REPLACE FUNCTION get_promoter_balance_from_existing_data(p_promoter_id UUID)
RETURNS TABLE (
    total_earnings DECIMAL(10,2),
    available_balance DECIMAL(10,2),
    pending_withdrawals DECIMAL(10,2)
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH earnings AS (
        -- Get earnings from payments table
        SELECT COALESCE(SUM(amount), 0) as payment_earnings
        FROM payments 
        WHERE promoter_id = p_promoter_id 
        AND payment_type = 'credit' 
        AND status = 'completed'
    ),
    commissions AS (
        -- Get earnings from commissions table (using amount column we just added)
        SELECT COALESCE(SUM(amount), 0) as commission_earnings
        FROM commissions 
        WHERE promoter_id = p_promoter_id 
        AND status = 'completed'
    ),
    affiliate_commissions AS (
        -- Get earnings from affiliate_commissions table
        SELECT COALESCE(SUM(amount), 0) as affiliate_earnings
        FROM affiliate_commissions 
        WHERE recipient_id = p_promoter_id 
        AND status = 'credited'
    ),
    wallet_data AS (
        -- Get data from promoter_wallet if available
        SELECT COALESCE(balance, 0) as wallet_balance,
               COALESCE(total_earned, 0) as wallet_earned
        FROM promoter_wallet 
        WHERE promoter_id = p_promoter_id
    ),
    withdrawals AS (
        SELECT 
            COALESCE(SUM(CASE WHEN status IN ('approved', 'completed') THEN amount ELSE 0 END), 0) as withdrawn,
            COALESCE(SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END), 0) as pending
        FROM withdrawal_requests 
        WHERE promoter_id = p_promoter_id
    )
    SELECT 
        -- Use wallet data if available, otherwise calculate from transactions
        CASE 
            WHEN w.wallet_earned > 0 THEN w.wallet_earned
            ELSE (e.payment_earnings + c.commission_earnings + ac.affiliate_earnings)
        END as total_earnings,
        -- Available balance
        CASE 
            WHEN w.wallet_balance > 0 THEN w.wallet_balance
            ELSE (e.payment_earnings + c.commission_earnings + ac.affiliate_earnings - wd.withdrawn)
        END as available_balance,
        -- Pending withdrawals
        wd.pending as pending_withdrawals
    FROM earnings e, commissions c, affiliate_commissions ac, wallet_data w, withdrawals wd;
END;
$$;

-- =====================================================
-- 6. VERIFICATION
-- =====================================================

-- Verify the fix worked
SELECT 
    'Column Verification' as check_type,
    table_name || '.' || column_name as column_name,
    '✅ Now Exists' as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND (
    (table_name = 'withdrawal_requests' AND column_name = 'bank_details') OR
    (table_name = 'profiles' AND column_name = 'bank_accounts') OR
    (table_name = 'commissions' AND column_name = 'amount')
)
ORDER BY table_name, column_name;

-- Test the balance function for existing promoters
SELECT 
    'Balance Test' as check_type,
    p.promoter_id,
    b.total_earnings,
    b.available_balance,
    b.pending_withdrawals
FROM profiles p
CROSS JOIN LATERAL get_promoter_balance_from_existing_data(p.id) b
WHERE p.role = 'promoter' 
AND p.promoter_id IS NOT NULL
LIMIT 3;

-- Success message
SELECT '✅ Targeted withdrawal fix completed! Frontend should now work with existing data.' as status;
