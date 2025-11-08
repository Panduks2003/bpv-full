-- =====================================================
-- FIX PROMOTER DATA ISSUES
-- =====================================================
-- Run this after diagnosing the issue with debug-promoter-issue.sql

-- 1. If promoter exists but has no pins, give them some pins
UPDATE profiles 
SET pins = 10, updated_at = NOW()
WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e' 
AND role = 'promoter' 
AND (pins IS NULL OR pins = 0);

-- 2. If promoter exists but role is wrong, fix the role
UPDATE profiles 
SET role = 'promoter', updated_at = NOW()
WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e' 
AND role != 'promoter';

-- 3. If promoter doesn't exist, create a basic promoter record
-- (Only run this if the promoter doesn't exist in profiles table)
INSERT INTO profiles (
    id, 
    name, 
    role, 
    promoter_id, 
    pins, 
    created_at, 
    updated_at
) 
SELECT 
    'c38c36ce-177e-4407-9233-d7fdbd4e150e',
    'Test Promoter',
    'promoter',
    'PROM0019',
    10,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e'
);

-- 4. Verify the fix
SELECT 'PROMOTER_FIXED_CHECK' as check_type,
       id, name, role, promoter_id, pins
FROM profiles 
WHERE id = 'c38c36ce-177e-4407-9233-d7fdbd4e150e';

-- 5. Test pin check function after fix
SELECT 'PIN_CHECK_AFTER_FIX' as check_type,
       check_promoter_pins('c38c36ce-177e-4407-9233-d7fdbd4e150e', 1) as has_sufficient_pins;
