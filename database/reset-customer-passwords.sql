-- =====================================================
-- RESET CUSTOMER PASSWORDS TO WORKING VERSION
-- =====================================================
-- This script resets all customer passwords to "password123"
-- and creates auth records for any missing customers

BEGIN;

-- Enable pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
    customer_record RECORD;
    auth_email TEXT;
    hashed_password TEXT;
    default_password TEXT := 'password123';
    auth_exists BOOLEAN;
    update_count INTEGER := 0;
    create_count INTEGER := 0;
BEGIN
    -- Loop through all customers
    FOR customer_record IN 
        SELECT * FROM profiles WHERE role = 'customer'
    LOOP
        -- Check if auth record exists
        SELECT EXISTS (
            SELECT 1 FROM auth.users WHERE id = customer_record.id
        ) INTO auth_exists;
        
        -- Generate auth email
        auth_email := 'customer+' || replace(customer_record.id::text, '-', '') || '@brightplanetventures.local';
        
        -- Hash password with pgcrypto crypt (bf - blowfish)
        hashed_password := crypt(default_password, gen_salt('bf'));
        
        IF auth_exists THEN
            -- Update existing auth record with new password
            UPDATE auth.users
            SET encrypted_password = hashed_password,
                updated_at = NOW()
            WHERE id = customer_record.id;
            
            update_count := update_count + 1;
            RAISE NOTICE '✅ Updated password for customer: % (%)', 
                customer_record.customer_id, 
                customer_record.name;
                
        ELSE
            -- Create new auth record
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
                    customer_record.id,
                    '00000000-0000-0000-0000-000000000000',
                    auth_email,
                    hashed_password,
                    NOW(),
                    NOW(),
                    NOW(),
                    'authenticated',
                    'authenticated'
                );
                
                create_count := create_count + 1;
                RAISE NOTICE '✅ Created auth record for customer: % (%)', 
                    customer_record.customer_id, 
                    customer_record.name;
                    
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '❌ Failed to create auth record for customer %: %', 
                    customer_record.customer_id, 
                    SQLERRM;
            END;
        END IF;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'CUSTOMER PASSWORD RESET COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Updated % customers', update_count;
    RAISE NOTICE 'Created % new auth records', create_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Default password for all customers: password123';
    RAISE NOTICE 'All passwords are now hashed with pgcrypto crypt (bf)';
    RAISE NOTICE '=======================================================';
END $$;

COMMIT;

-- Verification query
SELECT 
    'VERIFICATION' as check_type,
    p.customer_id,
    p.name,
    CASE 
        WHEN au.id IS NOT NULL THEN '✅ Has auth record'
        ELSE '❌ Missing auth record'
    END as auth_status,
    CASE 
        WHEN au.encrypted_password IS NOT NULL 
        AND au.encrypted_password LIKE '$2%' THEN '✅ bcrypt hash'
        ELSE '⚠️  Unknown hash format'
    END as password_format
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'customer'
ORDER BY p.customer_id;

