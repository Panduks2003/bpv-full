# Fix Customer Authentication PGRST203 Error

## Problem
The customer login is failing with error `PGRST203`:
```
Could not choose the best candidate function between authenticate_customer_by_card_no(p_customer_id => text, p_password => text)
```

This error occurs when PostgREST finds multiple versions of the same function with conflicting signatures, making it impossible to determine which one to call.

## Solution
Apply the fix script to drop all conflicting versions and create a single clean function.

## How to Apply

### Option 1: Via Supabase Dashboard
1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Open the file: `database/fix-customer-auth-function-conflict.sql`
4. Copy the entire contents
5. Paste into SQL Editor
6. Click **Run**

### Option 2: Via psql Command Line
```bash
psql -h your-db-host.supabase.co -U postgres -d postgres -f database/fix-customer-auth-function-conflict.sql
```

## What the Fix Does
1. **Drops all conflicting versions** of `authenticate_customer_by_card_no` function
2. **Creates a single clean version** with TEXT parameters
3. **Grants proper permissions** to authenticated and anon roles
4. **Verifies the function** was created correctly

## Expected Result
After applying the fix:
- ✅ Customer login should work correctly
- ✅ No more PGRST203 errors
- ✅ Function will be called with the correct signature

## Testing
Try logging in as a customer (e.g., BPVC04) again. The error should be resolved.

