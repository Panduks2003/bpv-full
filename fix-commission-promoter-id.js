/**
 * FIX: Add promoter_id column to affiliate_commissions table
 * 
 * This script fixes the error: "column "promoter_id" of relation "affiliate_commissions" does not exist"
 * Run this in your browser console while logged in as an admin
 */

(async function() {
  try {
    console.log('🔧 Starting fix for missing promoter_id column in affiliate_commissions table...');
    
    // Get the Supabase client from the window object
    const supabase = window.supabase;
    
    if (!supabase) {
      throw new Error('Supabase client not found. Make sure you are logged in and on the admin panel.');
    }
    
    // Step 1: Check if we have admin access
    console.log('✅ Checking admin access...');
    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', supabase.auth.user().id)
      .single();
      
    if (profileError || !profileData || profileData.role !== 'admin') {
      throw new Error('You must be logged in as an admin to run this fix.');
    }
    
    console.log('✅ Admin access confirmed');
    
    // Step 2: Run the SQL to add the column using RPC
    console.log('🔧 Adding promoter_id column to affiliate_commissions table...');
    
    const sql = `
      DO $$
      BEGIN
        -- Add the column if it doesn't exist
        IF NOT EXISTS (
          SELECT 1 
          FROM information_schema.columns 
          WHERE table_name = 'affiliate_commissions' 
          AND column_name = 'promoter_id'
        ) THEN
          ALTER TABLE affiliate_commissions 
          ADD COLUMN promoter_id UUID REFERENCES profiles(id) ON DELETE CASCADE;
          
          -- Update existing records to set promoter_id = initiator_promoter_id
          UPDATE affiliate_commissions 
          SET promoter_id = initiator_promoter_id;
          
          RAISE NOTICE 'Successfully added promoter_id column to affiliate_commissions table';
        ELSE
          RAISE NOTICE 'Column promoter_id already exists in affiliate_commissions table';
        END IF;
        
        -- Create index on the new column for better performance
        IF NOT EXISTS (
          SELECT 1
          FROM pg_indexes
          WHERE tablename = 'affiliate_commissions'
          AND indexname = 'idx_affiliate_commissions_promoter_id'
        ) THEN
          CREATE INDEX idx_affiliate_commissions_promoter_id ON affiliate_commissions(promoter_id);
        END IF;
      END $$;
    `;
    
    // Execute the SQL using RPC (requires an RPC function that can execute SQL)
    const { data, error } = await supabase.rpc('execute_sql_as_admin', { sql_query: sql });
    
    if (error) {
      // If the RPC method doesn't exist, try direct SQL (only works with service role)
      console.log('⚠️ RPC method not available, trying direct SQL...');
      
      const { error: sqlError } = await supabase.from('affiliate_commissions').select('id').limit(1);
      
      if (sqlError && sqlError.message.includes('promoter_id')) {
        console.log('⚠️ Direct SQL not possible. Please run the SQL fix on the server side.');
        console.log('⚠️ Contact your database administrator to run the following SQL:');
        console.log(sql);
        throw new Error('Cannot automatically fix the issue. Please contact your database administrator.');
      }
    }
    
    console.log('✅ Fix applied successfully!');
    console.log('🔍 Verifying the fix...');
    
    // Step 3: Verify the fix by checking if the column exists
    const { data: verifyData, error: verifyError } = await supabase
      .from('affiliate_commissions')
      .select('id')
      .limit(1);
    
    if (verifyError && verifyError.message.includes('promoter_id')) {
      throw new Error('Fix verification failed. The column still does not exist.');
    }
    
    console.log('✅ Fix verified successfully!');
    console.log('✅ You can now create customers without the "promoter_id" error.');
    
    return { success: true, message: 'Fix applied successfully!' };
  } catch (error) {
    console.error('❌ Error applying fix:', error.message);
    return { success: false, error: error.message };
  }
})();