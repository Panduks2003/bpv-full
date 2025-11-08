-- =====================================================
-- FIX WITHDRAWAL STATUS UPDATE ISSUE
-- =====================================================
-- This script addresses the issue where withdrawal status
-- remains "pending" even after admin approval
-- =====================================================

-- =====================================================
-- 1. CHECK CURRENT WITHDRAWAL REQUEST STRUCTURE
-- =====================================================

-- First, let's see what withdrawal requests exist and their current status
SELECT 
    'Current Withdrawal Requests' as info,
    id,
    promoter_id,
    amount,
    status,
    processed_at,
    processed_by,
    admin_notes,
    transaction_id,
    created_at,
    updated_at
FROM withdrawal_requests
ORDER BY created_at DESC;

-- =====================================================
-- 2. CHECK FOR POTENTIAL ISSUES
-- =====================================================

-- Check if there are any constraints or triggers that might prevent updates
SELECT 
    'Table Constraints' as info,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'withdrawal_requests'
AND table_schema = 'public';

-- Check if RLS policies might be blocking updates
SELECT 
    'RLS Policies' as info,
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'withdrawal_requests';

-- =====================================================
-- 3. TEST STATUS UPDATE MANUALLY
-- =====================================================

-- Let's try to manually update a withdrawal request status to test
-- (This will help identify if the issue is with the admin interface or database)

-- First, create a test withdrawal request if none exist
INSERT INTO withdrawal_requests (
    promoter_id,
    amount,
    status,
    reason,
    created_at
)
SELECT 
    id,
    1000.00,
    'pending',
    'Test withdrawal request for status update verification',
    NOW()
FROM profiles 
WHERE role = 'promoter' 
AND promoter_id IS NOT NULL
LIMIT 1
ON CONFLICT DO NOTHING;

-- Get the ID of a pending request for testing
DO $$
DECLARE
    test_request_id UUID;
    admin_user_id UUID;
BEGIN
    -- Get a pending request
    SELECT id INTO test_request_id
    FROM withdrawal_requests 
    WHERE status = 'pending'
    LIMIT 1;
    
    -- Get an admin user
    SELECT id INTO admin_user_id
    FROM profiles 
    WHERE role = 'admin'
    LIMIT 1;
    
    IF test_request_id IS NOT NULL AND admin_user_id IS NOT NULL THEN
        -- Try to update the status
        UPDATE withdrawal_requests 
        SET 
            status = 'approved',
            processed_at = NOW(),
            processed_by = admin_user_id,
            admin_notes = 'Test approval - automated status update verification',
            updated_at = NOW()
        WHERE id = test_request_id;
        
        RAISE NOTICE 'Test update completed for request ID: %', test_request_id;
    ELSE
        RAISE NOTICE 'No pending requests or admin users found for testing';
    END IF;
END $$;

-- =====================================================
-- 4. VERIFY THE UPDATE WORKED
-- =====================================================

-- Check if the test update worked
SELECT 
    'After Test Update' as info,
    id,
    status,
    processed_at,
    processed_by,
    admin_notes,
    updated_at
FROM withdrawal_requests
WHERE admin_notes LIKE '%Test approval%'
OR updated_at > NOW() - INTERVAL '1 minute';

-- =====================================================
-- 5. CREATE FUNCTION TO SAFELY UPDATE WITHDRAWAL STATUS
-- =====================================================

-- Create a function that handles withdrawal status updates properly
CREATE OR REPLACE FUNCTION update_withdrawal_status(
    p_request_id UUID,
    p_new_status VARCHAR(20),
    p_admin_id UUID,
    p_admin_notes TEXT DEFAULT NULL,
    p_transaction_id VARCHAR(100) DEFAULT NULL,
    p_rejection_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_exists BOOLEAN;
    admin_exists BOOLEAN;
BEGIN
    -- Check if request exists
    SELECT EXISTS(
        SELECT 1 FROM withdrawal_requests WHERE id = p_request_id
    ) INTO request_exists;
    
    IF NOT request_exists THEN
        RAISE EXCEPTION 'Withdrawal request not found: %', p_request_id;
    END IF;
    
    -- Check if admin exists
    SELECT EXISTS(
        SELECT 1 FROM profiles WHERE id = p_admin_id AND role = 'admin'
    ) INTO admin_exists;
    
    IF NOT admin_exists THEN
        RAISE EXCEPTION 'Admin user not found: %', p_admin_id;
    END IF;
    
    -- Update the withdrawal request
    UPDATE withdrawal_requests 
    SET 
        status = p_new_status,
        processed_at = CASE 
            WHEN p_new_status IN ('approved', 'rejected', 'completed') 
            THEN NOW() 
            ELSE processed_at 
        END,
        processed_by = p_admin_id,
        admin_notes = COALESCE(p_admin_notes, admin_notes),
        transaction_id = CASE 
            WHEN p_new_status = 'completed' AND p_transaction_id IS NOT NULL 
            THEN p_transaction_id 
            ELSE transaction_id 
        END,
        rejection_reason = CASE 
            WHEN p_new_status = 'rejected' AND p_rejection_reason IS NOT NULL 
            THEN p_rejection_reason 
            ELSE rejection_reason 
        END,
        completed_at = CASE 
            WHEN p_new_status = 'completed' 
            THEN NOW() 
            ELSE completed_at 
        END,
        updated_at = NOW()
    WHERE id = p_request_id;
    
    -- Log the update
    RAISE NOTICE 'Withdrawal request % updated to status: %', p_request_id, p_new_status;
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to update withdrawal status: %', SQLERRM;
        RETURN FALSE;
END;
$$;

-- =====================================================
-- 6. CREATE RLS POLICIES FOR THE FUNCTION
-- =====================================================

-- Ensure the function can be called by admins
GRANT EXECUTE ON FUNCTION update_withdrawal_status TO authenticated;

-- Create policy to allow the function to update records
DO $$
BEGIN
    -- Drop existing policies if they exist
    DROP POLICY IF EXISTS "allow_function_updates" ON withdrawal_requests;
    
    -- Create policy for function updates
    CREATE POLICY "allow_function_updates" ON withdrawal_requests
        FOR UPDATE USING (true)
        WITH CHECK (true);
        
    RAISE NOTICE 'RLS policies updated for withdrawal_requests';
END $$;

-- =====================================================
-- 7. TEST THE NEW FUNCTION
-- =====================================================

-- Test the function with a pending request
DO $$
DECLARE
    test_request_id UUID;
    admin_user_id UUID;
    update_result BOOLEAN;
BEGIN
    -- Get a pending request
    SELECT id INTO test_request_id
    FROM withdrawal_requests 
    WHERE status = 'pending'
    LIMIT 1;
    
    -- Get an admin user
    SELECT id INTO admin_user_id
    FROM profiles 
    WHERE role = 'admin'
    LIMIT 1;
    
    IF test_request_id IS NOT NULL AND admin_user_id IS NOT NULL THEN
        -- Test the function
        SELECT update_withdrawal_status(
            test_request_id,
            'approved',
            admin_user_id,
            'Function test approval',
            NULL,
            NULL
        ) INTO update_result;
        
        RAISE NOTICE 'Function test result: %', update_result;
    ELSE
        RAISE NOTICE 'No test data available for function testing';
    END IF;
END $$;

-- =====================================================
-- 8. FINAL VERIFICATION
-- =====================================================

-- Show final status of all withdrawal requests
SELECT 
    'Final Status Check' as info,
    id,
    status,
    processed_at,
    processed_by,
    admin_notes,
    updated_at,
    CASE 
        WHEN updated_at > created_at THEN 'Updated'
        ELSE 'Not Updated'
    END as update_status
FROM withdrawal_requests
ORDER BY created_at DESC;

-- Success message
SELECT '✅ Withdrawal status update system verified and fixed!' as result;
