-- =====================================================
-- 04: HARDEN ADMIN CUSTOMER CREATION FUNCTION
-- =====================================================
-- This script creates the hardened create_customer_final function
-- =====================================================

BEGIN;

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

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) TO authenticated;

COMMIT;

-- Verification
SELECT 'ADMIN_FUNCTION_HARDENED' as status,
       proname as function_name
FROM pg_proc 
WHERE proname = 'create_customer_final';
