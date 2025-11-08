// Test commission summary calculation
// Run this in browser console on the Commission History page

// Test the commission service directly
(async () => {
  console.log('🧪 Testing Commission Summary...');
  
  // Get current user ID (replace with actual promoter ID)
  const userId = 'your-promoter-id-here'; // You'll need to replace this
  
  try {
    // Test the commission service
    const commissionService = window.commissionService || {
      async getPromoterCommissionSummary(promoterId) {
        // Direct database query test
        const { data: commissions } = await supabase
          .from('affiliate_commissions')
          .select('amount, status')
          .eq('recipient_id', promoterId)
          .eq('status', 'credited');
        
        const totalEarned = commissions?.reduce((sum, comm) => sum + parseFloat(comm.amount), 0) || 0;
        const commissionCount = commissions?.length || 0;
        
        console.log('📊 Commission Data:', {
          commissions,
          totalEarned,
          commissionCount
        });
        
        return {
          success: true,
          data: {
            wallet_balance: totalEarned,
            total_earned: totalEarned,
            commission_count: commissionCount,
            recent_commissions: commissions || []
          }
        };
      }
    };
    
    // Test with current user
    const result = await commissionService.getPromoterCommissionSummary(userId);
    console.log('✅ Commission Summary Result:', result);
    
    // Also test direct query
    const { data: directCommissions } = await supabase
      .from('affiliate_commissions')
      .select('*')
      .eq('recipient_id', userId)
      .eq('status', 'credited');
    
    console.log('📋 Direct Commission Query:', directCommissions);
    
    const total = directCommissions?.reduce((sum, comm) => sum + parseFloat(comm.amount), 0) || 0;
    console.log(`💰 Total Earned: ₹${total}`);
    console.log(`📊 Commission Count: ${directCommissions?.length || 0}`);
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
})();

// Instructions:
// 1. Open Commission History page
// 2. Open browser console (F12)
// 3. Replace 'your-promoter-id-here' with actual promoter ID
// 4. Paste and run this script
// 5. Check console output for commission totals
