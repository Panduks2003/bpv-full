-- =====================================================
-- UNIFIED PROMOTER SYSTEM - TESTING AND VERIFICATION
-- =====================================================
-- This file contains test functions and sample data

-- =====================================================
-- 10. FUNCTION: TEST PROMOTER SYSTEM
-- =====================================================

-- Function to verify the system works
CREATE OR REPLACE FUNCTION test_promoter_system()
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    test_result JSON;
    sample_promoter JSON;
    next_id VARCHAR(20);
BEGIN
    -- Test generating promoter ID
    SELECT generate_next_promoter_id() INTO next_id;
    
    -- Test creating a sample promoter
    SELECT create_unified_promoter(
        'Test Promoter',
        'password123',
        '9876543210',
        'test@example.com',
        '123 Test Street, Test City',
        NULL,
        'Affiliate',
        'Active'
    ) INTO sample_promoter;
    
    -- Return test results
    RETURN json_build_object(
        'schema_created', true,
        'functions_created', true,
        'next_promoter_id', next_id,
        'sample_promoter_test', sample_promoter
    );
END;
$$;

-- =====================================================
-- 11. SAMPLE DATA CREATION (OPTIONAL)
-- =====================================================

-- Function to create sample promoters for testing
CREATE OR REPLACE FUNCTION create_sample_promoters()
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    admin_id UUID;
    promoter1_result JSON;
    promoter2_result JSON;
    promoter3_result JSON;
BEGIN
    -- Get an admin user ID (assuming one exists)
    SELECT id INTO admin_id FROM profiles WHERE role = 'admin' LIMIT 1;
    
    -- Create sample promoters
    SELECT create_unified_promoter(
        'John Smith',
        'password123',
        '9876543210',
        'john@example.com',
        '123 Main Street, Mumbai',
        admin_id,
        'Manager',
        'Active'
    ) INTO promoter1_result;
    
    SELECT create_unified_promoter(
        'Sarah Johnson',
        'password456',
        '9876543211',
        'sarah@example.com',
        '456 Oak Avenue, Delhi',
        admin_id,
        'Regional',
        'Active'
    ) INTO promoter2_result;
    
    SELECT create_unified_promoter(
        'Mike Wilson',
        'password789',
        '9876543212',
        NULL, -- No email
        '789 Pine Road, Bangalore',
        admin_id,
        'Affiliate',
        'Active'
    ) INTO promoter3_result;
    
    RETURN json_build_object(
        'promoter1', promoter1_result,
        'promoter2', promoter2_result,
        'promoter3', promoter3_result
    );
END;
$$;

-- =====================================================
-- 12. SYSTEM VERIFICATION
-- =====================================================

-- Function to verify all components are working
CREATE OR REPLACE FUNCTION verify_promoter_system()
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    verification_result JSON;
    table_exists BOOLEAN;
    function_exists BOOLEAN;
    sequence_exists BOOLEAN;
BEGIN
    -- Check if promoter_id_sequence table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'promoter_id_sequence'
    ) INTO sequence_exists;
    
    -- Check if profiles table has required columns
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'promoter_id'
    ) INTO table_exists;
    
    -- Check if main function exists
    SELECT EXISTS (
        SELECT FROM information_schema.routines 
        WHERE routine_name = 'create_unified_promoter'
    ) INTO function_exists;
    
    RETURN json_build_object(
        'sequence_table_exists', sequence_exists,
        'profiles_table_updated', table_exists,
        'create_function_exists', function_exists,
        'system_ready', (sequence_exists AND table_exists AND function_exists),
        'timestamp', NOW()
    );
END;
$$;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Test and verification functions created successfully!';
    RAISE NOTICE 'Run SELECT verify_promoter_system(); to check system status';
    RAISE NOTICE 'Run SELECT test_promoter_system(); to test functionality';
END $$;
