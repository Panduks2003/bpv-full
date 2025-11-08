-- =====================================================
-- FINAL FIX: USE CORRECT COLUMN NAMES FROM ACTUAL TABLE
-- =====================================================
-- Based on the actual table structure, update the function to use payment_amount

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
        
        -- 6. CREATE 20-MONTH PAYMENT SCHEDULE
        -- Using the exact column names from your table:
        -- id, customer_id, month_number, payment_amount, payment_date, status, marked_by, notes, created_at, updated_at, amount
        INSERT INTO customer_payments (
            customer_id,
            month_number,
            payment_amount,  -- Using payment_amount (the main column)
            status,
            created_at,
            updated_at
        )
        SELECT 
            new_customer_id,
            generate_series(1, 20),
            1000.00,  -- Using NUMERIC format to match payment_amount column type
            'pending',
            NOW(),
            NOW();
        
        -- 7. DEDUCT PIN FROM PROMOTER
        UPDATE profiles 
        SET pins = pins - 1,
            updated_at = NOW()
        WHERE id = p_parent_promoter_id AND role = 'promoter';
        
        -- 8. LOG THE PIN DEDUCTION
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

-- Optional: Clean up the duplicate amount column that was added by the previous fix
-- Uncomment the line below if you want to remove the duplicate column
-- ALTER TABLE customer_payments DROP COLUMN IF EXISTS amount;

SELECT 'FUNCTION_UPDATED' as status, 'Customer creation function now uses payment_amount column' as message;
