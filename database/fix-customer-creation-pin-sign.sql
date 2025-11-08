-- =====================================================
-- FIX CUSTOMER CREATION PIN SIGN
-- =====================================================
-- This script fixes the pin_usage_log to show customer creation as negative (pins consumed)

BEGIN;

-- =====================================================
-- 1. UPDATE EXISTING CUSTOMER CREATION RECORDS
-- =====================================================

-- Fix existing customer_creation records to show negative pins (consumed)
UPDATE pin_usage_log 
SET pins_used = -ABS(pins_used)  -- Ensure it's negative
WHERE action_type = 'customer_creation' 
AND pins_used > 0;  -- Only update positive values

-- =====================================================
-- 2. UPDATE CUSTOMER CREATION FUNCTIONS
-- =====================================================

-- Update any customer creation functions to use negative pins_used
-- Search for functions that insert into pin_usage_log with customer_creation

-- Example of what needs to be changed in customer creation functions:
-- OLD: INSERT INTO pin_usage_log (promoter_id, customer_id, pins_used, action_type, notes)
--      VALUES (p_parent_promoter_id, new_customer_id, 1, 'customer_creation', 'Customer created');
-- NEW: INSERT INTO pin_usage_log (promoter_id, customer_id, pins_used, action_type, notes)  
--      VALUES (p_parent_promoter_id, new_customer_id, -1, 'customer_creation', 'Customer created');

-- Note: This requires manual update of customer creation functions in your database
-- Look for functions like create_customer_final(), create_customer_with_pin_deduction(), etc.

COMMIT;

-- =====================================================
-- 3. VERIFICATION
-- =====================================================

-- Check that customer_creation records now show negative pins
SELECT 'CUSTOMER_CREATION_PIN_SIGN_CHECK' as check_type,
       action_type,
       pins_used,
       COUNT(*) as count
FROM pin_usage_log 
WHERE action_type = 'customer_creation'
GROUP BY action_type, pins_used
ORDER BY pins_used;

-- Show sample customer creation records
SELECT 'SAMPLE_CUSTOMER_CREATION_RECORDS' as check_type,
       transaction_id,
       action_type,
       pins_used,
       notes,
       created_at
FROM pin_usage_log 
WHERE action_type = 'customer_creation'
ORDER BY created_at DESC 
LIMIT 5;
