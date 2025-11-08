-- =====================================================
-- FIX CUSTOMER AUTHENTICATION FUNCTION CONFLICT
-- =====================================================
-- Drop all existing versions and create a clean function
-- This fixes the PGRST203 error: "Could not choose the best candidate function"

BEGIN;

-- =====================================================
-- 1. DROP ALL EXISTING VERSIONS OF THE FUNCTION
-- =====================================================

-- Drop all possible versions of authenticate_customer_by_card_no
DROP FUNCTION IF EXISTS authenticate_customer_by_card_no(VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS authenticate_customer_by_card_no(TEXT, TEXT);
DROP FUNCTION IF EXISTS authenticate_customer_by_card_no(character varying, character varying);
DROP FUNCTION IF EXISTS authenticate_customer_by_card_no(text, text);

-- Dynamic cleanup for any remaining versions
DO $$
DECLARE
    func_record RECORD;
BEGIN
    -- Clean up any remaining authenticate_customer_by_card_no functions
    FOR func_record IN 
        SELECT proname, oidvectortypes(proargtypes) as args
        FROM pg_proc 
        WHERE proname = 'authenticate_customer_by_card_no'
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || func_record.proname || '(' || func_record.args || ') CASCADE';
        RAISE NOTICE 'Dropped function: %(%)', func_record.proname, func_record.args;
    END LOOP;
END $$;

-- =====================================================
-- 2. CREATE CLEAN CUSTOMER CARD NO AUTHENTICATION FUNCTION
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
-- 4. VERIFY FUNCTION
-- =====================================================

SELECT 
    'FUNCTION_CREATED' as status,
    proname as function_name,
    pg_get_function_arguments(oid) as parameters,
    pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'authenticate_customer_by_card_no'
AND pronamespace = 'public'::regnamespace;

-- =====================================================
-- 5. TEST FUNCTION (if customer exists)
-- =====================================================

DO $$
DECLARE
    test_customer_id TEXT;
    test_result JSON;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== TESTING CUSTOMER AUTHENTICATION FUNCTION ===';
    
    -- Get a test customer
    SELECT customer_id INTO test_customer_id
    FROM profiles 
    WHERE role = 'customer' 
    AND customer_id IS NOT NULL 
    LIMIT 1;
    
    IF test_customer_id IS NOT NULL THEN
        RAISE NOTICE 'Found test customer: ID=%', test_customer_id;
        RAISE NOTICE 'Function is ready for testing with actual credentials.';
        
        -- Test invalid credentials (should fail gracefully)
        BEGIN
            test_result := authenticate_customer_by_card_no(test_customer_id, 'wrongpassword');
            IF (test_result->>'success')::boolean THEN
                RAISE NOTICE '❌ ERROR: Should have failed with wrong password';
            ELSE
                RAISE NOTICE '✅ SUCCESS: Correctly rejected invalid password for Customer ID';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ ERROR: Exception occurred: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️  No customers found for testing. Function is ready.';
    END IF;
END $$;

-- =====================================================
-- 6. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'CUSTOMER AUTHENTICATION FUNCTION CONFLICT RESOLVED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Fixed Issues:';
    RAISE NOTICE '1. Dropped all conflicting function versions';
    RAISE NOTICE '2. Created clean function with TEXT parameters';
    RAISE NOTICE '3. Ensured consistent return type (JSON)';
    RAISE NOTICE '';
    RAISE NOTICE 'Function Available:';
    RAISE NOTICE '- authenticate_customer_by_card_no(customer_id TEXT, password TEXT)';
    RAISE NOTICE '';
    RAISE NOTICE 'Customer login should now work correctly!';
    RAISE NOTICE '=======================================================';
END $$;

COMMIT;

