-- =====================================================
-- UNIFIED PROMOTER SYSTEM - PROMOTER ID SEQUENCE
-- =====================================================
-- This file creates the promoter ID sequence management system

-- =====================================================
-- 2. CREATE PROMOTER ID SEQUENCE TABLE
-- =====================================================

-- Create sequence table for global ID generation
CREATE TABLE IF NOT EXISTS promoter_id_sequence (
    id SERIAL PRIMARY KEY,
    last_promoter_number INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Initialize sequence if empty
INSERT INTO promoter_id_sequence (last_promoter_number) 
SELECT 0 
WHERE NOT EXISTS (SELECT 1 FROM promoter_id_sequence);

-- =====================================================
-- 3. FUNCTION: GENERATE NEXT PROMOTER ID
-- =====================================================

-- Drop existing function if it exists with different signature
DROP FUNCTION IF EXISTS generate_next_promoter_id;
DROP FUNCTION IF EXISTS generate_next_promoter_id();

CREATE OR REPLACE FUNCTION generate_next_promoter_id()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_number INTEGER;
    new_promoter_id VARCHAR(20);
BEGIN
    -- Get and increment the next number atomically
    UPDATE promoter_id_sequence 
    SET last_promoter_number = last_promoter_number + 1,
        updated_at = NOW()
    RETURNING last_promoter_number INTO next_number;
    
    -- Format as PROM0001, PROM0002, etc.
    new_promoter_id := 'PROM' || LPAD(next_number::TEXT, 4, '0');
    
    -- Ensure uniqueness (in case of race conditions)
    WHILE EXISTS (SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) LOOP
        UPDATE promoter_id_sequence 
        SET last_promoter_number = last_promoter_number + 1,
            updated_at = NOW()
        RETURNING last_promoter_number INTO next_number;
        
        new_promoter_id := 'PROM' || LPAD(next_number::TEXT, 4, '0');
    END LOOP;
    
    RETURN new_promoter_id;
END;
$$;

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Promoter ID sequence system created successfully!';
END $$;
