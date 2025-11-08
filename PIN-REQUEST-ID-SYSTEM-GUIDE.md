# PIN Request ID System Implementation Guide

## Overview
This guide explains the new global sequential ID system for PIN requests, which generates formatted IDs like `PIN-REQ01`, `PIN-REQ02`, etc.

## What Changed

### Database Changes
- Added a new `formatted_request_id` column to the `pin_requests` table
- Created a sequence `pin_request_sequence` for generating sequential numbers
- Created a trigger to automatically generate formatted IDs when new requests are created
- Updated existing PIN requests to have formatted IDs

### Frontend Changes
- Updated `pinRequestService.js` to display the new formatted request IDs
- The system now shows `PIN-REQ01`, `PIN-REQ02`, etc. instead of generic request numbers

## How to Deploy

### Step 1: Run the Database Migration

1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Open and run the file: `database/pin-request-id-system.sql`
4. This will:
   - Create the sequence for generating IDs
   - Add the `formatted_request_id` column
   - Create the trigger function
   - Update existing records with formatted IDs
   - Set up automatic ID generation for new requests

### Step 2: Verify the Deployment

After running the SQL script, verify that:
- The `pin_requests` table has a `formatted_request_id` column
- Existing PIN requests have formatted IDs assigned
- New PIN requests will automatically get formatted IDs

### Step 3: Test the System

1. Go to the Admin PIN Requests page
2. Check that existing requests show IDs like `PIN-REQ01`
3. Create a new PIN request (as a promoter)
4. Verify it gets assigned the next sequential ID (e.g., `PIN-REQ02`)

## How It Works

### ID Format
- Format: `PIN-REQ` + sequential number (padded to 2 digits)
- Examples: `PIN-REQ01`, `PIN-REQ02`, `PIN-REQ03`, etc.
- After 99, it becomes `PIN-REQ100`, `PIN-REQ101`, etc.

### Automatic Generation
- When a new PIN request is created, the trigger fires automatically
- It calls `generate_pin_request_id()` function
- The function generates the next sequential number and formats it
- The ID is automatically assigned to the request

### Backward Compatibility
- Old requests without formatted IDs will show `REQ-XXX` format
- Once the migration is run, all requests will have formatted IDs
- The frontend gracefully handles both formats

## Database Functions

### `generate_pin_request_id()`
Generates the next formatted PIN request ID.

Returns: `VARCHAR(20)` - e.g., "PIN-REQ01"

### `get_next_pin_request_id()`
Gets the next ID without incrementing the sequence (for preview).

Returns: `VARCHAR(20)` - Shows what the next ID will be

### `get_pin_request_by_id(p_request_id VARCHAR(20))`
Retrieves a PIN request by its formatted ID.

Parameters:
- `p_request_id`: The formatted request ID (e.g., "PIN-REQ01")

Returns: PIN request record

## Sequence Management

The system uses a PostgreSQL sequence to ensure:
- **Global uniqueness**: Each ID is unique across all requests
- **Sequential numbering**: IDs are generated in order
- **No gaps**: Even if a request is deleted, the sequence continues
- **Thread-safe**: Multiple concurrent requests won't conflict

## Examples

### Example 1: Creating a PIN Request
```sql
INSERT INTO pin_requests (promoter_id, requested_pins, reason)
VALUES ('promoter-uuid', 50, 'Need more pins for customer creation');

-- Automatically gets assigned: PIN-REQ01
```

### Example 2: Querying by Formatted ID
```sql
SELECT * FROM get_pin_request_by_id('PIN-REQ01');
```

### Example 3: Viewing Next ID
```sql
SELECT get_next_pin_request_id();
-- Returns: PIN-REQ02 (without incrementing)
```

## Frontend Display

### Admin Dashboard
- PIN requests table shows the formatted ID in the "Request ID" column
- Modal displays show the formatted ID when approving/rejecting

### Promoter Dashboard
- Promoter's own requests show the formatted ID
- Request history displays formatted IDs

## Troubleshooting

### Issue: Error "cannot change return type of existing function"
**Solution**: The SQL script now includes DROP statements to handle this. The script automatically removes any column defaults that depend on the function.

### Issue: Error "cannot drop function because other objects depend on it"
**Solution**: The updated script now:
1. Removes any default values from columns that depend on the function
2. Drops triggers that depend on the function
3. Uses `CASCADE` option when dropping functions

If you still encounter dependency errors, you can manually resolve them:
```sql
-- Remove default value if it exists
ALTER TABLE pin_requests ALTER COLUMN request_id DROP DEFAULT IF EXISTS;

-- Drop trigger
DROP TRIGGER IF EXISTS trigger_set_pin_request_id ON pin_requests;

-- Drop functions with CASCADE
DROP FUNCTION IF EXISTS generate_pin_request_id() CASCADE;
DROP FUNCTION IF EXISTS set_pin_request_id() CASCADE;
```

Then run the migration script again.

### Issue: IDs are still showing REQ-XXX format
**Solution**: Run the database migration script again to update existing records

### Issue: New requests not getting formatted IDs
**Solution**: Check if the trigger `trigger_set_pin_request_id` exists and is enabled

### Issue: Duplicate IDs
**Solution**: The sequence should handle this automatically. Check if there's manual intervention

### Issue: Sequence restarting
**Solution**: Check if the sequence was accidentally dropped and recreated

## Migration Script Location
- **File**: `database/pin-request-id-system.sql`
- **Location**: Database folder in the project root

## Rollback (if needed)

If you need to rollback this system:

```sql
-- Drop the trigger
DROP TRIGGER IF EXISTS trigger_set_pin_request_id ON pin_requests;

-- Drop the functions
DROP FUNCTION IF EXISTS set_pin_request_id();
DROP FUNCTION IF EXISTS generate_pin_request_id();
DROP FUNCTION IF EXISTS get_next_pin_request_id();
DROP FUNCTION IF EXISTS get_pin_request_by_id(VARCHAR(20));

-- Drop the sequence
DROP SEQUENCE IF EXISTS pin_request_sequence;

-- Remove the column
ALTER TABLE pin_requests DROP COLUMN IF EXISTS formatted_request_id;
```

## Success Indicators

✅ SQL script executed without errors
✅ Existing PIN requests have formatted IDs
✅ New PIN requests automatically get formatted IDs
✅ Admin dashboard displays formatted IDs
✅ Promoter dashboard displays formatted IDs

## Notes

- The sequence starts at 1, so the first ID will be `PIN-REQ01`
- IDs are globally unique and increment forever
- The system handles existing data gracefully
- Frontend code already supports the new format

