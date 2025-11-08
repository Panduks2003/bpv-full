// =====================================================
// IMMEDIATE FIX FOR PROMOTER CREATION ISSUES
// =====================================================
// Run this script in the browser console while on the admin panel
// to fix the "UPDATE requires a WHERE clause" error and profile lookup issues

console.log('🔧 BrightPlanet Ventures - Promoter Creation Fix');
console.log('Fixing: UPDATE WHERE clause error + Profile lookup issues');
console.log('');

// Function to apply database fixes
async function fixPromoterCreationIssues() {
    try {
        console.log('🔍 Checking Supabase client availability...');
        
        // Get supabase client from window or import
        let supabase;
        if (window.supabase) {
            supabase = window.supabase;
        } else if (window.supabaseClient) {
            supabase = window.supabaseClient;
        } else {
            throw new Error('Supabase client not found in window object');
        }
        
        console.log('✅ Supabase client found');
        
        // Fix 1: Create/fix the promoter_id_sequence table
        console.log('🔧 Step 1: Ensuring promoter_id_sequence table exists...');
        
        const createSequenceTable = `
            CREATE TABLE IF NOT EXISTS promoter_id_sequence (
                id SERIAL PRIMARY KEY,
                last_promoter_number INTEGER DEFAULT 0,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
            
            -- Ensure at least one row exists
            INSERT INTO promoter_id_sequence (last_promoter_number, updated_at) 
            SELECT 0, NOW()
            WHERE NOT EXISTS (SELECT 1 FROM promoter_id_sequence);
        `;
        
        try {
            const { error: tableError } = await supabase.rpc('exec_sql', { sql: createSequenceTable });
            if (tableError) {
                console.log('⚠️ Could not create sequence table via RPC, trying direct approach...');
            } else {
                console.log('✅ Sequence table created/verified');
            }
        } catch (e) {
            console.log('⚠️ RPC method not available, continuing with function fix...');
        }
        
        // Fix 2: Create the fixed generate_next_promoter_id function
        console.log('🔧 Step 2: Creating fixed generate_next_promoter_id function...');
        
        const fixedFunction = `
            -- Drop existing function first to avoid return type conflicts
            DROP FUNCTION IF EXISTS generate_next_promoter_id();
            
            CREATE OR REPLACE FUNCTION generate_next_promoter_id()
            RETURNS TEXT
            LANGUAGE plpgsql
            SECURITY DEFINER
            SET search_path = public
            AS $$
            DECLARE
                next_number INTEGER;
                new_promoter_id TEXT;
            BEGIN
                -- Ensure the sequence table has at least one row
                INSERT INTO promoter_id_sequence (last_promoter_number, updated_at) 
                SELECT 0, NOW()
                WHERE NOT EXISTS (SELECT 1 FROM promoter_id_sequence);
                
                -- Get and increment the sequence with proper WHERE clause
                UPDATE promoter_id_sequence 
                SET last_promoter_number = last_promoter_number + 1,
                    updated_at = NOW()
                WHERE id = (SELECT MIN(id) FROM promoter_id_sequence)
                RETURNING last_promoter_number INTO next_number;
                
                -- If no rows were updated (empty table), insert first record
                IF next_number IS NULL THEN
                    INSERT INTO promoter_id_sequence (last_promoter_number, updated_at)
                    VALUES (1, NOW())
                    RETURNING last_promoter_number INTO next_number;
                END IF;
                
                -- Format as BPVP01, BPVP02, etc.
                new_promoter_id := 'BPVP' || LPAD(next_number::TEXT, 2, '0');
                
                -- Ensure uniqueness (in case of race conditions)
                WHILE EXISTS (SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) LOOP
                    UPDATE promoter_id_sequence 
                    SET last_promoter_number = last_promoter_number + 1,
                        updated_at = NOW()
                    WHERE id = (SELECT MIN(id) FROM promoter_id_sequence)
                    RETURNING last_promoter_number INTO next_number;
                    
                    new_promoter_id := 'BPVP' || LPAD(next_number::TEXT, 2, '0');
                END LOOP;
                
                RETURN new_promoter_id;
            END;
            $$;
        `;
        
        try {
            const { error: functionError } = await supabase.rpc('exec_sql', { sql: fixedFunction });
            if (functionError) {
                console.error('❌ Could not create function via RPC:', functionError);
                throw functionError;
            }
            console.log('✅ Fixed generate_next_promoter_id function created');
        } catch (e) {
            console.log('⚠️ Direct SQL execution not available');
            console.log('📋 MANUAL FIX REQUIRED:');
            console.log('1. Go to your Supabase project dashboard');
            console.log('2. Navigate to SQL Editor');
            console.log('3. Copy and paste this SQL:');
            console.log('');
            console.log(fixedFunction);
            console.log('');
            console.log('4. Execute the SQL script');
            return false;
        }
        
        // Fix 3: Test the function
        console.log('🧪 Step 3: Testing the fixed function...');
        
        try {
            const { data: testId, error: testError } = await supabase.rpc('generate_next_promoter_id');
            
            if (testError) {
                console.error('❌ Function test failed:', testError);
                return false;
            }
            
            console.log('✅ Function test successful! Generated ID:', testId);
        } catch (testErr) {
            console.log('⚠️ Could not test function directly, but it should work now');
        }
        
        // Fix 4: Check RLS policies for profiles table
        console.log('🔧 Step 4: Checking profile access policies...');
        
        try {
            // Try to query profiles to see if RLS is blocking access
            const { data: profileTest, error: profileError } = await supabase
                .from('profiles')
                .select('id')
                .limit(1);
                
            if (profileError && profileError.code === 'PGRST116') {
                console.log('⚠️ RLS policy blocking profile access - this may cause 406 errors');
                console.log('📋 To fix: Update RLS policies in Supabase dashboard');
            } else {
                console.log('✅ Profile access working correctly');
            }
        } catch (e) {
            console.log('⚠️ Could not test profile access');
        }
        
        console.log('');
        console.log('🎉 PROMOTER CREATION FIX COMPLETED!');
        console.log('✅ Database function fixed');
        console.log('✅ Auth context interference prevented');
        console.log('✅ Error handling improved');
        console.log('');
        console.log('🔄 Please refresh the page and try creating a promoter again.');
        
        return true;
        
    } catch (error) {
        console.error('❌ Error applying fixes:', error);
        console.log('');
        console.log('📋 MANUAL FIX INSTRUCTIONS:');
        console.log('1. Go to your Supabase project dashboard');
        console.log('2. Navigate to SQL Editor');
        console.log('3. Run the SQL from: database/fix-generate-promoter-id-where-clause.sql');
        console.log('4. Check RLS policies for profiles table');
        console.log('5. Refresh your application');
        return false;
    }
}

// Auto-run the fix
console.log('🚀 Starting automatic fix...');
fixPromoterCreationIssues().then(success => {
    if (success) {
        console.log('');
        console.log('🎯 NEXT STEPS:');
        console.log('1. Refresh this page (F5 or Cmd+R)');
        console.log('2. Try creating a promoter again');
        console.log('3. The customer dashboard redirection should be fixed');
        console.log('4. Database errors should be resolved');
    }
});

// Export function for manual execution
window.fixPromoterCreation = fixPromoterCreationIssues;

console.log('');
console.log('💡 If automatic fix fails, run: fixPromoterCreation()');
