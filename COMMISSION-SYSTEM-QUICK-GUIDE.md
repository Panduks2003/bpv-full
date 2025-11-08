# 💰 Commission System Quick Access Guide

## 🎯 Where to Find Commission Earnings

### 👤 **FOR PROMOTERS** (http://localhost:3001)

**Navigation Menu:**
- Look for **"Commission History"** in the top navigation bar
- Located between "Pin Management" and "Withdrawal Request"

**Direct Access:**
```
http://localhost:3001/promoter/commission-history
```

**What You'll See:**
- 💵 **Wallet Balance** - Your available commission balance
- 📈 **Total Earned** - Lifetime commission earnings  
- 🏆 **Commission Count** - Number of commissions received
- 🎯 **Average Commission** - Average per transaction
- 📋 **Transaction History Table** with:
  - Commission Level (1-4)
  - Customer Name & ID
  - Amount Earned (₹500, ₹100, etc.)
  - Status (Credited/Pending/Failed)
  - Date & Time
  - Transaction Notes

---

### 👨‍💼 **FOR ADMIN** (http://localhost:3000)

**Navigation Menu:**
- Look for **"Commissions"** in the top navigation bar
- Located between "Pin Management" and "Withdrawals"

**Direct Access:**
```
http://localhost:3000/admin/affiliate-commissions
```

**What You'll See:**

**📊 Overview Tab:**
- 💰 Admin Wallet Balance
- 📊 Total Commission Received
- 🏦 Unclaimed Commissions (from missing affiliates)
- 📈 Total Transaction Count
- 📋 Commission Distribution Rules Display

**📜 History Tab:**
- Complete commission history for ALL promoters
- Advanced filters:
  - By Level (1-4 or Admin Fallback)
  - By Status (Credited/Pending/Failed)
  - By Date Range
- Detailed transaction table showing:
  - Transaction ID
  - Commission Level
  - Recipient Details
  - Amount
  - Status
  - Date & Time

**📈 Statistics Tab:**
- Commission distribution by level
- Status breakdown (Credited/Pending/Failed)
- Summary statistics
- Total amounts and averages

---

## 🧪 **How to Test the System**

### Step 1: Login as Promoter
```
URL: http://localhost:3001
```

### Step 2: Create a Test Customer
- Go to Home page
- Click "Create Customer" button
- Fill in customer details
- Submit the form

### Step 3: Check Commission Distribution
- Click "Commission History" in the navigation
- You should see:
  - ₹500 credited to your wallet (Level 1 commission)
  - If you have parent promoters, they get ₹100 each (Levels 2-4)
  - Any missing levels go to admin wallet

### Step 4: Verify as Admin
```
URL: http://localhost:3000
Login as admin
Click "Commissions" in navigation
```
- View all commission transactions
- Check admin wallet for unclaimed amounts
- Review statistics and distribution

---

## 💡 **Commission Distribution Rules**

When a customer is created:

| Level | Recipient | Amount | Notes |
|-------|-----------|--------|-------|
| **1** | Creator (Promoter who created customer) | **₹500** | Always credited |
| **2** | Parent of Level 1 | **₹100** | If exists |
| **3** | Parent of Level 2 | **₹100** | If exists |
| **4** | Parent of Level 3 | **₹100** | If exists |
| **Admin** | System Admin | **Remaining** | If any level missing |

**Total per customer: ₹800**

---

## 🔍 **Database Verification**

To verify commissions in the database:

```sql
-- Check recent commissions
SELECT * FROM affiliate_commissions 
ORDER BY created_at DESC 
LIMIT 10;

-- Check promoter wallet balances
SELECT 
  p.name,
  pw.balance,
  pw.total_earned,
  pw.commission_count
FROM promoter_wallet pw
JOIN profiles p ON pw.promoter_id = p.id
ORDER BY pw.total_earned DESC;

-- Check admin wallet
SELECT * FROM admin_wallet;
```

---

## ✅ **System Status**

- ✅ Database tables created
- ✅ Commission distribution function active
- ✅ Automatic triggers enabled
- ✅ Promoter UI complete
- ✅ Admin UI complete
- ✅ Navigation links added
- ✅ Routes configured
- ✅ Ready for testing!

---

## 🚀 **Quick Access Links**

**Promoter Panel:**
- Home: http://localhost:3001/promoter/home
- Commission History: http://localhost:3001/promoter/commission-history
- PIN Management: http://localhost:3001/promoter/pin-management

**Admin Panel:**
- Dashboard: http://localhost:3000/admin/dashboard
- Commissions: http://localhost:3000/admin/affiliate-commissions
- PIN Management: http://localhost:3000/admin/pins

---

## 📞 **Support**

If commissions are not appearing:
1. Check database connection
2. Verify customer was created successfully
3. Check affiliate_commissions table for records
4. Review browser console for errors
5. Check promoter_wallet and admin_wallet tables

**The system is now fully operational and ready for production use!** 🎉
