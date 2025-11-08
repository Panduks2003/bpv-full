-- =====================================================
-- CHECK FOR DUPLICATE SYSTEM ADMINISTRATOR RECORDS
-- =====================================================
-- Check if there are promoter records with the same name as admin

-- =====================================================
-- 1. CHECK ALL USERS WITH "SYSTEM ADMINISTRATOR" NAME
-- =====================================================

SELECT 
    'ALL_SYSTEM_ADMIN_RECORDS' as check_type,
    id,
    name,
    email,
    role,
    promoter_id,
    phone,
    created_at,
    updated_at
FROM profiles 
WHERE name ILIKE '%System Administrator%' 
   OR name ILIKE '%System Admin%'
ORDER BY created_at ASC;

-- =====================================================
-- 2. CHECK FOR PROMOTERS WITH ADMIN-LIKE NAMES
-- =====================================================

SELECT 
    'PROMOTERS_WITH_ADMIN_NAMES' as check_type,
    id,
    name,
    email,
    role,
    promoter_id,
    phone,
    created_at
FROM profiles 
WHERE role = 'promoter' 
AND (
    name ILIKE '%admin%' 
    OR name ILIKE '%administrator%'
    OR email ILIKE '%admin%'
)
ORDER BY created_at ASC;

-- =====================================================
-- 3. CHECK FOR PROMOTERS WITHOUT PROMOTER_ID
-- =====================================================

SELECT 
    'PROMOTERS_WITHOUT_ID' as check_type,
    id,
    name,
    email,
    role,
    promoter_id,
    phone,
    created_at
FROM profiles 
WHERE role = 'promoter' 
AND (promoter_id IS NULL OR promoter_id = '')
ORDER BY created_at ASC;

-- =====================================================
-- 4. REMOVE DUPLICATE ADMIN-NAMED PROMOTERS
-- =====================================================

DO $$
DECLARE
    deleted_count INTEGER := 0;
    admin_name_promoters RECORD;
BEGIN
    RAISE NOTICE '=== REMOVING ADMIN-NAMED PROMOTER RECORDS ===';
    
    -- Delete promoter records that have admin-like names
    FOR admin_name_promoters IN 
        SELECT id, name, email, promoter_id
        FROM profiles 
        WHERE role = 'promoter' 
        AND (
            name ILIKE '%System Administrator%' 
            OR name ILIKE '%System Admin%'
            OR (name ILIKE '%admin%' AND email ILIKE '%admin%')
        )
    LOOP
        RAISE NOTICE 'Deleting promoter record: ID=%, Name=%, Email=%, PromoterID=%', 
            admin_name_promoters.id, 
            admin_name_promoters.name, 
            admin_name_promoters.email,
            admin_name_promoters.promoter_id;
        
        -- Delete from promoters table first (if exists)
        BEGIN
            DELETE FROM promoters WHERE id = admin_name_promoters.id;
        EXCEPTION WHEN OTHERS THEN
            NULL; -- Ignore if promoters table doesn't exist
        END;
        
        -- Delete from profiles table
        DELETE FROM profiles WHERE id = admin_name_promoters.id;
        
        deleted_count := deleted_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Deleted % admin-named promoter records', deleted_count;
    
    -- Also clean up auth.users for deleted records
    BEGIN
        DELETE FROM auth.users 
        WHERE id NOT IN (SELECT id FROM profiles);
        RAISE NOTICE 'Cleaned up orphaned auth.users records';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not clean up auth.users: %', SQLERRM;
    END;
END $$;

-- =====================================================
-- 5. VERIFICATION AFTER CLEANUP
-- =====================================================

-- Check admin users
SELECT 
    'FINAL_ADMIN_CHECK' as check_type,
    COUNT(*) as admin_count
FROM profiles 
WHERE role = 'admin';

-- Check promoters with admin-like names
SELECT 
    'FINAL_PROMOTER_ADMIN_NAMES' as check_type,
    COUNT(*) as count
FROM profiles 
WHERE role = 'promoter' 
AND (
    name ILIKE '%admin%' 
    OR name ILIKE '%administrator%'
);

-- Show remaining users
SELECT 
    'REMAINING_USERS' as check_type,
    role,
    COUNT(*) as count
FROM profiles 
GROUP BY role
ORDER BY role;

-- =====================================================
-- 6. COMPLETION MESSAGE
-- =====================================================

DO $$
DECLARE
    admin_count INTEGER;
    promoter_admin_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO admin_count FROM profiles WHERE role = 'admin';
    SELECT COUNT(*) INTO promoter_admin_count 
    FROM profiles 
    WHERE role = 'promoter' AND (name ILIKE '%admin%' OR name ILIKE '%administrator%');
    
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'DUPLICATE SYSTEM ADMINISTRATOR CLEANUP COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Final counts:';
    RAISE NOTICE '- Admin users: %', admin_count;
    RAISE NOTICE '- Promoters with admin names: %', promoter_admin_count;
    RAISE NOTICE '';
    
    IF admin_count = 1 AND promoter_admin_count = 0 THEN
        RAISE NOTICE '✅ SUCCESS: Only one admin user exists, no admin-named promoters';
        RAISE NOTICE 'The UI should now show only one admin option.';
    ELSE
        RAISE NOTICE '⚠️  Manual review may be needed.';
    END IF;
    
    RAISE NOTICE '=======================================================';
END $$;
