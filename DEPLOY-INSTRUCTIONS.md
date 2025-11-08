# 🚀 Deploy PIN Request Management System

## Quick Start - 2 Steps

### Step 1: Deploy Database Functions

Run this SQL in your **Supabase Dashboard SQL Editor**:

```sql
-- File: database/deploy-pin-request-system.sql
-- Copy and paste the entire contents into Supabase SQL Editor
```

**Or** run via CLI:
```bash
supabase db execute -f database/deploy-pin-request-system.sql
```

### Step 2: Test the System

1. **Admin Dashboard** → **Pin Management**
2. Click **"PIN Requests"** tab
3. You should now be able to:
   - ✅ View all PIN requests
   - ✅ Approve requests with one click
   - ✅ Reject requests with notes
   - ✅ See real-time PIN balance updates

---

## 📋 What Gets Installed

### Tables
- ✅ `pin_requests` - Stores all PIN requests

### Functions
- ✅ `approve_pin_request()` - Approves request and adds pins
- ✅ `reject_pin_request()` - Rejects request without adding pins

### Permissions
- ✅ Promoters can create and view their own requests
- ✅ Admins can view, approve, and reject all requests
- ✅ Proper RLS policies for security

---

## 🎯 How to Use

### As Admin - Approve Requests

1. Go to **Admin Dashboard → Pin Management → PIN Requests Tab**
2. Find a pending request
3. Click **✅ Approve** button
4. Add notes (optional)
5. Click **"Confirm Approval"**
6. ✅ Pins are instantly added to promoter's balance

### As Admin - Reject Requests

1. Same as above, but click **❌ Reject** button
2. **Required**: Add rejection reason
3. Click **"Confirm Rejection"**
4. ❌ Request is rejected, no pins are added

### As Admin - Direct Allocation

1. Go to **Direct Allocation** tab
2. Find promoter
3. Click **✏️ Edit** icon
4. Enter pins to add
5. Click **"Add Pins"**
6. ✅ Pins added instantly

---

## 🔧 Verification

After deploying, verify with:

```sql
-- Check if table exists
SELECT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'pin_requests'
);

-- Check if functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name IN ('approve_pin_request', 'reject_pin_request');
```

You should see:
- ✅ `pin_requests` table exists
- ✅ Both functions exist

---

## 📝 Notes

- All requests are logged for audit trail
- Pins are added instantly when approved
- Promoters see real-time status updates
- All actions are tracked with timestamps

---

## ✅ Done!

The PIN Request Management System is now fully operational! 🎉

