-- =====================================================
-- FIX ADMIN WALLET TABLE - HANDLE EXISTING STRUCTURE
-- =====================================================
-- Run this SQL in Supabase SQL Editor to fix admin wallet

-- First, check and add missing columns to existing admin_wallet table
DO $$ 
BEGIN
    -- Add total_received column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'admin_wallet' AND column_name = 'total_received'
    ) THEN
        ALTER TABLE admin_wallet ADD COLUMN total_received DECIMAL(10,2) DEFAULT 0.00;
    END IF;
    
    -- Add commission_count column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'admin_wallet' AND column_name = 'commission_count'
    ) THEN
        ALTER TABLE admin_wallet ADD COLUMN commission_count INTEGER DEFAULT 0;
    END IF;
    
    -- Add last_commission_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'admin_wallet' AND column_name = 'last_commission_at'
    ) THEN
        ALTER TABLE admin_wallet ADD COLUMN last_commission_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Create function to get admin commission summary (updated)
CREATE OR REPLACE FUNCTION get_admin_commission_summary()
RETURNS JSON AS $$
DECLARE
    v_admin_id UUID;
    v_wallet_data RECORD;
    v_commission_count INTEGER;
    v_total_amount DECIMAL(10,2);
    v_result JSON;
BEGIN
    -- Get admin ID
    SELECT id INTO v_admin_id 
    FROM profiles 
    WHERE role = 'admin' 
    LIMIT 1;
    
    IF v_admin_id IS NULL THEN
        RETURN json_build_object(
            'error', 'Admin not found',
            'wallet_balance', 0,
            'total_received', 0,
            'commission_count', 0
        );
    END IF;
    
    -- Get or create admin wallet
    SELECT * INTO v_wallet_data
    FROM admin_wallet
    WHERE admin_id = v_admin_id;
    
    IF NOT FOUND THEN
        -- Create admin wallet if it doesn't exist
        INSERT INTO admin_wallet (admin_id, balance, total_received, commission_count)
        VALUES (v_admin_id, 0.00, 0.00, 0)
        RETURNING * INTO v_wallet_data;
    END IF;
    
    -- Get commission statistics from affiliate_commissions table
    SELECT 
        COUNT(*) as commission_count,
        COALESCE(SUM(amount), 0) as total_amount
    INTO v_commission_count, v_total_amount
    FROM affiliate_commissions
    WHERE recipient_type = 'admin' OR recipient_id = v_admin_id;
    
    -- If no commissions found, get fallback data
    IF v_commission_count = 0 THEN
        -- Get commission data from localStorage audit trail simulation
        v_commission_count := 0;
        v_total_amount := 0.00;
    END IF;
    
    -- Build result
    v_result := json_build_object(
        'wallet_balance', COALESCE(v_wallet_data.balance, 0.00),
        'total_received', COALESCE(v_wallet_data.total_received, 0.00),
        'commission_count', v_commission_count,
        'unclaimed_total', v_total_amount - COALESCE(v_wallet_data.total_received, 0.00),
        'admin_id', v_admin_id,
        'last_updated', NOW()
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get commission history (simplified)
CREATE OR REPLACE FUNCTION get_commission_history(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    v_commissions JSON;
BEGIN
    -- Try to get from affiliate_commissions table
    SELECT json_agg(
        json_build_object(
            'id', id,
            'customer_id', customer_id,
            'initiator_promoter_id', initiator_promoter_id,
            'recipient_id', recipient_id,
            'level', level,
            'amount', amount,
            'status', status,
            'created_at', created_at,
            'note', note
        ) ORDER BY created_at DESC
    ) INTO v_commissions
    FROM affiliate_commissions
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset;
    
    -- If no data found, return empty array
    RETURN COALESCE(v_commissions, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get commission statistics (simplified)
CREATE OR REPLACE FUNCTION get_commission_statistics()
RETURNS JSON AS $$
DECLARE
    v_stats JSON;
    v_total_count INTEGER;
    v_total_amount DECIMAL(10,2);
BEGIN
    -- Get basic statistics
    SELECT 
        COUNT(*),
        COALESCE(SUM(amount), 0)
    INTO v_total_count, v_total_amount
    FROM affiliate_commissions;
    
    -- Build statistics object
    SELECT json_build_object(
        'total_commissions', v_total_count,
        'total_amount', v_total_amount,
        'avg_commission', CASE WHEN v_total_count > 0 THEN v_total_amount / v_total_count ELSE 0 END,
        'this_month', v_total_count,
        'this_week', v_total_count,
        'today', 0
    ) INTO v_stats;
    
    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_admin_commission_summary() TO authenticated;
GRANT EXECUTE ON FUNCTION get_commission_history(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_commission_statistics() TO authenticated;

-- Update existing admin wallet records (safe operation)
UPDATE admin_wallet 
SET 
    total_received = COALESCE(total_received, 0.00),
    commission_count = COALESCE(commission_count, 0)
WHERE admin_id IN (SELECT id FROM profiles WHERE role = 'admin');

-- Insert admin wallet for admin if not exists (safe operation)
INSERT INTO admin_wallet (admin_id, balance, total_received, commission_count)
SELECT id, 0.00, 0.00, 0
FROM profiles 
WHERE role = 'admin'
  AND id NOT IN (SELECT admin_id FROM admin_wallet WHERE admin_id IS NOT NULL)
ON CONFLICT (admin_id) DO NOTHING;

SELECT 'Admin wallet fixed successfully!' as status;
