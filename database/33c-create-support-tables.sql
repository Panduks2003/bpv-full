-- =====================================================
-- PART 3: CREATE SUPPORT TABLES
-- =====================================================
-- This script creates the pin usage log and customer payments tables

BEGIN;

-- =====================================================
-- 4. CREATE PIN USAGE LOG TABLE
-- =====================================================

-- Create table to track pin usage
CREATE TABLE IF NOT EXISTS pin_usage_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    pins_used INTEGER NOT NULL,
    action_type VARCHAR(50) NOT NULL, -- 'customer_creation', 'admin_allocation', etc.
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for pin usage log
CREATE INDEX IF NOT EXISTS idx_pin_usage_log_promoter ON pin_usage_log(promoter_id);
CREATE INDEX IF NOT EXISTS idx_pin_usage_log_customer ON pin_usage_log(customer_id);
CREATE INDEX IF NOT EXISTS idx_pin_usage_log_created_at ON pin_usage_log(created_at);

-- =====================================================
-- 5. CREATE CUSTOMER PAYMENTS TABLE IF NOT EXISTS
-- =====================================================

CREATE TABLE IF NOT EXISTS customer_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    month_number INTEGER NOT NULL,
    amount INTEGER NOT NULL DEFAULT 1000,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'paid'
    payment_date TIMESTAMP WITH TIME ZONE,
    marked_by UUID REFERENCES profiles(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(customer_id, month_number)
);

-- Create indexes for customer payments
CREATE INDEX IF NOT EXISTS idx_customer_payments_customer ON customer_payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_payments_status ON customer_payments(status);

-- =====================================================
-- 6. UPDATE RLS POLICIES
-- =====================================================

-- Enable RLS on new tables
ALTER TABLE pin_usage_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_payments ENABLE ROW LEVEL SECURITY;

-- RLS policies for pin_usage_log
CREATE POLICY "Users can view their own pin usage" ON pin_usage_log
    FOR SELECT USING (
        promoter_id = auth.uid() OR 
        customer_id = auth.uid() OR
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- RLS policies for customer_payments
CREATE POLICY "Users can view related payments" ON customer_payments
    FOR ALL USING (
        customer_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM profiles p1, profiles p2 
            WHERE p1.id = auth.uid() 
            AND p2.id = customer_payments.customer_id
            AND (p1.role = 'admin' OR p2.parent_promoter_id = p1.id)
        )
    );

-- Grant table permissions
GRANT SELECT, INSERT ON pin_usage_log TO authenticated;
GRANT SELECT, INSERT, UPDATE ON customer_payments TO authenticated;

COMMIT;

-- Verification
SELECT 'TABLE_CHECK' as check_type, tablename as table_name
FROM pg_tables 
WHERE tablename IN ('pin_usage_log', 'customer_payments')
AND schemaname = 'public';
