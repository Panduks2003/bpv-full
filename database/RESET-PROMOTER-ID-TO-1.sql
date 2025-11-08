-- =====================================================
-- RESET PROMOTER ID TO START FROM BPVP1
-- =====================================================
-- Current: BPVP29
-- Target: BPVP1 (for next promoter)
-- 
-- This script deletes all promoters so the next one
-- will be BPVP1
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: CHECK CURRENT STATE
-- =====================================================

DO $$
DECLARE
  current_max INTEGER;
  promoter_count INTEGER;
BEGIN
  -- Find current highest promoter number
  SELECT COALESCE(MAX(
    CASE 
      WHEN promoter_id ~ '^BPVP[0-9]+$' 
      THEN CAST(SUBSTRING(promoter_id FROM 5) AS INTEGER)
      ELSE 0
    END
  ), 0) INTO current_max
  FROM profiles
  WHERE role = 'promoter';
  
  SELECT COUNT(*) INTO promoter_count
  FROM profiles
  WHERE role = 'promoter';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'CURRENT STATE:';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total promoters: %', promoter_count;
  RAISE NOTICE 'Highest promoter number: BPVP%', current_max;
  RAISE NOTICE 'Next promoter would be: BPVP%', current_max + 1;
  RAISE NOTICE '========================================';
END $$;

-- =====================================================
-- STEP 2: DELETE ALL PROMOTER-RELATED DATA
-- =====================================================

-- Delete promoter commissions
DELETE FROM affiliate_commissions 
WHERE promoter_id IN (
  SELECT id FROM profiles WHERE role = 'promoter'
);
RAISE NOTICE '✅ Deleted promoter commissions';

-- Delete promoter PIN requests
DELETE FROM pin_requests 
WHERE promoter_id IN (
  SELECT id FROM profiles WHERE role = 'promoter'
);
RAISE NOTICE '✅ Deleted promoter PIN requests';

-- Delete promoter PIN transactions
DELETE FROM pin_transactions 
WHERE promoter_id IN (
  SELECT id FROM profiles WHERE role = 'promoter'
);
RAISE NOTICE '✅ Deleted promoter PIN transactions';

-- Delete promoter withdrawals
DELETE FROM withdrawal_requests 
WHERE user_id IN (
  SELECT id FROM profiles WHERE role = 'promoter'
);
RAISE NOTICE '✅ Deleted promoter withdrawals';

-- =====================================================
-- STEP 3: DELETE ALL PROMOTER PROFILES
-- =====================================================

-- Get list of promoters to delete
DO $$
DECLARE
  promoter_list TEXT;
BEGIN
  SELECT STRING_AGG(promoter_id || ' (' || name || ')', ', ')
  INTO promoter_list
  FROM profiles
  WHERE role = 'promoter';
  
  RAISE NOTICE 'Deleting promoters: %', promoter_list;
END $$;

-- Delete ALL promoter profiles
DELETE FROM profiles 
WHERE role = 'promoter';

RAISE NOTICE '✅ Deleted all promoter profiles';

-- =====================================================
-- STEP 4: DELETE PROMOTER AUTH USERS
-- =====================================================

-- Delete orphaned auth users (promoters without profiles)
DELETE FROM auth.users 
WHERE id NOT IN (SELECT id FROM profiles);

RAISE NOTICE '✅ Deleted orphaned auth users';

-- =====================================================
-- STEP 5: VERIFY RESET
-- =====================================================

DO $$
DECLARE
  promoter_count INTEGER;
  max_number INTEGER;
BEGIN
  SELECT COUNT(*) INTO promoter_count
  FROM profiles
  WHERE role = 'promoter';
  
  SELECT COALESCE(MAX(
    CASE 
      WHEN promoter_id ~ '^BPVP[0-9]+$' 
      THEN CAST(SUBSTRING(promoter_id FROM 5) AS INTEGER)
      ELSE 0
    END
  ), 0) INTO max_number
  FROM profiles
  WHERE role = 'promoter';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ PROMOTER ID RESET COMPLETE!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Remaining promoters: %', promoter_count;
  RAISE NOTICE 'Highest number: %', max_number;
  
  IF promoter_count = 0 THEN
    RAISE NOTICE '🎉 SUCCESS! Next promoter will be: BPVP1';
  ELSE
    RAISE NOTICE '⚠️  Still have % promoters. Next will be: BPVP%', promoter_count, max_number + 1;
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

COMMIT;

-- =====================================================
-- SHOW REMAINING DATA
-- =====================================================

-- Show what's left
SELECT 
  'Remaining Users' as info,
  role,
  COUNT(*) as count
FROM profiles
GROUP BY role
ORDER BY role;

-- Show if any promoters remain
SELECT 
  'Remaining Promoters (if any)' as info,
  promoter_id,
  name,
  email,
  available_pins
FROM profiles
WHERE role = 'promoter'
ORDER BY promoter_id;
