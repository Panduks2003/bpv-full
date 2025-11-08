-- =====================================================
-- RESET CUSTOMER PASSWORD
-- =====================================================
-- Resets password for a customer to allow login
-- =====================================================

-- Reset password for BPC004 (Test Customer) to "password123"
DO $$
DECLARE
    customer_auth_id UUID;
    new_password TEXT := 'password123';
    hashed_password TEXT;
    salt_value TEXT;
BEGIN
    -- Get the auth user ID for customer BPC004
    SELECT id INTO customer_auth_id
    FROM profiles
    WHERE customer_id = 'BPC004' AND role = 'customer';
    
    IF customer_auth_id IS NULL THEN
        RAISE EXCEPTION 'Customer BPC004 not found';
    END IF;
    
    -- Hash the password using pgcrypto
    BEGIN
        salt_value := gen_salt('bf');
        hashed_password := crypt(new_password, salt_value);
        RAISE NOTICE 'Using pgcrypto for password hashing';
    EXCEPTION WHEN OTHERS THEN
        -- Fallback to MD5 if pgcrypto fails
        hashed_password := md5(new_password || 'brightplanet_default_salt');
        RAISE NOTICE 'Using MD5 fallback hashing';
    END;
    
    -- Update the password in auth.users
    UPDATE auth.users
    SET encrypted_password = hashed_password,
        updated_at = NOW()
    WHERE id = customer_auth_id;
    
    RAISE NOTICE '✅ Password reset successful for BPC004';
    RAISE NOTICE '📋 Customer ID: BPC004';
    RAISE NOTICE '🔑 New Password: password123';
    
END $$;

-- Verify the customer can be found
SELECT 
    '✅ CUSTOMER INFO' as status,
    customer_id,
    name,
    phone,
    email,
    id as auth_user_id
FROM profiles
WHERE customer_id = 'BPC004';

-- Show login instructions
SELECT 
    '📋 LOGIN INSTRUCTIONS' as info,
    'Customer ID: BPC004' as username,
    'Password: password123' as password,
    'Use Customer ID login method' as method;
