-- =====================================================
-- REASSIGN EXISTING TRANSACTION IDs TO SEQUENTIAL
-- =====================================================
-- This script updates all existing commission records
-- to use clean sequential Transaction IDs: COM-01, COM-02, etc.
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: CREATE SEQUENCE IF NOT EXISTS
-- =====================================================

-- Create sequence for transaction IDs (if not already created)
CREATE SEQUENCE IF NOT EXISTS transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 1;

-- Reset sequence to start from 1
SELECT setval('transaction_id_seq', 1, false);

-- =====================================================
-- STEP 2: CREATE FUNCTION TO GENERATE SEQUENTIAL IDs
-- =====================================================

-- Function to generate clean sequential transaction IDs
CREATE OR REPLACE FUNCTION generate_transaction_id()
RETURNS TEXT AS $$
DECLARE
    v_next_id INTEGER;
    v_formatted_id TEXT;
BEGIN
    -- Get next value from sequence
    v_next_id := nextval('transaction_id_seq');
    
    -- Format as COM-XX (pad with zeros, minimum 2 digits)
    v_formatted_id := 'COM-' || LPAD(v_next_id::TEXT, 2, '0');
    
    RETURN v_formatted_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 3: SHOW CURRENT TRANSACTION IDs (BEFORE)
-- =====================================================

SELECT 
    '📊 CURRENT TRANSACTION IDs (BEFORE REASSIGNMENT)' as status,
    COUNT(*) as total_records,
    COUNT(DISTINCT transaction_id) as unique_transaction_ids,
    MIN(created_at) as oldest_record,
    MAX(created_at) as newest_record
FROM affiliate_commissions;

-- Show sample of current messy IDs
SELECT 
    '🔍 SAMPLE OF CURRENT MESSY IDs' as sample_type,
    id,
    transaction_id as old_transaction_id,
    level,
    recipient_type,
    amount,
    created_at
FROM affiliate_commissions 
ORDER BY created_at 
LIMIT 10;

-- =====================================================
-- STEP 4: REASSIGN ALL EXISTING TRANSACTION IDs
-- =====================================================

-- Update all existing commission records with sequential IDs
-- Order by created_at to maintain chronological sequence
UPDATE affiliate_commissions 
SET transaction_id = generate_transaction_id()
WHERE id IN (
    SELECT id 
    FROM affiliate_commissions 
    ORDER BY created_at, id
);

-- =====================================================
-- STEP 5: VERIFY THE REASSIGNMENT
-- =====================================================

-- Show updated transaction IDs
SELECT 
    '✅ UPDATED TRANSACTION IDs (AFTER REASSIGNMENT)' as status,
    COUNT(*) as total_records,
    COUNT(DISTINCT transaction_id) as unique_transaction_ids,
    MIN(transaction_id) as first_id,
    MAX(transaction_id) as last_id
FROM affiliate_commissions;

-- Show sample of new clean IDs
SELECT 
    '🎯 SAMPLE OF NEW CLEAN IDs' as sample_type,
    id,
    transaction_id as new_transaction_id,
    level,
    recipient_type,
    amount,
    created_at
FROM affiliate_commissions 
ORDER BY created_at 
LIMIT 10;

-- Show all transaction IDs in order
SELECT 
    '📋 ALL NEW TRANSACTION IDs IN ORDER' as list_type,
    transaction_id,
    level,
    recipient_type,
    amount,
    created_at,
    CASE 
        WHEN recipient_type = 'admin' THEN 'Admin Fallback'
        ELSE 'Level ' || level || ' Commission'
    END as commission_type
FROM affiliate_commissions 
ORDER BY 
    CAST(SUBSTRING(transaction_id FROM 'COM-(\d+)') AS INTEGER);

-- =====================================================
-- STEP 6: UPDATE SEQUENCE TO CONTINUE FROM NEXT NUMBER
-- =====================================================

-- Set sequence to continue from the next available number
SELECT setval('transaction_id_seq', 
    (SELECT COALESCE(
        MAX(CAST(SUBSTRING(transaction_id FROM 'COM-(\d+)') AS INTEGER)), 
        0
    ) FROM affiliate_commissions)
);

-- Show next ID that will be generated
SELECT 
    '🔮 NEXT TRANSACTION ID' as next_info,
    generate_transaction_id() as next_id,
    'This will be used for the next commission' as note;

-- Reset sequence back (since we just used one for testing)
SELECT setval('transaction_id_seq', 
    (SELECT COALESCE(
        MAX(CAST(SUBSTRING(transaction_id FROM 'COM-(\d+)') AS INTEGER)), 
        0
    ) FROM affiliate_commissions)
);

-- =====================================================
-- STEP 7: VERIFY SYSTEM INTEGRITY
-- =====================================================

-- Check for any duplicate transaction IDs
SELECT 
    '🔍 DUPLICATE CHECK' as check_type,
    transaction_id,
    COUNT(*) as occurrence_count
FROM affiliate_commissions 
GROUP BY transaction_id 
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- Verify commission totals are still correct
SELECT 
    '💰 COMMISSION TOTALS VERIFICATION' as verification_type,
    customer_id,
    COUNT(*) as commission_records,
    SUM(amount) as total_amount,
    CASE 
        WHEN SUM(amount) = 800 THEN '✅ CORRECT'
        WHEN SUM(amount) > 800 THEN '❌ EXCEEDS ₹800'
        ELSE '⚠️ LESS THAN ₹800'
    END as status
FROM affiliate_commissions 
GROUP BY customer_id
ORDER BY total_amount DESC;

-- =====================================================
-- STEP 8: SUMMARY STATISTICS
-- =====================================================

SELECT 
    '📈 REASSIGNMENT SUMMARY' as summary_type,
    (SELECT COUNT(*) FROM affiliate_commissions) as total_records_updated,
    (SELECT COUNT(DISTINCT customer_id) FROM affiliate_commissions) as customers_affected,
    (SELECT MIN(transaction_id) FROM affiliate_commissions) as first_new_id,
    (SELECT MAX(transaction_id) FROM affiliate_commissions) as last_new_id,
    (SELECT COUNT(DISTINCT transaction_id) FROM affiliate_commissions) as unique_ids_assigned;

-- Show commission breakdown by new transaction IDs
SELECT 
    '📊 COMMISSION BREAKDOWN BY NEW IDs' as breakdown_type,
    recipient_type,
    level,
    COUNT(*) as record_count,
    SUM(amount) as total_amount,
    ROUND(AVG(amount), 2) as avg_amount
FROM affiliate_commissions 
GROUP BY recipient_type, level
ORDER BY recipient_type, level;

COMMIT;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT 
    '🎉 TRANSACTION ID REASSIGNMENT COMPLETED!' as final_status,
    'All existing commissions now have clean sequential IDs' as result,
    'Format: COM-01, COM-02, COM-03, etc.' as format,
    'New commissions will continue the sequence automatically' as future_behavior;
