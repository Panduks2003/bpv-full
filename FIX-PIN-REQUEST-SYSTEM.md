# Fix PIN Request System - Quick Guide

## Problem
The PIN request system is failing because the database tables and functions are missing:
- `pin_requests` table doesn't exist
- `submit_pin_request()` function doesn't exist  
- `get_pin_requests()` function doesn't exist

## Solution - Run SQL Script in Supabase

### Step 1: Open Supabase SQL Editor
1. Go to https://supabase.com/dashboard
2. Select your project: **ubokvxgxszhpzmjonuss**
3. Click on **SQL Editor** in the left sidebar
4. Click **New Query**

### Step 2: Copy and Run the SQL Script

Copy the entire contents of this file:
```
database/setup-pin-requests-simple.sql
```

Or use the SQL below:

```sql
-- =====================================================
-- SIMPLE PIN REQUESTS SETUP SCRIPT
-- =====================================================
-- Run this script to set up the PIN requests system

-- Create the pin_requests table
CREATE TABLE IF NOT EXISTS pin_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_number SERIAL UNIQUE,
    promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    requested_pins INTEGER NOT NULL CHECK (requested_pins > 0),
    reason TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    approved_by UUID REFERENCES profiles(id),
    admin_notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_pin_requests_promoter_id ON pin_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_pin_requests_status ON pin_requests(status);
CREATE INDEX IF NOT EXISTS idx_pin_requests_created_at ON pin_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pin_requests_approved_by ON pin_requests(approved_by);

-- Enable Row Level Security
ALTER TABLE pin_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (with safe creation)
DO $$
BEGIN
    -- Drop existing policies if they exist
    DROP POLICY IF EXISTS "promoters_can_view_own_requests" ON pin_requests;
    DROP POLICY IF EXISTS "promoters_can_create_requests" ON pin_requests;
    DROP POLICY IF EXISTS "admins_can_view_all_requests" ON pin_requests;
    DROP POLICY IF EXISTS "admins_can_update_requests" ON pin_requests;

    -- Create new policies
    CREATE POLICY "promoters_can_view_own_requests" ON pin_requests
        FOR SELECT USING (promoter_id = auth.uid());

    CREATE POLICY "promoters_can_create_requests" ON pin_requests
        FOR INSERT WITH CHECK (promoter_id = auth.uid());

    CREATE POLICY "admins_can_view_all_requests" ON pin_requests
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.role = 'admin'
            )
        );

    CREATE POLICY "admins_can_update_requests" ON pin_requests
        FOR UPDATE USING (
            EXISTS (
                SELECT 1 FROM profiles 
                WHERE profiles.id = auth.uid() 
                AND profiles.role = 'admin'
            )
        );
EXCEPTION WHEN OTHERS THEN
    -- Ignore errors if policies already exist
    NULL;
END $$;

-- Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_pin_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS pin_requests_updated_at_trigger ON pin_requests;
CREATE TRIGGER pin_requests_updated_at_trigger
    BEFORE UPDATE ON pin_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_pin_requests_updated_at();

-- Create submit_pin_request function
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
    v_request_number INTEGER;
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
    RETURNING id, request_number INTO v_request_id, v_request_number;

    -- Return success result
    v_result := json_build_object(
        'success', true,
        'request_id', v_request_id,
        'request_number', v_request_number,
        'message', 'PIN request submitted successfully'
    );

    RETURN v_result;

EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END $$;

-- Create get_pin_requests function
CREATE OR REPLACE FUNCTION get_pin_requests(
    p_promoter_id UUID DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE (
    id UUID,
    request_number INTEGER,
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
        pr.request_number,
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION submit_pin_request(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_pin_requests(UUID, VARCHAR(20), INTEGER) TO authenticated;

-- Verification query
SELECT 
    'PIN Requests Setup' as status,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pin_requests') 
         THEN 'Table Created' ELSE 'Table Missing' END as table_status,
    (SELECT COUNT(*) FROM pg_proc WHERE proname IN ('submit_pin_request', 'get_pin_requests')) as functions_created;
```

### Step 3: Run the Query
1. Paste the SQL into the editor
2. Click **Run** button (or press Cmd/Ctrl + Enter)
3. Wait for the success message

### Step 4: Verify Installation
You should see output like:
```
status: PIN Requests Setup
table_status: Table Created
functions_created: 2
```

### Step 5: Refresh Your Application
1. Go back to your browser tabs with the application
2. Hard refresh (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)
3. Try submitting a PIN request again

## What This Script Does

✅ Creates `pin_requests` table with proper schema
✅ Creates indexes for performance
✅ Enables Row Level Security (RLS)
✅ Creates RLS policies for promoters and admins
✅ Creates `submit_pin_request()` function
✅ Creates `get_pin_requests()` function
✅ Grants proper permissions

## Expected Result

After running this script, promoters will be able to:
- Submit PIN requests
- View their own PIN requests
- See request status (pending/approved/rejected)

Admins will be able to:
- View all PIN requests
- Approve/reject requests
- Allocate PINs to promoters

## Troubleshooting

If you still see errors after running the script:

1. **Check if the script ran successfully**
   - Look for any error messages in the SQL editor
   - Make sure all statements completed

2. **Verify the functions exist**
   Run this query:
   ```sql
   SELECT proname FROM pg_proc 
   WHERE proname IN ('submit_pin_request', 'get_pin_requests');
   ```

3. **Verify the table exists**
   Run this query:
   ```sql
   SELECT * FROM information_schema.tables 
   WHERE table_name = 'pin_requests';
   ```

4. **Clear browser cache**
   - Hard refresh your application (Cmd+Shift+R)
   - Or clear browser cache completely

## Need Help?

If you encounter any issues, check the browser console for specific error messages and share them for further assistance.
