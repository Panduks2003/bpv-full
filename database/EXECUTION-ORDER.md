# Promoter Hierarchy System - Execution Order

Execute these SQL files in the following order to avoid errors:

## Step 1: Create Table Structure
```sql
\i 01-hierarchy-table-creation.sql
```

## Step 2A: Add Foreign Keys (Optional)
```sql
\i 02a-add-foreign-keys.sql
```

## Step 2B: Create Indexes
```sql
\i 02-hierarchy-indexes.sql
```

## Step 3: Create Helper Functions
```sql
\i 03-hierarchy-helper-functions.sql
```

## Step 4: Create Main Functions
```sql
\i 04-build-hierarchy-function.sql
```

## Step 5: Create Rebuild Function
```sql
\i 05-rebuild-all-hierarchies-function.sql
```

## Alternative: Execute All at Once
If you want to run all steps together, you can execute them one by one in your database client, or create a master script that includes all files.

## Test the System
After all steps are complete, you can test with:
```sql
-- Test building hierarchy for existing promoters
SELECT rebuild_all_promoter_hierarchies();
```

## Notes
- If Step 2A fails (foreign keys), you can skip it and the system will still work
- Make sure the `profiles` table exists before running these scripts
- The system will automatically maintain hierarchies once set up
