-- Debug authentication context vs user context

-- 1. Check what auth.uid() returns in the database
SELECT 
    'AUTH_UID_CHECK' as test_type,
    auth.uid() as current_auth_uid,
    auth.jwt() ->> 'sub' as jwt_subject;

-- 2. Check if the auth user exists in profiles
SELECT 
    'AUTH_USER_PROFILE_CHECK' as test_type,
    p.id,
    p.name,
    p.promoter_id,
    p.role,
    p.email
FROM profiles p
WHERE p.id = auth.uid();

-- 3. Check commissions for the auth user
SELECT 
    'AUTH_USER_COMMISSIONS' as test_type,
    COUNT(*) as commission_count,
    SUM(amount) as total_amount
FROM affiliate_commissions 
WHERE recipient_id = auth.uid()
  AND status = 'credited';

-- 4. Check commissions for the specific BPVP15 user
SELECT 
    'BPVP15_COMMISSIONS' as test_type,
    COUNT(*) as commission_count,
    SUM(amount) as total_amount
FROM affiliate_commissions 
WHERE recipient_id = 'fc5deb02-1b33-4779-990d-ac89f3863e19'
  AND status = 'credited';

-- 5. Test if the RLS policy is working correctly
-- This should return results if auth.uid() matches the recipient_id
SELECT 
    'RLS_POLICY_TEST' as test_type,
    ac.id,
    ac.recipient_id,
    ac.amount,
    ac.status,
    (ac.recipient_id = auth.uid()) as is_auth_user_recipient
FROM affiliate_commissions ac
WHERE status = 'credited'
LIMIT 5;

-- 6. Check if there's a session/auth issue
SELECT 
    'SESSION_CHECK' as test_type,
    CASE 
        WHEN auth.uid() IS NULL THEN 'NO_AUTH'
        WHEN auth.uid() = 'fc5deb02-1b33-4779-990d-ac89f3863e19' THEN 'CORRECT_USER'
        ELSE 'DIFFERENT_USER'
    END as auth_status,
    auth.uid() as actual_auth_uid;

SELECT 'AUTH_DEBUG_COMPLETE' as result;
