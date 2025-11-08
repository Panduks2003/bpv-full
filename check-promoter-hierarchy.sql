-- Check Promoter Hierarchy Status
-- This query shows the current promoter hierarchy and identifies any missing relationships

-- 1. Basic promoter information with parent relationships
SELECT 
  p1.promoter_id as "Promoter ID",
  p1.name as "Promoter Name",
  p1.id as "Internal ID",
  p1.parent_promoter_id as "Parent Internal ID",
  p2.promoter_id as "Parent Promoter ID",
  p2.name as "Parent Name",
  CASE 
    WHEN p1.parent_promoter_id IS NULL THEN 'ROOT (No Parent)'
    ELSE 'HAS PARENT'
  END as "Hierarchy Status"
FROM profiles p1
LEFT JOIN profiles p2 ON p1.parent_promoter_id = p2.id
WHERE p1.role = 'promoter'
ORDER BY p1.promoter_id;

-- 2. Hierarchy depth analysis
WITH RECURSIVE hierarchy_depth AS (
  -- Base case: promoters with no parent (root level)
  SELECT 
    id,
    promoter_id,
    name,
    parent_promoter_id,
    0 as level,
    promoter_id as path
  FROM profiles 
  WHERE role = 'promoter' AND parent_promoter_id IS NULL
  
  UNION ALL
  
  -- Recursive case: promoters with parents
  SELECT 
    p.id,
    p.promoter_id,
    p.name,
    p.parent_promoter_id,
    h.level + 1 as level,
    h.path || ' -> ' || p.promoter_id as path
  FROM profiles p
  INNER JOIN hierarchy_depth h ON p.parent_promoter_id = h.id
  WHERE p.role = 'promoter'
)
SELECT 
  promoter_id as "Promoter ID",
  name as "Name",
  level as "Hierarchy Level",
  path as "Hierarchy Path"
FROM hierarchy_depth
ORDER BY level, promoter_id;

-- 3. Summary statistics
SELECT 
  COUNT(*) as "Total Promoters",
  COUNT(parent_promoter_id) as "Promoters with Parents",
  COUNT(*) - COUNT(parent_promoter_id) as "Root Promoters (No Parent)",
  ROUND(
    (COUNT(parent_promoter_id) * 100.0 / COUNT(*)), 2
  ) as "Hierarchy Coverage %"
FROM profiles 
WHERE role = 'promoter';

-- 4. Identify potential issues
SELECT 
  'ISSUE' as "Status",
  'Promoters without hierarchy' as "Description",
  COUNT(*) as "Count"
FROM profiles 
WHERE role = 'promoter' AND parent_promoter_id IS NULL
HAVING COUNT(*) > 1

UNION ALL

SELECT 
  'WARNING' as "Status",
  'Orphaned parent references' as "Description",
  COUNT(*) as "Count"
FROM profiles p1
WHERE role = 'promoter' 
  AND parent_promoter_id IS NOT NULL 
  AND parent_promoter_id NOT IN (
    SELECT id FROM profiles WHERE role = 'promoter'
  );

-- 5. Commission flow test (shows what would happen for each promoter)
SELECT 
  p1.promoter_id as "If Customer Created By",
  p1.name as "Creator Name",
  'Level 1 (₹500)' as "Commission Level",
  p1.promoter_id as "Goes To",
  p1.name as "Recipient Name"
FROM profiles p1
WHERE p1.role = 'promoter'

UNION ALL

SELECT 
  p1.promoter_id as "If Customer Created By",
  p1.name as "Creator Name",
  'Level 2 (₹100)' as "Commission Level",
  COALESCE(p2.promoter_id, 'ADMIN FALLBACK') as "Goes To",
  COALESCE(p2.name, 'System Admin') as "Recipient Name"
FROM profiles p1
LEFT JOIN profiles p2 ON p1.parent_promoter_id = p2.id
WHERE p1.role = 'promoter'

UNION ALL

SELECT 
  p1.promoter_id as "If Customer Created By",
  p1.name as "Creator Name",
  'Level 3 (₹100)' as "Commission Level",
  COALESCE(p3.promoter_id, 'ADMIN FALLBACK') as "Goes To",
  COALESCE(p3.name, 'System Admin') as "Recipient Name"
FROM profiles p1
LEFT JOIN profiles p2 ON p1.parent_promoter_id = p2.id
LEFT JOIN profiles p3 ON p2.parent_promoter_id = p3.id
WHERE p1.role = 'promoter'

UNION ALL

SELECT 
  p1.promoter_id as "If Customer Created By",
  p1.name as "Creator Name",
  'Level 4 (₹100)' as "Commission Level",
  COALESCE(p4.promoter_id, 'ADMIN FALLBACK') as "Goes To",
  COALESCE(p4.name, 'System Admin') as "Recipient Name"
FROM profiles p1
LEFT JOIN profiles p2 ON p1.parent_promoter_id = p2.id
LEFT JOIN profiles p3 ON p2.parent_promoter_id = p3.id
LEFT JOIN profiles p4 ON p3.parent_promoter_id = p4.id
WHERE p1.role = 'promoter'

ORDER BY "If Customer Created By", "Commission Level";
