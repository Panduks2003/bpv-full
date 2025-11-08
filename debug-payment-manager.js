// Debug script for Payment Manager issues
// Run this in browser console when Payment Manager shows "0 of 0 months"

async function debugPaymentManager() {
    console.log('🔍 Debugging Payment Manager...');
    
    try {
        // Step 1: Check all customers
        const { data: customers, error: customersError } = await supabase
            .from('profiles')
            .select('id, name, customer_id, role')
            .eq('role', 'customer')
            .limit(5);
            
        if (customersError) {
            console.error('❌ Error loading customers:', customersError);
            return;
        }
        
        console.log('👥 Sample customers:', customers);
        
        // Step 2: Check payment records
        const { data: payments, error: paymentsError } = await supabase
            .from('customer_payments')
            .select('customer_id, month_number, payment_amount, amount, status')
            .limit(10);
            
        if (paymentsError) {
            console.error('❌ Error loading payments:', paymentsError);
            return;
        }
        
        console.log('💰 Sample payments:', payments);
        
        // Step 3: Check for specific customer
        if (customers && customers.length > 0) {
            const testCustomer = customers[0];
            console.log('🎯 Testing with customer:', testCustomer);
            
            const { data: customerPayments, error: customerPaymentsError } = await supabase
                .from('customer_payments')
                .select('*')
                .eq('customer_id', testCustomer.id)
                .order('month_number', { ascending: true });
                
            console.log(`💳 Payments for ${testCustomer.name} (ID: ${testCustomer.id}):`, customerPayments);
            
            if (customerPayments && customerPayments.length > 0) {
                console.log('✅ Payments found! Payment Manager should work.');
                console.log('📊 Payment details:', {
                    count: customerPayments.length,
                    firstPayment: customerPayments[0],
                    hasAmount: !!customerPayments[0].amount,
                    hasPaymentAmount: !!customerPayments[0].payment_amount
                });
            } else {
                console.log('❌ No payments found for this customer!');
                
                // Check if there are any payments at all
                const { data: allPayments, error: allPaymentsError } = await supabase
                    .from('customer_payments')
                    .select('customer_id')
                    .limit(5);
                    
                if (allPayments && allPayments.length > 0) {
                    console.log('⚠️ Payments exist but not for this customer. Customer IDs in payments:', 
                        [...new Set(allPayments.map(p => p.customer_id))]);
                } else {
                    console.log('❌ No payments exist in the system at all!');
                }
            }
        }
        
        // Step 4: Check column names in customer_payments table
        const { data: tableInfo, error: tableError } = await supabase
            .from('customer_payments')
            .select('*')
            .limit(1);
            
        if (tableInfo && tableInfo.length > 0) {
            console.log('📋 Customer payments table columns:', Object.keys(tableInfo[0]));
        }
        
    } catch (error) {
        console.error('❌ Debug failed:', error);
    }
}

// Also check what customer is currently selected in Payment Manager
function checkSelectedCustomer() {
    // This will show the customer data that's being passed to PaymentManager
    console.log('🎯 Check the customer object being passed to PaymentManager');
    console.log('Look for selectedCustomerForPayments in the component state');
}

console.log('🔧 Debug functions loaded:');
console.log('- debugPaymentManager() - Check payment data');
console.log('- checkSelectedCustomer() - Check selected customer');
console.log('');
console.log('Run: debugPaymentManager()');
