-- =====================================================
-- SIMPLE WITHDRAWAL STATUS FIX
-- =====================================================
-- Run this directly in Supabase SQL Editor
-- =====================================================

-- 1. First, let's manually approve the pending withdrawal request
-- Replace the UUIDs with actual values from your database

UPDATE withdrawal_requests 
SET 
    status = 'approved',
    processed_at = NOW(),
    processed_by = (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
    admin_notes = 'Manual approval - fixing status update issue',
    updated_at = NOW()
WHERE id = 'ffdb2c27-33f6-42a8-bc53-7e545bd62ba1';

-- 2. Check if the update worked
SELECT 
    'After Manual Update' as info,
    id,
    status,
    processed_at,
    processed_by,
    admin_notes
FROM withdrawal_requests
WHERE id = 'ffdb2c27-33f6-42a8-bc53-7e545bd62ba1';

-- 3. Create a function for future status updates
CREATE OR REPLACE FUNCTION update_withdrawal_status_simple(
    request_id UUID,
    new_status VARCHAR(20),
    admin_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE withdrawal_requests 
    SET 
        status = new_status,
        processed_at = NOW(),
        processed_by = auth.uid(),
        admin_notes = COALESCE(admin_notes, withdrawal_requests.admin_notes),
        updated_at = NOW()
    WHERE id = request_id;
    
    RETURN FOUND;
END;
$$;

-- 4. Grant permissions
GRANT EXECUTE ON FUNCTION update_withdrawal_status_simple TO authenticated;

-- Success message
SELECT '✅ Withdrawal status manually updated and function created!' as result;
