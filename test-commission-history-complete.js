// Complete test for Commission History page issues
// Run this in browser console on http://localhost:3000/promoter/commission-history

(async () => {
  console.log('🔍 === COMPLETE COMMISSION HISTORY DIAGNOSTIC ===');
  
  try {
    // Test 1: Check Supabase client
    console.log('\n📊 Test 1: Supabase Client Check');
    console.log('Supabase client:', typeof supabase);
    console.log('Supabase URL:', supabase?.supabaseUrl);
    console.log('Supabase Key:', supabase?.supabaseKey ? 'Present' : 'Missing');
    
    // Test 2: Check authentication
    console.log('\n🔐 Test 2: Authentication Check');
    const { data: authData, error: authError } = await supabase.auth.getUser();
    console.log('Auth user:', authData?.user?.id);
    console.log('Auth error:', authError);
    
    // Test 3: Check user context
    console.log('\n👤 Test 3: User Context Check');
    const user = window.user || JSON.parse(localStorage.getItem('user') || '{}');
    console.log('User ID:', user.id);
    console.log('User Name:', user.name);
    console.log('Promoter ID:', user.promoter_id);
    
    // Test 4: Test direct table access
    console.log('\n📋 Test 4: Direct Table Access Test');
    const { data: tableTest, error: tableError } = await supabase
      .from('affiliate_commissions')
      .select('count')
      .limit(1);
    console.log('Table access result:', tableTest);
    console.log('Table access error:', tableError);
    
    // Test 5: Test the exact failing query
    console.log('\n🔍 Test 5: Exact Frontend Query Test');
    const { data: exactQuery, error: exactError } = await supabase
      .from('affiliate_commissions')
      .select('*')
      .eq('recipient_id', user.id)
      .eq('status', 'credited');
    console.log('Exact query result:', exactQuery);
    console.log('Exact query error:', exactError);
    console.log('Result count:', exactQuery?.length || 0);
    
    // Test 6: Test without status filter
    console.log('\n🔍 Test 6: Query Without Status Filter');
    const { data: noStatusQuery, error: noStatusError } = await supabase
      .from('affiliate_commissions')
      .select('*')
      .eq('recipient_id', user.id);
    console.log('No status filter result:', noStatusQuery);
    console.log('No status filter error:', noStatusError);
    console.log('No status result count:', noStatusQuery?.length || 0);
    
    // Test 7: Test RLS policies
    console.log('\n🔒 Test 7: RLS Policy Test');
    const { data: rlsTest, error: rlsError } = await supabase
      .from('affiliate_commissions')
      .select('id, recipient_id, status')
      .limit(5);
    console.log('RLS test result:', rlsTest);
    console.log('RLS test error:', rlsError);
    
    // Test 8: Test profiles table access
    console.log('\n👥 Test 8: Profiles Table Test');
    const { data: profileTest, error: profileError } = await supabase
      .from('profiles')
      .select('wallet_balance')
      .eq('id', user.id)
      .single();
    console.log('Profile test result:', profileTest);
    console.log('Profile test error:', profileError);
    
    // Test 9: Check commission service
    console.log('\n🔧 Test 9: Commission Service Test');
    try {
      const commissionService = window.commissionService || await import('/src/services/commissionService.js').then(m => m.default);
      if (commissionService) {
        const serviceResult = await commissionService.getPromoterCommissionSummary(user.id);
        console.log('Commission service result:', serviceResult);
      } else {
        console.log('Commission service not available');
      }
    } catch (serviceError) {
      console.log('Commission service error:', serviceError);
    }
    
    // Test 10: Manual calculation
    console.log('\n🧮 Test 10: Manual Calculation');
    if (exactQuery && exactQuery.length > 0) {
      const total = exactQuery.reduce((sum, comm) => sum + parseFloat(comm.amount), 0);
      console.log('Manual calculation total: ₹' + total);
      console.log('Commission breakdown:', exactQuery.map(c => `₹${c.amount} (Level ${c.level})`));
    } else {
      console.log('No data for manual calculation');
    }
    
    console.log('\n✅ === DIAGNOSTIC COMPLETE ===');
    console.log('Summary:');
    console.log('- Auth User ID:', authData?.user?.id);
    console.log('- Context User ID:', user.id);
    console.log('- Table Access:', tableError ? 'FAILED' : 'SUCCESS');
    console.log('- Exact Query:', exactError ? 'FAILED' : 'SUCCESS');
    console.log('- Commission Count:', exactQuery?.length || 0);
    console.log('- Profile Access:', profileError ? 'FAILED' : 'SUCCESS');
    
  } catch (error) {
    console.error('❌ Diagnostic failed:', error);
  }
})();

console.log('📋 Run this test and share ALL the output to identify the exact issue!');
