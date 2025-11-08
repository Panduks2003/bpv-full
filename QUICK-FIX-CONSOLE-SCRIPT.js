// =====================================================
// QUICK FIX - RUN THIS IN BROWSER CONSOLE
// =====================================================
// Copy and paste this entire script into your browser console
// while on your admin panel (http://localhost:3000/admin)

console.log('🔧 BrightPlanet Ventures - Database Fix');
console.log('Fixing: UPDATE requires a WHERE clause error');
console.log('');

// The SQL fix
const sqlFix = `
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
    
    -- If no rows were updated, insert first record
    IF next_number IS NULL THEN
        INSERT INTO promoter_id_sequence (last_promoter_number, updated_at)
        VALUES (1, NOW())
        RETURNING last_promoter_number INTO next_number;
    END IF;
    
    -- Format as BPVP01, BPVP02, etc.
    new_promoter_id := 'BPVP' || LPAD(next_number::TEXT, 2, '0');
    
    -- Ensure uniqueness
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
async function applyDatabaseFix() {
    try {
        console.log('🔍 Looking for Supabase client...');
        
        // Get supabase client from the application
        const supabaseModule = await import('./src/common/services/supabaseClient.js');
        const { supabase } = supabaseModule;
        
        if (!supabase) {
            throw new Error('Supabase client not found');
        }
        
        console.log('✅ Supabase client found');
        console.log('🔧 Applying database fix...');
        
        // Since we can't execute raw SQL directly, we need to do this manually
        console.log('');
        console.log('📋 MANUAL FIX REQUIRED:');
        console.log('1. Go to https://supabase.com/dashboard');
        console.log('2. Select your project');
        console.log('3. Go to SQL Editor');
        console.log('4. Copy and paste this SQL:');
        console.log('');
        console.log(sqlFix);
        console.log('');
        console.log('5. Click RUN');
        console.log('6. Refresh this page and try creating a promoter');
        
        // Test current function
        console.log('🧪 Testing current function...');
        try {
            const { data, error } = await supabase.rpc('generate_next_promoter_id');
            if (error) {
                console.log('❌ Function has error (expected):', error.message);
            } else {
                console.log('✅ Function works! Generated:', data);
            }
        } catch (e) {
            console.log('❌ Function error:', e.message);
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        console.log('');
        console.log('📋 ALTERNATIVE: Manual SQL execution required');
        console.log('Go to your Supabase dashboard and execute the SQL above');
    }
}

// Auto-run the fix
applyDatabaseFix();

// Also make it available as a global function
window.fixDatabaseError = applyDatabaseFix;

console.log('');
console.log('💡 If the auto-fix doesn\'t work, run: fixDatabaseError()');
