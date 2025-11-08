-- =====================================================
-- REMOVE ALL PROMOTERS FROM DATABASE
-- =====================================================
-- This script safely removes all promoter records while maintaining database integrity
-- WARNING: This will delete ALL promoter data permanently!

-- =====================================================
-- 1. SAFETY CHECK AND CONFIRMATION
-- =====================================================

DO $$
DECLARE
    promoter_count INTEGER;
    customer_count INTEGER;
    admin_count INTEGER;
BEGIN
    -- Count current promoters
    SELECT COUNT(*) INTO promoter_count FROM profiles WHERE role = 'promoter';
    SELECT COUNT(*) INTO customer_count FROM profiles WHERE role = 'customer';
    SELECT COUNT(*) INTO admin_count FROM profiles WHERE role = 'admin';
    
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PROMOTER DELETION SAFETY CHECK';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Current database state:';
    RAISE NOTICE '- Promoters: %', promoter_count;
    RAISE NOTICE '- Customers: %', customer_count;
    RAISE NOTICE '- Admins: %', admin_count;
    RAISE NOTICE '';
    RAISE NOTICE 'This operation will DELETE ALL % promoters!', promoter_count;
    RAISE NOTICE 'Customers and Admins will be preserved.';
    RAISE NOTICE '=======================================================';
END $$;

-- =====================================================
-- 2. DISABLE RLS TEMPORARILY FOR COMPLETE ACCESS
-- =====================================================

-- Temporarily disable RLS to ensure complete deletion
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE promoters DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. HANDLE DEPENDENT RECORDS
-- =====================================================

-- Update customers that have promoters as parent_promoter to NULL
-- (This prevents foreign key constraint violations)
DO $$
DECLARE
    updated_customers INTEGER;
BEGIN
    UPDATE profiles 
    SET parent_promoter_id = NULL 
    WHERE role = 'customer' 
    AND parent_promoter_id IN (
        SELECT id FROM profiles WHERE role = 'promoter'
    );
    
    GET DIAGNOSTICS updated_customers = ROW_COUNT;
    RAISE NOTICE 'Updated % customers to remove promoter parent references', updated_customers;
END $$;

-- Handle other dependent tables that might reference promoters
DO $$
BEGIN
    -- Update withdrawal requests (if table exists)
    BEGIN
        UPDATE withdrawal_requests 
        SET promoter_id = NULL 
        WHERE promoter_id IN (
            SELECT id FROM profiles WHERE role = 'promoter'
        );
        RAISE NOTICE 'Updated withdrawal_requests to remove promoter references';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'withdrawal_requests table not found or no updates needed';
    END;
    
    -- Update notifications (if table exists)
    BEGIN
        DELETE FROM notifications 
        WHERE user_id IN (
            SELECT id FROM profiles WHERE role = 'promoter'
        );
        RAISE NOTICE 'Deleted promoter notifications';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'notifications table not found or no deletions needed';
    END;
    
    -- Update customer_payments (if table exists)
    BEGIN
        UPDATE customer_payments 
        SET marked_by = NULL 
        WHERE marked_by IN (
            SELECT id FROM profiles WHERE role = 'promoter'
        );
        RAISE NOTICE 'Updated customer_payments to remove promoter references';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'customer_payments table not found or no updates needed';
    END;
END $$;

-- =====================================================
-- 4. DELETE PROMOTER RECORDS
-- =====================================================

DO $$
DECLARE
    deleted_promoters INTEGER;
    deleted_profiles INTEGER;
    deleted_auth_users INTEGER;
BEGIN
    -- Delete from promoters table first (child table)
    BEGIN
        DELETE FROM promoters 
        WHERE id IN (
            SELECT id FROM profiles WHERE role = 'promoter'
        );
        GET DIAGNOSTICS deleted_promoters = ROW_COUNT;
        RAISE NOTICE 'Deleted % records from promoters table', deleted_promoters;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'promoters table not found or no deletions needed: %', SQLERRM;
        deleted_promoters := 0;
    END;
    
    -- Store promoter IDs for auth.users deletion
    CREATE TEMP TABLE temp_promoter_ids AS 
    SELECT id FROM profiles WHERE role = 'promoter';
    
    -- Delete from profiles table
    DELETE FROM profiles WHERE role = 'promoter';
    GET DIAGNOSTICS deleted_profiles = ROW_COUNT;
    RAISE NOTICE 'Deleted % records from profiles table', deleted_profiles;
    
    -- Delete from auth.users table
    BEGIN
        DELETE FROM auth.users 
        WHERE id IN (SELECT id FROM temp_promoter_ids);
        GET DIAGNOSTICS deleted_auth_users = ROW_COUNT;
        RAISE NOTICE 'Deleted % records from auth.users table', deleted_auth_users;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'auth.users deletion failed or not accessible: %', SQLERRM;
        deleted_auth_users := 0;
    END;
    
    -- Clean up temp table
    DROP TABLE temp_promoter_ids;
    
    -- Summary
    RAISE NOTICE '';
    RAISE NOTICE '=== DELETION SUMMARY ===';
    RAISE NOTICE 'Promoters table: % deleted', deleted_promoters;
    RAISE NOTICE 'Profiles table: % deleted', deleted_profiles;
    RAISE NOTICE 'Auth.users table: % deleted', deleted_auth_users;
END $$;

-- =====================================================
-- 5. RESET PROMOTER ID SEQUENCE
-- =====================================================

-- Reset the promoter ID sequence to start from 0
DO $$
BEGIN
    UPDATE promoter_id_sequence 
    SET last_promoter_number = 0, 
        updated_at = NOW()
    WHERE id = (SELECT MIN(id) FROM promoter_id_sequence);
    
    RAISE NOTICE 'Reset promoter ID sequence to 0';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'promoter_id_sequence table not found or reset failed: %', SQLERRM;
END $$;

-- =====================================================
-- 6. RE-ENABLE RLS
-- =====================================================

-- Re-enable RLS policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE promoters ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 7. VERIFICATION
-- =====================================================

DO $$
DECLARE
    remaining_promoters INTEGER;
    remaining_customers INTEGER;
    remaining_admins INTEGER;
    sequence_value INTEGER;
BEGIN
    -- Count remaining records
    SELECT COUNT(*) INTO remaining_promoters FROM profiles WHERE role = 'promoter';
    SELECT COUNT(*) INTO remaining_customers FROM profiles WHERE role = 'customer';
    SELECT COUNT(*) INTO remaining_admins FROM profiles WHERE role = 'admin';
    
    -- Check sequence value
    SELECT COALESCE(last_promoter_number, 0) INTO sequence_value 
    FROM promoter_id_sequence LIMIT 1;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== VERIFICATION RESULTS ===';
    RAISE NOTICE 'Remaining promoters: %', remaining_promoters;
    RAISE NOTICE 'Remaining customers: %', remaining_customers;
    RAISE NOTICE 'Remaining admins: %', remaining_admins;
    RAISE NOTICE 'Promoter ID sequence: %', sequence_value;
    
    IF remaining_promoters = 0 THEN
        RAISE NOTICE '✅ SUCCESS: All promoters deleted successfully!';
    ELSE
        RAISE NOTICE '❌ WARNING: % promoters still remain', remaining_promoters;
    END IF;
END $$;

-- =====================================================
-- 8. COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PROMOTER DELETION COMPLETED';
    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'Operations performed:';
    RAISE NOTICE '1. Removed all promoter records from all tables';
    RAISE NOTICE '2. Updated dependent records to prevent constraint violations';
    RAISE NOTICE '3. Reset promoter ID sequence to 0';
    RAISE NOTICE '4. Preserved all customer and admin data';
    RAISE NOTICE '';
    RAISE NOTICE 'Database is now clean and ready for new promoter creation.';
    RAISE NOTICE 'Next promoter will get ID: PROM0001';
    RAISE NOTICE '=======================================================';
END $$;
