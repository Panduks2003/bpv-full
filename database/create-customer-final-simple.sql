-- =====================================================
-- CREATE CUSTOMER FINAL FUNCTION (SIMPLIFIED VERSION)
-- =====================================================
-- This creates customers using Supabase Auth properly
-- =====================================================

-- Drop function if it exists
DROP FUNCTION IF EXISTS Suitable create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) CASCADE;

-- Create the simplified function
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
BEGIN
    -- 1. CHECK PROMOTER HAS ENOUGH PINS
    SELECT pins INTO promoter_pins
    FROM profiles
    WHERE id = p_parent_promoter_id AND role = 'promoter';
    
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
    
    -- 3. GENERATE UNIQUE AUTH EMAIL
    auth_email := 'customer+' || replace(gen_random_uuid()::text, '-', '') || '@brightplanetventures.local';
    
    -- 4. CREATE AUTH USER USING SUPABASE ADMIN FUNCTION
    -- Note: This requires using the Supabase Auth admin API from the frontend
    -- For now, we'll skip auth user creation and return the customer ID
    -- The frontend should use Supabase Admin API to create the auth user
    
    -- 5. GENERATE NEW UUID FOR CUSTOMER
    new_customer_id := gen_random_uuid();
    
    -- 6. CREATE PROFILE ONLY (without auth user for now)
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
    
    -- 8. RETURN SUCCESS (frontend will handle auth user creation)
    result := json_build_object(
        'success', true,
        'customer_id', new_customer_id,
        'customer_card_no', p_customer_id,
        'auth_email', auth_email,
        'password', p_password, -- Return password for frontend to use with Supabase Admin API
        'message', 'Customer created successfully. Use Supabase Admin API to create auth user.'
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

-- Success message
SELECT '✅ create_customer_final function created successfully!' as result;

