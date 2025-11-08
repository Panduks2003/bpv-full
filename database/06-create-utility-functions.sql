-- =====================================================
-- STEP 6: CREATE UTILITY FUNCTIONS
-- =====================================================
-- Creates helper functions for commission queries
-- Run this after step 5
-- =====================================================

-- =====================================================
-- GET PROMOTER COMMISSION SUMMARY
-- =====================================================
CREATE OR REPLACE FUNCTION get_promoter_commission_summary(p_promoter_id UUID)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'promoter_id', p_promoter_id,
        'wallet_balance', COALESCE(pw.balance, 0),
        'total_earned', COALESCE(pw.total_earned, 0),
        'commission_count', COALESCE(pw.commission_count, 0),
        'last_commission', pw.last_commission_at,
        'recent_commissions', (
            SELECT json_agg(
                json_build_object(
                    'id', ac.id,
                    'customer_id', ac.customer_id,
                    'level', ac.level,
                    'amount', ac.amount,
                    'status', ac.status,
                    'created_at', ac.created_at,
                    'note', ac.note
                )
            )
            FROM affiliate_commissions ac
            WHERE ac.recipient_id = p_promoter_id
            ORDER BY ac.created_at DESC
            LIMIT 10
        )
    ) INTO v_result
    FROM promoter_wallet pw
    WHERE pw.promoter_id = p_promoter_id;
    
    RETURN COALESCE(v_result, json_build_object('promoter_id', p_promoter_id, 'wallet_balance', 0));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment
COMMENT ON FUNCTION get_promoter_commission_summary IS 'Returns comprehensive commission summary for promoters';

-- =====================================================
-- GET ADMIN COMMISSION SUMMARY
-- =====================================================
CREATE OR REPLACE FUNCTION get_admin_commission_summary()
RETURNS JSON AS $$
DECLARE
    v_result JSON;
    v_admin_id UUID;
BEGIN
    -- Get admin ID
    SELECT id INTO v_admin_id FROM profiles WHERE role = 'admin' LIMIT 1;
    
    SELECT json_build_object(
        'admin_id', v_admin_id,
        'wallet_balance', COALESCE(aw.balance, 0),
        'total_received', COALESCE(aw.total_commission_received, 0),
        'unclaimed_total', COALESCE(aw.unclaimed_commissions, 0),
        'commission_count', COALESCE(aw.commission_count, 0),
        'last_commission', aw.last_commission_at,
        'daily_summary', (
            SELECT json_agg(
                json_build_object(
                    'date', DATE(ac.created_at),
                    'total_amount', SUM(ac.amount),
                    'commission_count', COUNT(*)
                )
            )
            FROM affiliate_commissions ac
            WHERE ac.recipient_type = 'admin'
            AND ac.created_at >= NOW() - INTERVAL '30 days'
            GROUP BY DATE(ac.created_at)
            ORDER BY DATE(ac.created_at) DESC
        )
    ) INTO v_result
    FROM admin_wallet aw
    WHERE aw.admin_id = v_admin_id;
    
    RETURN COALESCE(v_result, json_build_object('admin_id', v_admin_id, 'wallet_balance', 0));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment
COMMENT ON FUNCTION get_admin_commission_summary IS 'Returns admin commission summary and statistics';

-- Success message
SELECT 'Step 6 completed: Utility functions created successfully!' as status;
