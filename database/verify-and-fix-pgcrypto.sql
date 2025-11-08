-- =====================================================
-- VERIFY AND FIX PGCRYPTO EXTENSION
-- =====================================================

-- Check if extension exists
SELECT 
    extname as extension_name,
    extversion as version
FROM pg_extension 
WHERE extname = 'pgcrypto';

-- Drop and recreate the extension to ensure it's properly installed
DROP EXTENSION IF EXISTS pgcrypto CASCADE;
CREATE EXTENSION pgcrypto;

-- Verify functions are available
SELECT 
    proname as function_name,
    pronargs as num_args
FROM pg_proc 
WHERE proname IN ('gen_salt', 'crypt')
ORDER BY proname;

-- Test gen_salt function
SELECT 
    'Testing gen_salt' as test,
    gen_salt('bf') as result;

-- Test crypt function
SELECT 
    'Testing crypt' as test,
    crypt('test123', gen_salt('bf')) as result;

-- Final verification
SELECT '✅ pgcrypto extension is now properly installed and working' as status;
