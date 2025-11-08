-- =====================================================
-- FIX DUPLICATE ADMIN USERS
-- =====================================================
-- Check for and remove duplicate admin users, keeping only one

-- =====================================================
-- 1. CHECK CURRENT ADMIN USERS
-- =====================================================

DO $$
DECLARE
    admin_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO admin_count FROM profiles WHERE role = 'admin';
    
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'ADMIN USERS AUDIT';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Total admin users found: %', admin_count;
    RAISE NOTICE '';
END $$;

-- Show all admin users with details
SELECT 
    'ADMIN_USERS' as check_type,
    id,
    name,
    email,
    phone,
    created_at,
    updated_at
FROM profiles 
WHERE role = 'admin'
ORDER BY created_at ASC;

-- =====================================================
-- 2. IDENTIFY DUPLICATES
-- =====================================================

-- Check for duplicate admin users by email
SELECT 
    'DUPLICATE_BY_EMAIL' as check_type,
    email,
    COUNT(*) as count,
    array_agg(id) as user_ids,
    array_agg(name) as names
FROM profiles 
WHERE role = 'admin' 
AND email IS NOT NULL
GROUP BY email 
HAVING COUNT(*) > 1;

-- Check for duplicate admin users by name
SELECT 
    'DUPLICATE_BY_NAME' as check_type,
    name,
    COUNT(*) as count,
    array_agg(id) as user_ids,
    array_agg(email) as emails
FROM profiles 
WHERE role = 'admin'
GROUP BY name 
HAVING COUNT(*) > 1;

-- =====================================================
-- 3. REMOVE DUPLICATE ADMIN USERS (KEEP OLDEST)
-- =====================================================

DO $$
DECLARE
    admin_record RECORD;
    oldest_admin_id UUID;
    duplicate_count INTEGER := 0;
    deleted_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== REMOVING DUPLICATE ADMIN USERS ===';
    
    -- Find the oldest admin user (first created)
    SELECT id INTO oldest_admin_id 
    FROM profiles 
    WHERE role = 'admin' 
    ORDER BY created_at ASC 
    LIMIT 1;
    
    IF oldest_admin_id IS NOT NULL THEN
        RAISE NOTICE 'Keeping oldest admin user: %', oldest_admin_id;
        
        -- Count duplicates
        SELECT COUNT(*) - 1 INTO duplicate_count 
        FROM profiles 
        WHERE role = 'admin';
        
        -- Delete all admin users except the oldest one
        DELETE FROM profiles 
        WHERE role = 'admin' 
        AND id != oldest_admin_id;
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        
        RAISE NOTICE 'Deleted % duplicate admin users', deleted_count;
        
        -- Also clean up auth.users for deleted admins
        BEGIN
            DELETE FROM auth.users 
            WHERE id IN (
                SELECT id FROM profiles WHERE role = 'admin' AND id != oldest_admin_id
            );
            RAISE NOTICE 'Cleaned up auth.users for deleted admin duplicates';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not clean up auth.users: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE 'No admin users found!';
    END IF;
END $$;

-- =====================================================
-- 4. ENSURE SINGLE ADMIN USER EXISTS
-- =====================================================

DO $$
DECLARE
    admin_count INTEGER;
    new_admin_id UUID;
BEGIN
    -- Check if we have exactly one admin
    SELECT COUNT(*) INTO admin_count FROM profiles WHERE role = 'admin';
    
    IF admin_count = 0 THEN
        RAISE NOTICE 'No admin users found. Creating default admin...';
        
        -- Create a default admin user
        new_admin_id := gen_random_uuid();
        
        INSERT INTO profiles (
            id,
            email,
            name,
            role,
            phone,
            created_at,
            updated_at
        ) VALUES (
            new_admin_id,
            'admin@brightplanetventures.com',
            'System Admin',
            'admin',
            '9999999999',
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Created default admin user: %', new_admin_id;
        
    ELSIF admin_count = 1 THEN
        RAISE NOTICE '✅ Perfect! Exactly one admin user exists.';
        
    ELSE
        RAISE NOTICE '⚠️  Warning: Still have % admin users. Manual cleanup may be needed.', admin_count;
    END IF;
END $$;

-- =====================================================
-- 5. FINAL VERIFICATION
-- =====================================================

-- Show final admin user(s)
SELECT 
    'FINAL_ADMIN_USERS' as check_type,
    id,
    name,
    email,
    phone,
    created_at
FROM profiles 
WHERE role = 'admin'
ORDER BY created_at ASC;

-- Count final admin users
DO $$
DECLARE
    final_admin_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO final_admin_count FROM profiles WHERE role = 'admin';
    
    RAISE NOTICE '';
    RAISE NOTICE '=== FINAL VERIFICATION ===';
    RAISE NOTICE 'Final admin user count: %', final_admin_count;
    
    IF final_admin_count = 1 THEN
        RAISE NOTICE '✅ SUCCESS: Exactly one admin user exists!';
    ELSIF final_admin_count = 0 THEN
        RAISE NOTICE '❌ ERROR: No admin users exist!';
    ELSE
        RAISE NOTICE '⚠️  WARNING: Multiple admin users still exist!';
    END IF;
END $$;

-- =====================================================
-- 6. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'ADMIN USER CLEANUP COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Operations performed:';
    RAISE NOTICE '1. Audited all admin users';
    RAISE NOTICE '2. Identified and removed duplicates';
    RAISE NOTICE '3. Kept the oldest admin user';
    RAISE NOTICE '4. Ensured exactly one admin exists';
    RAISE NOTICE '';
    RAISE NOTICE 'The promoter creation form should now show only one admin option.';
    RAISE NOTICE '=======================================================';
END $$;
