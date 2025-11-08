-- =====================================================
-- FIX WITHDRAWAL REQUESTS RLS POLICY (COMPLETE)
-- =====================================================
-- This script fixes the Row-Level Security policies for withdrawal_requests
-- and ensures the sequence exists
-- =====================================================

-- =====================================================
-- 1. CHECK AND FIX TABLE STRUCTURE
-- =====================================================

-- Check if the id column is using a sequence
DO $$
DECLARE
    seq_exists boolean;
    table_exists boolean;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'withdrawal_requests'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE 'Table withdrawal_requests does not exist. Creating it...';
        
        -- Create the table with proper structure
        CREATE TABLE withdrawal_requests (
            id BIGSERIAL PRIMARY KEY,
            promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
            amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
            status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
            reason TEXT,
            bank_details JSONB,
            admin_notes TEXT,
            processed_at TIMESTAMP WITH TIME ZONE,
            transaction_id VARCHAR(100),
            rejection_reason TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE '✅ Table withdrawal_requests created with BIGSERIAL id';
    ELSE
        -- Check if sequence exists
        SELECT EXISTS (
            SELECT 1 FROM pg_class 
            WHERE relname = 'withdrawal_requests_id_seq' 
            AND relkind = 'S'
        ) INTO seq_exists;
        
        IF NOT seq_exists THEN
            RAISE NOTICE 'Sequence does not exist. Creating it...';
            
            -- Create the sequence
            CREATE SEQUENCE withdrawal_requests_id_seq;
            
            -- Set the sequence to start from the current max id + 1
            PERFORM setval('withdrawal_requests_id_seq', COALESCE((SELECT MAX(id) FROM withdrawal_requests), 0) + 1, false);
            
            -- Alter the id column to use the sequence
            ALTER TABLE withdrawal_requests ALTER COLUMN id SET DEFAULT nextval('withdrawal_requests_id_seq');
            
            -- Set the sequence owner to the id column
            ALTER SEQUENCE withdrawal_requests_id_seq OWNED BY withdrawal_requests.id;
            
            RAISE NOTICE '✅ Sequence withdrawal_requests_id_seq created and linked';
        ELSE
            RAISE NOTICE '✅ Sequence already exists';
        END IF;
    END IF;
END $$;

-- =====================================================
-- 2. DROP EXISTING RLS POLICIES
-- =====================================================

DROP POLICY IF EXISTS "promoters_can_view_own_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_create_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_insert_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "promoters_can_update_own_pending_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "admins_can_manage_all_withdrawals" ON withdrawal_requests;
DROP POLICY IF EXISTS "allow_all_for_authenticated" ON withdrawal_requests;

-- =====================================================
-- 3. ENABLE RLS
-- =====================================================

ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. CREATE NEW RLS POLICIES
-- =====================================================

-- Policy 1: Promoters can view their own withdrawal requests
CREATE POLICY "promoters_can_view_own_withdrawals" 
ON withdrawal_requests
FOR SELECT 
USING (
    auth.uid() = promoter_id 
    OR 
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy 2: Promoters can insert their own withdrawal requests
CREATE POLICY "promoters_can_insert_withdrawals" 
ON withdrawal_requests
FOR INSERT 
WITH CHECK (
    auth.uid() = promoter_id
    AND
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'promoter'
    )
);

-- Policy 3: Promoters can update their own pending withdrawal requests
CREATE POLICY "promoters_can_update_own_pending_withdrawals" 
ON withdrawal_requests
FOR UPDATE 
USING (
    auth.uid() = promoter_id 
    AND status = 'pending'
)
WITH CHECK (
    auth.uid() = promoter_id 
    AND status = 'pending'
);

-- Policy 4: Admins can do everything
CREATE POLICY "admins_can_manage_all_withdrawals" 
ON withdrawal_requests
FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- =====================================================
-- 5. GRANT PERMISSIONS
-- =====================================================

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE ON withdrawal_requests TO authenticated;

-- Grant sequence usage only if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'withdrawal_requests_id_seq' AND relkind = 'S') THEN
        GRANT USAGE, SELECT ON SEQUENCE withdrawal_requests_id_seq TO authenticated;
        RAISE NOTICE '✅ Sequence permissions granted';
    END IF;
END $$;

-- =====================================================
-- 6. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_promoter_id ON withdrawal_requests(promoter_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_created_at ON withdrawal_requests(created_at DESC);

-- =====================================================
-- 7. VERIFICATION
-- =====================================================

-- Check table structure
SELECT 
    '📋 Table Structure' as check_type,
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'withdrawal_requests'
ORDER BY ordinal_position;

-- Check sequence
SELECT 
    '🔢 Sequence Info' as check_type,
    sequencename as name,
    last_value,
    is_called
FROM pg_sequences 
WHERE schemaname = 'public' 
AND sequencename = 'withdrawal_requests_id_seq';

-- Check policies
SELECT 
    '🔒 RLS Policies' as check_type,
    policyname,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read'
        WHEN cmd = 'INSERT' THEN 'Create'
        WHEN cmd = 'UPDATE' THEN 'Update'
        WHEN cmd = 'DELETE' THEN 'Delete'
        WHEN cmd = '*' THEN 'All Operations'
    END as operation,
    permissive as is_permissive
FROM pg_policies 
WHERE tablename = 'withdrawal_requests'
ORDER BY policyname;

-- Check permissions
SELECT 
    '✅ Permissions' as check_type,
    grantee,
    privilege_type
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name = 'withdrawal_requests'
AND grantee = 'authenticated';

-- Success message
SELECT '✅ Withdrawal RLS policies and sequence fixed! Promoters can now submit withdrawal requests.' as status;
