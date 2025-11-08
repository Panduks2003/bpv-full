-- =====================================================
-- FIX NULL CUSTOMER ID IN COMMISSION FUNCTION
-- =====================================================
-- This script updates the distribute_affiliate_commission function
-- to properly validate customer_id and prevent null values
-- =====================================================

-- Update the commission distribution function with proper validation
CREATE OR REPLACE FUNCTION distribute_affiliate_commission(
    p_customer_id UUID,
    p_initiator_promoter_id UUID
) RETURNS JSON AS $$
DECLARE
    v_commission_levels DECIMAL[] := ARRAY[500.00, 100.00, 100.00, 100.00];
    v_current_promoter_id UUID := p_initiator_promoter_id;
    v_level INTEGER;
    v_recipient_id UUID;
    v_amount DECIMAL(10,2);
    v_transaction_id VARCHAR(50);
    v_admin_id UUID;
    v_remaining_amount DECIMAL(10,2) := 0.00;
    v_result JSON;
    v_distributed_count INTEGER := 0;
    v_total_distributed DECIMAL(10,2) := 0.00;
    v_customer_exists BOOLEAN;
BEGIN
    -- Input validation - CRITICAL FIX
    IF p_customer_id IS NULL OR p_customer_id = '' THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Customer ID cannot be null or empty',
            'code', 'NULL_CUSTOMER_ID'
        );
    END IF;
    
    -- Verify customer exists
    SELECT EXISTS(
        SELECT 1 FROM profiles 
        WHERE id = p_customer_id AND role = 'customer'
    ) INTO v_customer_exists;
    
    IF NOT v_customer_exists THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Customer does not exist with ID: ' || p_customer_id::text,
            'code', 'CUSTOMER_NOT_FOUND'
        );
    END IF;
    
    -- Get admin ID for fallback
    SELECT id INTO v_admin_id 
    FROM profiles 
    WHERE role = 'admin' 
    LIMIT 1;
    
    -- Start transaction
    BEGIN
        -- Loop through 4 commission levels
        FOR v_level IN 1..4 LOOP
            v_amount := v_commission_levels[v_level];
            
            -- Find parent promoter for current level
            IF v_level = 1 THEN
                v_recipient_id := v_current_promoter_id;
            ELSE
                SELECT parent_promoter_id INTO v_recipient_id
                FROM profiles
                WHERE id = v_current_promoter_id
                AND parent_promoter_id IS NOT NULL;
            END IF;
            
            -- Generate unique transaction ID
            v_transaction_id := 'COMM-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || v_level;
            
            IF v_recipient_id IS NOT NULL THEN
                -- Credit commission to promoter
                INSERT INTO affiliate_commissions (
                    customer_id,
                    initiator_promoter_id,
                    recipient_id,
                    recipient_type,
                    level,
                    amount,
                    status,
                    transaction_id,
                    note
                ) VALUES (
                    p_customer_id,  -- This is now guaranteed to be non-null
                    p_initiator_promoter_id,
                    v_recipient_id,
                    'promoter',
                    v_level,
                    v_amount,
                    'credited',
                    v_transaction_id,
                    'Level ' || v_level || ' Commission - ₹' || v_amount
                );
                
                -- Update promoter wallet
                INSERT INTO promoter_wallet (promoter_id, balance, total_earned, commission_count, last_commission_at)
                VALUES (v_recipient_id, v_amount, v_amount, 1, NOW())
                ON CONFLICT (promoter_id) DO UPDATE SET
                    balance = promoter_wallet.balance + v_amount,
                    total_earned = promoter_wallet.total_earned + v_amount,
                    commission_count = promoter_wallet.commission_count + 1,
                    last_commission_at = NOW(),
                    updated_at = NOW();
                
                v_distributed_count := v_distributed_count + 1;
                v_total_distributed := v_total_distributed + v_amount;
                
                -- Move to next level
                v_current_promoter_id := v_recipient_id;
            ELSE
                -- No promoter at this level, add to admin fallback
                v_remaining_amount := v_remaining_amount + v_amount;
            END IF;
        END LOOP;
        
        -- Credit remaining amount to admin if any
        IF v_remaining_amount > 0 AND v_admin_id IS NOT NULL THEN
            v_transaction_id := 'COMM-ADMIN-' || EXTRACT(EPOCH FROM NOW())::BIGINT;
            
            INSERT INTO affiliate_commissions (
                customer_id,
                initiator_promoter_id,
                recipient_id,
                recipient_type,
                level,
                amount,
                status,
                transaction_id,
                note
            ) VALUES (
                p_customer_id,  -- This is now guaranteed to be non-null
                p_initiator_promoter_id,
                v_admin_id,
                'admin',
                0,
                v_remaining_amount,
                'credited',
                v_transaction_id,
                'Admin Fallback Commission - ₹' || v_remaining_amount
            );
            
            v_distributed_count := v_distributed_count + 1;
            v_total_distributed := v_total_distributed + v_remaining_amount;
        END IF;
        
        -- Return success result
        RETURN json_build_object(
            'success', true,
            'distributed_count', v_distributed_count,
            'total_amount', v_total_distributed,
            'customer_id', p_customer_id,
            'message', 'Commission distributed successfully'
        );
        
    EXCEPTION WHEN OTHERS THEN
        -- Return error result
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'customer_id', p_customer_id,
            'code', 'DB_ERROR'
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO service_role;

-- Update the create_customer_final function to ensure it returns customer_id properly
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
    -- Generate UUID for new customer
    new_customer_id := gen_random_uuid();
    
    -- Check promoter has enough pins
    SELECT pins INTO promoter_pins
    FROM profiles
    WHERE id = p_parent_promoter_id AND role = 'promoter'
    FOR UPDATE;
    
    IF promoter_pins IS NULL THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Promoter not found'
        );
    END IF;
    
    IF promoter_pins < 1 THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Insufficient pins to create customer'
        );
    END IF;
    
    -- Hash password
    BEGIN
        salt_value := gen_salt('bf');
        hashed_password := crypt(p_password, salt_value);
    EXCEPTION WHEN OTHERS THEN
        hashed_password := md5(p_password || 'brightplanet_salt');
    END;
    
    -- Create customer profile with safe customer_id
    INSERT INTO profiles (
        id,
        name,
        mobile,
        state,
        city,
        pincode,
        address,
        customer_id,
        role,
        status,
        parent_promoter_id,
        email,
        password
    ) VALUES (
        new_customer_id,
        p_name,
        p_mobile,
        p_state,
        p_city,
        p_pincode,
        p_address,
        COALESCE(NULLIF(p_customer_id, ''), 'CUST-' || new_customer_id::text), -- Generate customer_id if empty
        'customer',
        'active',
        p_parent_promoter_id,
        p_email,
        hashed_password
    );
    
    -- Deduct pin from promoter
    UPDATE profiles
    SET pins = pins - 1
    WHERE id = p_parent_promoter_id;
    
    -- CRITICAL FIX: Always include customer_id in the result
    RETURN json_build_object(
        'success', true, 
        'customer_id', new_customer_id, 
        'message', 'Customer created successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false, 
        'error', SQLERRM
    );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_customer_final(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, UUID, TEXT) TO anon;