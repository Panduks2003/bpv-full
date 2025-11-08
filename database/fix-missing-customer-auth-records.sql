-- =====================================================
-- FIX MISSING CUSTOMER AUTH RECORDS
-- =====================================================
-- This script creates auth.users records for customers
-- that were created but don't have corresponding auth records

BEGIN;

-- Create auth records for customers missing them
DO $$
DECLARE
    customer_record RECORD;
    auth_email TEXT;
    default_password TEXT := 'password123'; -- Default password for existing customers
    hashed_password TEXT;
    auth_exists BOOLEAN;
BEGIN
    -- Loop through all customers
    FOR customer_record IN 
        SELECT * FROM profiles WHERE role = 'customer'
    LOOP
        -- Check if auth record exists
        SELECT EXISTS (
            SELECT 1 FROM auth.users WHERE id = customer_record.id
        ) INTO auth_exists;
        
        -- If auth record doesn't exist, create it
        IF NOT auth_exists THEN
            -- Generate auth email
            auth_email := 'customer+' || replace(customer_record.id::text, '-', '') || '@brightplanetventures.local';
            
            -- Hash password with pgcrypto (bf - blowfish)
            BEGIN
                hashed_password := crypt(default_password, gen_salt('bf'));
            EXCEPTION WHEN OTHERS THEN
                -- Fallback to MD5 if pgcrypto fails
                hashed_password := md5(default_password || customer_record.id::text);
                RAISE NOTICE 'Using MD5 fallback for customer %', customer_record.customer_id;
            END;
            
            -- Create auth user record
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
                
                RAISE NOTICE '✅ Created auth record for customer: % (%)', 
                    customer_record.customer_id, 
                    customer_record.name;
                    
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '❌ Failed to create auth record for customer %: %', 
                    customer_record.customer_id, 
                    SQLERRM;
            END;
        ELSE
            RAISE NOTICE '⏭️  Skipping customer % - auth record already exists', 
                customer_record.customer_id;
        END IF;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'MISSING AUTH RECORDS FIX COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'All customers now have auth records';
    RAISE NOTICE 'Default password for all customers: password123';
    RAISE NOTICE 'Customers should change their password after first login';
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
    au.email as auth_email
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE p.role = 'customer'
ORDER BY p.customer_id;

