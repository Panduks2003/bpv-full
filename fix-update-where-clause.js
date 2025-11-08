// =====================================================
// FIX UPDATE WHERE CLAUSE ERROR - BROWSER CONSOLE SCRIPT
// =====================================================
// Run this script in the browser console to fix the 
// "UPDATE requires a WHERE clause" error

console.log('🔧 Starting UPDATE WHERE clause fix...');

// SQL fix for the generate_next_promoter_id function
const SQL_FIX = `
-- Fix generate_next_promoter_id function with proper WHERE clauses
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

// Function to apply the fix
async function applyUpdateWhereFix() {
    try {
        console.log('🔍 Checking if Supabase client is available...');
        
        // Try to get supabase from window or import it
        let supabase;
        if (window.supabase) {
            supabase = window.supabase;
            console.log('✅ Found Supabase client in window');
        } else {
            // Try to import from the frontend
            try {
                const module = await import('./frontend/src/common/services/supabaseClient.js');
                supabase = module.supabase;
                console.log('✅ Imported Supabase client');
            } catch (importError) {
                console.error('❌ Could not import Supabase client:', importError);
                throw new Error('Supabase client not available');
            }
        }

        console.log('🔧 Applying database fix...');
        
        // Apply the SQL fix
        const { data, error } = await supabase.rpc('exec', { sql: SQL_FIX });
        
        if (error) {
            console.error('❌ Failed to apply SQL fix:', error);
            console.log('');
            console.log('📋 MANUAL FIX REQUIRED:');
            console.log('1. Go to your Supabase project dashboard');
            console.log('2. Navigate to SQL Editor');
            console.log('3. Copy and paste this SQL:');
            console.log('');
            console.log(SQL_FIX);
            console.log('');
            console.log('4. Execute the SQL script');
            console.log('5. Refresh this page and try creating a promoter again');
            return false;
        }

        console.log('✅ SQL fix applied successfully!');
        
        // Test the fix
        console.log('🧪 Testing the fixed function...');
        
        const { data: testId, error: testError } = await supabase.rpc('generate_next_promoter_id');
        
        if (testError) {
            console.error('❌ Test failed:', testError);
            return false;
        }
        
        console.log('✅ Test successful! Generated ID:', testId);
        console.log('');
        console.log('🎉 FIX COMPLETED SUCCESSFULLY!');
        console.log('You can now create promoters without the UPDATE WHERE clause error.');
        
        return true;
        
    } catch (error) {
        console.error('❌ Error applying fix:', error);
        console.log('');
        console.log('📋 MANUAL FIX INSTRUCTIONS:');
        console.log('1. Go to your Supabase project dashboard');
        console.log('2. Navigate to SQL Editor');
        console.log('3. Copy the SQL from the file: database/fix-generate-promoter-id-where-clause.sql');
        console.log('4. Execute the SQL script');
        console.log('5. Refresh this page and try again');
        return false;
    }
}

// Alternative method using direct SQL execution
async function applyFixManually() {
    console.log('');
    console.log('📋 MANUAL FIX INSTRUCTIONS:');
    console.log('='.repeat(50));
    console.log('1. Go to your Supabase project dashboard');
    console.log('2. Navigate to SQL Editor');
    console.log('3. Copy and paste this SQL code:');
    console.log('');
    console.log(SQL_FIX);
    console.log('');
    console.log('4. Click "Run" to execute the SQL');
    console.log('5. Refresh your application');
    console.log('6. Try creating a promoter again');
    console.log('='.repeat(50));
}

// Export functions to window for manual execution
window.applyUpdateWhereFix = applyUpdateWhereFix;
window.showManualFixInstructions = applyFixManually;

console.log('');
console.log('🚀 Fix script loaded! Choose one option:');
console.log('');
console.log('OPTION 1 (Automatic):');
console.log('  Run: applyUpdateWhereFix()');
console.log('');
console.log('OPTION 2 (Manual):');
console.log('  Run: showManualFixInstructions()');
console.log('');

// Auto-run the fix
console.log('🔄 Auto-running the fix...');
applyUpdateWhereFix();
