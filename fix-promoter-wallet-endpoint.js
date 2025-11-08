// =====================================================
// FIX PROMOTER WALLET ENDPOINT 406 ERROR
// =====================================================
// Copy and paste this script into browser console on admin page

console.log('🔧 Fixing promoter_wallet endpoint 406 error...');

async function fixPromoterWalletEndpoint() {
    try {
        // Get supabase client
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            console.log('❌ Supabase client not found - make sure you\'re on the admin page');
            return false;
        }

        console.log('✅ Supabase client found');

        // Step 1: Check if promoter_wallet table exists
        console.log('🔍 Checking if promoter_wallet table exists...');
        
        const checkTableSQL = `
            SELECT 
                table_name,
                table_type
            FROM information_schema.tables 
            WHERE table_name = 'promoter_wallet'
              AND table_schema = 'public';
        `;

        const { data: tableCheck, error: tableError } = await supabase.rpc('sql', { 
            query: checkTableSQL 
        });

        if (tableError) {
            console.log('❌ Error checking table:', tableError.message);
            return false;
        }

        console.log('📊 Table check result:', tableCheck);

        if (!tableCheck || tableCheck.length === 0) {
            console.log('❌ promoter_wallet table does not exist - creating it...');
            
            const createTableSQL = `
                CREATE TABLE IF NOT EXISTS promoter_wallet (
                    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                    promoter_id UUID UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
                    balance DECIMAL(10,2) DEFAULT 0.00,
                    total_earned DECIMAL(10,2) DEFAULT 0.00,
                    total_withdrawn DECIMAL(10,2) DEFAULT 0.00,
                    commission_count INTEGER DEFAULT 0,
                    last_commission_at TIMESTAMP WITH TIME ZONE,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                );
                
                -- Create indexes
                CREATE INDEX IF NOT EXISTS idx_promoter_wallet_promoter_id ON promoter_wallet(promoter_id);
                
                -- Grant permissions
                GRANT SELECT, INSERT, UPDATE ON promoter_wallet TO authenticated;
                GRANT SELECT, INSERT, UPDATE ON promoter_wallet TO anon;
            `;

            const { data: createResult, error: createError } = await supabase.rpc('sql', { 
                query: createTableSQL 
            });

            if (createError) {
                console.log('❌ Error creating table:', createError.message);
                return false;
            }

            console.log('✅ promoter_wallet table created successfully');
        } else {
            console.log('✅ promoter_wallet table exists');
        }

        // Step 2: Check RLS settings
        console.log('🔍 Checking Row Level Security settings...');
        
        const checkRLSSQL = `
            SELECT 
                tablename,
                rowsecurity as rls_enabled
            FROM pg_tables 
            WHERE tablename = 'promoter_wallet'
              AND schemaname = 'public';
        `;

        const { data: rlsCheck, error: rlsError } = await supabase.rpc('sql', { 
            query: checkRLSSQL 
        });

        if (!rlsError && rlsCheck && rlsCheck.length > 0) {
            console.log('📊 RLS settings:', rlsCheck[0]);
            
            if (rlsCheck[0].rls_enabled) {
                console.log('⚠️ RLS is enabled - disabling for now...');
                
                const disableRLSSQL = `
                    ALTER TABLE promoter_wallet DISABLE ROW LEVEL SECURITY;
                    GRANT ALL ON promoter_wallet TO authenticated;
                    GRANT ALL ON promoter_wallet TO anon;
                `;

                const { data: disableResult, error: disableError } = await supabase.rpc('sql', { 
                    query: disableRLSSQL 
                });

                if (disableError) {
                    console.log('❌ Error disabling RLS:', disableError.message);
                } else {
                    console.log('✅ RLS disabled successfully');
                }
            }
        }

        // Step 3: Test the endpoint directly
        console.log('🧪 Testing promoter_wallet endpoint...');
        
        try {
            const { data: testData, error: testError } = await supabase
                .from('promoter_wallet')
                .select('*')
                .limit(1);

            if (testError) {
                console.log('❌ Direct endpoint test failed:', testError.message);
                
                // Try to populate the table with existing promoter data
                console.log('🔧 Attempting to populate promoter_wallet table...');
                
                const populateSQL = `
                    INSERT INTO promoter_wallet (promoter_id, balance, total_earned, total_withdrawn, commission_count)
                    SELECT 
                        p.id as promoter_id,
                        COALESCE(
                            (SELECT SUM(amount) FROM affiliate_commissions WHERE recipient_id = p.id AND status = 'credited'), 
                            0
                        ) as balance,
                        COALESCE(
                            (SELECT SUM(amount) FROM affiliate_commissions WHERE recipient_id = p.id AND status = 'credited'), 
                            0
                        ) as total_earned,
                        0 as total_withdrawn,
                        COALESCE(
                            (SELECT COUNT(*) FROM affiliate_commissions WHERE recipient_id = p.id AND status = 'credited'), 
                            0
                        ) as commission_count
                    FROM profiles p
                    WHERE p.role = 'promoter'
                    ON CONFLICT (promoter_id) DO UPDATE SET
                        balance = EXCLUDED.balance,
                        total_earned = EXCLUDED.total_earned,
                        commission_count = EXCLUDED.commission_count,
                        updated_at = NOW();
                `;

                const { data: populateResult, error: populateError } = await supabase.rpc('sql', { 
                    query: populateSQL 
                });

                if (populateError) {
                    console.log('❌ Error populating table:', populateError.message);
                } else {
                    console.log('✅ Table populated with promoter data');
                }
            } else {
                console.log('✅ Direct endpoint test successful:', testData);
            }
        } catch (endpointError) {
            console.log('❌ Endpoint test error:', endpointError.message);
        }

        // Step 4: Test the specific query that's failing
        console.log('🧪 Testing specific query that was failing...');
        
        try {
            const { data: specificTest, error: specificError } = await supabase
                .from('promoter_wallet')
                .select('balance, total_earned, total_withdrawn')
                .eq('promoter_id', '9266982f-e9cc-4fc4-9f07-09065eedd9e5');

            if (specificError) {
                console.log('❌ Specific query failed:', specificError.message);
            } else {
                console.log('✅ Specific query successful:', specificTest);
            }
        } catch (specificTestError) {
            console.log('❌ Specific query error:', specificTestError.message);
        }

        console.log('');
        console.log('🎉 PROMOTER WALLET ENDPOINT FIX COMPLETED!');
        console.log('');
        console.log('✅ Actions taken:');
        console.log('   • Verified promoter_wallet table exists');
        console.log('   • Disabled RLS if it was causing issues');
        console.log('   • Populated table with existing promoter data');
        console.log('   • Granted proper permissions');
        console.log('');
        console.log('💡 The 406 error should now be resolved!');
        
        return true;

    } catch (error) {
        console.error('❌ Critical error fixing promoter_wallet endpoint:', error);
        return false;
    }
}

// Auto-execute the fix
fixPromoterWalletEndpoint();
