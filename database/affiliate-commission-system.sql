-- =====================================================
-- AFFILIATE COMMISSION DISTRIBUTION SYSTEM
-- =====================================================
-- Creates tables and triggers for automated ₹800 commission
-- distribution across 4 affiliate levels when customers are created
-- =====================================================

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS affiliate_commissions CASCADE;
DROP TABLE IF EXISTS promoter_wallet CASCADE;
DROP TABLE IF EXISTS admin_wallet CASCADE;

-- =====================================================
-- 1. AFFILIATE COMMISSIONS TABLE
-- =====================================================
-- Tracks all commission distributions with complete audit trail
CREATE TABLE affiliate_commissions (
    id SERIAL PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    initiator_promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('promoter', 'admin')),
    level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 4),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'credited', 'failed')),
    transaction_id VARCHAR(50) UNIQUE,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure no duplicate commissions for same customer-level combination
    UNIQUE(customer_id, level),
    
    -- Index for performance
    INDEX idx_affiliate_commissions_customer (customer_id),
    INDEX idx_affiliate_commissions_initiator (initiator_promoter_id),
    INDEX idx_affiliate_commissions_recipient (recipient_id),
    INDEX idx_affiliate_commissions_level (level),
    INDEX idx_affiliate_commissions_status (status),
    INDEX idx_affiliate_commissions_created (created_at)
);

-- Add RLS policies for affiliate_commissions
ALTER TABLE affiliate_commissions ENABLE ROW LEVEL SECURITY;

-- Promoters can view commissions where they are recipient or initiator
CREATE POLICY "promoters_can_view_own_commissions" ON affiliate_commissions
    FOR SELECT USING (
        auth.uid() = recipient_id OR 
        auth.uid() = initiator_promoter_id OR
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'promoter'
        )
    );

-- Admins can view all commissions
CREATE POLICY "admins_can_view_all_commissions" ON affiliate_commissions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- =====================================================
-- 2. PROMOTER WALLET TABLE
-- =====================================================
-- Manages promoter wallet balances with commission tracking
CREATE TABLE promoter_wallet (
    promoter_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    total_earned DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (total_earned >= 0),
    total_withdrawn DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (total_withdrawn >= 0),
    commission_count INTEGER NOT NULL DEFAULT 0 CHECK (commission_count >= 0),
    last_commission_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Index for performance
    INDEX idx_promoter_wallet_balance (balance),
    INDEX idx_promoter_wallet_updated (updated_at)
);

-- Add RLS policies for promoter_wallet
ALTER TABLE promoter_wallet ENABLE ROW LEVEL SECURITY;

-- Promoters can view their own wallet
CREATE POLICY "promoters_can_view_own_wallet" ON promoter_wallet
    FOR SELECT USING (auth.uid() = promoter_id);

-- Admins can view all wallets
CREATE POLICY "admins_can_view_all_wallets" ON promoter_wallet
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- =====================================================
-- 3. ADMIN WALLET TABLE
-- =====================================================
-- Manages admin wallet for unclaimed commissions
CREATE TABLE admin_wallet (
    admin_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    total_commission_received DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    unclaimed_commissions DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    commission_count INTEGER NOT NULL DEFAULT 0 CHECK (commission_count >= 0),
    last_commission_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Index for performance
    INDEX idx_admin_wallet_balance (balance),
    INDEX idx_admin_wallet_updated (updated_at)
);

-- Add RLS policies for admin_wallet
ALTER TABLE admin_wallet ENABLE ROW LEVEL SECURITY;

-- Only admins can access admin wallet
CREATE POLICY "admins_can_access_admin_wallet" ON admin_wallet
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- =====================================================
-- 4. COMMISSION DISTRIBUTION FUNCTION
-- =====================================================
-- Main function to distribute ₹800 commission across 4 levels
CREATE OR REPLACE FUNCTION distribute_affiliate_commission(
    p_customer_id UUID,
    p_initiator_promoter_id UUID
) RETURNS JSON AS $$
DECLARE
    v_commission_levels DECIMAL[] := ARRAY[500.00, 100.00, 100.00, 100.00];
    v_current_promoter_id UUID := p_initiator_promoter_id;
    v_level INTEGER;
    v_recipient_id UUID;
    v_amount DECIMAL(10,2);
    v_transaction_id VARCHAR(50);
    v_admin_id UUID;
    v_remaining_amount DECIMAL(10,2) := 0.00;
    v_result JSON;
    v_distributed_count INTEGER := 0;
    v_total_distributed DECIMAL(10,2) := 0.00;
BEGIN
    -- Get admin ID for fallback
    SELECT id INTO v_admin_id 
    FROM profiles 
    WHERE role = 'admin' 
    LIMIT 1;
    
    -- Start transaction
    BEGIN
        -- Loop through 4 commission levels
        FOR v_level IN 1..4 LOOP
            v_amount := v_commission_levels[v_level];
            
            -- Find parent promoter for current level
            IF v_level = 1 THEN
                v_recipient_id := v_current_promoter_id;
            ELSE
                SELECT parent_promoter INTO v_recipient_id
                FROM profiles
                WHERE id = v_current_promoter_id
                AND parent_promoter IS NOT NULL;
            END IF;
            
            -- Generate unique transaction ID
            v_transaction_id := 'COMM-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || v_level;
            
            IF v_recipient_id IS NOT NULL THEN
                -- Credit commission to promoter
                INSERT INTO affiliate_commissions (
                    customer_id,
                    initiator_promoter_id,
                    recipient_id,
                    recipient_type,
                    level,
                    amount,
                    status,
                    transaction_id,
                    note
                ) VALUES (
                    p_customer_id,
                    p_initiator_promoter_id,
                    v_recipient_id,
                    'promoter',
                    v_level,
                    v_amount,
                    'credited',
                    v_transaction_id,
                    'Level ' || v_level || ' Commission - ₹' || v_amount
                );
                
                -- Update promoter wallet
                INSERT INTO promoter_wallet (promoter_id, balance, total_earned, commission_count, last_commission_at)
                VALUES (v_recipient_id, v_amount, v_amount, 1, NOW())
                ON CONFLICT (promoter_id) DO UPDATE SET
                    balance = promoter_wallet.balance + v_amount,
                    total_earned = promoter_wallet.total_earned + v_amount,
                    commission_count = promoter_wallet.commission_count + 1,
                    last_commission_at = NOW(),
                    updated_at = NOW();
                
                v_distributed_count := v_distributed_count + 1;
                v_total_distributed := v_total_distributed + v_amount;
                
                -- Move to next level
                v_current_promoter_id := v_recipient_id;
            ELSE
                -- No promoter at this level, add to admin fallback
                v_remaining_amount := v_remaining_amount + v_amount;
            END IF;
        END LOOP;
        
        -- Credit remaining amount to admin if any
        IF v_remaining_amount > 0 AND v_admin_id IS NOT NULL THEN
            v_transaction_id := 'COMM-ADMIN-' || EXTRACT(EPOCH FROM NOW())::BIGINT;
            
            INSERT INTO affiliate_commissions (
                customer_id,
                initiator_promoter_id,
                recipient_id,
                recipient_type,
                level,
                amount,
                status,
                transaction_id,
                note
            ) VALUES (
                p_customer_id,
                p_initiator_promoter_id,
                v_admin_id,
                'admin',
                0, -- Admin level
                v_remaining_amount,
                'credited',
                v_transaction_id,
                'Unclaimed Commission Fallback - ₹' || v_remaining_amount
            );
            
            -- Update admin wallet
            INSERT INTO admin_wallet (admin_id, balance, total_commission_received, unclaimed_commissions, commission_count, last_commission_at)
            VALUES (v_admin_id, v_remaining_amount, v_remaining_amount, v_remaining_amount, 1, NOW())
            ON CONFLICT (admin_id) DO UPDATE SET
                balance = admin_wallet.balance + v_remaining_amount,
                total_commission_received = admin_wallet.total_commission_received + v_remaining_amount,
                unclaimed_commissions = admin_wallet.unclaimed_commissions + v_remaining_amount,
                commission_count = admin_wallet.commission_count + 1,
                last_commission_at = NOW(),
                updated_at = NOW();
                
            v_total_distributed := v_total_distributed + v_remaining_amount;
        END IF;
        
        -- Build result JSON
        v_result := json_build_object(
            'success', true,
            'customer_id', p_customer_id,
            'initiator_promoter_id', p_initiator_promoter_id,
            'total_distributed', v_total_distributed,
            'levels_distributed', v_distributed_count,
            'admin_fallback', v_remaining_amount,
            'timestamp', NOW()
        );
        
        RETURN v_result;
        
    EXCEPTION WHEN OTHERS THEN
        -- Rollback on error
        RAISE EXCEPTION 'Commission distribution failed: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. TRIGGER FOR AUTOMATIC COMMISSION DISTRIBUTION
-- =====================================================
-- Automatically trigger commission distribution when customer is created
CREATE OR REPLACE FUNCTION trigger_commission_distribution()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger for new customer insertions
    IF TG_OP = 'INSERT' THEN
        -- Distribute commission asynchronously to avoid blocking customer creation
        PERFORM pg_notify(
            'commission_distribution',
            json_build_object(
                'customer_id', NEW.id,
                'promoter_id', NEW.promoter_id
            )::text
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on customers table
DROP TRIGGER IF EXISTS trigger_affiliate_commission ON customers;
CREATE TRIGGER trigger_affiliate_commission
    AFTER INSERT ON customers
    FOR EACH ROW
    EXECUTE FUNCTION trigger_commission_distribution();

-- =====================================================
-- 6. UTILITY FUNCTIONS
-- =====================================================

-- Get promoter commission summary
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

-- Get admin commission summary
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

-- =====================================================
-- 7. INITIAL DATA SETUP
-- =====================================================

-- Create admin wallet for existing admin
INSERT INTO admin_wallet (admin_id, balance, total_commission_received, unclaimed_commissions)
SELECT id, 0.00, 0.00, 0.00
FROM profiles 
WHERE role = 'admin'
ON CONFLICT (admin_id) DO NOTHING;

-- Create promoter wallets for existing promoters
INSERT INTO promoter_wallet (promoter_id, balance, total_earned)
SELECT id, 0.00, 0.00
FROM profiles 
WHERE role = 'promoter'
ON CONFLICT (promoter_id) DO NOTHING;

-- =====================================================
-- 8. INDEXES FOR PERFORMANCE
-- =====================================================

-- Additional indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_parent_promoter ON profiles(parent_promoter);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_customers_promoter_id ON customers(promoter_id);

-- =====================================================
-- SETUP COMPLETE
-- =====================================================

COMMENT ON TABLE affiliate_commissions IS 'Tracks all affiliate commission distributions with complete audit trail';
COMMENT ON TABLE promoter_wallet IS 'Manages promoter wallet balances and commission earnings';
COMMENT ON TABLE admin_wallet IS 'Manages admin wallet for unclaimed commission fallbacks';
COMMENT ON FUNCTION distribute_affiliate_commission IS 'Distributes ₹800 commission across 4 affiliate levels';
COMMENT ON FUNCTION get_promoter_commission_summary IS 'Returns comprehensive commission summary for promoters';
COMMENT ON FUNCTION get_admin_commission_summary IS 'Returns admin commission summary and statistics';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Affiliate Commission Distribution System setup completed successfully!';
    RAISE NOTICE 'Tables created: affiliate_commissions, promoter_wallet, admin_wallet';
    RAISE NOTICE 'Functions created: distribute_affiliate_commission, get_promoter_commission_summary, get_admin_commission_summary';
    RAISE NOTICE 'Triggers created: automatic commission distribution on customer creation';
    RAISE NOTICE 'RLS policies applied for security';
END $$;
