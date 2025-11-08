# 🚀 Commission System Setup Instructions

## ⚠️ IMPORTANT: Run These SQL Scripts First!

The commission system requires database tables and functions to be created. Follow these steps:

## 📋 Step-by-Step Setup:

### 1. Run the Fixed Commission Table Creation
```bash
psql -U postgres -d your_database_name -f database/10-fix-commission-foreign-key.sql
```

### 2. Create Wallet Tables
```bash
psql -U postgres -d your_database_name -f database/02-create-wallet-tables.sql
```

### 3. Create Indexes
```bash
psql -U postgres -d your_database_name -f database/03-create-indexes.sql
```

### 4. Create Commission Distribution Function
```bash
psql -U postgres -d your_database_name -f database/05-create-commission-function.sql
```

### 5. Create Utility Functions
```bash
psql -U postgres -d your_database_name -f database/06-create-utility-functions.sql
```

### 6. Create Triggers
```bash
psql -U postgres -d your_database_name -f database/07-create-triggers.sql
```

### 7. Initialize Wallets
```bash
psql -U postgres -d your_database_name -f database/08-initialize-wallets.sql
```

### 8. Verify Setup
```bash
psql -U postgres -d your_database_name -f database/09-verification-queries.sql
```

---

## 🔧 Alternative: Run All at Once

Create a single script to run everything:

```bash
#!/bin/bash
DB_NAME="your_database_name"
DB_USER="postgres"

echo "🚀 Setting up Commission System..."

psql -U $DB_USER -d $DB_NAME -f database/10-fix-commission-foreign-key.sql
psql -U $DB_USER -d $DB_NAME -f database/02-create-wallet-tables.sql
psql -U $DB_USER -d $DB_NAME -f database/03-create-indexes.sql
psql -U $DB_USER -d $DB_NAME -f database/05-create-commission-function.sql
psql -U $DB_USER -d $DB_NAME -f database/06-create-utility-functions.sql
psql -U $DB_USER -d $DB_NAME -f database/07-create-triggers.sql
psql -U $DB_USER -d $DB_NAME -f database/08-initialize-wallets.sql
psql -U $DB_USER -d $DB_NAME -f database/09-verification-queries.sql

echo "✅ Commission System Setup Complete!"
```

---

## 🎯 Using Supabase Dashboard (Recommended)

If you're using Supabase, you can run these scripts directly in the SQL Editor:

1. Go to your Supabase Dashboard
2. Click on **SQL Editor** in the left sidebar
3. Create a **New Query**
4. Copy and paste each script content one by one
5. Click **Run** for each script

### Order to Run:
1. `10-fix-commission-foreign-key.sql` ✅ (Creates affiliate_commissions table)
2. `02-create-wallet-tables.sql` ✅ (Creates promoter_wallet and admin_wallet)
3. `03-create-indexes.sql` ✅ (Creates performance indexes)
4. `05-create-commission-function.sql` ✅ (Creates distribute_affiliate_commission function)
5. `06-create-utility-functions.sql` ✅ (Creates get_promoter_commission_summary function)
6. `07-create-triggers.sql` ✅ (Creates automatic triggers)
7. `08-initialize-wallets.sql` ✅ (Initializes wallets for existing users)
8. `09-verification-queries.sql` ✅ (Verifies everything is set up)

---

## ✅ Verification Checklist

After running all scripts, verify:

- [ ] `affiliate_commissions` table exists
- [ ] `promoter_wallet` table exists
- [ ] `admin_wallet` table exists
- [ ] `distribute_affiliate_commission()` function exists
- [ ] `get_promoter_commission_summary()` function exists
- [ ] `get_admin_commission_summary()` function exists
- [ ] Wallets initialized for existing promoters and admin
- [ ] All indexes created
- [ ] RLS policies active

---

## 🐛 Current Errors Explained:

**404 Errors:**
- `get_promoter_commission_summary` - Function doesn't exist yet
- `promoter_wallet` - Table doesn't exist yet
- `affiliate_commissions` - Table doesn't exist yet

**Solution:** Run the SQL scripts above to create these database objects!

---

## 🎉 After Setup:

Once all scripts are run successfully:
1. Refresh your browser
2. Create a test customer as a promoter
3. Check Commission History page
4. You should see ₹500 credited to your wallet!

---

## 📞 Need Help?

If you encounter errors:
1. Check your database connection
2. Verify you have proper permissions
3. Make sure you're connected to the correct database
4. Check the Supabase logs for detailed error messages
