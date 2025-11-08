# 🚨 URGENT FIX: Column "request_number" Error

## Problem
```
❌ PIN request returned error: column "request_number" does not exist
```

The `submit_pin_request()` function is trying to return a `request_number` column that doesn't exist in the table yet.

## Quick Fix - Run This SQL in Supabase

### Step 1: Open Supabase SQL Editor
1. Go to https://supabase.com/dashboard
2. Select your project
3. Click "SQL Editor" → "New Query"

### Step 2: Run This SQL

```sql
-- Fix submit_pin_request function to not reference request_number
CREATE OR REPLACE FUNCTION submit_pin_request(
    p_promoter_id UUID,
    p_requested_pins INTEGER,
    p_reason TEXT DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request_id UUID;
    v_pending_count INTEGER;
    v_result JSON;
BEGIN
    -- Validate promoter exists and has correct role
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = p_promoter_id AND role = 'promoter'
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid promoter ID or role'
        );
    END IF;

    -- Check for existing pending requests
    SELECT COUNT(*) INTO v_pending_count
    FROM pin_requests 
    WHERE promoter_id = p_promoter_id AND status = 'pending';

    IF v_pending_count > 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'You already have a pending PIN request. Please wait for admin approval.'
        );
    END IF;

    -- Validate requested pins
    IF p_requested_pins <= 0 OR p_requested_pins > 1000 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Requested PINs must be between 1 and 1000'
        );
    END IF;

    -- Insert the request
    INSERT INTO pin_requests (promoter_id, requested_pins, reason)
    VALUES (p_promoter_id, p_requested_pins, p_reason)
    RETURNING id INTO v_request_id;

    -- Return success result (without request_number)
    v_result := json_build_object(
        'success', true,
        'request_id', v_request_id,
        'message', 'PIN request submitted successfully'
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END $$;

-- Also update get_pin_requests to not reference request_number
CREATE OR REPLACE FUNCTION get_pin_requests(
    p_promoter_id UUID DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE (
    id UUID,
    promoter_id UUID,
    promoter_name TEXT,
    promoter_email TEXT,
    requested_pins INTEGER,
    reason TEXT,
    status VARCHAR(20),
    approved_by UUID,
    admin_name TEXT,
    admin_notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pr.id,
        pr.promoter_id,
        p_promoter.name as promoter_name,
        p_promoter.email as promoter_email,
        pr.requested_pins,
        pr.reason,
        pr.status,
        pr.approved_by,
        p_admin.name as admin_name,
        pr.admin_notes,
        pr.approved_at,
        pr.created_at,
        pr.updated_at
    FROM pin_requests pr
    LEFT JOIN profiles p_promoter ON pr.promoter_id = p_promoter.id
    LEFT JOIN profiles p_admin ON pr.approved_by = p_admin.id
    WHERE 
        (p_promoter_id IS NULL OR pr.promoter_id = p_promoter_id)
        AND (p_status IS NULL OR pr.status = p_status)
    ORDER BY pr.created_at DESC
    LIMIT p_limit;
END $$;

-- Verification
SELECT 'Functions updated successfully' as status;
```

### Step 3: Click "Run"

You should see:
```
status: Functions updated successfully
```

### Step 4: Refresh Your Browser

1. Go back to http://localhost:3001/promoter/pin-management
2. Hard refresh: **Cmd + Shift + R** (Mac) or **Ctrl + Shift + F5** (Windows)
3. Try submitting a PIN request again

## What This Does

✅ Removes the `request_number` reference from `submit_pin_request()` function
✅ Removes the `request_number` reference from `get_pin_requests()` function  
✅ Functions now only use columns that actually exist in the table

## Expected Result

After running this SQL and refreshing:
- ✅ PIN request submission should work
- ✅ No more "column request_number does not exist" error
- ✅ You can submit PIN requests successfully

## Test It

1. Login as BPVP36 on http://localhost:3001/promoter/pin-management
2. Click "Request PINs"
3. Enter:
   - Number of PINs: 10
   - Reason: "Testing fixed PIN request system"
4. Submit

**Expected**: ✅ Success message!

---

## Alternative: Copy from File

The SQL is also available in:
```
database/fix-pin-request-function.sql
```

Just copy the entire file contents and paste into Supabase SQL Editor.
