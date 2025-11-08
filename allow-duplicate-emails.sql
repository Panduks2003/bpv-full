-- Allow duplicate emails since they're for informational purposes only
-- Remove email uniqueness constraint and update customer creation function

-- Update the create_customer_final function to allow duplicate emails
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
    payment_count INTEGER;
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
            RAISE EXCEPTION 'Insufficient pins. Promoter has % pins, but 1 is required', promoter_pins;
        END IF;
        
        -- 2. GENERATE UNIQUE AUTH EMAIL (always unique for auth system)
        -- Use customer ID + timestamp to ensure uniqueness for auth.users table
        auth_email := 'customer_' || p_customer_id || '_' || extract(epoch from now())::bigint || '@brightplanetventures.local';
        
        -- 3. GENERATE PASSWORD HASH
        BEGIN
            salt_value := gen_salt('bf');
            hashed_password := crypt(p_password, salt_value);
        EXCEPTION WHEN OTHERS THEN
            -- Fallback hashing
            salt_value := 'brightplanet_' || extract(epoch from now())::text;
            hashed_password := md5(p_password || salt_value);
        END;
        
        -- 4. CREATE AUTH USER (with unique auth email)
        BEGIN
            INSERT INTO auth.users (
                instance_id,
                id,
                aud,
                role,
                email,
                encrypted_password,
                email_confirmed_at,
                invited_at,
                confirmation_sent_at,
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
                auth_email, -- This is always unique
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
        
        -- 5. CREATE PROFILE (with user-provided email, can be duplicate)
        new_customer_id := auth_user_id;
        
        INSERT INTO profiles (
            id,
            name,
            email, -- This can be duplicate since it's for informational purposes
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
            p_email, -- Use the provided email directly (can be duplicate)
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
        BEGIN
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
            
            -- Verify payments were created
            SELECT COUNT(*) INTO payment_count
            FROM customer_payments
            WHERE customer_id = new_customer_id;
            
            IF payment_count != 20 THEN
                RAISE EXCEPTION 'Payment schedule creation failed. Expected 20 payments, got %', payment_count;
            END IF;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to create payment schedule: %', SQLERRM;
        END;
        
        -- Return success result
        result := json_build_object(
            'success', true,
            'customer_id', new_customer_id,
            'customer_card_no', p_customer_id,
            'auth_user_id', auth_user_id,
            'auth_email', auth_email,
            'user_email', p_email,
            'payment_count', payment_count,
            'message', 'Customer created successfully with ' || payment_count || ' payment records'
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) TO authenticated;

-- Remove the email availability check function since we don't need it anymore
DROP FUNCTION IF EXISTS check_email_availability(TEXT);

SELECT 'DUPLICATE_EMAILS_ALLOWED' as status,
       'Users can now use the same email for informational purposes' as message;
