-- =====================================================
-- UNIFIED PIN TRANSACTION SYSTEM
-- =====================================================
-- Complete standardization of PIN transactions across all modules
-- Ensures uniformity in Admin, Promoter, and Customer systems

BEGIN;

-- =====================================================
-- 1. UNIFIED PIN TRANSACTIONS TABLE
-- =====================================================
-- Single source of truth for all PIN-related operations

CREATE TABLE IF NOT EXISTS pin_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Transaction Details
    transaction_id VARCHAR(50) UNIQUE NOT NULL DEFAULT 'BPV-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8)),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Transaction Type (Standardized ActionTypes)
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN (
        'customer_creation',    -- ❌ Customer Creation (- PIN)
        'admin_allocation',     -- ✅ Admin Allocation (+ PIN)  
        'admin_deduction'       -- ❌ Admin Deduction (- PIN)
    )),
    
    -- PIN Changes
    pin_change_value INTEGER NOT NULL, -- Positive for additions, negative for deductions
    balance_before INTEGER NOT NULL DEFAULT 0,
    balance_after INTEGER NOT NULL DEFAULT 0,
    
    -- Metadata
    note TEXT NOT NULL, -- Standardized auto-generated notes
    created_by UUID REFERENCES profiles(id), -- Admin who performed the action (NULL for system actions)
    related_entity_id UUID, -- Customer ID for customer_creation, etc.
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_pin_transactions_user_id ON pin_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_pin_transactions_action_type ON pin_transactions(action_type);
CREATE INDEX IF NOT EXISTS idx_pin_transactions_created_at ON pin_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pin_transactions_transaction_id ON pin_transactions(transaction_id);

-- =====================================================
-- 3. ROW LEVEL SECURITY POLICIES
-- =====================================================

ALTER TABLE pin_transactions ENABLE ROW LEVEL SECURITY;

-- Admin can see all transactions
CREATE POLICY "admin_can_view_all_pin_transactions" ON pin_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Users can see their own transactions
CREATE POLICY "users_can_view_own_pin_transactions" ON pin_transactions
    FOR SELECT USING (user_id = auth.uid());

-- Only admins can insert/update transactions
CREATE POLICY "admin_can_manage_pin_transactions" ON pin_transactions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- =====================================================
-- 4. STANDARDIZED NOTE GENERATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION generate_pin_transaction_note(
    p_action_type VARCHAR(50),
    p_pin_change_value INTEGER,
    p_related_entity_name TEXT DEFAULT NULL
) RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    CASE p_action_type
        WHEN 'customer_creation' THEN
            RETURN CASE 
                WHEN p_related_entity_name IS NOT NULL THEN 
                    'Customer creation: ' || p_related_entity_name || ' (-' || ABS(p_pin_change_value) || ' PIN)'
                ELSE 
                    'Customer creation (-' || ABS(p_pin_change_value) || ' PIN)'
            END;
        WHEN 'admin_allocation' THEN
            RETURN 'Admin allocation (+' || ABS(p_pin_change_value) || ' PIN' || CASE WHEN ABS(p_pin_change_value) > 1 THEN 's' ELSE '' END || ')';
        WHEN 'admin_deduction' THEN
            RETURN 'Admin deduction (-' || ABS(p_pin_change_value) || ' PIN' || CASE WHEN ABS(p_pin_change_value) > 1 THEN 's' ELSE '' END || ')';
        ELSE
            RETURN 'PIN transaction (' || p_pin_change_value || ')';
    END CASE;
END $$;

-- =====================================================
-- 5. UNIFIED PIN TRANSACTION FUNCTION
-- =====================================================
-- Central function for all PIN operations

CREATE OR REPLACE FUNCTION execute_pin_transaction(
    p_user_id UUID,
    p_action_type VARCHAR(50),
    p_pin_change_value INTEGER,
    p_created_by UUID DEFAULT NULL,
    p_related_entity_id UUID DEFAULT NULL,
    p_related_entity_name TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_balance INTEGER;
    v_new_balance INTEGER;
    v_transaction_id VARCHAR(50);
    v_note TEXT;
    v_result JSON;
BEGIN
    -- Validate action type
    IF p_action_type NOT IN ('customer_creation', 'admin_allocation', 'admin_deduction') THEN
        RAISE EXCEPTION 'Invalid action_type: %. Must be one of: customer_creation, admin_allocation, admin_deduction', p_action_type;
    END IF;

    -- Get current balance with row lock
    SELECT COALESCE(pins, 0) INTO v_current_balance
    FROM profiles
    WHERE id = p_user_id AND role IN ('promoter', 'admin')
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found or invalid role: %', p_user_id;
    END IF;

    -- Calculate new balance
    v_new_balance := v_current_balance + p_pin_change_value;

    -- Validate sufficient balance for deductions
    IF p_pin_change_value < 0 AND v_new_balance < 0 THEN
        RAISE EXCEPTION 'Insufficient PIN balance. Current: %, Required: %, Shortfall: %', 
            v_current_balance, ABS(p_pin_change_value), ABS(v_new_balance);
    END IF;

    -- Generate transaction ID
    v_transaction_id := 'BPV-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8));

    -- Generate standardized note
    v_note := generate_pin_transaction_note(p_action_type, p_pin_change_value, p_related_entity_name);

    -- Update user's PIN balance
    UPDATE profiles 
    SET pins = v_new_balance,
        updated_at = NOW()
    WHERE id = p_user_id;

    -- Insert transaction record
    INSERT INTO pin_transactions (
        transaction_id,
        user_id,
        action_type,
        pin_change_value,
        balance_before,
        balance_after,
        note,
        created_by,
        related_entity_id
    ) VALUES (
        v_transaction_id,
        p_user_id,
        p_action_type,
        p_pin_change_value,
        v_current_balance,
        v_new_balance,
        v_note,
        p_created_by,
        p_related_entity_id
    );

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'balance_before', v_current_balance,
        'balance_after', v_new_balance,
        'pin_change', p_pin_change_value,
        'note', v_note
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    -- Return error result
    v_result := json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
    RETURN v_result;
END $$;

-- =====================================================
-- 6. CONVENIENCE FUNCTIONS FOR SPECIFIC OPERATIONS
-- =====================================================

-- Customer Creation (Deduct 1 PIN from promoter)
CREATE OR REPLACE FUNCTION deduct_pin_for_customer_creation(
    p_promoter_id UUID,
    p_customer_id UUID,
    p_customer_name TEXT
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN execute_pin_transaction(
        p_user_id := p_promoter_id,
        p_action_type := 'customer_creation',
        p_pin_change_value := -1,
        p_created_by := NULL, -- System action
        p_related_entity_id := p_customer_id,
        p_related_entity_name := p_customer_name
    );
END $$;

-- Admin PIN Allocation
CREATE OR REPLACE FUNCTION admin_allocate_pins(
    p_target_user_id UUID,
    p_pin_amount INTEGER,
    p_admin_id UUID
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN execute_pin_transaction(
        p_user_id := p_target_user_id,
        p_action_type := 'admin_allocation',
        p_pin_change_value := ABS(p_pin_amount), -- Ensure positive
        p_created_by := p_admin_id,
        p_related_entity_id := NULL,
        p_related_entity_name := NULL
    );
END $$;

-- Admin PIN Deduction
CREATE OR REPLACE FUNCTION admin_deduct_pins(
    p_target_user_id UUID,
    p_pin_amount INTEGER,
    p_admin_id UUID
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN execute_pin_transaction(
        p_user_id := p_target_user_id,
        p_action_type := 'admin_deduction',
        p_pin_change_value := -ABS(p_pin_amount), -- Ensure negative
        p_created_by := p_admin_id,
        p_related_entity_id := NULL,
        p_related_entity_name := NULL
    );
END $$;

-- =====================================================
-- 7. MIGRATION FROM OLD SYSTEM
-- =====================================================
-- Migrate existing pin_usage_log data to new unified system

DO $$
DECLARE
    log_record RECORD;
    migration_result JSON;
BEGIN
    -- Check if pin_usage_log table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pin_usage_log') THEN
        
        RAISE NOTICE 'Migrating existing pin_usage_log data...';
        
        -- Migrate each record from pin_usage_log
        FOR log_record IN 
            SELECT * FROM pin_usage_log ORDER BY created_at ASC
        LOOP
            -- Determine action type mapping
            DECLARE
                mapped_action_type VARCHAR(50);
                pin_change INTEGER;
            BEGIN
                CASE log_record.action_type
                    WHEN 'customer_creation' THEN
                        mapped_action_type := 'customer_creation';
                        pin_change := -ABS(log_record.pins_used); -- Ensure negative
                    WHEN 'admin_allocation' THEN
                        mapped_action_type := 'admin_allocation';
                        pin_change := ABS(log_record.pins_used); -- Ensure positive
                    WHEN 'admin_deduction' THEN
                        mapped_action_type := 'admin_deduction';
                        pin_change := -ABS(log_record.pins_used); -- Ensure negative
                    ELSE
                        -- Skip unknown action types
                        CONTINUE;
                END CASE;

                -- Insert into new unified table (without executing balance updates)
                INSERT INTO pin_transactions (
                    transaction_id,
                    user_id,
                    action_type,
                    pin_change_value,
                    balance_before,
                    balance_after,
                    note,
                    created_by,
                    related_entity_id,
                    created_at
                ) VALUES (
                    COALESCE(log_record.transaction_id, 'BPV-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8))),
                    log_record.promoter_id,
                    mapped_action_type,
                    pin_change,
                    0, -- Will be recalculated
                    0, -- Will be recalculated
                    COALESCE(log_record.notes, generate_pin_transaction_note(mapped_action_type, pin_change)),
                    NULL, -- Unknown admin
                    log_record.customer_id,
                    log_record.created_at
                );
            END;
        END LOOP;
        
        RAISE NOTICE 'Migration completed. Migrated % records.', (SELECT COUNT(*) FROM pin_transactions);
    ELSE
        RAISE NOTICE 'No pin_usage_log table found. Skipping migration.';
    END IF;
END $$;

-- =====================================================
-- 8. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION execute_pin_transaction(UUID, VARCHAR(50), INTEGER, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION deduct_pin_for_customer_creation(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_allocate_pins(UUID, INTEGER, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_deduct_pins(UUID, INTEGER, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_pin_transaction_note(VARCHAR(50), INTEGER, TEXT) TO authenticated;

COMMIT;

-- =====================================================
-- 9. VERIFICATION QUERIES
-- =====================================================

-- Verify table creation
SELECT 'pin_transactions' as table_name, 
       CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pin_transactions') 
            THEN 'CREATED' ELSE 'MISSING' END as status;

-- Verify functions
SELECT 'FUNCTIONS' as component, COUNT(*) as count
FROM pg_proc 
WHERE proname IN (
    'execute_pin_transaction',
    'deduct_pin_for_customer_creation', 
    'admin_allocate_pins',
    'admin_deduct_pins',
    'generate_pin_transaction_note'
);

-- Show sample transaction data
SELECT 'SAMPLE_DATA' as component, COUNT(*) as transaction_count
FROM pin_transactions;

-- Verify action types
SELECT action_type, COUNT(*) as count
FROM pin_transactions
GROUP BY action_type
ORDER BY action_type;

RAISE NOTICE 'Unified PIN Transaction System installation completed successfully!';
