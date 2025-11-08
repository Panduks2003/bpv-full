-- =====================================================
-- TEST WITHDRAWAL INSERT - SIMULATE WEB APP
-- =====================================================
-- This simulates what the web app is trying to do
-- Replace 'YOUR_USER_ID' with the actual promoter ID
-- =====================================================

-- First, let's see all promoters to get a valid ID
SELECT 
    '📋 Available Promoters' as info,
    id,
    name,
    email,
    role,
    promoter_id
FROM profiles
WHERE role = 'promoter'
LIMIT 5;

-- Now test if a specific promoter can insert
-- Replace this UUID with an actual promoter ID from above
DO $$
DECLARE
    test_promoter_id UUID := '6b23e675-53ec-4be8-8192-207f006181c2'; -- Replace with actual ID
    can_insert BOOLEAN;
BEGIN
    -- Check if this promoter exists and has correct role
    SELECT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = test_promoter_id AND role = 'promoter'
    ) INTO can_insert;
    
    IF can_insert THEN
        RAISE NOTICE '✅ Promoter exists with correct role';
        
        -- Try to insert a test withdrawal
        INSERT INTO withdrawal_requests (
            promoter_id,
            amount,
            status,
            reason,
            requested_date
        ) VALUES (
            test_promoter_id,
            1000,
            'pending',
            'Test withdrawal from SQL',
            CURRENT_DATE
        );
        
        RAISE NOTICE '✅ Test withdrawal inserted successfully!';
        
        -- Clean up the test record
        DELETE FROM withdrawal_requests 
        WHERE promoter_id = test_promoter_id 
        AND reason = 'Test withdrawal from SQL';
        
        RAISE NOTICE '✅ Test record cleaned up';
    ELSE
        RAISE NOTICE '❌ Promoter not found or not a promoter role';
    END IF;
END $$;
