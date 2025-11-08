// Quick fix to create payment schedules directly via Supabase
// Run this in the browser console when logged in as admin

console.log('🔧 Quick Fix: Creating Payment Schedules...');

async function createPaymentSchedulesQuickFix() {
    try {
        // Get supabase client from window (frontend)
        const { supabase } = window;
        
        if (!supabase) {
            console.error('❌ Supabase client not found. Make sure you\'re on the application page.');
            return;
        }
        
        console.log('📋 Step 1: Getting customers without payments...');
        
        // Get all customers
        const { data: customers, error: customersError } = await supabase
            .from('profiles')
            .select('id, name, email')
            .eq('role', 'customer');
            
        if (customersError) {
            console.error('❌ Error getting customers:', customersError.message);
            return;
        }
        
        console.log(`✅ Found ${customers?.length || 0} total customers`);
        
        // Check which customers already have payments
        const { data: existingPayments, error: paymentsError } = await supabase
            .from('customer_payments')
            .select('customer_id');
            
        if (paymentsError) {
            console.error('❌ Error checking existing payments:', paymentsError.message);
            return;
        }
        
        const customerIdsWithPayments = new Set(existingPayments?.map(p => p.customer_id) || []);
        const customersWithoutPayments = customers?.filter(c => !customerIdsWithPayments.has(c.id)) || [];
        
        console.log(`📊 Customers without payments: ${customersWithoutPayments.length}`);
        console.log(`📊 Customers with payments: ${customerIdsWithPayments.size}`);
        
        if (customersWithoutPayments.length === 0) {
            console.log('✅ All customers already have payment schedules!');
            return;
        }
        
        console.log('📋 Step 2: Creating payment schedules...');
        
        let totalCreated = 0;
        
        // Process each customer
        for (let i = 0; i < customersWithoutPayments.length; i++) {
            const customer = customersWithoutPayments[i];
            console.log(`🔄 Processing ${i + 1}/${customersWithoutPayments.length}: ${customer.name}...`);
            
            try {
                // Create payment records for this customer
                const paymentRecords = [];
                for (let month = 1; month <= 20; month++) {
                    paymentRecords.push({
                        customer_id: customer.id,
                        month_number: month,
                        payment_amount: 1000.00,
                        status: 'pending'
                    });
                }
                
                const { data: createdPayments, error: createError } = await supabase
                    .from('customer_payments')
                    .insert(paymentRecords)
                    .select();
                    
                if (createError) {
                    console.error(`❌ Failed to create payments for ${customer.name}:`, createError.message);
                    continue;
                }
                
                const created = createdPayments?.length || 0;
                totalCreated += created;
                console.log(`✅ Created ${created} payments for ${customer.name}`);
                
                // Small delay to avoid overwhelming the database
                await new Promise(resolve => setTimeout(resolve, 100));
                
            } catch (error) {
                console.error(`❌ Error processing ${customer.name}:`, error.message);
            }
        }
        
        console.log('\n🎉 Payment Schedule Creation Complete!');
        console.log('='.repeat(50));
        console.log(`📊 Customers processed: ${customersWithoutPayments.length}`);
        console.log(`📊 Total payments created: ${totalCreated}`);
        console.log(`📊 Average per customer: ${customersWithoutPayments.length > 0 ? (totalCreated / customersWithoutPayments.length).toFixed(1) : 0}`);
        
        // Verify the results
        console.log('\n📋 Verification...');
        const { data: finalPayments, error: verifyError } = await supabase
            .from('customer_payments')
            .select('customer_id')
            .not('customer_id', 'is', null);
            
        if (!verifyError) {
            const uniqueCustomers = new Set(finalPayments?.map(p => p.customer_id) || []);
            console.log(`✅ Final verification: ${uniqueCustomers.size} customers now have payment schedules`);
            console.log(`✅ Total payment records: ${finalPayments?.length || 0}`);
        }
        
    } catch (error) {
        console.error('❌ Quick fix failed:', error.message);
    }
}

// Run the fix
createPaymentSchedulesQuickFix();

// Make function available for manual retry
window.createPaymentSchedulesQuickFix = createPaymentSchedulesQuickFix;

console.log('💡 If this fails, you can retry by running: createPaymentSchedulesQuickFix()');
