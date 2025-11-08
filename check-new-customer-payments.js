// Check if the newly created customer has payment records
// Run this in browser console

async function checkNewCustomerPayments() {
    const newCustomerId = '8c0c436f-96ce-4550-8de3-d622398c5d21';
    
    console.log('🔍 Checking payments for newly created customer:', newCustomerId);
    
    try {
        // Check customer profile
        const { data: customer, error: customerError } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', newCustomerId)
            .single();
            
        if (customerError) {
            console.error('❌ Customer not found:', customerError);
            return;
        }
        
        console.log('👤 Customer profile:', customer);
        
        // Check payment records
        const { data: payments, error: paymentsError } = await supabase
            .from('customer_payments')
            .select('*')
            .eq('customer_id', newCustomerId)
            .order('month_number');
            
        if (paymentsError) {
            console.error('❌ Error loading payments:', paymentsError);
            return;
        }
        
        console.log(`💰 Payment records found: ${payments?.length || 0}/20`);
        
        if (payments && payments.length > 0) {
            console.log('✅ PAYMENT AUTOMATION WORKING!');
            console.log('📊 Sample payments:', payments.slice(0, 3));
            console.log('💳 Payment structure:', {
                hasAmount: !!payments[0].amount,
                hasPaymentAmount: !!payments[0].payment_amount,
                amount: payments[0].amount || payments[0].payment_amount,
                status: payments[0].status
            });
        } else {
            console.log('❌ NO PAYMENTS FOUND - Automation failed for this customer');
            
            // Try to create payments manually for this customer
            console.log('🔧 Creating payments manually...');
            
            const paymentRecords = [];
            for (let month = 1; month <= 20; month++) {
                paymentRecords.push({
                    customer_id: newCustomerId,
                    month_number: month,
                    payment_amount: 1000.00,
                    status: 'pending',
                    created_at: new Date().toISOString(),
                    updated_at: new Date().toISOString()
                });
            }
            
            const { data: insertResult, error: insertError } = await supabase
                .from('customer_payments')
                .insert(paymentRecords);
                
            if (insertError) {
                console.error('❌ Failed to create payments:', insertError);
            } else {
                console.log('✅ Successfully created 20 payment records');
            }
        }
        
        // Check commission records
        const { data: commissions, error: commissionsError } = await supabase
            .from('affiliate_commissions')
            .select('*')
            .eq('customer_id', newCustomerId);
            
        if (!commissionsError) {
            console.log(`🎯 Commission records: ${commissions?.length || 0}`);
            if (commissions && commissions.length > 0) {
                console.log('💰 Total commission amount:', 
                    commissions.reduce((sum, c) => sum + (c.amount || 0), 0));
            }
        }
        
    } catch (error) {
        console.error('❌ Check failed:', error);
    }
}

// Run the check
checkNewCustomerPayments();
