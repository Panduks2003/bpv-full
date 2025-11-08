-- =====================================================
-- FORCE DELETE ALL PROMOTERS (INCLUDING ALL EMAIL PATTERNS)
-- =====================================================
-- This script aggressively deletes ALL promoters
-- regardless of email pattern
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: DELETE ALL PROMOTER-RELATED DATA FIRST
-- =====================================================

-- Delete all commissions where promoter is involved
DELETE FROM affiliate_commissions 
WHERE promoter_id IN (
  SELECT id FROM profiles WHERE role = 'promoter'
);
RAISE NOTICE '✅ Deleted all promoter commissions';

-- Delete all PIN requests from promoters
DELETE FROM pin_requests 
WHERE promoter_id IN (
  SELECT id FROM profiles WHERE role = 'promoter'
);
RAISE NOTICE '✅ Deleted all promoter PIN requests';

-- Delete all PIN transactions from promoters
DELETE FROM pin_transactions 
WHERE promoter_id IN (
  SELECT id FROM profiles WHERE role = 'promoter'
);
RAISE NOTICE '✅ Deleted all promoter PIN transactions';

-- Delete all withdrawal requests from promoters
DELETE FROM withdrawal_requests 
WHERE user_id IN (
  SELECT id FROM profiles WHERE role = 'promoter'
);
RAISE NOTICE '✅ Deleted all promoter withdrawal requests';

-- =====================================================
-- STEP 2: GET LIST OF ALL PROMOTER IDs
-- =====================================================

DO $$
DECLARE
  promoter_ids UUID[];
  promoter_count INTEGER;
BEGIN
  -- Get all promoter IDs
  SELECT ARRAY_AGG(id) INTO promoter_ids
  FROM profiles 
  WHERE role = 'promoter';
  
  -- Get count
  SELECT COUNT(*) INTO promoter_count
  FROM profiles 
  WHERE role = 'promoter';
  
  RAISE NOTICE 'Found % promoters to delete', promoter_count;
  RAISE NOTICE 'Promoter IDs: %', promoter_ids;
END $$;

-- =====================================================
-- STEP 3: DELETE ALL PROMOTER PROFILES
-- =====================================================

-- Delete ALL promoter profiles (no email filter)
DELETE FROM profiles 
WHERE role = 'promoter';

RAISE NOTICE '✅ Deleted ALL promoter profiles';

-- =====================================================
-- STEP 4: DELETE ALL PROMOTER AUTH USERS
-- =====================================================

-- Delete auth users that don't have a profile anymore
DELETE FROM auth.users 
WHERE id NOT IN (
  SELECT id FROM profiles
)
AND id NOT IN (
  SELECT id FROM profiles WHERE role = 'admin'
);

RAISE NOTICE '✅ Deleted all orphaned auth users';

-- =====================================================
-- STEP 5: VERIFY CLEANUP
-- =====================================================

DO $$
DECLARE
  promoter_count INTEGER;
  auth_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO promoter_count FROM profiles WHERE role = 'promoter';
  SELECT COUNT(*) INTO auth_count FROM auth.users WHERE id NOT IN (SELECT id FROM profiles);
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'PROMOTER DELETION COMPLETE!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Remaining promoters: %', promoter_count;
  RAISE NOTICE 'Orphaned auth users: %', auth_count;
  
  IF promoter_count = 0 THEN
    RAISE NOTICE '✅ ALL PROMOTERS DELETED SUCCESSFULLY!';
  ELSE
    RAISE NOTICE '⚠️  WARNING: % promoters still remain!', promoter_count;
  END IF;
  RAISE NOTICE '========================================';
END $$;

COMMIT;

-- =====================================================
-- SHOW REMAINING USERS
-- =====================================================

SELECT 
  role,
  COUNT(*) as count,
  STRING_AGG(email, ', ') as emails
FROM profiles
GROUP BY role
ORDER BY role;
