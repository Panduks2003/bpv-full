// Test Supabase client with proper import
// Run this in browser console on Commission History page

(async () => {
  console.log('🔍 === SUPABASE IMPORT TEST ===');
  
  try {
    // Get user context
    const user = window.user || JSON.parse(localStorage.getItem('user') || '{}');
    console.log('👤 User ID:', user.id);
    console.log('👤 Promoter ID:', user.promoter_id);
    
    // Try to import supabase client
    console.log('\n📊 Importing Supabase client...');
    const { default: supabase } = await import('/src/common/services/supabaseClient.js');
    console.log('✅ Supabase client imported successfully');
    console.log('📊 Supabase URL:', supabase.supabaseUrl);
    
    // Test authentication
    console.log('\n🔐 Testing authentication...');
    const { data: authData, error: authError } = await supabase.auth.getUser();
    console.log('Auth user:', authData?.user?.id);
    console.log('Auth error:', authError);
    
    // Test the exact failing query
    console.log('\n🔍 Testing exact commission query...');
    const { data: commissions, error: commissionError } = await supabase
      .from('affiliate_commissions')
      .select('*')
      .eq('recipient_id', user.id)
      .eq('status', 'credited');
    
    console.log('Commission query result:');
    console.log('- Error:', commissionError);
    console.log('- Count:', commissions?.length || 0);
    console.log('- Data:', commissions);
    
    if (commissions && commissions.length > 0) {
      const total = commissions.reduce((sum, comm) => sum + parseFloat(comm.amount), 0);
      console.log('✅ SUCCESS: Found', commissions.length, 'commissions totaling ₹' + total);
      
      // Test if we can update the UI directly
      console.log('\n🔧 Attempting to fix UI directly...');
      
      // Find commission data elements and update them
      const walletElement = document.querySelector('[data-testid="wallet-balance"]') || 
                           document.querySelector('*:contains("Wallet Balance")');
      const totalElement = document.querySelector('[data-testid="total-earned"]') ||
                          document.querySelector('*:contains("Total Earned")');
      
      console.log('Wallet element found:', !!walletElement);
      console.log('Total element found:', !!totalElement);
      
      // Try to trigger a re-render by dispatching a custom event
      window.dispatchEvent(new CustomEvent('commission-data-found', {
        detail: {
          wallet_balance: total,
          total_earned: total,
          commission_count: commissions.length,
          recent_commissions: commissions
        }
      }));
      
      console.log('✅ Dispatched commission-data-found event with correct data');
      
    } else {
      console.log('❌ FAILED: No commissions found even with direct import');
      
      // Test without status filter
      console.log('\n🔍 Testing without status filter...');
      const { data: allCommissions, error: allError } = await supabase
        .from('affiliate_commissions')
        .select('*')
        .eq('recipient_id', user.id);
      
      console.log('All commissions result:');
      console.log('- Error:', allError);
      console.log('- Count:', allCommissions?.length || 0);
      console.log('- Data:', allCommissions);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
})();

console.log('📋 This test will use the correct Supabase import and try to fix the UI!');
