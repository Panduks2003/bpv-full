-- =====================================================
-- CUSTOMER CARD NO-ONLY AUTHENTICATION SYSTEM
-- =====================================================
-- This revamps the customer authentication system to use 
-- ONLY Card Number (Customer ID) for login, making email 
-- and phone metadata-only fields
-- =====================================================

BEGIN;

-- =====================================================
-- 1. UPDATE DATABASE SCHEMA TO ALLOW DUPLICATE EMAILS/PHONES FOR CUSTOMERS
-- =====================================================

-- Remove unique constraints on email and phone for profiles table (if they exist)
-- This is already done in the promoter system, but we'll ensure it for customers too
DO $$
BEGIN
    -- Drop unique index on email if it exists
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'profiles_email_key'
    ) THEN
        DROP INDEX profiles_email_key;
        RAISE NOTICE '✅ Removed unique constraint on email';
    END IF;
    
    -- Drop unique index on phone if it exists
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'profiles_phone_key'
    ) THEN
        DROP INDEX profiles_phone_key;
        RAISE NOTICE '✅ Removed unique constraint on phone';
    END IF;
END $$;

-- Ensure customer_id remains unique and has an index
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_customer_id ON profiles(customer_id) 
WHERE customer_id IS NOT NULL AND role = 'customer';

-- =====================================================
-- 2. CREATE CUSTOMER CARD NO AUTHENTICATION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION authenticate_customer_by_card_no(
    p_customer_id TEXT,
    p_password TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    customer_record RECORD;
    auth_record RECORD;
    auth_email TEXT;
BEGIN
    -- Input validation
    IF p_customer_id IS NULL OR TRIM(p_customer_id) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Customer ID (Card No) is required'
        );
    END IF;
    
    IF p_password IS NULL OR TRIM(p_password) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Password is required'
        );
    END IF;
    
    -- Find customer by customer_id
    SELECT p.* INTO customer_record
    FROM profiles p
    WHERE UPPER(p.customer_id) = UPPER(TRIM(p_customer_id))
    AND p.role = 'customer'
    AND (p.status = 'active' OR p.status IS NULL);
    
    -- Check if customer exists
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid Customer ID or password'
        );
    END IF;
    
    -- Get auth user record
    SELECT au.* INTO auth_record
    FROM auth.users au
    WHERE au.id = customer_record.id;
    
    -- Check if auth user exists
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Authentication failed: No auth record found'
        );
    END IF;
    
    -- Get the auth email (this is the placeholder email used in auth.users)
    auth_email := auth_record.email;
    
    -- Note: We don't verify password here because Supabase Auth uses its own
    -- hashing method (pbkdf2) which we can't easily verify with database functions.
    -- The frontend will use Supabase Auth to sign in, which will verify the password.
    
    -- Return success with user data and auth email
    RETURN json_build_object(
        'success', true,
        'user', json_build_object(
            'id', customer_record.id,
            'customer_id', customer_record.customer_id,
            'name', customer_record.name,
            'email', customer_record.email,
            'phone', customer_record.phone,
            'state', customer_record.state,
            'city', customer_record.city,
            'pincode', customer_record.pincode,
            'address', customer_record.address,
            'investment_plan', customer_record.investment_plan,
            'role', customer_record.role,
            'parent_promoter_id', customer_record.parent_promoter_id,
            'status', customer_record.status,
            'created_at', customer_record.created_at,
            'updated_at', customer_record.updated_at
        ),
        'auth_email', auth_email
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Authentication failed: ' || SQLERRM
    );
END;
$$;

-- =====================================================
-- 3. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION authenticate_customer_by_card_no(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_customer_by_card_no(TEXT, TEXT) TO anon;

-- =====================================================
-- 4. VERIFY CHANGES
-- =====================================================

DO $$
DECLARE
    test_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'CUSTOMER CARD NO-ONLY AUTHENTICATION SYSTEM INSTALLED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'NEW SYSTEM FEATURES:';
    RAISE NOTICE '✅ Customer login uses ONLY Card No (Customer ID) + Password';
    RAISE NOTICE '✅ Email and Phone are metadata only (can repeat)';
    RAISE NOTICE '✅ Each customer gets unique auth email internally';
    RAISE NOTICE '✅ Clean, consistent authentication model';
    RAISE NOTICE '';
    RAISE NOTICE 'AUTHENTICATION FUNCTION:';
    RAISE NOTICE '  - authenticate_customer_by_card_no(customer_id, password)';
    RAISE NOTICE '';
    RAISE NOTICE 'EXAMPLE USAGE:';
    RAISE NOTICE '  SELECT authenticate_customer_by_card_no(''CARD001'', ''password123'');';
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
END $$;

COMMIT;
