-- =====================================================
-- FIX CUSTOMER AUTHENTICATION TO VERIFY PASSWORDS
-- =====================================================
-- The current function doesn't verify passwords at all!
-- This script updates it to properly verify passwords using pgcrypto

BEGIN;

-- Enable pgcrypto extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Drop existing function
DROP FUNCTION IF EXISTS authenticate_customer_by_card_no(TEXT, TEXT);

-- =====================================================
-- CREATE FUNCTION WITH PASSWORD VERIFICATION
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
    password_valid BOOLEAN;
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
    
    -- =====================================================
    -- VERIFY PASSWORD
    -- =====================================================
    
    -- Try to verify password using pgcrypto crypt function
    BEGIN
        password_valid := (auth_record.encrypted_password = crypt(p_password, auth_record.encrypted_password));
        
        IF NOT password_valid THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Invalid Customer ID or password'
            );
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        -- If password verification fails, reject the login
        RAISE NOTICE 'Password verification error: %', SQLERRM;
        RETURN json_build_object(
            'success', false,
            'error', 'Authentication failed: Password verification error'
        );
    END;
    
    -- =====================================================
    -- RETURN SUCCESS WITH USER DATA
    -- =====================================================
    
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION authenticate_customer_by_card_no(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION authenticate_customer_by_card_no(TEXT, TEXT) TO anon;

COMMIT;

-- Success message
SELECT '✅ Customer authentication function updated with password verification!' as result;

