# Fix Withdrawal Request Issue - Quick Guide

## Problem
```
Failed to submit withdrawal request: new row violates row-level security policy for table "withdrawal_requests"
ERROR: relation "withdrawal_requests_id_seq" does not exist
```

## Solution - Apply This Script

### Step 1: Open Supabase SQL Editor
1. Go to: https://ubokvxgxszhpzmjonuss.supabase.co
2. Click **SQL Editor** in the left sidebar
3. Click **New query**

### Step 2: Run the Fix Script
1. Open file: `database/fix-withdrawal-rls-complete.sql`
2. Copy **ALL** contents
3. Paste into Supabase SQL Editor
4. Click **Run** (or press `Cmd+Enter`)

### Step 3: Verify Success
You should see output showing:
- ✅ Table Structure (with id column using sequence)
- ✅ Sequence Info (withdrawal_requests_id_seq)
- ✅ RLS Policies (4 policies created)
- ✅ Permissions (SELECT, INSERT, UPDATE granted)
- ✅ Success message

### Step 4: Test
1. Refresh your browser
2. Login as promoter BPVP36
3. Go to Withdrawal Request page
4. Submit a withdrawal - should work now!

## What This Script Does

1. **Fixes the Sequence Issue**
   - Creates `withdrawal_requests_id_seq` if missing
   - Links it to the `id` column
   - Sets proper starting value

2. **Fixes RLS Policies**
   - Removes old conflicting policies
   - Creates 4 new policies:
     - Promoters can view their own withdrawals
     - Promoters can insert new withdrawals ✨ (this was missing!)
     - Promoters can update pending withdrawals
     - Admins can do everything

3. **Grants Permissions**
   - Allows authenticated users to access the table
   - Grants sequence usage rights

4. **Adds Performance Indexes**
   - Speeds up queries by promoter_id, status, and date

## If It Still Doesn't Work

Check the console for any new errors and share them. The script includes comprehensive verification queries that will help diagnose any remaining issues.
