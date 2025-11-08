-- =====================================================
-- FIX BPVC04 CUSTOMER ID (TYPOS)
-- =====================================================
-- Corrects potential typos in customer IDs (BPVC04 -> BPC04)
-- =====================================================

-- Check if BPVC04 exists
SELECT 
    '🔍 SEARCH RESULTS' as status,
    customer_id,
    name,
    role,
    status
FROM profiles
WHERE customer_id LIKE '%BPVC04%' OR customer_id LIKE '%BPC04%';

-- If BPVC04 is a typo for BPC04, update it
UPDATE profiles
SET customer_id = 'BPC04'
WHERE customer_id = 'BPVC04';

-- Verify
SELECT 
    '✅ VERIFICATION' as status,
    customer_id,
    name,
    'Should be BPC04' as expected_value
FROM profiles
WHERE customer_id IN ('BPVC04', 'BPC04');
