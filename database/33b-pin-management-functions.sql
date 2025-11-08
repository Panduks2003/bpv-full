-- =====================================================
-- PART 2: PIN MANAGEMENT FUNCTIONS
-- =====================================================
-- This script creates the core pin management functions

BEGIN;

-- =====================================================
-- 2. CREATE PIN MANAGEMENT FUNCTIONS
-- =====================================================

-- Function to check if promoter has sufficient pins
CREATE OR REPLACE FUNCTION check_promoter_pins(
    p_promoter_id UUID,
    p_required_pins INTEGER DEFAULT 1
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_pins INTEGER;
BEGIN
    -- Get current pin count
    SELECT pins INTO current_pins
    FROM profiles
    WHERE id = p_promoter_id AND role = 'promoter';
    
    -- Return true if promoter has sufficient pins
    RETURN COALESCE(current_pins, 0) >= p_required_pins;
END $$;

-- Function to deduct pins from promoter
CREATE OR REPLACE FUNCTION deduct_promoter_pins(
    p_promoter_id UUID,
    p_pins_to_deduct INTEGER DEFAULT 1
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_pins INTEGER;
    updated_rows INTEGER;
BEGIN
    -- Get current pin count with row lock
    SELECT pins INTO current_pins
    FROM profiles
    WHERE id = p_promoter_id AND role = 'promoter'
    FOR UPDATE;
    
    -- Check if sufficient pins available
    IF COALESCE(current_pins, 0) < p_pins_to_deduct THEN
        RAISE EXCEPTION 'Insufficient pins. Required: %, Available: %', 
            p_pins_to_deduct, COALESCE(current_pins, 0);
    END IF;
    
    -- Deduct pins
    UPDATE profiles 
    SET pins = pins - p_pins_to_deduct,
        updated_at = NOW()
    WHERE id = p_promoter_id AND role = 'promoter';
    
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    
    IF updated_rows = 0 THEN
        RAISE EXCEPTION 'Failed to deduct pins from promoter %', p_promoter_id;
    END IF;
    
    RETURN TRUE;
END $$;

-- Function to add pins to promoter (for admin use)
CREATE OR REPLACE FUNCTION add_promoter_pins(
    p_promoter_id UUID,
    p_pins_to_add INTEGER
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    updated_rows INTEGER;
BEGIN
    -- Add pins
    UPDATE profiles 
    SET pins = COALESCE(pins, 0) + p_pins_to_add,
        updated_at = NOW()
    WHERE id = p_promoter_id AND role = 'promoter';
    
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    
    IF updated_rows = 0 THEN
        RAISE EXCEPTION 'Promoter not found or failed to add pins: %', p_promoter_id;
    END IF;
    
    RETURN TRUE;
END $$;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION check_promoter_pins(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION deduct_promoter_pins(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION add_promoter_pins(UUID, INTEGER) TO authenticated;

COMMIT;

-- Verification
SELECT 'FUNCTION_CHECK' as check_type, proname as function_name
FROM pg_proc 
WHERE proname IN (
    'check_promoter_pins',
    'deduct_promoter_pins', 
    'add_promoter_pins'
);
