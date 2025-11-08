-- =====================================================
-- CREATE CUSTOMER FINAL FUNCTION
-- =====================================================
-- This creates the create_customer_final function that AdminCustomers.js expects
-- =====================================================

-- Drop function if it exists
DROP FUNCTION IF EXISTS create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) CASCADE;

-- Create the function
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
    -- Start transaction
    BEGIN
        
        -- 1. CHECK PROMOTER HAS ENOUGH PINS
        SELECT pins INTO promoter_pins
        FROM profiles
        WHERE id = p_parent_promoter_id AND role = 'promoter'
        FOR UPDATE;
        
        IF promoter_pins IS NULL THEN
            RAISE EXCEPTION 'Promoter not found';
        END IF;
        
        IF promoter_pins < 1 THEN
            RAISE EXCEPTION 'Insufficient pins to create customer. Available: %, Required: 1', promoter_pins;
        END IF;
        
        -- 2. CHECK CUSTOMER ID UNIQUENESS
        IF EXISTS (SELECT 1 FROM profiles WHERE customer_id = p_customer_id) THEN
            RAISE EXCEPTION 'Customer ID already exists: %', p_customer_id;
        END IF;
        
        -- 3. HASH PASSWORD WITH ROBUST ERROR HANDLING
        BEGIN
            -- Try pgcrypto first
            salt_value := gen_salt('bf');
            hashed_password := crypt(p_password, salt_value);
            RAISE NOTICE 'Using pgcrypto for password hashing';
        EXCEPTION WHEN OTHERS THEN
            -- Fallback to simple hashing with random salt
            BEGIN
                salt_value := 'brightplanet_' || extract(epoch from now())::text;
                hashed_password := md5(p_password || salt_value);
                RAISE NOTICE 'Using fallback MD5 hashing: %', SQLERRM;
            EXCEPTION WHEN OTHERS THEN
                -- Ultimate fallback
                hashed_password := md5(p_password || 'brightplanet_default_salt');
                RAISE NOTICE 'Using basic MD5 hashing';
            END;
        END;
        
        -- 4. CREATE AUTH USER
        auth_email := 'customer+' || replace(gen_random_uuid()::text, '-', '') || '@brightplanetventures.local';
        
        BEGIN
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
                '{}',
                NOW(),
                NOW(),
                '',
                '',
                '',
                ''
            ) RETURNING id INTO auth_user_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to create auth user: %', SQLERRM;
        END;
        
        -- 5. CREATE PROFILE
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
            saving_plan,
            created_at,
            updated_at
        ) VALUES (
            new_customer_id,
            p_name,
            COALESCE(p_email, auth_email),
            p_mobile,
            'customer',
            p_customer_id,
            p_state,
            p_city,
            p_pincode,
            p_address,
            p_parent_promoter_id,
            'active',
            '₹1000 per month for 20 months',
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
        
        -- 7. DO NOT DEDUCT PIN HERE - The frontend handles it with pinTransactionService
        
        -- Return success result (without deducting PIN - admin handles that separately)
        result := json_build_object(
            'success', true,
            'customer_id', new_customer_id,
            'customer_card_no', p_customer_id,
            'auth_user_id', auth_user_id,
            'message', 'Customer created successfully'
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
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) TO anon;

-- Success message
SELECT '✅ create_customer_final function created successfully!' as result;

