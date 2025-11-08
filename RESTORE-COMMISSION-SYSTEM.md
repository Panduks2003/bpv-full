# 🔄 RESTORE COMMISSION SYSTEM

## Problem
The commission system was working before but got disconnected during the customer creation function updates. When a customer is created, commissions are NOT being calculated and distributed.

## Solution
The commission distribution function **already exists** and works correctly. We just need to reconnect it to the customer creation process.

## Commission Structure (Already Implemented)
- **Level 1 (Direct)**: ₹500
- **Level 2**: ₹100
- **Level 3**: ₹100
- **Level 4**: ₹100
- **Total**: ₹800 per customer

**If no upline exists at any level, that amount goes to Admin.**

## How It Works

### Existing Commission Function
The `distribute_affiliate_commission()` function already exists in the database and handles:
1. ✅ Distributes ₹500 to Level 1 (direct promoter)
2. ✅ Distributes ₹100 to Level 2 (parent of Level 1)
3. ✅ Distributes ₹100 to Level 3 (parent of Level 2)
4. ✅ Distributes ₹100 to Level 4 (parent of Level 3)
5. ✅ Any unclaimed commission goes to Admin wallet
6. ✅ Updates promoter wallets automatically
7. ✅ Creates commission records in `affiliate_commissions` table

### What Was Missing
The `create_customer_with_pin_deduction()` function was NOT calling the commission distribution function.

## Fix Required

### Run This SQL Script:
```
database/add-commission-to-customer-creation.sql
```

### Steps:
1. Open Supabase Dashboard → SQL Editor → New Query
2. Copy ALL contents from `add-commission-to-customer-creation.sql`
3. Paste and click **Run**
4. You should see: `✅ Customer creation function updated with commission calculation`

### What This Does:
Updates the `create_customer_with_pin_deduction()` function to:
1. Create the customer (existing)
2. Deduct 1 PIN (existing)
3. Create payment schedule (existing)
4. **NEW: Call `distribute_affiliate_commission()` to calculate and distribute ₹800**

## Testing After Fix

### Test 1: Create a Customer as Promoter
1. Login as promoter (BPVP36)
2. Create a new customer
3. Check promoter wallet - should show +₹500 commission

### Test 2: Check Commission Records
Run this query in Supabase SQL Editor:
```sql
SELECT 
    ac.id,
    ac.level,
    ac.amount,
    ac.status,
    p.name as recipient_name,
    p.promoter_id,
    ac.note,
    ac.created_at
FROM affiliate_commissions ac
LEFT JOIN profiles p ON ac.recipient_id = p.id
ORDER BY ac.created_at DESC
LIMIT 10;
```

### Test 3: Check Promoter Wallet
```sql
SELECT 
    p.name,
    p.promoter_id,
    pw.balance,
    pw.total_earned,
    pw.commission_count,
    pw.last_commission_at
FROM promoter_wallet pw
JOIN profiles p ON pw.promoter_id = p.id
WHERE p.role = 'promoter'
ORDER BY pw.updated_at DESC;
```

### Test 4: Check Admin Fallback
If a promoter has no upline, check admin wallet:
```sql
SELECT 
    aw.balance,
    aw.total_commission_received,
    aw.unclaimed_commissions,
    aw.commission_count
FROM admin_wallet aw
LIMIT 1;
```

## Expected Results

### Scenario 1: Promoter with Full Upline (4 levels)
- Level 1 gets ₹500
- Level 2 gets ₹100
- Level 3 gets ₹100
- Level 4 gets ₹100
- Admin gets ₹0

### Scenario 2: Promoter with 2 Levels Only
- Level 1 gets ₹500
- Level 2 gets ₹100
- Admin gets ₹200 (unclaimed from Level 3 & 4)

### Scenario 3: Promoter with No Upline
- Level 1 gets ₹500
- Admin gets ₹300 (unclaimed from Level 2, 3 & 4)

## Database Tables Involved

### `affiliate_commissions`
Stores all commission records with:
- customer_id
- initiator_promoter_id
- recipient_id
- level (1-4, or 0 for admin)
- amount
- status (credited/pending/failed)
- transaction_id

### `promoter_wallet`
Tracks promoter wallet balances:
- balance (current available)
- total_earned (lifetime)
- total_withdrawn
- commission_count

### `admin_wallet`
Tracks admin wallet for unclaimed commissions:
- balance
- total_commission_received
- unclaimed_commissions
- commission_count

## Verification

After running the fix, create a test customer and verify:
1. ✅ Customer created successfully
2. ✅ 1 PIN deducted from promoter
3. ✅ Commission records created in `affiliate_commissions`
4. ✅ Promoter wallet updated with ₹500
5. ✅ Upline wallets updated (if they exist)
6. ✅ Admin wallet updated for any unclaimed amounts

## Important Notes

- The commission system is **already fully implemented**
- We're just **reconnecting** it to customer creation
- No changes to commission amounts or logic needed
- The function handles all edge cases (missing uplines, admin fallback, etc.)
- All transactions are atomic (all or nothing)

## Troubleshooting

If commissions are still not working after the fix:

1. **Check if function exists:**
   ```sql
   SELECT proname FROM pg_proc WHERE proname = 'distribute_affiliate_commission';
   ```

2. **Check for errors in logs:**
   Look for NOTICE messages in Supabase logs after customer creation

3. **Verify tables exist:**
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_name IN ('affiliate_commissions', 'promoter_wallet', 'admin_wallet');
   ```

4. **Test commission function directly:**
   ```sql
   SELECT distribute_affiliate_commission(
       '<customer_id>'::UUID,
       '<promoter_id>'::UUID
   );
   ```

---

## Summary

The commission system (₹500, ₹100, ₹100, ₹100 with admin fallback) is already implemented and working. We just need to run the SQL script to reconnect it to the customer creation process. After that, every new customer will automatically trigger commission distribution! 🎉
