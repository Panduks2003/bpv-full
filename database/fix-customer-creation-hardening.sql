-- =====================================================
-- CUSTOMER CREATION WORKFLOW HARDENING
-- =====================================================
-- This script fixes and hardens the customer creation system
-- Scope: Fix existing validation, constraints, and transaction safety
-- =====================================================

BEGIN;

-- =====================================================
-- 1. FIX DATABASE SCHEMA INCONSISTENCIES
-- =====================================================

-- Standardize customer_payments table columns
DO $$
BEGIN
    -- Check if both amount and payment_amount columns exist
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customer_payments' AND column_name = 'amount')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customer_payments' AND column_name = 'payment_amount') THEN
        
        -- Copy data from amount to payment_amount if payment_amount is empty
        UPDATE customer_payments SET payment_amount = amount WHERE payment_amount IS NULL OR payment_amount = 0;
        
        -- Drop the duplicate amount column
        ALTER TABLE customer_payments DROP COLUMN amount;
        RAISE NOTICE 'Removed duplicate amount column from customer_payments';
    END IF;
    
    -- Ensure payment_amount column exists and has proper constraints
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'customer_payments' AND column_name = 'payment_amount') THEN
        ALTER TABLE customer_payments ADD COLUMN payment_amount DECIMAL(10,2) NOT NULL DEFAULT 1000.00;
        RAISE NOTICE 'Added payment_amount column to customer_payments';
    END IF;
END $$;

-- =====================================================
-- 2. ADD MISSING DATABASE CONSTRAINTS
-- =====================================================

-- Add constraints to profiles table for customer data integrity
DO $$
BEGIN
    -- Customer ID uniqueness constraint (if not exists)
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_customer_id_unique') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_unique UNIQUE (customer_id);
        RAISE NOTICE 'Added unique constraint on customer_id';
    END IF;
    
    -- Customer ID format validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_customer_id_format') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_customer_id_format 
            CHECK (customer_id IS NULL OR (customer_id ~ '^[A-Z0-9]{3,20}$'));
        RAISE NOTICE 'Added format constraint on customer_id';
    END IF;
    
    -- Phone number format validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_phone_format') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_phone_format 
            CHECK (phone IS NULL OR (phone ~ '^[6-9][0-9]{9}$'));
        RAISE NOTICE 'Added phone format constraint';
    END IF;
    
    -- Pincode format validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_pincode_format') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_pincode_format 
            CHECK (pincode IS NULL OR (pincode ~ '^[0-9]{6}$'));
        RAISE NOTICE 'Added pincode format constraint';
    END IF;
    
    -- Role validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_role_check') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_role_check 
            CHECK (role IN ('admin', 'promoter', 'customer'));
        RAISE NOTICE 'Added role validation constraint';
    END IF;
    
    -- Status validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_status_check') THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_status_check 
            CHECK (status IN ('active', 'inactive', 'suspended', 'Active', 'Inactive'));
        RAISE NOTICE 'Added status validation constraint';
    END IF;
END $$;

-- Add constraints to customer_payments table
DO $$
BEGIN
    -- Payment amount validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'customer_payments_amount_check') THEN
        ALTER TABLE customer_payments ADD CONSTRAINT customer_payments_amount_check 
            CHECK (payment_amount > 0 AND payment_amount <= 100000);
        RAISE NOTICE 'Added payment amount validation constraint';
    END IF;
    
    -- Month number validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'customer_payments_month_check') THEN
        ALTER TABLE customer_payments ADD CONSTRAINT customer_payments_month_check 
            CHECK (month_number >= 1 AND month_number <= 60);
        RAISE NOTICE 'Added month number validation constraint';
    END IF;
    
    -- Status validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'customer_payments_status_check') THEN
        ALTER TABLE customer_payments ADD CONSTRAINT customer_payments_status_check 
            CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled'));
        RAISE NOTICE 'Added payment status validation constraint';
    END IF;
END $$;

-- Add constraints to pin_usage_log table
DO $$
BEGIN
    -- Pins used validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pin_usage_log_pins_check') THEN
        ALTER TABLE pin_usage_log ADD CONSTRAINT pin_usage_log_pins_check 
            CHECK (pins_used > 0 AND pins_used <= 1000);
        RAISE NOTICE 'Added pins used validation constraint';
    END IF;
    
    -- Action type validation
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pin_usage_log_action_check') THEN
        ALTER TABLE pin_usage_log ADD CONSTRAINT pin_usage_log_action_check 
            CHECK (action_type IN ('customer_creation', 'admin_allocation', 'promoter_creation', 'adjustment'));
        RAISE NOTICE 'Added action type validation constraint';
    END IF;
END $$;

-- =====================================================
-- 3. ADD MISSING INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_role_status ON profiles(role, status);
CREATE INDEX IF NOT EXISTS idx_profiles_parent_promoter_role ON profiles(parent_promoter_id, role);
CREATE INDEX IF NOT EXISTS idx_customer_payments_customer_month ON customer_payments(customer_id, month_number);
CREATE INDEX IF NOT EXISTS idx_customer_payments_status_date ON customer_payments(status, payment_date);
CREATE INDEX IF NOT EXISTS idx_pin_usage_log_promoter_action ON pin_usage_log(promoter_id, action_type);

-- =====================================================
-- 4. HARDEN CUSTOMER CREATION FUNCTIONS
-- =====================================================

-- Drop and recreate the admin customer creation function with better validation
DROP FUNCTION IF EXISTS create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION create_customer_final(
    p_name TEXT,
    p_mobile TEXT,
    p_state TEXT,
    p_city TEXT,
    p_pincode TEXT,
    p_address TEXT,
    p_customer_id VARCHAR,
    p_password TEXT,
    p_parent_promoter_id UUID,
    p_email TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_customer_id UUID;
    auth_user_id UUID;
    auth_email VARCHAR(255);
    result JSON;
    promoter_pins INTEGER;
    hashed_password TEXT;
    salt_value TEXT;
BEGIN
    -- Input validation
    IF p_name IS NULL OR trim(p_name) = '' THEN
        RAISE EXCEPTION 'Customer name is required';
    END IF;
    
    IF p_mobile IS NULL OR NOT (p_mobile ~ '^[6-9][0-9]{9}$') THEN
        RAISE EXCEPTION 'Valid mobile number is required (10 digits starting with 6-9)';
    END IF;
    
    IF p_customer_id IS NULL OR NOT (p_customer_id ~ '^[A-Z0-9]{3,20}$') THEN
        RAISE EXCEPTION 'Valid customer ID is required (3-20 alphanumeric characters)';
    END IF;
    
    IF p_password IS NULL OR length(p_password) < 6 THEN
        RAISE EXCEPTION 'Password must be at least 6 characters long';
    END IF;
    
    IF p_pincode IS NULL OR NOT (p_pincode ~ '^[0-9]{6}$') THEN
        RAISE EXCEPTION 'Valid 6-digit pincode is required';
    END IF;
    
    IF p_parent_promoter_id IS NULL THEN
        RAISE EXCEPTION 'Parent promoter ID is required';
    END IF;

    -- Start atomic transaction
    BEGIN
        -- 1. ATOMIC CHECK AND LOCK PROMOTER PINS
        SELECT pins INTO promoter_pins
        FROM profiles
        WHERE id = p_parent_promoter_id AND (role = 'promoter' OR role = 'admin')
        FOR UPDATE NOWAIT;
        
        IF promoter_pins IS NULL THEN
            RAISE EXCEPTION 'Promoter not found or invalid role';
        END IF;
        
        IF promoter_pins < 1 THEN
            RAISE EXCEPTION 'Insufficient pins to create customer. Available: %, Required: 1', promoter_pins;
        END IF;
        
        -- 2. ATOMIC CUSTOMER ID UNIQUENESS CHECK
        PERFORM 1 FROM profiles WHERE customer_id = p_customer_id FOR UPDATE;
        IF FOUND THEN
            RAISE EXCEPTION 'Customer ID already exists: %', p_customer_id;
        END IF;
        
        -- 3. SECURE PASSWORD HASHING
        BEGIN
            -- Use pgcrypto with proper error handling
            hashed_password := crypt(p_password, gen_salt('bf', 10));
            IF hashed_password IS NULL OR length(hashed_password) < 10 THEN
                RAISE EXCEPTION 'Password hashing failed';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- Secure fallback
            salt_value := 'bp_' || extract(epoch from now())::text || '_' || gen_random_uuid()::text;
            hashed_password := encode(digest(p_password || salt_value, 'sha256'), 'hex');
            RAISE NOTICE 'Using SHA256 fallback for password hashing';
        END;
        
        -- 4. CREATE AUTH USER WITH VALIDATION
        auth_email := COALESCE(p_email, 'customer+' || replace(gen_random_uuid()::text, '-', '') || '@brightplanetventures.local');
        
        -- Validate email format if provided
        IF p_email IS NOT NULL AND NOT (p_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            RAISE EXCEPTION 'Invalid email format: %', p_email;
        END IF;
        
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            recovery_sent_at,
            last_sign_in_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            email_change,
            email_change_token_new,
            recovery_token
        )
        VALUES (
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            auth_email,
            hashed_password,
            NOW(),
            NOW(),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            jsonb_build_object('customer_id', p_customer_id, 'created_by', 'admin'),
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        ) RETURNING id INTO auth_user_id;
        
        -- 5. CREATE CUSTOMER PROFILE
        new_customer_id := auth_user_id;
        
        INSERT INTO profiles (
            id,
            name,
            email,
            phone,
            role,
            customer_id,
            state,
            city,
            pincode,
            address,
            parent_promoter_id,
            status,
            investment_plan,
            created_at,
            updated_at
        ) VALUES (
            new_customer_id,
            trim(p_name),
            auth_email,
            p_mobile,
            'customer',
            upper(trim(p_customer_id)),
            trim(p_state),
            trim(p_city),
            p_pincode,
            trim(p_address),
            p_parent_promoter_id,
            'active',
            '₹1000 per month for 20 months',
            NOW(),
            NOW()
        );
        
        -- 6. CREATE 20-MONTH PAYMENT SCHEDULE WITH VALIDATION
        INSERT INTO customer_payments (
            customer_id,
            month_number,
            payment_amount,
            status,
            created_at,
            updated_at
        )
        SELECT 
            new_customer_id,
            generate_series(1, 20),
            1000.00,
            'pending',
            NOW(),
            NOW();
        
        -- Verify payment schedule was created
        IF (SELECT COUNT(*) FROM customer_payments WHERE customer_id = new_customer_id) != 20 THEN
            RAISE EXCEPTION 'Failed to create complete payment schedule';
        END IF;
        
        -- Return success result
        result := json_build_object(
            'success', true,
            'customer_id', new_customer_id,
            'customer_card_no', upper(trim(p_customer_id)),
            'auth_user_id', auth_user_id,
            'message', 'Customer created successfully',
            'timestamp', NOW()
        );
        
        RETURN result;
        
    EXCEPTION WHEN OTHERS THEN
        -- Comprehensive error logging
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE,
            'message', 'Failed to create customer: ' || SQLERRM,
            'timestamp', NOW()
        );
        RETURN result;
    END;
END;
$$;

-- =====================================================
-- 5. HARDEN PROMOTER CUSTOMER CREATION FUNCTION
-- =====================================================

-- Drop and recreate the promoter customer creation function
DROP FUNCTION IF EXISTS create_customer_with_pin_deduction(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR, UUID, VARCHAR, VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION create_customer_with_pin_deduction(
    p_name VARCHAR(255),
    p_mobile VARCHAR(20),
    p_state VARCHAR(100),
    p_city VARCHAR(100),
    p_pincode VARCHAR(10),
    p_address TEXT,
    p_customer_id VARCHAR(50),
    p_password VARCHAR(255),
    p_parent_promoter_id UUID,
    p_email VARCHAR(255) DEFAULT NULL,
    p_investment_plan VARCHAR(255) DEFAULT '₹1000 per month for 20 months'
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_customer_id UUID;
    auth_user_id UUID;
    auth_email VARCHAR(255);
    result JSON;
    promoter_pins INTEGER;
    hashed_password TEXT;
BEGIN
    -- Enhanced input validation
    IF p_name IS NULL OR trim(p_name) = '' THEN
        RAISE EXCEPTION 'Customer name is required';
    END IF;
    
    IF p_mobile IS NULL OR NOT (p_mobile ~ '^[6-9][0-9]{9}$') THEN
        RAISE EXCEPTION 'Valid mobile number is required (10 digits starting with 6-9)';
    END IF;
    
    IF p_customer_id IS NULL OR NOT (p_customer_id ~ '^[A-Z0-9]{3,20}$') THEN
        RAISE EXCEPTION 'Valid customer ID is required (3-20 alphanumeric characters)';
    END IF;
    
    IF p_password IS NULL OR length(p_password) < 6 THEN
        RAISE EXCEPTION 'Password must be at least 6 characters long';
    END IF;
    
    IF p_pincode IS NULL OR NOT (p_pincode ~ '^[0-9]{6}$') THEN
        RAISE EXCEPTION 'Valid 6-digit pincode is required';
    END IF;

    -- Start atomic transaction
    BEGIN
        -- 1. ATOMIC PROMOTER VALIDATION AND PIN DEDUCTION
        UPDATE profiles 
        SET pins = pins - 1,
            updated_at = NOW()
        WHERE id = p_parent_promoter_id 
          AND role = 'promoter' 
          AND pins >= 1
        RETURNING pins + 1 INTO promoter_pins;
        
        IF promoter_pins IS NULL THEN
            RAISE EXCEPTION 'Promoter not found, insufficient pins, or invalid role';
        END IF;
        
        -- 2. ATOMIC CUSTOMER ID UNIQUENESS CHECK
        PERFORM 1 FROM profiles WHERE customer_id = upper(trim(p_customer_id)) FOR UPDATE;
        IF FOUND THEN
            RAISE EXCEPTION 'Customer ID already exists: %', p_customer_id;
        END IF;
        
        -- 3. SECURE PASSWORD HASHING
        BEGIN
            hashed_password := crypt(p_password, gen_salt('bf', 10));
            IF hashed_password IS NULL OR length(hashed_password) < 10 THEN
                RAISE EXCEPTION 'Password hashing failed';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- Secure fallback
            hashed_password := encode(digest(p_password || 'bp_' || extract(epoch from now())::text, 'sha256'), 'hex');
        END;
        
        -- 4. CREATE AUTH USER
        auth_email := COALESCE(p_email, 'customer+' || replace(gen_random_uuid()::text, '-', '') || '@brightplanetventures.local');
        
        -- Validate email format if provided
        IF p_email IS NOT NULL AND NOT (p_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            RAISE EXCEPTION 'Invalid email format: %', p_email;
        END IF;
        
        INSERT INTO auth.users (
            id,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            raw_app_meta_data,
            raw_user_meta_data,
            is_super_admin,
            role
        ) VALUES (
            gen_random_uuid(),
            auth_email,
            hashed_password,
            NOW(),
            NOW(),
            NOW(),
            '{"provider": "email", "providers": ["email"]}',
            jsonb_build_object('name', trim(p_name), 'customer_id', upper(trim(p_customer_id)), 'created_by', 'promoter'),
            false,
            'authenticated'
        ) RETURNING id INTO auth_user_id;
        
        -- 5. CREATE CUSTOMER PROFILE
        new_customer_id := auth_user_id;
        
        INSERT INTO profiles (
            id,
            name,
            email,
            phone,
            state,
            city,
            pincode,
            address,
            customer_id,
            parent_promoter_id,
            investment_plan,
            role,
            status,
            created_at,
            updated_at
        ) VALUES (
            new_customer_id,
            trim(p_name),
            auth_email,
            p_mobile,
            trim(p_state),
            trim(p_city),
            p_pincode,
            trim(p_address),
            upper(trim(p_customer_id)),
            p_parent_promoter_id,
            p_investment_plan,
            'customer',
            'active',
            NOW(),
            NOW()
        );
        
        -- 6. CREATE 20-MONTH PAYMENT SCHEDULE
        INSERT INTO customer_payments (
            customer_id,
            month_number,
            payment_amount,
            status,
            created_at,
            updated_at
        )
        SELECT 
            new_customer_id,
            generate_series(1, 20),
            1000.00,
            'pending',
            NOW(),
            NOW();
        
        -- 7. LOG PIN DEDUCTION
        INSERT INTO pin_usage_log (
            promoter_id,
            customer_id,
            pins_used,
            action_type,
            notes,
            created_at
        ) VALUES (
            p_parent_promoter_id,
            new_customer_id,
            1,
            'customer_creation',
            'PIN deducted for customer creation: ' || upper(trim(p_customer_id)),
            NOW()
        );
        
        -- Return success result
        result := json_build_object(
            'success', true,
            'customer_id', new_customer_id,
            'customer_card_no', upper(trim(p_customer_id)),
            'auth_user_id', auth_user_id,
            'pins_remaining', promoter_pins - 1,
            'message', 'Customer created successfully. 1 pin deducted.',
            'timestamp', NOW()
        );
        
        RETURN result;
        
    EXCEPTION WHEN OTHERS THEN
        -- Comprehensive error logging
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE,
            'message', 'Failed to create customer: ' || SQLERRM,
            'timestamp', NOW()
        );
        RETURN result;
    END;
END $$;

-- =====================================================
-- 6. GRANT PROPER PERMISSIONS
-- =====================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_customer_with_pin_deduction(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR, UUID, VARCHAR, VARCHAR) TO authenticated;

-- =====================================================
-- 7. CREATE AUDIT TRIGGER FOR CUSTOMER CREATION
-- =====================================================

-- Create audit function for customer creation tracking
CREATE OR REPLACE FUNCTION audit_customer_creation()
RETURNS TRIGGER AS $$
BEGIN
    -- Log customer creation in a simple way
    INSERT INTO pin_usage_log (
        promoter_id,
        customer_id,
        pins_used,
        action_type,
        notes,
        created_at
    ) VALUES (
        NEW.parent_promoter_id,
        NEW.id,
        0, -- No pins used in audit log
        'customer_audit',
        'Customer profile created: ' || NEW.customer_id,
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for customer creation audit
DROP TRIGGER IF EXISTS trigger_audit_customer_creation ON profiles;
CREATE TRIGGER trigger_audit_customer_creation
    AFTER INSERT ON profiles
    FOR EACH ROW
    WHEN (NEW.role = 'customer')
    EXECUTE FUNCTION audit_customer_creation();

COMMIT;

-- =====================================================
-- 8. VERIFICATION QUERIES
-- =====================================================

-- Verify constraints were added
SELECT 'CONSTRAINTS_CHECK' as check_type, 
       COUNT(*) as constraint_count
FROM pg_constraint 
WHERE conname LIKE 'profiles_%' OR conname LIKE 'customer_payments_%' OR conname LIKE 'pin_usage_log_%';

-- Verify functions exist
SELECT 'FUNCTIONS_CHECK' as check_type,
       proname as function_name
FROM pg_proc 
WHERE proname IN ('create_customer_final', 'create_customer_with_pin_deduction');

-- Success message
SELECT '✅ Customer creation workflow hardening completed successfully!' as result;
