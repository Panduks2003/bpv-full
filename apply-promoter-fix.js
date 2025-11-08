// Script to apply the promoter creation fix
// This can be run in the browser console or as a Node.js script

console.log('🔧 Applying promoter creation fix...');

// For browser console execution
if (typeof window !== 'undefined') {
  // Browser environment
  console.log('📍 Running in browser environment');
  
  // Function to execute SQL file via Supabase
  async function applyDatabaseFix() {
    try {
      // Import Supabase client
      const { supabase } = await import('./frontend/src/common/services/supabaseClient.js');
      
      console.log('✅ Supabase client loaded');
      
      // Read the SQL file content (you'll need to copy-paste this manually in browser)
      console.log('📋 Please execute the SQL file manually in your Supabase dashboard:');
      console.log('   1. Go to your Supabase project dashboard');
      console.log('   2. Navigate to SQL Editor');
      console.log('   3. Copy and paste the content from: database/09-fix-promoter-creation-issues.sql');
      console.log('   4. Execute the SQL script');
      console.log('   5. Refresh this page and try creating a promoter again');
      
      // Test if the fix is already applied
      console.log('🔍 Testing current database functions...');
      
      // Test generate_next_promoter_id
      try {
        const { data: promoterId, error: idError } = await supabase.rpc('generate_next_promoter_id');
        if (idError) {
          console.error('❌ generate_next_promoter_id not working:', idError);
          console.log('💡 This function needs to be created. Execute the SQL fix.');
        } else {
          console.log('✅ generate_next_promoter_id working. Generated ID:', promoterId);
        }
      } catch (error) {
        console.error('❌ Error testing generate_next_promoter_id:', error);
      }
      
      // Test admin users loading
      try {
        const { data: adminUsers, error: adminError } = await supabase
          .from('profiles')
          .select('id, name, email, role')
          .eq('role', 'admin');
        
        if (adminError) {
          console.error('❌ Cannot load admin users:', adminError);
          console.log('💡 This might be an RLS policy issue. Execute the SQL fix.');
        } else {
          console.log('✅ Admin users loaded successfully:', adminUsers?.length || 0, 'admins');
          if (adminUsers?.length === 0) {
            console.log('⚠️  No admin users found. The SQL fix will create a test admin.');
          }
        }
      } catch (error) {
        console.error('❌ Error testing admin users:', error);
      }
      
      // Test promoter creation (dry run)
      try {
        console.log('🔄 Testing promoter creation function...');
        const testData = {
          p_name: 'Test Promoter',
          p_password: 'testpass123',
          p_phone: '9876543210',
          p_email: null,
          p_address: null,
          p_parent_promoter_id: null,
          p_role_level: 'Affiliate',
          p_status: 'Active'
        };
        
        const { data: createResult, error: createError } = await supabase.rpc('create_unified_promoter', testData);
        
        if (createError) {
          console.error('❌ create_unified_promoter not working:', createError);
          console.log('💡 This function needs to be fixed. Execute the SQL fix.');
        } else {
          console.log('✅ create_unified_promoter working. Result:', createResult);
          
          // Clean up test promoter
          if (createResult?.success && createResult?.user_id) {
            await supabase.from('profiles').delete().eq('id', createResult.user_id);
            console.log('🧹 Test promoter cleaned up');
          }
        }
      } catch (error) {
        console.error('❌ Error testing create_unified_promoter:', error);
      }
      
    } catch (error) {
      console.error('❌ Failed to load Supabase client:', error);
    }
  }
  
  // Export function for manual execution
  window.applyPromoterFix = applyDatabaseFix;
  
  console.log('📝 Function loaded. Run window.applyPromoterFix() to test database functions.');
  
} else {
  // Node.js environment
  console.log('📍 Running in Node.js environment');
  console.log('💡 For Node.js execution, you would need to:');
  console.log('   1. Install @supabase/supabase-js');
  console.log('   2. Set up environment variables');
  console.log('   3. Execute the SQL file via Supabase client');
  console.log('');
  console.log('🔧 For now, please execute the SQL file manually in Supabase dashboard.');
}

console.log('');
console.log('📋 MANUAL STEPS TO FIX PROMOTER CREATION:');
console.log('1. Open your Supabase project dashboard');
console.log('2. Go to SQL Editor');
console.log('3. Copy content from: database/09-fix-promoter-creation-issues.sql');
console.log('4. Paste and execute the SQL script');
console.log('5. Refresh your web application');
console.log('6. Try creating a promoter from the admin panel');
console.log('');
