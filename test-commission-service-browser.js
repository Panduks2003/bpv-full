// Test commission service in browser console
// Go to Commission History page, open console (F12), and run this

(async () => {
  console.log('🔍 Testing Commission Service...');
  
  try {
    // Get current user from auth context
    const user = window.user || JSON.parse(localStorage.getItem('user') || '{}');
    console.log('👤 Current User:', user);
    
    if (!user.id) {
      console.error('❌ No user ID found. Make sure you are logged in.');
      return;
    }
    
    // Test 1: Direct database query for commissions
    console.log('\n📊 Test 1: Direct Commission Query');
    const { data: commissions, error: commError } = await supabase
      .from('affiliate_commissions')
      .select('*')
      .eq('recipient_id', user.id)
      .eq('status', 'credited');
    
    console.log('Commission Query Result:', { commissions, error: commError });
    
    if (commissions && commissions.length > 0) {
      const total = commissions.reduce((sum, comm) => sum + parseFloat(comm.amount), 0);
      console.log(`💰 Direct Calculation: ₹${total} from ${commissions.length} commissions`);
    }
    
    // Test 2: Check wallet balance in profiles
    console.log('\n💳 Test 2: Wallet Balance Query');
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('wallet_balance, name')
      .eq('id', user.id)
      .single();
    
    console.log('Profile Query Result:', { profile, error: profileError });
    
    // Test 3: Test the commission service function
    console.log('\n🔧 Test 3: Commission Service Function');
    
    // Import the commission service if available
    const commissionService = window.commissionService || await import('/src/services/commissionService.js').then(m => m.default);
    
    if (commissionService && commissionService.getPromoterCommissionSummary) {
      const result = await commissionService.getPromoterCommissionSummary(user.id);
      console.log('Commission Service Result:', result);
    } else {
      console.log('⚠️ Commission service not available, testing fallback...');
      
      // Manual fallback test
      const { data: walletData } = await supabase
        .from('profiles')
        .select('wallet_balance')
        .eq('id', user.id)
        .eq('role', 'promoter')
        .single();
      
      const { data: allCommissions } = await supabase
        .from('affiliate_commissions')
        .select('amount')
        .eq('recipient_id', user.id)
        .eq('status', 'credited');
      
      const totalEarned = allCommissions?.reduce((sum, comm) => sum + (parseFloat(comm.amount) || 0), 0) || 0;
      const commissionCount = allCommissions?.length || 0;
      
      const fallbackResult = {
        promoter_id: user.id,
        wallet_balance: parseFloat(walletData?.wallet_balance) || totalEarned,
        total_earned: totalEarned,
        commission_count: commissionCount
      };
      
      console.log('Manual Fallback Result:', fallbackResult);
    }
    
    // Test 4: Check what CommissionHistory component is receiving
    console.log('\n📱 Test 4: Component State Check');
    const commissionHistoryComponent = document.querySelector('[data-testid="commission-history"]');
    if (commissionHistoryComponent) {
      console.log('Commission History component found');
    } else {
      console.log('Commission History component not found');
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
})();

console.log('📋 Instructions:');
console.log('1. Make sure you are on the Commission History page');
console.log('2. Make sure you are logged in as a promoter');
console.log('3. Check the console output above');
console.log('4. Look for any errors or unexpected values');
