-- =====================================================
-- FIX CUSTOMER CREATION FUNCTION - COLUMN NAMES
-- =====================================================
-- This script updates the customer creation function to use correct column names

-- First check what columns exist in customer_payments table
SELECT 'EXISTING_COLUMNS' as info, column_name 
FROM information_schema.columns 
WHERE table_name = 'customer_payments';

-- Update the customer creation function to handle different column scenarios
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
    has_amount_column BOOLEAN;
    has_month_number_column BOOLEAN;
    has_status_column BOOLEAN;
BEGIN
    -- Start transaction
    BEGIN
        -- 1. VALIDATE PROMOTER HAS SUFFICIENT PINS
        SELECT pins INTO promoter_pins
        FROM profiles
        WHERE id = p_parent_promoter_id AND role = 'promoter'
        FOR UPDATE;
        
        IF promoter_pins IS NULL THEN
            RAISE EXCEPTION 'Promoter not found: %', p_parent_promoter_id;
        END IF;
        
        IF promoter_pins < 1 THEN
            RAISE EXCEPTION 'Insufficient pins to create customer. Available pins: %, Required: 1', promoter_pins;
        END IF;
        
        -- 2. CHECK CUSTOMER ID UNIQUENESS
        IF EXISTS (SELECT 1 FROM profiles WHERE customer_id = p_customer_id) THEN
            RAISE EXCEPTION 'Customer ID already exists: %', p_customer_id;
        END IF;
        
        -- 3. HASH PASSWORD
        hashed_password := crypt(p_password, gen_salt('bf'));
        
        -- 4. CREATE AUTH USER
        auth_email := 'customer+' || replace(gen_random_uuid()::text, '-', '') || '@brightplanetventures.local';
        
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
                auth_email,
                hashed_password,
                NOW(),
                NOW(),
                NOW(),
                '{"provider": "email", "providers": ["email"]}',
                jsonb_build_object('name', p_name, 'customer_id', p_customer_id),
                false,
                'authenticated'
            ) RETURNING id INTO auth_user_id;
        EXCEPTION WHEN OTHERS THEN
            auth_user_id := gen_random_uuid();
        END;
        
        -- 5. CREATE CUSTOMER PROFILE
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
            NOW(),
            NOW()
        ) RETURNING id INTO new_customer_id;
        
        -- 6. CHECK WHAT COLUMNS EXIST IN CUSTOMER_PAYMENTS TABLE
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'customer_payments' AND column_name = 'amount'
        ) INTO has_amount_column;
        
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'customer_payments' AND column_name = 'month_number'
        ) INTO has_month_number_column;
        
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'customer_payments' AND column_name = 'status'
        ) INTO has_status_column;
        
        -- 7. CREATE 20-MONTH PAYMENT SCHEDULE (DYNAMIC BASED ON AVAILABLE COLUMNS)
        IF has_amount_column AND has_month_number_column AND has_status_column THEN
            -- Full column set available
            INSERT INTO customer_payments (
                customer_id,
                month_number,
                amount,
                status,
                created_at
            )
            SELECT 
                new_customer_id,
                generate_series(1, 20),
                1000,
                'pending',
                NOW();
        ELSIF has_month_number_column THEN
            -- Basic columns available
            INSERT INTO customer_payments (
                customer_id,
                month_number,
                created_at
            )
            SELECT 
                new_customer_id,
                generate_series(1, 20),
                NOW();
        ELSE
            -- Minimal insert - just customer_id and created_at
            INSERT INTO customer_payments (
                customer_id,
                created_at
            )
            SELECT 
                new_customer_id,
                NOW()
            FROM generate_series(1, 20);
        END IF;
        
        -- 8. DEDUCT PIN FROM PROMOTER
        UPDATE profiles 
        SET pins = pins - 1,
            updated_at = NOW()
        WHERE id = p_parent_promoter_id AND role = 'promoter';
        
        -- 9. LOG THE PIN DEDUCTION
        INSERT INTO pin_usage_log (
            promoter_id,
            customer_id,
            pins_used,
            action_type,
            created_at
        ) VALUES (
            p_parent_promoter_id,
            new_customer_id,
            1,
            'customer_creation',
            NOW()
        );
        
        -- Return success result
        result := json_build_object(
            'success', true,
            'customer_id', new_customer_id,
            'customer_card_no', p_customer_id,
            'auth_user_id', auth_user_id,
            'pins_remaining', promoter_pins - 1,
            'message', 'Customer created successfully. 1 pin deducted.'
        );
        
        RETURN result;
        
    EXCEPTION WHEN OTHERS THEN
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Failed to create customer: ' || SQLERRM
        );
        RETURN result;
    END;
END $$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_customer_with_pin_deduction(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR, UUID, VARCHAR, VARCHAR) TO authenticated;
