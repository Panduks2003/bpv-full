// =====================================================
// PAYMENT MANAGEMENT DIAGNOSIS SCRIPT
// =====================================================
// This script helps diagnose payment management issues

console.log('🔍 Starting Payment Management Diagnosis...');

// Test Supabase connection
async function testSupabaseConnection() {
    try {
        const { createClient } = require('./backend/node_modules/@supabase/supabase-js');
        
        // Read environment variables from backend
        require('dotenv').config({ path: './backend/.env' });
        
        const supabaseUrl = process.env.SUPABASE_URL || 'https://ubokvxgxszhpzmjonuss.supabase.co';
        const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
        
        if (!supabaseKey) {
            console.error('❌ SUPABASE_SERVICE_ROLE_KEY not found in environment');
            return false;
        }
        
        const supabase = createClient(supabaseUrl, supabaseKey);
        
        // Test connection
        const { data, error } = await supabase.from('profiles').select('count').limit(1);
        
        if (error) {
            console.error('❌ Supabase connection failed:', error.message);
            return false;
        }
        
        console.log('✅ Supabase connection successful');
        return supabase;
        
    } catch (error) {
        console.error('❌ Error testing Supabase connection:', error.message);
        return false;
    }
}

// Check if customer_payments table exists and has correct structure
async function checkPaymentsTable(supabase) {
    try {
        console.log('\n📋 Checking customer_payments table...');
        
        // Check if table exists by trying to query it
        const { data, error } = await supabase
            .from('customer_payments')
            .select('*')
            .limit(1);
            
        if (error) {
            console.error('❌ customer_payments table issue:', error.message);
            return false;
        }
        
        console.log('✅ customer_payments table exists and is accessible');
        
        // Check table structure
        const { data: tableData, error: tableError } = await supabase
            .from('customer_payments')
            .select('*')
            .limit(5);
            
        if (tableError) {
            console.error('❌ Error querying customer_payments:', tableError.message);
            return false;
        }
        
        console.log(`✅ Found ${tableData?.length || 0} payment records`);
        
        if (tableData && tableData.length > 0) {
            console.log('📊 Sample payment record structure:', Object.keys(tableData[0]));
        }
        
        return true;
        
    } catch (error) {
        console.error('❌ Error checking payments table:', error.message);
        return false;
    }
}

// Check customers and their payment schedules
async function checkCustomerPayments(supabase) {
    try {
        console.log('\n👥 Checking customer payment schedules...');
        
        // Get all customers
        const { data: customers, error: customersError } = await supabase
            .from('profiles')
            .select('id, name, email, role')
            .eq('role', 'customer')
            .limit(10);
            
        if (customersError) {
            console.error('❌ Error fetching customers:', customersError.message);
            return false;
        }
        
        console.log(`✅ Found ${customers?.length || 0} customers`);
        
        if (!customers || customers.length === 0) {
            console.log('ℹ️ No customers found - this might be why payment management appears empty');
            return true;
        }
        
        // Check payment schedules for first few customers
        for (let i = 0; i < Math.min(3, customers.length); i++) {
            const customer = customers[i];
            
            const { data: payments, error: paymentsError } = await supabase
                .from('customer_payments')
                .select('*')
                .eq('customer_id', customer.id)
                .order('month_number');
                
            if (paymentsError) {
                console.error(`❌ Error fetching payments for ${customer.name}:`, paymentsError.message);
                continue;
            }
            
            console.log(`📊 Customer: ${customer.name} - ${payments?.length || 0} payment records`);
            
            if (payments && payments.length > 0) {
                const paidCount = payments.filter(p => p.status === 'paid').length;
                const pendingCount = payments.filter(p => p.status === 'pending').length;
                console.log(`   💰 Paid: ${paidCount}, Pending: ${pendingCount}`);
            }
        }
        
        return true;
        
    } catch (error) {
        console.error('❌ Error checking customer payments:', error.message);
        return false;
    }
}

// Check RLS policies
async function checkRLSPolicies(supabase) {
    try {
        console.log('\n🔒 Checking RLS policies...');
        
        // Try to query as different user types would
        const { data: adminCheck, error: adminError } = await supabase
            .from('customer_payments')
            .select('count')
            .limit(1);
            
        if (adminError) {
            console.error('❌ RLS policy issue:', adminError.message);
            console.log('ℹ️ This might indicate RLS is blocking access');
            return false;
        }
        
        console.log('✅ RLS policies allow access with service role key');
        return true;
        
    } catch (error) {
        console.error('❌ Error checking RLS policies:', error.message);
        return false;
    }
}

// Main diagnosis function
async function diagnosePaymentIssue() {
    console.log('🚀 Payment Management Diagnosis Starting...\n');
    
    const supabase = await testSupabaseConnection();
    if (!supabase) {
        console.log('\n❌ Cannot proceed without Supabase connection');
        return;
    }
    
    const tableOk = await checkPaymentsTable(supabase);
    const paymentsOk = await checkCustomerPayments(supabase);
    const rlsOk = await checkRLSPolicies(supabase);
    
    console.log('\n📋 DIAGNOSIS SUMMARY:');
    console.log('='.repeat(50));
    console.log(`Database Connection: ${supabase ? '✅' : '❌'}`);
    console.log(`Payments Table: ${tableOk ? '✅' : '❌'}`);
    console.log(`Customer Data: ${paymentsOk ? '✅' : '❌'}`);
    console.log(`RLS Policies: ${rlsOk ? '✅' : '❌'}`);
    
    if (tableOk && paymentsOk && rlsOk) {
        console.log('\n✅ Payment system appears to be working correctly');
        console.log('ℹ️ If you\'re still experiencing issues, check:');
        console.log('   - Browser console for frontend errors');
        console.log('   - Network tab for failed API calls');
        console.log('   - User authentication status');
    } else {
        console.log('\n❌ Issues found that need to be addressed');
    }
}

// Run diagnosis
diagnosePaymentIssue().catch(error => {
    console.error('❌ Diagnosis failed:', error.message);
});
