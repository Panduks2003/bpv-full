# How to Test RLS Policies After Fix

## 1. Set Auth Context
Run this FIRST in Supabase SQL Editor:
```sql
SET LOCAL request.jwt.claims = '{"sub":"e95cb062-cd53-4591-8739-5ca6d144d8b2", "role":"authenticated"}';
```

## 2. Test Profile Access
Then run:
```sql
SELECT 
    id,
    name,
    customer_id,
    'Should be visible' as test_result
FROM profiles
WHERE id = auth.uid();
```

## 3. Test Profile Update
```sql
-- This should return 1 row if RLS works
UPDATE profiles
SET name = name || ' (test)'
WHERE id = auth.uid()
RETURNING *;
```

## Expected Results
- ✅ Should see BPC004's profile data
- ✅ Should be able to update the profile
- ❌ If errors, check RLS policies again
