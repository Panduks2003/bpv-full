-- =====================================================
-- FIX COMMISSION FUNCTION AND CREATE PAYMENTS
-- =====================================================
-- This script fixes the calculate_commissions function and then creates payment schedules

BEGIN;

-- First, let's check the structure of affiliate_commissions table
SELECT 'AFFILIATE_COMMISSIONS_STRUCTURE' as check_type,
       column_name,
       data_type,
       is_nullable,
       column_default
FROM information_schema.columns 
WHERE table_name = 'affiliate_commissions'
ORDER BY ordinal_position;

-- Fix the calculate_commissions function with duplicate prevention
CREATE OR REPLACE FUNCTION calculate_commissions()
RETURNS TRIGGER AS $$
DECLARE
    level1_promoter UUID;
    level2_promoter UUID;
    level3_promoter UUID;
    level4_promoter UUID;
    admin_id UUID;
    initiator_promoter UUID;
    admin_total_amount DECIMAL := 0;
    existing_commission_count INTEGER;
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

    -- Level 1: 500
    IF level1_promoter IS NOT NULL THEN
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, level1_promoter, level1_promoter, 'promoter', initiator_promoter, 500, 1, 'pending');
    ELSE
        -- Accumulate admin amount instead of inserting immediately
        admin_total_amount := admin_total_amount + 500;
    END IF;

    -- Level 2: 100
    IF level2_promoter IS NOT NULL THEN
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, level2_promoter, level2_promoter, 'promoter', initiator_promoter, 100, 2, 'pending');
    ELSE
        -- Accumulate admin amount instead of inserting immediately
        admin_total_amount := admin_total_amount + 100;
    END IF;

    -- Level 3: 100
    IF level3_promoter IS NOT NULL THEN
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, level3_promoter, level3_promoter, 'promoter', initiator_promoter, 100, 3, 'pending');
    ELSE
        -- Accumulate admin amount instead of inserting immediately
        admin_total_amount := admin_total_amount + 100;
    END IF;

    -- Level 4: 100
    IF level4_promoter IS NOT NULL THEN
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, level4_promoter, level4_promoter, 'promoter', initiator_promoter, 100, 4, 'pending');
    ELSE
        -- Accumulate admin amount instead of inserting immediately
        admin_total_amount := admin_total_amount + 100;
    END IF;

    -- Create single admin commission record with accumulated amount (if any)
    IF admin_total_amount > 0 AND admin_id IS NOT NULL THEN
        INSERT INTO affiliate_commissions (customer_id, promoter_id, recipient_id, recipient_type, initiator_promoter_id, amount, level, status)
        VALUES (NEW.customer_id, admin_id, admin_id, 'admin', initiator_promoter, admin_total_amount, 0, 'pending');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Now create payment schedules for customers without them
INSERT INTO customer_payments (
    customer_id,
    month_number,
    payment_amount,
    status,
    created_at,
    updated_at
)
SELECT 
    p.id as customer_id,
    month_series.month_number,
    1000.00 as payment_amount,
    'pending' as status,
    NOW() as created_at,
    NOW() as updated_at
FROM profiles p
CROSS JOIN generate_series(1, 20) AS month_series(month_number)
WHERE p.role = 'customer'
AND NOT EXISTS (
    SELECT 1 FROM customer_payments cp 
    WHERE cp.customer_id = p.id 
    AND cp.month_number = month_series.month_number
);

-- Show results
SELECT 'PAYMENT_CREATION_RESULTS' as result_type,
       COUNT(DISTINCT customer_id) as customers_with_payments,
       COUNT(*) as total_payment_records,
       SUM(payment_amount) as total_amount_pending
FROM customer_payments;

-- Show commission creation results
SELECT 'COMMISSION_CREATION_RESULTS' as result_type,
       COUNT(*) as total_commissions,
       COUNT(DISTINCT customer_id) as customers_with_commissions,
       COUNT(DISTINCT promoter_id) as promoters_earning,
       SUM(amount) as total_commission_amount
FROM affiliate_commissions
WHERE created_at >= NOW() - INTERVAL '1 minute';

-- Verify payment schedules
SELECT 'PAYMENT_VERIFICATION' as result_type,
       p.name as customer_name,
       COUNT(cp.id) as payment_count,
       CASE 
           WHEN COUNT(cp.id) = 20 THEN 'COMPLETE' 
           ELSE 'INCOMPLETE' 
       END as payment_status
FROM profiles p
LEFT JOIN customer_payments cp ON p.id = cp.customer_id
WHERE p.role = 'customer'
GROUP BY p.id, p.name
ORDER BY COUNT(cp.id) DESC, p.name
LIMIT 10;

COMMIT;

-- Final success message
SELECT 'SUCCESS' as status, 
       'Commission function fixed and payment schedules created successfully' as message,
       NOW() as completed_at;
