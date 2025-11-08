# 📌 PIN SYSTEM INSTALLATION GUIDE

## 🚀 **QUICK INSTALLATION**

### **Option 1: Run All Parts Together**
```sql
\i 33-run-all-pin-system.sql
```

### **Option 2: Run Parts Separately (Recommended)**
```sql
-- Part 1: Add pins column
\i 33a-add-pins-column.sql

-- Part 2: Create pin management functions  
\i 33b-pin-management-functions.sql

-- Part 3: Create support tables
\i 33c-create-support-tables.sql

-- Part 4: Create customer creation function
\i 33d-customer-creation-function.sql
```

---

## 📋 **INSTALLATION PARTS**

### **Part 1: `33a-add-pins-column.sql`**
- ✅ Adds `pins` column to `profiles` table
- ✅ Creates index for performance
- ✅ Initializes existing promoters with 0 pins

### **Part 2: `33b-pin-management-functions.sql`**
- ✅ `check_promoter_pins()` - Validates pin availability
- ✅ `deduct_promoter_pins()` - Safely deducts pins
- ✅ `add_promoter_pins()` - Allows admin pin allocation

### **Part 3: `33c-create-support-tables.sql`**
- ✅ `pin_usage_log` table - Tracks all pin operations
- ✅ `customer_payments` table - Manages payment schedules
- ✅ RLS policies for security

### **Part 4: `33d-customer-creation-function.sql`**
- ✅ `create_customer_with_pin_deduction()` - Enhanced customer creation
- ✅ Pin validation and deduction
- ✅ Atomic transactions with rollback

---

## ✅ **VERIFICATION**

After installation, verify all components:

```sql
-- Check pins column
SELECT pins FROM profiles WHERE role = 'promoter' LIMIT 1;

-- Check functions exist
SELECT proname FROM pg_proc WHERE proname LIKE '%pin%';

-- Check tables exist
SELECT tablename FROM pg_tables WHERE tablename IN ('pin_usage_log', 'customer_payments');

-- Test pin allocation (replace UUID with actual promoter ID)
SELECT add_promoter_pins('your-promoter-uuid-here', 10);
```

---

## 🔧 **TROUBLESHOOTING**

### **Common Issues:**

1. **Function signature errors**: Run parts separately to isolate issues
2. **Permission errors**: Ensure you have SUPERUSER privileges
3. **Column already exists**: Safe to ignore, script handles this
4. **RLS policy conflicts**: Drop existing policies if needed

### **If Installation Fails:**
1. Run each part separately
2. Check error messages for specific issues
3. Verify database permissions
4. Ensure no conflicting functions/tables exist

---

## 🎯 **POST-INSTALLATION**

### **1. Allocate Initial Pins to Promoters:**
```sql
-- Give 50 pins to a promoter (replace with actual UUID)
SELECT add_promoter_pins('promoter-uuid-here', 50);
```

### **2. Test Customer Creation:**
- Use the frontend to create a customer
- Verify pin deduction works
- Check pin_usage_log for audit trail

### **3. Monitor Pin Usage:**
```sql
-- View pin usage log
SELECT * FROM pin_usage_log ORDER BY created_at DESC;

-- Check promoter pin balances
SELECT name, pins FROM profiles WHERE role = 'promoter';
```

---

## ✅ **SYSTEM READY**

Once installed, the system will:
- ✅ Require pins for customer creation
- ✅ Automatically deduct 1 pin per customer
- ✅ Prevent creation without sufficient pins
- ✅ Provide admin interface for pin allocation
- ✅ Track all pin operations with audit trail

**The pin-based customer creation system is now ready for production use!**
