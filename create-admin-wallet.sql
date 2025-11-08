-- =====================================================
-- CREATE ADMIN WALLET TABLE AND FUNCTIONS
-- =====================================================
-- Run this SQL in Supabase SQL Editor to enable admin commission tracking

-- Create admin wallet table
CREATE TABLE IF NOT EXISTS admin_wallet (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID UNIQUE REFERENCES profiles(id),
    balance DECIMAL(10,2) DEFAULT 0.00,
    total_received DECIMAL(10,2) DEFAULT 0.00,
    commission_count INTEGER DEFAULT 0,
    last_commission_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create function to get admin commission summary
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
    
    -- Get commission statistics
    SELECT 
        COUNT(*) as commission_count,
        COALESCE(SUM(amount), 0) as total_amount
    INTO v_commission_count, v_total_amount
    FROM affiliate_commissions
    WHERE recipient_type = 'admin' OR recipient_id = v_admin_id;
    
    -- Build result
    v_result := json_build_object(
        'wallet_balance', v_wallet_data.balance,
        'total_received', v_wallet_data.total_received,
        'commission_count', v_commission_count,
        'unclaimed_total', v_total_amount - v_wallet_data.total_received,
        'admin_id', v_admin_id,
        'last_updated', NOW()
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get commission history
CREATE OR REPLACE FUNCTION get_commission_history(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSON AS $$
DECLARE
    v_commissions JSON;
BEGIN
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
    
    RETURN COALESCE(v_commissions, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get commission statistics
CREATE OR REPLACE FUNCTION get_commission_statistics()
RETURNS JSON AS $$
DECLARE
    v_stats JSON;
BEGIN
    SELECT json_build_object(
        'total_commissions', COUNT(*),
        'total_amount', COALESCE(SUM(amount), 0),
        'avg_commission', COALESCE(AVG(amount), 0),
        'this_month', COUNT(*) FILTER (WHERE created_at >= date_trunc('month', NOW())),
        'this_week', COUNT(*) FILTER (WHERE created_at >= date_trunc('week', NOW())),
        'today', COUNT(*) FILTER (WHERE created_at >= date_trunc('day', NOW()))
    ) INTO v_stats
    FROM affiliate_commissions;
    
    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_admin_commission_summary() TO authenticated;
GRANT EXECUTE ON FUNCTION get_commission_history(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_commission_statistics() TO authenticated;

-- Insert admin wallet for existing admin
INSERT INTO admin_wallet (admin_id, balance, total_received, commission_count)
SELECT id, 0.00, 0.00, 0
FROM profiles 
WHERE role = 'admin'
ON CONFLICT (admin_id) DO NOTHING;

SELECT 'Admin commission system created successfully!' as status;
