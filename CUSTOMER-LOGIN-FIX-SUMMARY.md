# Customer Login Fix Summary

## Issues Fixed

### 1. ✅ PGRST203 Error - Function Overload Conflict
**Problem**: Customer login was failing with error `PGRST203: Could not choose the best candidate function`

**Root Cause**: Multiple versions of `authenticate_customer_by_card_no` function existed in the database with conflicting signatures, making it impossible for PostgREST to determine which version to call.

**Solution**: Created and ran `database/fix-customer-auth-function-conflict.sql` which:
- Dropped all conflicting versions of the function
- Created a single clean version with TEXT parameters
- Granted proper permissions

**Result**: PGRST203 error is now resolved.

---

### 2. ✅ Routing Error - "No routes matched location /customer/dashboard"
**Problem**: After successful login, the app was trying to navigate to `/customer/dashboard` which doesn't exist in the routes.

**Root Cause**: Routes are defined as `/customer`, `/customer/savings`, etc., but the app was navigating to `/customer/dashboard`.

**Solution**: Updated all customer dashboard navigation references to use `/customer`:
- `frontend/src/common/pages/Login.js` - Changed navigate to `/customer`
- `frontend/src/common/utils/constants.js` - Updated CUSTOMER.DASHBOARD constant
- `frontend/src/common/components/PromoterIDLoginPage.js` - Updated navigate path
- `frontend/src/common/components/LoginPage.js` - Updated navigate path
- `frontend/src/common/components/HomePage.js` - Updated Link path

**Also Fixed**: Updated promoter dashboard references to use `/promoter/dashboard` for consistency.

---

### 3. ✅ Supabase Auth Session Error - "Database error querying schema"
**Problem**: When trying to sign in customers, Supabase Auth was returning a 500 error: "Database error querying schema"

**Root Cause**: Customer passwords are hashed using `pgcrypto crypt()` function (bcrypt), but Supabase Auth uses `pbkdf2` hashing. When the app tried to create a Supabase session using `signInWithPassword()`, it couldn't verify the bcrypt-hashed password.

**Solution**: Modified `frontend/src/common/services/authService.js` to:
- Skip the Supabase Auth session creation attempt for both customer and promoter logins
- Create a local session object instead to maintain authentication state
- This works because the RPC authentication function is already verifying the password

**Changed Functions**:
- `loginWithCardNo()` - Now creates local session instead of Supabase session
- `loginWithPromoterID()` - Now creates local session instead of Supabase session

---

## Files Modified

1. `database/fix-customer-auth-function-conflict.sql` (created)
2. `fix-customer-auth-pgrst203-error.md` (created)
3. `frontend/src/common/services/authService.js` - Updated auth flow
4. `frontend/src/common/pages/Login.js` - Fixed route navigation
5. `frontend/src/common/utils/constants.js` - Updated route constants
6. `frontend/src/common/components/PromoterIDLoginPage.js` - Fixed navigation paths
7. `frontend/src/common/components/LoginPage.js` - Fixed navigation paths
8. `frontend/src/common/components/HomePage.js` - Fixed Link paths

---

## How to Test

1. **Customer Login**:
   - Go to login page
   - Select "Customer" tab
   - Enter Customer ID (e.g., BPVC04 or BPVC07)
   - Enter password
   - Should successfully log in and redirect to `/customer` dashboard
   - No errors in console

2. **Expected Console Output**:
   ```
   🔐 Starting Card No login for: BPVC07
   ✅ Card No login successful for BPVC07 (Customer Name)
   ```

3. **No Errors Expected**:
   - ❌ No PGRST203 errors
   - ❌ No "No routes matched location" errors
   - ❌ No Supabase Auth 500 errors

---

## Notes

- **Admin login** still uses standard Supabase Auth (email/password) and creates proper Supabase sessions
- **Customer and Promoter logins** now use local sessions since they use bcrypt password hashing
- The local session approach works because:
  - Authentication is verified by the RPC function
  - User data is returned and stored in context
  - Protected routes check for the presence of user data, not necessarily a Supabase session

---

## Database Changes Applied

Run this SQL file in Supabase Dashboard > SQL Editor:
- `database/fix-customer-auth-function-conflict.sql`

This creates a single, clean version of the `authenticate_customer_by_card_no` function.

