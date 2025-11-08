-- =====================================================
-- COMPLETE DATABASE COLUMN FIX
-- =====================================================
-- This script fixes the investment_plan vs saving_plan column issue
-- and ensures all customer creation works properly
-- =====================================================

-- Step 1: Check current column name in profiles table
SELECT 'CURRENT_COLUMNS' as check_type,
       column_name,
       data_type,
       is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' 
  AND column_name IN ('investment_plan', 'saving_plan')
ORDER BY column_name;

-- Step 2: If saving_plan doesn't exist, rename investment_plan to saving_plan
DO $$
BEGIN
    -- Check if saving_plan column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'saving_plan'
    ) THEN
        -- Check if investment_plan exists
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'profiles' AND column_name = 'investment_plan'
        ) THEN
            -- Rename investment_plan to saving_plan
            ALTER TABLE profiles RENAME COLUMN investment_plan TO saving_plan;
            RAISE NOTICE 'Renamed investment_plan to saving_plan';
        ELSE
            -- Create saving_plan column if neither exists
            ALTER TABLE profiles ADD COLUMN saving_plan VARCHAR(255) DEFAULT '₹1000 per month for 20 months';
            RAISE NOTICE 'Created new saving_plan column';
        END IF;
    ELSE
        RAISE NOTICE 'saving_plan column already exists';
    END IF;
END $$;

-- Step 3: Update the create_customer_final function with correct column name
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
        
        -- 2. GENERATE EMAIL AND PASSWORD
        auth_email := COALESCE(p_email, p_customer_id || '@brightplanetventures.local');
        
        -- Generate salt and hash password
        salt_value := gen_salt('bf');
        hashed_password := crypt(p_password, salt_value);
        
        -- 3. CREATE AUTH USER
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
            RAISE EXCEPTION 'Failed to create auth user: %', SQLERRM;
        END;
        
        -- 4. CREATE PROFILE (using saving_plan column)
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
        
        -- 5. CREATE 20-MONTH PAYMENT SCHEDULE WITH EXPLICIT ERROR HANDLING
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

-- Step 4: Fix the missing payment schedule for the current customer
INSERT INTO customer_payments (
    customer_id,
    month_number,
    payment_amount,
    status,
    created_at,
    updated_at
)
SELECT 
    '8c0c436f-96ce-4550-8de3-d622398c5d21',
    generate_series(1, 20),
    1000.00,
    'pending',
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM customer_payments 
    WHERE customer_id = '8c0c436f-96ce-4550-8de3-d622398c5d21'
);

-- Step 5: Verification
SELECT 'VERIFICATION' as check_type,
       'Column renamed and function updated' as status;

-- Check the column exists
SELECT 'COLUMN_CHECK' as check_type,
       column_name,
       data_type
FROM information_schema.columns 
WHERE table_name = 'profiles' 
  AND column_name = 'saving_plan';

-- Check payment count for the customer
SELECT 'PAYMENT_CHECK' as check_type,
       COUNT(*) as payment_count,
       'Expected: 20' as expected
FROM customer_payments 
WHERE customer_id = '8c0c436f-96ce-4550-8de3-d622398c5d21';

SELECT 'COMPLETE_FIX_APPLIED' as status;
