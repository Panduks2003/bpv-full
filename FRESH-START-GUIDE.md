# 🔄 FRESH START GUIDE - Reset Database

## ⚠️ IMPORTANT WARNING

This will **DELETE ALL DATA** from your database:
- ✅ All Promoters (except admin)
- ✅ All Customers
- ✅ All PIN Requests
- ✅ All PIN Transactions
- ✅ All Commissions
- ✅ All Withdrawals

**Database structure will be preserved** (tables, functions, triggers remain intact)

---

## 📋 STEP-BY-STEP RESET PROCESS

### **STEP 1: Backup Current Data (Optional but Recommended)**

Before resetting, you may want to backup:

1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `ubokvxgxszhpzmjonuss`
3. Go to: **Database** → **Backups**
4. Click: **Create Backup** (optional)

---

### **STEP 2: Run Reset SQL Script**

1. **Open Supabase SQL Editor:**
   - Go to: https://supabase.com/dashboard
   - Select project: `ubokvxgxszhpzmjonuss`
   - Click: **SQL Editor** (left sidebar)

2. **Create New Query:**
   - Click: **New Query**

3. **Copy and Paste:**
   - Open file: `database/RESET-DATABASE-FRESH-START.sql`
   - Copy ALL contents
   - Paste into SQL Editor

4. **Run the Script:**
   - Click: **Run** button (or press Ctrl+Enter)
   - Wait for completion (5-10 seconds)

5. **Check Results:**
   - You should see success messages
   - Final counts should show:
     ```
     - Admins: 1
     - Promoters: 0
     - Customers: 0
     - PIN Requests: 0
     - PIN Transactions: 0
     - Commissions: 0
     - Withdrawals: 0
     ```

---

### **STEP 3: Verify Fresh State**

#### **Option A: Check via Supabase Dashboard**

1. Go to: **Table Editor**
2. Check each table:
   - `profiles` → Should only have admin user
   - `pin_requests` → Should be empty
   - `pin_transactions` → Should be empty
   - `affiliate_commissions` → Should be empty
   - `withdrawal_requests` → Should be empty

#### **Option B: Check via SQL**

Run this query in SQL Editor:

```sql
-- Quick verification query
SELECT 
  'profiles' as table_name,
  role,
  COUNT(*) as count
FROM profiles
GROUP BY role

UNION ALL

SELECT 'pin_requests', 'all', COUNT(*) FROM pin_requests
UNION ALL
SELECT 'pin_transactions', 'all', COUNT(*) FROM pin_transactions
UNION ALL
SELECT 'affiliate_commissions', 'all', COUNT(*) FROM affiliate_commissions
UNION ALL
SELECT 'withdrawal_requests', 'all', COUNT(*) FROM withdrawal_requests
ORDER BY table_name, role;
```

Expected result:
```
profiles        | admin    | 1
pin_requests    | all      | 0
pin_transactions| all      | 0
affiliate_commissions | all | 0
withdrawal_requests   | all | 0
```

---

### **STEP 4: Reset Admin User (Optional)**

If you want to reset admin's PIN balance and wallet:

```sql
UPDATE profiles 
SET available_pins = 0,
    wallet_balance = 0
WHERE role = 'admin';
```

Or give admin some starting PINs:

```sql
UPDATE profiles 
SET available_pins = 100,
    wallet_balance = 0
WHERE role = 'admin';
```

---

### **STEP 5: Test Your Fresh Application**

1. **Clear Browser Cache:**
   - Press: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)

2. **Login to Admin:**
   - Go to: https://brightplanetventures.com/admin
   - Login with your admin credentials

3. **Verify Fresh State:**
   - Check: **Promoters** → Should be empty
   - Check: **Customers** → Should be empty
   - Check: **PIN Management** → Should be empty
   - Check: **Commissions** → Should be empty
   - Check: **Withdrawals** → Should be empty

4. **Create Test Data:**
   - Create 1 promoter to test
   - Create 1 customer to test
   - Verify commission system works
   - Verify PIN system works

---

## 🔧 ALTERNATIVE: Complete Fresh Start (Delete Admin Too)

If you want to delete admin and create a new one:

### **Step 1: Delete Everything**

Run this in Supabase SQL Editor:

```sql
BEGIN;

-- Delete all data
DELETE FROM withdrawal_requests;
DELETE FROM affiliate_commissions;
DELETE FROM pin_transactions;
DELETE FROM pin_requests;
DELETE FROM payment_schedules;
DELETE FROM profiles;

-- Delete all auth users
DELETE FROM auth.users;

COMMIT;
```

### **Step 2: Create New Admin**

1. **Go to Supabase Authentication:**
   - Dashboard → **Authentication** → **Users**
   - Click: **Add User**

2. **Create Admin User:**
   - Email: `admin@brightplanetventures.com`
   - Password: (your choice)
   - Auto Confirm: ✅ Yes

3. **Add Admin Profile:**

Run this SQL (replace `USER_ID` with the ID from step 2):

```sql
INSERT INTO profiles (
  id,
  email,
  name,
  role,
  available_pins,
  wallet_balance,
  created_at
) VALUES (
  'USER_ID_FROM_AUTH_USERS',
  'admin@brightplanetventures.com',
  'Admin',
  'admin',
  100,
  0,
  NOW()
);
```

---

## 📊 WHAT GETS DELETED

| Table | What Gets Deleted | What Remains |
|-------|------------------|--------------|
| `profiles` | All promoters & customers | Admin user (optional) |
| `auth.users` | All auth accounts | Admin auth (optional) |
| `pin_requests` | All PIN requests | Nothing |
| `pin_transactions` | All PIN transactions | Nothing |
| `affiliate_commissions` | All commissions | Nothing |
| `withdrawal_requests` | All withdrawals | Nothing |
| `payment_schedules` | All payment schedules | Nothing |

---

## 🛡️ WHAT STAYS INTACT

✅ **Database Structure:**
- All tables
- All columns
- All indexes
- All constraints

✅ **Database Functions:**
- `distribute_affiliate_commission()`
- `create_customer_with_pin_deduction()`
- `create_customer_final()`
- All other RPC functions

✅ **Database Triggers:**
- `trigger_affiliate_commission`
- All other triggers

✅ **Row Level Security (RLS):**
- All RLS policies
- All security rules

---

## 🎯 RECOMMENDED WORKFLOW

### **For Testing:**
1. Reset database using `RESET-DATABASE-FRESH-START.sql`
2. Keep admin user
3. Create 2-3 test promoters
4. Create 2-3 test customers
5. Test all features
6. Reset again when needed

### **For Production Launch:**
1. Reset database completely (delete admin too)
2. Create fresh admin account
3. Give admin initial PIN allocation
4. Start onboarding real promoters
5. Never reset again!

---

## 🆘 TROUBLESHOOTING

### **Issue: Script fails with permission error**

**Solution:** Make sure you're running as database owner or have admin privileges.

### **Issue: Some data remains after reset**

**Solution:** Run the verification query to see what's left, then manually delete.

### **Issue: Can't login after reset**

**Solution:** 
1. Check admin user exists in `auth.users`
2. Check admin profile exists in `profiles`
3. Clear browser cache and try again

### **Issue: Commission system not working after reset**

**Solution:** The functions and triggers are preserved. Just test with new data.

---

## 📝 QUICK RESET CHECKLIST

- [ ] Backup current data (optional)
- [ ] Open Supabase SQL Editor
- [ ] Copy `RESET-DATABASE-FRESH-START.sql`
- [ ] Run the script
- [ ] Verify counts are correct
- [ ] Clear browser cache
- [ ] Test admin login
- [ ] Create test promoter
- [ ] Create test customer
- [ ] Verify commission works
- [ ] Ready for fresh start! 🎉

---

## 🎉 YOU'RE READY!

Your database is now fresh and clean. Start creating real data for your production launch!

**Good luck with your fresh start!** 🚀
