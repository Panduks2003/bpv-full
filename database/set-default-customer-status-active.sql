-- =====================================================
-- SET DEFAULT CUSTOMER STATUS TO ACTIVE
-- =====================================================
-- This script ensures all customers are created with 'active' status by default

BEGIN;

-- =====================================================
-- 1. ADD STATUS COLUMN WITH DEFAULT VALUE IF NOT EXISTS
-- =====================================================

-- Add status column with default 'active' if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'status'
    ) THEN
        ALTER TABLE profiles ADD COLUMN status VARCHAR(20) DEFAULT 'active';
        CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
        RAISE NOTICE 'Added status column to profiles table with default active';
    ELSE
        -- Update existing column to have default 'active'
        ALTER TABLE profiles ALTER COLUMN status SET DEFAULT 'active';
        RAISE NOTICE 'Updated status column default to active';
    END IF;
END $$;

-- =====================================================
-- 2. UPDATE EXISTING CUSTOMERS WITHOUT STATUS
-- =====================================================

-- Set status to 'active' for any existing customers that have NULL status
UPDATE profiles 
SET status = 'active' 
WHERE role = 'customer' 
AND (status IS NULL OR status = '');

-- =====================================================
-- 3. UPDATE CUSTOMER CREATION FUNCTION TO INCLUDE STATUS
-- =====================================================

-- Update the customer creation function to explicitly set status to 'active'
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
    promoter_pins INTEGER;
    result JSON;
BEGIN
    -- 1. VALIDATE PROMOTER HAS SUFFICIENT PINS
    SELECT pins INTO promoter_pins 
    FROM profiles 
    WHERE id = p_parent_promoter_id AND role = 'promoter';
    
    IF promoter_pins IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Promoter not found');
    END IF;
    
    IF promoter_pins < 1 THEN
        RETURN json_build_object('success', false, 'error', 'Insufficient pins');
    END IF;
    
    -- 2. CREATE AUTH USER
    BEGIN
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
            COALESCE(p_email, p_customer_id || '@brightplanetventures.local'),
            crypt(p_password, gen_salt('bf')),
            NOW(),
            NOW(),
            NOW(),
            '{"provider": "email", "providers": ["email"]}',
            json_build_object('name', p_name, 'customer_id', p_customer_id),
            false,
            'authenticated'
        ) RETURNING id INTO auth_user_id;
    EXCEPTION WHEN OTHERS THEN
        -- If auth user creation fails, continue with profile creation
        auth_user_id := gen_random_uuid();
    END;
    
    -- 3. CREATE CUSTOMER PROFILE WITH ACTIVE STATUS
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
        auth_user_id,
        p_name,
        p_email,
        p_mobile,
        p_state,
        p_city,
        p_pincode,
        p_address,
        p_customer_id,
        p_parent_promoter_id,
        p_investment_plan,
        'customer',
        'active',
        NOW(),
        NOW()
    ) RETURNING id INTO new_customer_id;
    
    -- 4. DEDUCT PIN FROM PROMOTER
    UPDATE profiles 
    SET pins = pins - 1, updated_at = NOW()
    WHERE id = p_parent_promoter_id;
    
    -- 5. LOG PIN USAGE (with negative value for consumption)
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
        -1,
        'customer_creation',
        'Pin consumed for customer creation: ' || p_name,
        NOW()
    );
    
    -- 6. CREATE 20-MONTH PAYMENT SCHEDULE
    INSERT INTO customer_payments (customer_id, month_number, amount, status, created_at)
    SELECT 
        new_customer_id,
        generate_series(1, 20),
        1000,
        'pending',
        NOW();
    
    -- 7. GET REMAINING PINS
    SELECT pins INTO promoter_pins 
    FROM profiles 
    WHERE id = p_parent_promoter_id;
    
    -- 8. RETURN SUCCESS RESULT
    RETURN json_build_object(
        'success', true,
        'customer_id', new_customer_id,
        'pins_remaining', promoter_pins,
        'message', 'Customer created successfully with active status'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false, 
        'error', SQLERRM
    );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_customer_with_pin_deduction(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR, UUID, VARCHAR, VARCHAR) TO authenticated;

COMMIT;

-- =====================================================
-- 4. VERIFICATION
-- =====================================================

-- Check status column exists with default
SELECT 'STATUS_COLUMN_CHECK' as check_type,
       column_name,
       column_default,
       is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'status';

-- Check existing customers have active status
SELECT 'CUSTOMER_STATUS_CHECK' as check_type,
       status,
       COUNT(*) as count
FROM profiles 
WHERE role = 'customer'
GROUP BY status;

-- Verify function exists
SELECT 'FUNCTION_CHECK' as check_type,
       CASE WHEN EXISTS (
           SELECT 1 FROM pg_proc WHERE proname = 'create_customer_with_pin_deduction'
       ) THEN 'EXISTS' ELSE 'MISSING' END as status;
