# Admin Pin Management System Guide

## Overview

The Pin Management System allows admins to:
1. **Approve/Reject PIN Requests** from promoters
2. **Directly Allocate Pins** to promoters
3. **View PIN Transaction History**

---

## 📍 Accessing Pin Management

**Location**: Admin Dashboard → **Pin Management**

**URL**: `/admin/pins`

---

## 🔄 How to Approve/Reject PIN Requests

### Step 1: Navigate to PIN Requests Tab

1. Go to **Admin Dashboard**
2. Click **"Pin Management"** in the navigation
3. Click the **"PIN Requests"** tab at the top
4. You'll see a list of all pending PIN requests from promoters

### Step 2: Review PIN Requests

The PIN Requests tab shows:
- **Request ID**: Unique identifier
- **Promoter Name**: Who requested the pins
- **Requested Pins**: Number of pins requested
- **Request Date**: When the request was made
- **Status**: Pending/Approved/Rejected

### Step 3: Approve or Reject

#### **To Approve a Request**:
1. Find the request you want to approve
2. Click the **✅ Approve** button (green checkmark)
3. A modal will appear
4. **Add Admin Notes** (optional): Explain why you're approving
5. Click **"Confirm Approval"**
6. The promoter will receive the pins immediately

#### **To Reject a Request**:
1. Find the request you want to reject
2. Click the **❌ Reject** button (red X)
3. A modal will appear
4. **Add Rejection Reason** (required): Explain why you're rejecting
5. Click **"Confirm Rejection"**
6. The promoter will be notified

---

## 💾 Direct PIN Allocation

### Step 1: Navigate to Direct Allocation Tab

1. In **Pin Management**, click the **"Direct Allocation"** tab
2. You'll see a list of all promoters

### Step 2: Allocate Pins to a Promoter

1. Find the promoter you want to give pins to
2. Click the **✏️ Edit icon** (pencil) in the Actions column
3. A modal will open showing:
   - **Promoter Name**
   - **Email**
   - **Current Pin Balance**
4. Enter the number of pins to add
5. Click **"Add Pins"**

### Step 3: View Updated Balance

After allocation:
- The promoter's pin balance updates immediately
- The transaction is recorded in the PIN transaction history
- You'll see a success message

---

## 📊 PIN Transaction History

The **"Requests"** tab also shows a complete transaction history including:

- **Customer Creations**: Pins deducted when promoters create customers
- **Admin Allocations**: Pins added by admin
- **Admin Deductions**: Pins removed by admin
- **Request Approvals**: Pins allocated via approved requests
- **Request Rejections**: Requests that were denied

---

## 🎯 Key Features

### Auto-Actions

When you **approve** a PIN request:
- ✅ Pins are automatically added to the promoter's balance
- ✅ Transaction is recorded in history
- ✅ Promoter is notified
- ✅ Request status changes from "Pending" to "Approved"

When you **reject** a PIN request:
- ❌ No pins are deducted
- ❌ Transaction is recorded for audit purposes
- ❌ Promoter is notified with rejection reason
- ❌ Request status changes from "Pending" to "Rejected"

### Search and Filter

- **Search by**: Request ID, Promoter Email, or Promoter Name
- **Filter by**: Action Type (Customer Creation, Admin Allocation, etc.)
- **Sort by**: Date (newest first)

### Statistics Dashboard

At the top of the Pin Management page, you'll see:
- **Total Transactions**: All PIN-related activities
- **Customer Creations**: Pins used for customer creation
- **Admin Allocations**: Pins given directly by admin
- **Admin Deductions**: Pins removed by admin

---

## ⚠️ Important Notes

### Approval Best Practices

1. **Review the Request**: Check why the promoter needs more pins
2. **Verify Promoter Status**: Ensure the promoter is active and in good standing
3. **Add Notes**: Document your reason for approval/rejection for audit trail
4. **Monitor Balance**: Check the promoter's current pin balance before approving large requests

### Rejection Best Practices

1. **Always Provide a Reason**: Help promoters understand why their request was rejected
2. **Be Specific**: Explain what they need to do differently if applicable
3. **Record for Audit**: All rejections are logged for compliance

---

## 🔍 Troubleshooting

### Issue: "Could not find the function" Error

**Cause**: Database function `get_pin_requests` doesn't exist

**Solution**: The system will automatically fall back to direct table queries

### Issue: Approval Modal Not Showing

**Cause**: JavaScript error or modal state issue

**Solution**: 
1. Refresh the page
2. Check browser console for errors
3. Try clicking the approve/reject button again

### Issue: PINs Not Added After Approval

**Cause**: Database transaction failed

**Solution**:
1. Check the promoter's balance in the "Direct Allocation" tab
2. If pins weren't added, use "Direct Allocation" to manually add them
3. Check the error message in browser console

---

## 📝 Database Functions (For Reference)

### approve_pin_request()
```sql
SELECT approve_pin_request(
  p_request_id := 'request-uuid',
  p_admin_id := 'admin-uuid',
  p_admin_notes := 'Approved for good performance'
);
```

### reject_pin_request()
```sql
SELECT reject_pin_request(
  p_request_id := 'request-uuid',
  p_admin_id := 'admin-uuid',
  p_admin_notes := 'Insufficient justification provided'
);
```

---

## ✅ Summary

**To Approve PIN Requests**:
1. Admin Dashboard → Pin Management → PIN Requests Tab
2. Click ✅ Approve button
3. Add notes and confirm

**To Allocate Pins Directly**:
1. Admin Dashboard → Pin Management → Direct Allocation Tab
2. Click ✏️ Edit icon for promoter
3. Enter number of pins and submit

All actions are logged in the PIN Transaction History for complete audit trail! 🎉

