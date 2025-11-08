-- =====================================================
-- FIX EMAIL DUPLICATE ISSUE IN CUSTOMER CREATION
-- =====================================================
-- This script fixes the duplicate email constraint issue
-- by generating unique emails for each customer
-- =====================================================

BEGIN;

-- Drop existing function
DROP FUNCTION IF EXISTS create_customer_with_pin_deduction(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT) CASCADE;

-- Create improved customer creation function with unique email generation
CREATE OR REPLACE FUNCTION create_customer_with_pin_deduction(
    p_name TEXT,
    p_mobile TEXT,
    p_state TEXT,
    p_city TEXT,
    p_pincode TEXT,
    p_address TEXT,
    p_customer_id TEXT,
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
    auth_email TEXT;
    result JSON;
    promoter_pins INTEGER;
    hashed_password TEXT;
    salt_value TEXT;
    payment_count INTEGER;
    existing_customer_count INTEGER;
    email_suffix INTEGER := 1;
    base_email TEXT;
    email_exists BOOLEAN := TRUE;
BEGIN
    -- Start transaction
    BEGIN
        
        -- 1. INPUT VALIDATION
        IF p_name IS NULL OR TRIM(p_name) = '' THEN
            RAISE EXCEPTION 'Customer name is required';
        END IF;
        
        IF p_mobile IS NULL OR TRIM(p_mobile) = '' THEN
            RAISE EXCEPTION 'Mobile number is required';
        END IF;
        
        IF p_customer_id IS NULL OR TRIM(p_customer_id) = '' THEN
            RAISE EXCEPTION 'Customer ID is required';
        END IF;
        
        IF p_password IS NULL OR TRIM(p_password) = '' THEN
            RAISE EXCEPTION 'Password is required';
        END IF;
        
        -- Normalize customer ID
        p_customer_id := UPPER(TRIM(p_customer_id));
        
        -- 2. CHECK FOR DUPLICATE CUSTOMER ID
        SELECT COUNT(*) INTO existing_customer_count 
        FROM profiles 
        WHERE customer_id = p_customer_id;
        
        IF existing_customer_count > 0 THEN
            RAISE EXCEPTION 'Customer ID "%" already exists. Please choose a different Customer ID.', p_customer_id;
        END IF;
        
        -- 3. CHECK PROMOTER HAS ENOUGH PINS
        SELECT pins INTO promoter_pins
        FROM profiles
        WHERE id = p_parent_promoter_id AND role = 'promoter'
        FOR UPDATE;
        
        IF promoter_pins IS NULL THEN
            RAISE EXCEPTION 'Promoter not found or invalid promoter ID';
        END IF;
        
        IF promoter_pins < 1 THEN
            RAISE EXCEPTION 'Insufficient pins. Promoter has % pins, but 1 is required to create a customer', promoter_pins;
        END IF;
        
        -- 4. GENERATE UNIQUE EMAIL
        IF p_email IS NOT NULL AND TRIM(p_email) != '' THEN
            -- Use provided email but check if it exists
            SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = TRIM(p_email)) INTO email_exists;
            IF email_exists THEN
                -- If provided email exists, generate a unique one based on customer ID
                base_email := LOWER(p_customer_id) || '@brightplanetventures.local';
            ELSE
                base_email := TRIM(p_email);
                email_exists := FALSE;
            END IF;
        ELSE
            -- Generate email based on customer ID
            base_email := LOWER(p_customer_id) || '@brightplanetventures.local';
        END IF;
        
        -- Ensure email is unique by adding suffix if needed
        auth_email := base_email;
        WHILE email_exists LOOP
            SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = auth_email) INTO email_exists;
            IF email_exists THEN
                auth_email := LOWER(p_customer_id) || email_suffix || '@brightplanetventures.local';
                email_suffix := email_suffix + 1;
            END IF;
            -- Safety break to prevent infinite loop
            IF email_suffix > 1000 THEN
                auth_email := LOWER(p_customer_id) || extract(epoch from now())::bigint || '@brightplanetventures.local';
                EXIT;
            END IF;
        END LOOP;
        
        -- Generate salt and hash password
        salt_value := gen_salt('bf');
        hashed_password := crypt(p_password, salt_value);
        
        -- 5. CREATE AUTH USER WITH UNIQUE EMAIL
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
            RAISE EXCEPTION 'Failed to create authentication user: %', SQLERRM;
        END;
        
        -- 6. CREATE PROFILE (using saving_plan column)
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
            TRIM(p_name),
            auth_email,  -- Use the unique email we generated
            TRIM(p_mobile),
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
        
        -- 7. DEDUCT PIN FROM PROMOTER
        UPDATE profiles 
        SET pins = pins - 1,
            updated_at = NOW()
        WHERE id = p_parent_promoter_id;
        
        -- Get remaining pins for response
        SELECT pins INTO promoter_pins
        FROM profiles
        WHERE id = p_parent_promoter_id;
        
        -- 8. CREATE 20-MONTH PAYMENT SCHEDULE
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
        
        -- 9. LOG PIN USAGE (if table exists)
        BEGIN
            INSERT INTO pin_usage_log (
                promoter_id,
                pins_used,
                action_type,
                description,
                created_at
            ) VALUES (
                p_parent_promoter_id,
                1,
                'customer_creation',
                'Pin deducted for creating customer: ' || p_customer_id,
                NOW()
            );
        EXCEPTION WHEN OTHERS THEN
            -- Ignore if pin_usage_log table doesn't exist
            NULL;
        END;
        
        -- Return success result
        result := json_build_object(
            'success', true,
            'customer_id', new_customer_id,
            'customer_card_no', p_customer_id,
            'auth_user_id', auth_user_id,
            'payment_count', payment_count,
            'pins_remaining', promoter_pins,
            'email_used', auth_email,
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
GRANT EXECUTE ON FUNCTION create_customer_with_pin_deduction(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_customer_with_pin_deduction(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION create_customer_with_pin_deduction(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, TEXT) TO postgres;

COMMIT;
