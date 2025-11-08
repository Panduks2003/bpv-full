// =====================================================
// TEST PAYMENT MANAGEMENT FROM FRONTEND
// =====================================================
// This script tests the payment management functionality from the frontend perspective
// Run this in the browser console when logged in as an admin or promoter

console.log('🧪 Testing Payment Management Frontend...');

// Test function to check payment loading
async function testPaymentLoading() {
    try {
        console.log('📋 Testing payment data loading...');
        
        // Get the supabase client from the frontend
        const { supabase } = window;
        
        if (!supabase) {
            console.error('❌ Supabase client not found. Make sure you\'re on the application page.');
            return false;
        }
        
        // Test 1: Check if customer_payments table is accessible
        console.log('🔍 Test 1: Checking customer_payments table access...');
        const { data: tableTest, error: tableError } = await supabase
            .from('customer_payments')
            .select('count')
            .limit(1);
            
        if (tableError) {
            console.error('❌ Cannot access customer_payments table:', tableError.message);
            console.log('💡 Possible issues:');
            console.log('   - Table does not exist');
            console.log('   - RLS policies are blocking access');
            console.log('   - User authentication issue');
            return false;
        }
        
        console.log('✅ customer_payments table is accessible');
        
        // Test 2: Get current user
        console.log('🔍 Test 2: Checking current user authentication...');
        const { data: { user }, error: userError } = await supabase.auth.getUser();
        
        if (userError || !user) {
            console.error('❌ User authentication issue:', userError?.message || 'No user found');
            return false;
        }
        
        console.log('✅ User authenticated:', user.email);
        
        // Test 3: Get user profile
        console.log('🔍 Test 3: Getting user profile...');
        const { data: profile, error: profileError } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', user.id)
            .single();
            
        if (profileError) {
            console.error('❌ Cannot get user profile:', profileError.message);
            return false;
        }
        
        console.log('✅ User profile:', profile.name, '- Role:', profile.role);
        
        // Test 4: Get customers (if admin/promoter)
        if (profile.role === 'admin' || profile.role === 'promoter') {
            console.log('🔍 Test 4: Getting customers...');
            
            let customerQuery = supabase.from('profiles').select('*').eq('role', 'customer');
            
            if (profile.role === 'promoter') {
                customerQuery = customerQuery.eq('parent_promoter_id', user.id);
            }
            
            const { data: customers, error: customersError } = await customerQuery.limit(10);
            
            if (customersError) {
                console.error('❌ Cannot get customers:', customersError.message);
                return false;
            }
            
            console.log(`✅ Found ${customers?.length || 0} customers`);
            
            // Test 5: Get payment data for first customer
            if (customers && customers.length > 0) {
                const testCustomer = customers[0];
                console.log(`🔍 Test 5: Getting payments for customer: ${testCustomer.name}...`);
                
                const { data: payments, error: paymentsError } = await supabase
                    .from('customer_payments')
                    .select('*')
                    .eq('customer_id', testCustomer.id)
                    .order('month_number');
                    
                if (paymentsError) {
                    console.error('❌ Cannot get customer payments:', paymentsError.message);
                    return false;
                }
                
                console.log(`✅ Found ${payments?.length || 0} payment records for ${testCustomer.name}`);
                
                if (payments && payments.length > 0) {
                    const paidCount = payments.filter(p => p.status === 'paid').length;
                    const pendingCount = payments.filter(p => p.status === 'pending').length;
                    console.log(`   💰 Paid: ${paidCount}, Pending: ${pendingCount}`);
                    console.log('   📊 Sample payment:', payments[0]);
                } else {
                    console.log('⚠️ No payment records found for this customer');
                    console.log('💡 This customer may need a payment schedule created');
                }
            } else {
                console.log('⚠️ No customers found');
                console.log('💡 You may need to create customers first');
            }
        } else {
            console.log('ℹ️ User is a customer - testing own payment access...');
            
            const { data: ownPayments, error: ownPaymentsError } = await supabase
                .from('customer_payments')
                .select('*')
                .eq('customer_id', user.id)
                .order('month_number');
                
            if (ownPaymentsError) {
                console.error('❌ Cannot get own payments:', ownPaymentsError.message);
                return false;
            }
            
            console.log(`✅ Found ${ownPayments?.length || 0} payment records for current user`);
        }
        
        console.log('\n🎉 All tests passed! Payment management should be working.');
        return true;
        
    } catch (error) {
        console.error('❌ Test failed with error:', error.message);
        return false;
    }
}

// Test function to simulate opening payment manager
async function testPaymentManager() {
    console.log('\n🎯 Testing Payment Manager Component...');
    
    // Check if PaymentManager component is available
    const paymentButtons = document.querySelectorAll('[data-testid="payment-manager"], button[title*="payment"], button[title*="Payment"]');
    
    if (paymentButtons.length === 0) {
        console.log('⚠️ No payment manager buttons found on current page');
        console.log('💡 Try navigating to:');
        console.log('   - Admin Customers page (if admin)');
        console.log('   - Promoter Customers page (if promoter)');
        return false;
    }
    
    console.log(`✅ Found ${paymentButtons.length} payment-related buttons`);
    console.log('💡 Click on a payment button to test the PaymentManager component');
    
    return true;
}

// Run tests
async function runAllTests() {
    console.log('🚀 Starting Payment Management Tests...\n');
    
    const loadingTest = await testPaymentLoading();
    const managerTest = await testPaymentManager();
    
    console.log('\n📋 TEST SUMMARY:');
    console.log('='.repeat(50));
    console.log(`Data Loading: ${loadingTest ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`UI Components: ${managerTest ? '✅ PASS' : '❌ FAIL'}`);
    
    if (loadingTest && managerTest) {
        console.log('\n🎉 Payment Management appears to be working correctly!');
    } else {
        console.log('\n❌ Issues found. Check the error messages above for details.');
    }
}

// Auto-run tests
runAllTests();

// Make functions available globally for manual testing
window.testPaymentLoading = testPaymentLoading;
window.testPaymentManager = testPaymentManager;
window.runAllTests = runAllTests;

console.log('\n💡 Functions available for manual testing:');
console.log('   - testPaymentLoading()');
console.log('   - testPaymentManager()');
console.log('   - runAllTests()');
