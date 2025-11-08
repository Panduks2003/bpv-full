-- =====================================================
-- FIX BPC004 AUTH USER ID
-- =====================================================
-- The customer has a placeholder ID, need to create proper auth user
-- =====================================================

-- Check current status
SELECT 
    '🔍 CURRENT STATUS' as check_type,
    p.customer_id,
    p.name,
    p.id as profile_id,
    au.id as auth_id,
    CASE 
        WHEN p.id = '00000000-0000-0000-0000-000000000003' THEN '❌ Placeholder ID'
        WHEN au.id IS NULL THEN '❌ No auth user'
        WHEN p.id = au.id THEN '✅ Properly linked'
        ELSE '⚠️ Mismatch'
    END as status
FROM profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE p.customer_id = 'BPC004';

-- Fix: Create proper auth user and update profile
DO $$
DECLARE
    old_profile_id UUID := '00000000-0000-0000-0000-000000000003';
    new_auth_id UUID;
    customer_email TEXT;
    hashed_password TEXT;
    salt_value TEXT;
BEGIN
    -- Check if this is the problematic customer
    IF EXISTS (SELECT 1 FROM profiles WHERE id = old_profile_id AND customer_id = 'BPC004') THEN
        
        -- Generate unique email for auth user
        customer_email := 'customer+bpc004@brightplanetventures.local';
        
        -- Hash password
        BEGIN
            salt_value := gen_salt('bf');
            hashed_password := crypt('password123', salt_value);
        EXCEPTION WHEN OTHERS THEN
            hashed_password := md5('password123' || 'brightplanet_default_salt');
        END;
        
        -- Create new auth user
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            recovery_sent_at,
            last_sign_in_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            email_change,
            email_change_token_new,
            recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            customer_email,
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
        ) RETURNING id INTO new_auth_id;
        
        -- Update profile to use new auth ID
        UPDATE profiles
        SET id = new_auth_id,
            email = customer_email,
            updated_at = NOW()
        WHERE id = old_profile_id;
        
        -- Update customer_payments references
        UPDATE customer_payments
        SET customer_id = new_auth_id
        WHERE customer_id = old_profile_id;
        
        RAISE NOTICE '✅ Fixed BPC004: Old ID: %, New ID: %', old_profile_id, new_auth_id;
        
    ELSE
        RAISE NOTICE '✅ BPC004 already has proper auth user';
    END IF;
END $$;

-- Verify fix
SELECT 
    '✅ AFTER FIX' as check_type,
    p.customer_id,
    p.name,
    p.id as profile_id,
    au.id as auth_id,
    p.email,
    CASE 
        WHEN p.id = au.id THEN '✅ Properly linked'
        ELSE '❌ Still broken'
    END as status
FROM profiles p
JOIN auth.users au ON au.id = p.id
WHERE p.customer_id = 'BPC004';

-- Show login credentials
SELECT 
    '📋 LOGIN CREDENTIALS' as info,
    'Customer ID: BPC004' as username,
    'Password: password123' as password;
