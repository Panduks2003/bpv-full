-- =====================================================
-- FIX gen_salt FUNCTION - Enable pgcrypto Extension
-- =====================================================
-- The gen_salt function requires the pgcrypto extension

-- Enable pgcrypto extension (provides gen_salt and crypt functions)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Verify the extension is installed
SELECT 
    'pgcrypto extension' as component,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto'
    ) THEN '✅ INSTALLED' ELSE '❌ MISSING' END as status;

-- Test gen_salt function
SELECT 
    'gen_salt function' as test,
    CASE WHEN gen_salt('bf') IS NOT NULL 
         THEN '✅ WORKING' 
         ELSE '❌ FAILED' 
    END as status;

-- Verification message
SELECT '✅ pgcrypto extension enabled - gen_salt() function is now available' as result;
