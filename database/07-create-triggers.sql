-- =====================================================
-- STEP 7: CREATE TRIGGERS
-- =====================================================
-- Creates triggers for automatic commission distribution
-- Run this after step 6
-- =====================================================

-- =====================================================
-- TRIGGER FUNCTION FOR COMMISSION DISTRIBUTION
-- =====================================================
CREATE OR REPLACE FUNCTION trigger_commission_distribution()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger for new customer insertions
    IF TG_OP = 'INSERT' THEN
        -- Distribute commission asynchronously to avoid blocking customer creation
        PERFORM pg_notify(
            'commission_distribution',
            json_build_object(
                'customer_id', NEW.id,
                'promoter_id', NEW.promoter_id
            )::text
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add comment
COMMENT ON FUNCTION trigger_commission_distribution IS 'Triggers commission distribution notification when customer is created';

-- =====================================================
-- CREATE TRIGGER ON CUSTOMERS TABLE
-- =====================================================
DROP TRIGGER IF EXISTS trigger_affiliate_commission ON customers;

CREATE TRIGGER trigger_affiliate_commission
    AFTER INSERT ON customers
    FOR EACH ROW
    EXECUTE FUNCTION trigger_commission_distribution();

-- Add comment
COMMENT ON TRIGGER trigger_affiliate_commission ON customers IS 'Automatically triggers commission distribution on customer creation';

-- Success message
SELECT 'Step 7 completed: Triggers created successfully!' as status;
