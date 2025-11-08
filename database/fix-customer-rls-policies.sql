-- =====================================================
-- FIX CUSTOMER RLS POLICIES
-- =====================================================
-- Ensures customers can update their own profiles
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "customers_can_view_own_profile" ON profiles;
DROP POLICY IF EXISTS "customers_can_update_own_profile" ON profiles;

-- Create proper RLS policies
CREATE POLICY "customers_can_view_own_profile" 
ON profiles
FOR SELECT
USING (
    id = auth.uid() AND role = 'customer'
);

CREATE POLICY "customers_can_update_own_profile" 
ON profiles
FOR UPDATE
USING (
    id = auth.uid() AND role = 'customer'
)
WITH CHECK (
    id = auth.uid() AND role = 'customer'
);

-- Verify policies
SELECT 
    '✅ RLS POLICIES' as status,
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN '✅ Read'
        WHEN cmd = 'UPDATE' THEN '✅ Update'
        ELSE cmd
    END as permission
FROM pg_policies
WHERE tablename = 'profiles'
AND (policyname LIKE '%customer%' OR policyname LIKE '%own%')
ORDER BY cmd;

-- Test with BPC004
SELECT 
    '🔍 TEST WITH BPC004' as check,
    p.customer_id,
    p.name,
    p.id = auth.uid() as "can_access_own_profile",
    EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'customers_can_update_own_profile'
    ) as "update_policy_exists"
FROM profiles p
WHERE p.customer_id = 'BPC004';

-- =====================================================
-- ADD MISSING COLUMNS TO PROFILES TABLE
-- =====================================================
DO $$
BEGIN
    -- Add mobile column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'mobile'
    ) THEN
        ALTER TABLE profiles ADD COLUMN mobile VARCHAR(20);
        RAISE NOTICE 'Added mobile column to profiles table';
    END IF;
    
    -- Add password column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'password'
    ) THEN
        ALTER TABLE profiles ADD COLUMN password VARCHAR(255);
        RAISE NOTICE 'Added password column to profiles table';
    END IF;
END $$;

-- Update existing records with phone number as mobile if empty
UPDATE profiles SET mobile = phone WHERE mobile IS NULL;

-- =====================================================
-- CREATE MISSING PIN DEDUCTION FUNCTION
-- =====================================================
-- The application expects deduct_promoter_pin (singular) but we have deduct_promoter_pins (plural)
-- Create the expected function that wraps the existing one

-- Drop existing function first to allow parameter name changes
DROP FUNCTION IF EXISTS deduct_promoter_pin(INTEGER, UUID);

CREATE FUNCTION deduct_promoter_pin(
    pins_to_deduct INTEGER,
    promoter_id UUID
) RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_pins INTEGER;
    result JSON;
BEGIN
    -- Check if promoter exists and get current pins
    SELECT p.pins INTO current_pins
    FROM profiles p
    WHERE p.id = deduct_promoter_pin.promoter_id AND p.role = 'promoter';
    
    IF current_pins IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Promoter not found'
        );
    END IF;
    
    -- Check if sufficient pins available
    IF current_pins < pins_to_deduct THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Insufficient pins',
            'available', current_pins,
            'required', pins_to_deduct
        );
    END IF;
    
    -- Deduct pins using existing function
    BEGIN
        PERFORM deduct_promoter_pins(deduct_promoter_pin.promoter_id, pins_to_deduct);
        
        -- Get updated balance
        SELECT p.pins INTO current_pins
        FROM profiles p
        WHERE p.id = deduct_promoter_pin.promoter_id;
        
        RETURN json_build_object(
            'success', true,
            'message', 'PIN deducted successfully',
            'pins_deducted', pins_to_deduct,
            'remaining_balance', current_pins
        );
        
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
    END;
END $$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION deduct_promoter_pin(INTEGER, UUID) TO authenticated;
