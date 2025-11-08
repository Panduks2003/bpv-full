-- =====================================================
-- 03: ADD PERFORMANCE INDEXES
-- =====================================================
-- This script adds missing indexes for better query performance
-- =====================================================

BEGIN;

-- =====================================================
-- ADD MISSING INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_role_status ON profiles(role, status);
CREATE INDEX IF NOT EXISTS idx_profiles_parent_promoter_role ON profiles(parent_promoter_id, role);
CREATE INDEX IF NOT EXISTS idx_customer_payments_customer_month ON customer_payments(customer_id, month_number);
CREATE INDEX IF NOT EXISTS idx_customer_payments_status_date ON customer_payments(status, payment_date);
CREATE INDEX IF NOT EXISTS idx_pin_usage_log_promoter_action ON pin_usage_log(promoter_id, action_type);

-- Additional useful indexes
CREATE INDEX IF NOT EXISTS idx_profiles_customer_id_role ON profiles(customer_id, role) WHERE customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at);
CREATE INDEX IF NOT EXISTS idx_customer_payments_created_at ON customer_payments(created_at);
CREATE INDEX IF NOT EXISTS idx_pin_usage_log_created_at ON pin_usage_log(created_at);

COMMIT;

-- Verification
SELECT 'INDEXES_ADDED' as status,
       indexname as index_name,
       tablename as table_name
FROM pg_indexes 
WHERE indexname LIKE 'idx_%'
  AND (tablename = 'profiles' OR tablename = 'customer_payments' OR tablename = 'pin_usage_log')
ORDER BY tablename, indexname;
