-- =====================================================
-- FIX PGCRYPTO EXTENSION ISSUE
-- =====================================================
-- This script enables the pgcrypto extension and fixes the gen_salt function issue

-- Enable pgcrypto extension (required for gen_salt and crypt functions)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Verify the extension is installed
SELECT 'PGCRYPTO_CHECK' as check_type,
       CASE WHEN EXISTS (
           SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto'
       ) THEN 'INSTALLED' ELSE 'MISSING' END as status;

-- Test the gen_salt function
SELECT 'GEN_SALT_TEST' as test_type,
       gen_salt('bf') as salt_result;

-- Test the crypt function
SELECT 'CRYPT_TEST' as test_type,
       crypt('test_password', gen_salt('bf')) as encrypted_password;
