# Promoter ID-Only Authentication System

## Overview

This document describes the revamped promoter authentication system that uses **ONLY Promoter ID (e.g., BPVP19) + Password** for login, making email and phone numbers metadata-only fields.

## 🎯 Key Changes

### 1. **Database Changes**

**File**: `database/promoter-id-only-auth-system.sql`

- Removed unique constraints on email and phone for the `profiles` table
- Created `authenticate_promoter_by_id_only()` function for Promoter ID authentication
- Created `create_promoter_with_id_auth()` function for creating new promoters
- Each promoter gets a unique internal auth email (e.g., `promoter+BPVP28@brightplanetventures.local`)

### 2. **Frontend Changes**

**Login UI** (`frontend/src/common/pages/Login.js`):
- Removed email/phone login method toggle for promoters
- Simplified to ONLY show Promoter ID input field
- Shows helpful guidance: "Use your Promoter ID (e.g., BPVP01) to login"

**Auth Service** (`frontend/src/common/services/authService.js`):
- Removed deprecated `loginWithPhone()` method
- Kept only `loginWithPromoterID()` method
- Clean, simplified authentication flow

**Auth Context** (`frontend/src/common/context/AuthContext.js`):
- Removed email/phone login logic for promoters
- Simplified to only use Promoter ID authentication

## 📋 How to Deploy

### Step 1: Apply Database Changes

Run the SQL script to update your database:

```bash
# Option 1: Using Supabase CLI
supabase db execute -f database/promoter-id-only-auth-system.sql

# Option 2: Using psql
psql -h your-db-host -U postgres -d your-database -f database/promoter-id-only-auth-system.sql

# Option 3: Copy and paste SQL into Supabase Dashboard
# Open Supabase Dashboard > SQL Editor > New Query
# Copy contents of promoter-id-only-auth-system.sql
# Run the query
```

### Step 2: Verify Frontend Changes

The frontend changes are already complete in the following files:
- `frontend/src/common/pages/Login.js` ✅
- `frontend/src/common/services/authService.js` ✅
- `frontend/src/common/context/AuthContext.js` ✅

### Step 3: Test the New System

1. **Test Login with Existing Promoter**:
   ```
   Promoter ID: BPVP01
   Password: [their password]
   ```

2. **Create New Promoter** (uses new system):
   - Use the admin panel to create a new promoter
   - The system will automatically generate a unique Promoter ID
   - Display the new Promoter ID to the user
   - They can login immediately using this ID

3. **Test Authentication**:
   ```sql
   -- Test authentication function directly
   SELECT authenticate_promoter_by_id_only('BPVP01', 'password123');
   ```

## 🔐 How It Works

### Login Flow

1. User enters Promoter ID (e.g., BPVP19) + Password
2. Frontend validates format (BPVP followed by digits)
3. Calls `authenticate_promoter_by_id_only()` database function
4. Database finds promoter by `promoter_id` in `profiles` table
5. Returns user profile data and internal auth email (password verification done by Supabase Auth)
6. Frontend uses Supabase Auth to sign in with the auth email and password
7. Supabase Auth verifies the password using its secure hashing
8. User is logged in successfully

### Signup Flow

1. Admin creates new promoter via form
2. Backend calls `create_promoter_with_id_auth()`
3. System generates unique Promoter ID (e.g., BPVP28)
4. Creates auth user with unique email: `promoter+BPVP28@brightplanetventures.local`
5. Stores profile with real email/phone as metadata (can be duplicate)
6. Returns success with generated Promoter ID
7. Admin displays Promoter ID to new promoter
8. Promoter can immediately login with Promoter ID + Password

## 🎨 Benefits

### For Users
- ✅ Simple login with just Promoter ID + Password
- ✅ No confusion between multiple login methods
- ✅ Clear, consistent authentication experience
- ✅ Promoter ID is memorable and unique

### For System
- ✅ Clean, scalable authentication model
- ✅ No email/phone conflicts
- ✅ Consistent auth_user linkage
- ✅ Easy to troubleshoot
- ✅ Support multiple promoters with shared contact info

### For Administrators
- ✅ Flexible - email/phone can repeat across promoters
- ✅ Robust - unique Promoter ID ensures no conflicts
- ✅ Maintainable - clear separation between auth and metadata
- ✅ Scalable - grows without complexity

## 🔧 Maintenance

### Adding a New Promoter

1. Fill out promoter form with:
   - Name (required)
   - Email (optional, can be shared)
   - Password (required, min 8 chars)
   - Phone (required, but can be duplicate)
   - Address (optional)

2. System automatically:
   - Generates unique Promoter ID (e.g., BPVP28)
   - Creates auth user with unique email
   - Stores profile with metadata
   - Returns Promoter ID for display

3. Admin shares Promoter ID with new promoter

4. Promoter logs in with:
   - Promoter ID: BPVP28
   - Password: [their chosen password]

### Troubleshooting Login Issues

Use the diagnostic function:

```sql
SELECT diagnose_promoter_auth('BPVP01');
```

This will show:
- Whether profile exists
- Whether auth user exists
- The exact issue

## 📝 Database Functions

### authenticate_promoter_by_id_only()

```sql
SELECT authenticate_promoter_by_id_only('BPVP01', 'password123');
```

Returns:
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "promoter_id": "BPVP01",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210",
    ...
  },
  "auth_email": "promoter+BPVP01@brightplanetventures.local"
}
```

### create_promoter_with_auth_id()

**Note**: This function is called from the frontend after creating the auth user via Supabase Auth API.

The frontend workflow is:
1. Generate unique auth email: `promoter_TIMESTAMP_RANDOM@brightplanetventures.dev`
2. Create auth user using `supabase.auth.signUp()`
3. Call `create_promoter_with_auth_id()` with the returned user ID

```sql
SELECT create_promoter_with_auth_id(
  'John Doe',              -- p_name (required)
  'uuid-of-auth-user',     -- p_user_id (required)
  'promoter_1234567890_5678@brightplanetventures.dev', -- p_auth_email (required)
  'securepassword123',     -- p_password (required)
  '9876543210',            -- p_phone (required)
  'john@example.com',      -- p_email (optional)
  '123 Main St',           -- p_address (optional)
  NULL,                    -- p_parent_promoter_id (optional)
  'Affiliate',             -- p_role_level (optional)
  'Active'                 -- p_status (optional)
);
```

**Note**: Auth user creation is handled by the frontend using Supabase Auth API to ensure proper password hashing.

Returns:
```json
{
  "success": true,
  "promoter_id": "BPVP28",
  "user_id": "uuid",
  "name": "John Doe",
  "message": "Promoter created successfully. Use Promoter ID: BPVP28 to login."
}
```

## ⚠️ Migration Notes

### Existing Promoters

- All existing promoters will continue to work with their current Promoter IDs
- No migration needed for existing accounts
- They will use the new Promoter ID-only login method going forward

### Email/Phone Changes

- Email and phone are now metadata-only fields
- Multiple promoters can share the same email or phone
- Only Promoter ID is used for authentication
- No conflicts when creating promoters with duplicate contact info

### Authentication Method Deprecation

- Phone-based login: **REMOVED** ❌
- Email-based login for promoters: **REMOVED** ❌
- Promoter ID login: **PRIMARY METHOD** ✅
- Admin/customer login: **UNCHANGED** ✅

## 📚 Related Files

- Database: `database/promoter-id-only-auth-system.sql`
- Frontend Login: `frontend/src/common/pages/Login.js`
- Auth Service: `frontend/src/common/services/authService.js`
- Auth Context: `frontend/src/common/context/AuthContext.js`

## ✨ Summary

The promoter authentication system has been successfully revamped to use **ONLY Promoter ID + Password** for login. This creates a clean, consistent, and scalable authentication model that:

- ✅ Eliminates email/phone conflicts
- ✅ Simplifies login for promoters
- ✅ Provides unique, memorable Promoter IDs
- ✅ Maintains robust authentication with Supabase
- ✅ Scales easily as more promoters join

**Login is now simple**: Enter Promoter ID → Enter Password → Access granted! 🎉

