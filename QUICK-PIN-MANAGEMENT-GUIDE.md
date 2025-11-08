# Quick Guide: How to Approve/Reject PIN Requests

## 🎯 Location

**Admin Dashboard → Pin Management → PIN Requests Tab**

---

## ✅ How to Approve PIN Requests

### Step 1: Access Pin Requests
1. Login as Admin
2. Go to **Admin Dashboard**
3. Click **"Pin Management"** in the sidebar
4. Click the **"PIN Requests"** tab

### Step 2: Review Requests
You'll see a table with:
- **Request Number** (e.g., REQ-001)
- **Promoter Name**
- **Requested Pins** (how many pins they want)
- **Status** (Pending/Approved/Rejected)
- **Request Date**

### Step 3: Approve a Request
1. Find the request you want to approve
2. Click the **✅ Approve** button (green button in the Actions column)
3. A modal window will appear
4. **Add Admin Notes** (optional): Write a note explaining why
5. Click **"Confirm Approval"**
6. ✅ Done! Pins are instantly added to the promoter's account

---

## ❌ How to Reject PIN Requests

### Step 1-2: Same as above (Access Pin Requests Tab)

### Step 3: Reject a Request
1. Find the request you want to reject
2. Click the **❌ Reject** button (red button in the Actions column)
3. A modal window will appear
4. **Add Rejection Reason** (required): Explain why you're rejecting
5. Click **"Confirm Rejection"**
6. ❌ Done! Request is marked as rejected, no pins are deducted

---

## 💾 Direct PIN Allocation (Give Pins to Promoters)

### Step 1: Go to Direct Allocation Tab
- In **Pin Management**, click **"Direct Allocation"** tab

### Step 2: Allocate Pins
1. Find the promoter you want to give pins to
2. Click the **✏️ Edit** icon (pencil) in their row
3. Enter the number of pins to add
4. Click **"Add Pins"**
5. ✅ Done! Pins added instantly

---

## 📊 What Happens When You Approve

When you approve a PIN request:
- ✅ Pins are added to the promoter's balance automatically
- ✅ A transaction is recorded in the history
- ✅ The request status changes from "Pending" to "Approved"
- ✅ The promoter can immediately use those pins

---

## 🔍 Need to Install the Database Functions?

If you see "function not found" errors, run this SQL in Supabase:

```sql
-- Run: database/pin-request-system.sql
```

This creates:
- `pin_requests` table
- `approve_pin_request()` function
- `reject_pin_request()` function
- All necessary indexes and policies

---

## ✅ Summary

**To Approve**: PIN Requests Tab → ✅ Approve Button → Confirm  
**To Reject**: PIN Requests Tab → ❌ Reject Button → Add Reason → Confirm  
**To Allocate Directly**: Direct Allocation Tab → ✏️ Edit → Enter Pins → Submit

Everything is logged for complete audit trail! 🎉

