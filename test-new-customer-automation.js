
// Test script to verify customer creation automation
// Run this in browser console on admin page

async function testCustomerAutomation() {
    console.log('🧪 Testing Customer Creation Automation...');
    
    // Test data
    const testCustomer = {
        name: 'Test Customer ' + Date.now(),
        mobile: '9876543210',
        email: 'test@example.com',
        state: 'Karnataka',
        city: 'Bangalore',
        pincode: '560001',
        address: 'Test Address',
        cardNo: 'TEST' + Date.now(),
        password: 'test123',
        parentPromoter: 'YOUR_PROMOTER_ID_HERE' // Replace with actual promoter ID
    };
    
    try {
        console.log('📝 Creating customer with data:', testCustomer);
        
        // Step 1: Create customer (this should create payments automatically)
        const { data: customerResult, error: customerError } = await supabase.rpc('create_customer_final', {
            p_name: testCustomer.name,
            p_mobile: testCustomer.mobile,
            p_state: testCustomer.state,
            p_city: testCustomer.city,
            p_pincode: testCustomer.pincode,
            p_address: testCustomer.address,
            p_customer_id: testCustomer.cardNo,
            p_password: testCustomer.password,
            p_parent_promoter_id: testCustomer.parentPromoter,
            p_email: testCustomer.email
        });
        
        if (customerError) {
            throw customerError;
        }
        
        console.log('✅ Customer created:', customerResult);
        const customerId = customerResult.customer_id;
        
        // Step 2: Check if payments were created automatically
        const { data: payments, error: paymentsError } = await supabase
            .from('customer_payments')
            .select('*')
            .eq('customer_id', customerId);
            
        console.log(`💰 Payment records created: ${payments?.length || 0}/20`);
        
        // Step 3: Check if commissions were created automatically
        const { data: commissions, error: commissionsError } = await supabase
            .from('affiliate_commissions')
            .select('*')
            .eq('customer_id', customerId);
            
        console.log(`🎯 Commission records created: ${commissions?.length || 0}`);
        
        // Step 4: Summary
        const automationStatus = {
            customerCreated: !!customerResult.success,
            paymentsCreated: payments?.length === 20,
            commissionsCreated: (commissions?.length || 0) > 0,
            customerId: customerId
        };
        
        console.log('📊 Automation Status:', automationStatus);
        
        if (automationStatus.customerCreated && automationStatus.paymentsCreated && automationStatus.commissionsCreated) {
            console.log('🎉 AUTOMATION WORKING PERFECTLY!');
        } else if (automationStatus.customerCreated && automationStatus.paymentsCreated) {
            console.log('⚠️ Payments created, but commissions may need manual trigger');
        } else {
            console.log('❌ Automation has issues');
        }
        
        return automationStatus;
        
    } catch (error) {
        console.error('❌ Test failed:', error);
        return { error: error.message };
    }
}

// Run the test
// testCustomerAutomation();
