-- =====================================================
-- FIX UTILITY FUNCTIONS WITH PROPER PERMISSIONS
-- =====================================================
-- Recreates utility functions with SECURITY DEFINER to bypass RLS
-- =====================================================

-- Drop existing functions
DROP FUNCTION IF EXISTS get_promoter_commission_summary(UUID);
DROP FUNCTION IF EXISTS get_admin_commission_summary();

-- =====================================================
-- GET PROMOTER COMMISSION SUMMARY (FIXED)
-- =====================================================
CREATE OR REPLACE FUNCTION get_promoter_commission_summary(p_promoter_id UUID)
RETURNS JSON AS $$
DECLARE
    v_wallet_balance DECIMAL(12,2) := 0;
    v_total_earned DECIMAL(12,2) := 0;
    v_commission_count INTEGER := 0;
    v_last_commission TIMESTAMP WITH TIME ZONE;
    v_recent_commissions JSON;
    v_result JSON;
BEGIN
    -- Get wallet information
    SELECT 
        COALESCE(balance, 0),
        COALESCE(total_earned, 0),
        COALESCE(commission_count, 0),
        last_commission_at
    INTO 
        v_wallet_balance,
        v_total_earned,
        v_commission_count,
        v_last_commission
    FROM promoter_wallet
    WHERE promoter_id = p_promoter_id;
    
    -- Get recent commissions
    SELECT COALESCE(json_agg(
        json_build_object(
            'id', id,
            'customer_id', customer_id,
            'level', level,
            'amount', amount,
            'status', status,
            'created_at', created_at,
            'note', note
        ) ORDER BY created_at DESC
    ), '[]'::json)
    INTO v_recent_commissions
    FROM (
        SELECT *
        FROM affiliate_commissions
        WHERE recipient_id = p_promoter_id
        ORDER BY created_at DESC
        LIMIT 10
    ) recent;
    
    -- Build result
    v_result := json_build_object(
        'promoter_id', p_promoter_id,
        'wallet_balance', v_wallet_balance,
        'total_earned', v_total_earned,
        'commission_count', v_commission_count,
        'last_commission', v_last_commission,
        'recent_commissions', v_recent_commissions
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_promoter_commission_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_promoter_commission_summary(UUID) TO anon;

-- Add comment
COMMENT ON FUNCTION get_promoter_commission_summary IS 'Returns comprehensive commission summary for promoters with RLS bypass';

-- =====================================================
-- GET ADMIN COMMISSION SUMMARY (FIXED)
-- =====================================================
CREATE OR REPLACE FUNCTION get_admin_commission_summary()
RETURNS JSON AS $$
DECLARE
    v_admin_id UUID;
    v_wallet_balance DECIMAL(12,2) := 0;
    v_total_received DECIMAL(12,2) := 0;
    v_unclaimed_total DECIMAL(12,2) := 0;
    v_commission_count INTEGER := 0;
    v_last_commission TIMESTAMP WITH TIME ZONE;
    v_daily_summary JSON;
    v_result JSON;
BEGIN
    -- Get admin ID
    SELECT id INTO v_admin_id FROM profiles WHERE role = 'admin' LIMIT 1;
    
    -- If no admin found, return empty result
    IF v_admin_id IS NULL THEN
        RETURN json_build_object(
            'admin_id', NULL,
            'wallet_balance', 0,
            'total_received', 0,
            'unclaimed_total', 0,
            'commission_count', 0,
            'last_commission', NULL,
            'daily_summary', '[]'::json
        );
    END IF;
    
    -- Get wallet information
    SELECT 
        COALESCE(balance, 0),
        COALESCE(total_commission_received, 0),
        COALESCE(unclaimed_commissions, 0),
        COALESCE(commission_count, 0),
        last_commission_at
    INTO 
        v_wallet_balance,
        v_total_received,
        v_unclaimed_total,
        v_commission_count,
        v_last_commission
    FROM admin_wallet
    WHERE admin_id = v_admin_id;
    
    -- Get daily summary with proper GROUP BY
    SELECT COALESCE(json_agg(
        json_build_object(
            'date', commission_date,
            'total_amount', total_amount,
            'commission_count', count
        ) ORDER BY commission_date DESC
    ), '[]'::json)
    INTO v_daily_summary
    FROM (
        SELECT 
            DATE(created_at) as commission_date,
            SUM(amount) as total_amount,
            COUNT(*) as count
        FROM affiliate_commissions
        WHERE recipient_type = 'admin'
        AND created_at >= NOW() - INTERVAL '30 days'
        GROUP BY DATE(created_at)
        ORDER BY DATE(created_at) DESC
    ) daily;
    
    -- Build result
    v_result := json_build_object(
        'admin_id', v_admin_id,
        'wallet_balance', v_wallet_balance,
        'total_received', v_total_received,
        'unclaimed_total', v_unclaimed_total,
        'commission_count', v_commission_count,
        'last_commission', v_last_commission,
        'daily_summary', v_daily_summary
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_admin_commission_summary() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_commission_summary() TO anon;

-- Add comment
COMMENT ON FUNCTION get_admin_commission_summary IS 'Returns admin commission summary and statistics with RLS bypass';

-- Success message
SELECT 'Step 11 completed: Utility functions fixed with proper permissions!' as status;
