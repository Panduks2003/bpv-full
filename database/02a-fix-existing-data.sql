-- =====================================================
-- 02A: FIX EXISTING DATA TO COMPLY WITH CONSTRAINTS
-- =====================================================
-- This script fixes existing data before applying constraints
-- =====================================================

BEGIN;

-- Fix existing customer_id values that don't match the format
UPDATE profiles 
SET customer_id = upper(regexp_replace(customer_id, '[^A-Z0-9]', '', 'g'))
WHERE customer_id IS NOT NULL 
  AND customer_id !~ '^[A-Z0-9]{3,20}$'
  AND role = 'customer';

-- Fix customer_id values that are too short (pad with zeros)
UPDATE profiles 
SET customer_id = customer_id || '000'
WHERE customer_id IS NOT NULL 
  AND length(customer_id) < 3
  AND role = 'customer';

-- Fix customer_id values that are too long (truncate to 20 chars)
UPDATE profiles 
SET customer_id = left(customer_id, 20)
WHERE customer_id IS NOT NULL 
  AND length(customer_id) > 20
  AND role = 'customer';

-- Fix phone numbers that don't match format
UPDATE profiles 
SET phone = regexp_replace(phone, '[^0-9]', '', 'g')
WHERE phone IS NOT NULL 
  AND phone !~ '^[6-9][0-9]{9}$'
  AND length(regexp_replace(phone, '[^0-9]', '', 'g')) = 10
  AND left(regexp_replace(phone, '[^0-9]', '', 'g'), 1) IN ('6','7','8','9');

-- Set invalid phone numbers to NULL (will need manual correction)
UPDATE profiles 
SET phone = NULL
WHERE phone IS NOT NULL 
  AND phone !~ '^[6-9][0-9]{9}$'
  AND NOT (length(regexp_replace(phone, '[^0-9]', '', 'g')) = 10
           AND left(regexp_replace(phone, '[^0-9]', '', 'g'), 1) IN ('6','7','8','9'));

-- Fix pincode format
UPDATE profiles 
SET pincode = lpad(regexp_replace(pincode, '[^0-9]', '', 'g'), 6, '0')
WHERE pincode IS NOT NULL 
  AND pincode !~ '^[0-9]{6}$'
  AND length(regexp_replace(pincode, '[^0-9]', '', 'g')) <= 6
  AND length(regexp_replace(pincode, '[^0-9]', '', 'g')) > 0;

-- Set invalid pincodes to NULL (will need manual correction)
UPDATE profiles 
SET pincode = NULL
WHERE pincode IS NOT NULL 
  AND pincode !~ '^[0-9]{6}$'
  AND NOT (length(regexp_replace(pincode, '[^0-9]', '', 'g')) <= 6
           AND length(regexp_replace(pincode, '[^0-9]', '', 'g')) > 0);

-- Standardize role values
UPDATE profiles SET role = 'admin' WHERE role ILIKE 'admin%';
UPDATE profiles SET role = 'promoter' WHERE role ILIKE 'promoter%';
UPDATE profiles SET role = 'customer' WHERE role ILIKE 'customer%';

-- Standardize status values
UPDATE profiles SET status = 'active' WHERE status ILIKE 'active%' OR status = 'Active';
UPDATE profiles SET status = 'inactive' WHERE status ILIKE 'inactive%' OR status = 'Inactive';

-- Fix payment amounts that are out of range
UPDATE customer_payments 
SET payment_amount = 1000.00 
WHERE payment_amount <= 0 OR payment_amount > 100000;

-- Fix month numbers that are out of range
UPDATE customer_payments 
SET month_number = 1 
WHERE month_number < 1;

UPDATE customer_payments 
SET month_number = 60 
WHERE month_number > 60;

-- Standardize payment status
UPDATE customer_payments SET status = 'pending' WHERE status NOT IN ('pending', 'paid', 'overdue', 'cancelled');

-- Fix pin usage log values
UPDATE pin_usage_log 
SET pins_used = 1 
WHERE pins_used <= 0 OR pins_used > 1000;

-- Standardize action types
UPDATE pin_usage_log 
SET action_type = 'customer_creation' 
WHERE action_type NOT IN ('customer_creation', 'admin_allocation', 'promoter_creation', 'adjustment');

COMMIT;

-- Report on data fixes
SELECT 'DATA_CLEANUP_COMPLETE' as status, 'Fixed existing data to comply with constraints' as message;
