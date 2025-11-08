-- =====================================================
-- VERIFY PROMOTER HIERARCHY FOR COMMISSION ANALYSIS
-- =====================================================
-- This script checks why some customers get admin commissions
-- =====================================================

-- Check the promoter hierarchy for customers with admin commissions
WITH problem_customers AS (
    SELECT DISTINCT customer_id 
    FROM affiliate_commissions 
    WHERE recipient_type = 'admin' 
    AND created_at > NOW() - INTERVAL '1 hour'
),
customer_details AS (
    SELECT 
        pc.customer_id,
        p.name as customer_name,
        p.customer_id as customer_card_no,
        p.parent_promoter_id as direct_promoter_id,
        pp1.name as level1_promoter_name,
        pp1.promoter_id as level1_promoter_id,
        pp1.parent_promoter_id as level2_promoter_id,
        pp2.name as level2_promoter_name,
        pp2.promoter_id as level2_promoter_card,
        pp2.parent_promoter_id as level3_promoter_id,
        pp3.name as level3_promoter_name,
        pp3.promoter_id as level3_promoter_card,
        pp3.parent_promoter_id as level4_promoter_id,
        pp4.name as level4_promoter_name,
        pp4.promoter_id as level4_promoter_card
    FROM problem_customers pc
    JOIN profiles p ON pc.customer_id = p.id
    LEFT JOIN profiles pp1 ON p.parent_promoter_id = pp1.id AND pp1.role = 'promoter'
    LEFT JOIN profiles pp2 ON pp1.parent_promoter_id = pp2.id AND pp2.role = 'promoter'
    LEFT JOIN profiles pp3 ON pp2.parent_promoter_id = pp3.id AND pp3.role = 'promoter'
    LEFT JOIN profiles pp4 ON pp3.parent_promoter_id = pp4.id AND pp4.role = 'promoter'
)
SELECT 
    'Hierarchy Analysis' as analysis_type,
    customer_card_no,
    customer_name,
    level1_promoter_id as "Level 1 (Direct)",
    level2_promoter_card as "Level 2", 
    level3_promoter_card as "Level 3",
    level4_promoter_card as "Level 4",
    CASE 
        WHEN level4_promoter_name IS NOT NULL THEN 'Complete (4 levels)'
        WHEN level3_promoter_name IS NOT NULL THEN 'Incomplete (3 levels)'
        WHEN level2_promoter_name IS NOT NULL THEN 'Incomplete (2 levels)'
        WHEN level1_promoter_name IS NOT NULL THEN 'Incomplete (1 level)'
        ELSE 'No hierarchy'
    END as hierarchy_status,
    CASE 
        WHEN level4_promoter_name IS NOT NULL THEN 0
        WHEN level3_promoter_name IS NOT NULL THEN 100
        WHEN level2_promoter_name IS NOT NULL THEN 200
        WHEN level1_promoter_name IS NOT NULL THEN 300
        ELSE 800
    END as expected_admin_amount
FROM customer_details
ORDER BY customer_card_no;

-- Also check the actual commission distribution for these customers
SELECT 
    'Commission Distribution' as analysis_type,
    p.customer_id as customer_card_no,
    ac.recipient_type,
    ac.level,
    ac.amount,
    pp.promoter_id as recipient_promoter_id,
    pp.name as recipient_name
FROM affiliate_commissions ac
JOIN profiles p ON ac.customer_id = p.id
LEFT JOIN profiles pp ON ac.recipient_id = pp.id
WHERE ac.customer_id IN (
    SELECT DISTINCT customer_id 
    FROM affiliate_commissions 
    WHERE recipient_type = 'admin' 
    AND created_at > NOW() - INTERVAL '1 hour'
)
ORDER BY p.customer_id, ac.level;
