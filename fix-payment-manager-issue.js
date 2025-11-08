// Quick fix for Payment Manager showing 0 payments
// Run this in browser console

async function fixPaymentManagerIssue() {
    console.log('🔧 Fixing Payment Manager Issue...');
    
    try {
        // Step 1: Find customers without payment schedules
        const { data: customers, error: customersError } = await supabase
            .from('profiles')
            .select('id, name, customer_id')
            .eq('role', 'customer');
            
        if (customersError) {
            console.error('❌ Error loading customers:', customersError);
            return;
        }
        
        console.log(`👥 Found ${customers.length} customers`);
        
        // Step 2: Check which customers have payment schedules
        const customersWithoutPayments = [];
        
        for (const customer of customers) {
            const { data: payments, error: paymentsError } = await supabase
                .from('customer_payments')
                .select('id')
                .eq('customer_id', customer.id);
                
            if (!paymentsError && (!payments || payments.length === 0)) {
                customersWithoutPayments.push(customer);
            }
        }
        
        console.log(`⚠️ Customers without payment schedules: ${customersWithoutPayments.length}`);
        customersWithoutPayments.forEach(c => console.log(`  - ${c.name} (ID: ${c.id})`));
        
        // Step 3: Create payment schedules for customers without them
        if (customersWithoutPayments.length > 0) {
            console.log('🔨 Creating payment schedules...');
            
            for (const customer of customersWithoutPayments) {
                console.log(`📅 Creating payments for ${customer.name}...`);
                
                // Create 20 payment records
                const paymentRecords = [];
                for (let month = 1; month <= 20; month++) {
                    paymentRecords.push({
                        customer_id: customer.id,
                        month_number: month,
                        payment_amount: 1000.00,
                        status: 'pending',
                        created_at: new Date().toISOString(),
                        updated_at: new Date().toISOString()
                    });
                }
                
                const { data, error } = await supabase
                    .from('customer_payments')
                    .insert(paymentRecords);
                    
                if (error) {
                    console.error(`❌ Failed to create payments for ${customer.name}:`, error);
                } else {
                    console.log(`✅ Created 20 payments for ${customer.name}`);
                }
            }
            
            console.log('🎉 Payment schedule creation complete!');
        } else {
            console.log('✅ All customers already have payment schedules');
        }
        
        // Step 4: Verify the fix
        console.log('🔍 Verifying fix...');
        const { data: totalPayments, error: totalError } = await supabase
            .from('customer_payments')
            .select('id');
            
        if (!totalError) {
            console.log(`💰 Total payment records in system: ${totalPayments.length}`);
            console.log(`📊 Expected: ${customers.length * 20} (${customers.length} customers × 20 months)`);
        }
        
    } catch (error) {
        console.error('❌ Fix failed:', error);
    }
}

console.log('🔧 Payment Manager Fix Script Loaded');
console.log('Run: fixPaymentManagerIssue()');
