// Run this in browser console on Commission History page to identify which user you're logged in as

(async () => {
  console.log('🔍 Identifying Current User...');
  
  try {
    // Get current user from various sources
    const authUser = supabase.auth.getUser ? await supabase.auth.getUser() : null;
    const localStorageUser = JSON.parse(localStorage.getItem('user') || '{}');
    const sessionStorageUser = JSON.parse(sessionStorage.getItem('user') || '{}');
    
    console.log('🔐 Auth User:', authUser?.data?.user);
    console.log('💾 LocalStorage User:', localStorageUser);
    console.log('📦 SessionStorage User:', sessionStorageUser);
    
    // Get the actual user ID being used
    const userId = authUser?.data?.user?.id || localStorageUser?.id || sessionStorageUser?.id;
    console.log('🎯 Current User ID:', userId);
    
    if (userId) {
      // Check this user's profile
      const { data: profile, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
      
      console.log('👤 Current User Profile:', profile);
      
      if (profile) {
        console.log(`📋 You are logged in as: ${profile.name} (${profile.promoter_id})`);
        console.log(`💰 Your wallet balance: ₹${profile.wallet_balance || 0}`);
        
        // Check commissions for this user
        const { data: commissions } = await supabase
          .from('affiliate_commissions')
          .select('amount, status')
          .eq('recipient_id', userId)
          .eq('status', 'credited');
        
        const totalEarned = commissions?.reduce((sum, comm) => sum + parseFloat(comm.amount), 0) || 0;
        console.log(`📊 Your commissions: ${commissions?.length || 0} commissions = ₹${totalEarned}`);
        
        // Show the mismatch if any
        if (profile.wallet_balance != totalEarned) {
          console.log('⚠️ MISMATCH: Wallet balance doesn\'t match commission total!');
          console.log(`Database wallet_balance: ₹${profile.wallet_balance}`);
          console.log(`Calculated from commissions: ₹${totalEarned}`);
        }
      }
    } else {
      console.error('❌ No user ID found! You might not be logged in properly.');
    }
    
  } catch (error) {
    console.error('❌ Error identifying user:', error);
  }
})();

console.log('📋 This will show you exactly which Pandu Shirabur account you\'re logged in as and why the wallet shows ₹0');
