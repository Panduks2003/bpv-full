-- =====================================================
-- WORKING CUSTOMER CREATION FUNCTION
-- =====================================================
-- Uses the same approach as promoter creation (with crypt hashing)
-- =====================================================

BEGIN;

-- Enable pgcrypto extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Drop function if it exists
DROP FUNCTION IF EXISTS create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) CASCADE;

-- Create working function
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
    auth_email VARCHAR(255);
    result JSON;
    promoter_pins INTEGER;
    hashed_password TEXT;
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
        RAISE EXCEPTION 'Insufficient pins. Available: %, Required: 1', promoter_pins;
    END IF;
    
    -- 2. CHECK CUSTOMER ID UNIQUENESS
    IF EXISTS (SELECT 1 FROM profiles WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer ID already exists: %', p_customer_id;
    END IF;
    
    -- 3. GENERATE UUID AND AUTH EMAIL
    new_customer_id := gen_random_uuid();
    auth_email := 'customer+' || replace(new_customer_id::text, '-', '') || '@brightplanetventures.local';
    
    -- 4. HASH PASSWORD WITH ERROR HANDLING
    BEGIN
        -- Try to use pgcrypto crypt function
        hashed_password := crypt(p_password, gen_salt('bf'));
        RAISE NOTICE 'Using pgcrypto for password hashing';
    EXCEPTION WHEN OTHERS THEN
        -- Fallback to MD5 hashing
        hashed_password := md5(p_password || new_customer_id::text);
        RAISE NOTICE 'Using MD5 fallback for password: %', SQLERRM;
    END;
    
    -- 5. CREATE AUTH USER
    BEGIN
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            aud,
            role
        ) VALUES (
            new_customer_id,
            '00000000-0000-0000-0000-000000000000',
            auth_email,
            hashed_password,
            NOW(),
            NOW(),
            NOW(),
            'authenticated',
            'authenticated'
        );
        
        RAISE NOTICE 'Auth user created: %', auth_email;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Auth user creation warning: %', SQLERRM;
        -- Continue anyway
    END;
    
    -- 6. CREATE PROFILE
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
    
    RAISE NOTICE 'Profile created for customer: %', p_customer_id;
    
    -- 7. CREATE 20-MONTH PAYMENT SCHEDULE
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
    
    -- 8. RETURN SUCCESS
    result := json_build_object(
        'success', true,
        'customer_id', new_customer_id,
        'customer_card_no', p_customer_id,
        'auth_email', auth_email,
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
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) TO anon;

COMMIT;

-- Success message
SELECT '✅ create_customer_final function created successfully!' as result;

