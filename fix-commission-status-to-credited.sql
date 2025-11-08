-- Fix commission status - commissions should be 'credited' immediately when customer is created
-- This will make commissions show as credited instead of pending

-- First, update the commission trigger function to create commissions as 'credited'
CREATE OR REPLACE FUNCTION calculate_commissions()
RETURNS TRIGGER AS $$
DECLARE
    existing_commission_count INTEGER := 0;
    level1_promoter UUID;
    level2_promoter UUID;
    level3_promoter UUID;
    level4_promoter UUID;
    admin_id UUID;
    admin_total_amount DECIMAL(10,2) := 0;
    initiator_promoter UUID;
BEGIN
    -- Check if commissions already exist for this customer
    SELECT COUNT(*) INTO existing_commission_count
    FROM affiliate_commissions 
    WHERE customer_id = NEW.customer_id;
    
    -- If commissions already exist, skip creating new ones
    IF existing_commission_count > 0 THEN
        RETURN NEW;
    END IF;
    
    -- Get the admin ID for fallback
    SELECT id INTO admin_id FROM profiles WHERE role = 'admin' LIMIT 1;
    
    -- Get upline promoters (4 levels)
    SELECT parent_promoter_id INTO level1_promoter FROM profiles WHERE id = NEW.customer_id;
    SELECT parent_promoter_id INTO level2_promoter FROM profiles WHERE id = level1_promoter;
    SELECT parent_promoter_id INTO level3_promoter FROM profiles WHERE id = level2_promoter;
    SELECT parent_promoter_id INTO level4_promoter FROM profiles WHERE id = level3_promoter;

    -- Set initiator_promoter to level1_promoter (the direct promoter of the customer)
    -- If no level1_promoter, use admin as initiator
    initiator_promoter := COALESCE(level1_promoter, admin_id);

    -- Level 1: 500 - CREDITED immediately
    IF level1_promoter IS NOT NULL THEN
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, level1_promoter, level1_promoter, 'promoter', initiator_promoter, 500, 1, 'credited');
    ELSE
        -- Accumulate admin amount instead of inserting immediately
        admin_total_amount := admin_total_amount + 500;
    END IF;

    -- Level 2: 100 - CREDITED immediately
    IF level2_promoter IS NOT NULL THEN
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, level2_promoter, level2_promoter, 'promoter', initiator_promoter, 100, 2, 'credited');
    ELSE
        -- Accumulate admin amount instead of inserting immediately
        admin_total_amount := admin_total_amount + 100;
    END IF;

    -- Level 3: 100 - CREDITED immediately
    IF level3_promoter IS NOT NULL THEN
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, level3_promoter, level3_promoter, 'promoter', initiator_promoter, 100, 3, 'credited');
    ELSE
        -- Accumulate admin amount instead of inserting immediately
        admin_total_amount := admin_total_amount + 100;
    END IF;

    -- Level 4: 100 - CREDITED immediately
    IF level4_promoter IS NOT NULL THEN
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, level4_promoter, level4_promoter, 'promoter', initiator_promoter, 100, 4, 'credited');
    ELSE
        -- Accumulate admin amount instead of inserting immediately
        admin_total_amount := admin_total_amount + 100;
    END IF;

    -- Admin commission: 200 + any accumulated amounts - CREDITED immediately
    IF admin_id IS NOT NULL THEN
        admin_total_amount := admin_total_amount + 200;
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, initiator_promoter, admin_id, 'admin', initiator_promoter, admin_total_amount, 0, 'credited');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update existing pending commissions to credited status
UPDATE affiliate_commissions 
SET status = 'credited', 
    updated_at = NOW()
WHERE status = 'pending';

-- Verify the changes
SELECT 
    'COMMISSION_STATUS_FIX' as check_type,
    status,
    COUNT(*) as commission_count,
    SUM(amount) as total_amount
FROM affiliate_commissions 
GROUP BY status
ORDER BY status;

SELECT 'COMMISSION_STATUS_FIXED_TO_CREDITED' as result;
