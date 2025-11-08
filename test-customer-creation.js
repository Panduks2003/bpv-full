/**
 * Test Customer Creation System
 * This script tests the customer creation functionality to identify issues
 */

import { supabase } from './frontend/src/common/services/supabaseClient.js';

async function testCustomerCreation() {
  console.log('🧪 Testing Customer Creation System...\n');

  try {
    // 1. Check if database functions exist
    console.log('1️⃣ Checking database functions...');
    
    const { data: functions, error: funcError } = await supabase.rpc('check_function_exists', {
      function_name: 'create_customer_final'
    });
    
    if (funcError) {
      console.error('❌ Error checking functions:', funcError);
    } else {
      console.log('✅ Function check result:', functions);
    }

    // 2. Check if we have any promoters to assign customers to
    console.log('\n2️⃣ Checking available promoters...');
    
    const { data: promoters, error: promoterError } = await supabase
      .from('profiles')
      .select('id, name, promoter_id, pins')
      .eq('role', 'promoter')
      .order('created_at', { ascending: false });
    
    if (promoterError) {
      console.error('❌ Error loading promoters:', promoterError);
      return;
    }
    
    console.log(`✅ Found ${promoters?.length || 0} promoters:`);
    promoters?.forEach(p => {
      console.log(`   - ${p.name} (${p.promoter_id}) - Pins: ${p.pins || 0}`);
    });

    if (!promoters || promoters.length === 0) {
      console.error('❌ No promoters found! Cannot create customers without promoters.');
      return;
    }

    // Find a promoter with pins
    const promoterWithPins = promoters.find(p => (p.pins || 0) > 0);
    if (!promoterWithPins) {
      console.error('❌ No promoters have pins! Cannot create customers without pins.');
      return;
    }

    console.log(`✅ Using promoter: ${promoterWithPins.name} (${promoterWithPins.pins} pins)`);

    // 3. Test customer creation function
    console.log('\n3️⃣ Testing customer creation function...');
    
    const testCustomerData = {
      p_name: 'Test Customer',
      p_mobile: '9876543210',
      p_state: 'Karnataka',
      p_city: 'Bangalore',
      p_pincode: '560001',
      p_address: 'Test Address, Bangalore',
      p_customer_id: `TEST${Date.now()}`, // Unique customer ID
      p_password: 'testpass123',
      p_parent_promoter_id: promoterWithPins.id,
      p_email: `test${Date.now()}@example.com`
    };

    console.log('📝 Test customer data:', testCustomerData);

    const { data: result, error: createError } = await supabase.rpc('create_customer_final', testCustomerData);

    if (createError) {
      console.error('❌ Customer creation failed:', createError);
      console.error('Error details:', createError.message);
      return;
    }

    if (!result?.success) {
      console.error('❌ Customer creation returned failure:', result);
      return;
    }

    console.log('✅ Customer creation successful!');
    console.log('📋 Result:', result);

    // 4. Verify customer was created in database
    console.log('\n4️⃣ Verifying customer in database...');
    
    const { data: createdCustomer, error: verifyError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', result.customer_id)
      .eq('role', 'customer')
      .single();

    if (verifyError) {
      console.error('❌ Error verifying customer:', verifyError);
      return;
    }

    console.log('✅ Customer verified in database:');
    console.log('   - ID:', createdCustomer.id);
    console.log('   - Name:', createdCustomer.name);
    console.log('   - Customer ID:', createdCustomer.customer_id);
    console.log('   - Phone:', createdCustomer.phone);
    console.log('   - Parent Promoter:', createdCustomer.parent_promoter_id);

    // 5. Check payment schedule
    console.log('\n5️⃣ Checking payment schedule...');
    
    const { data: payments, error: paymentError } = await supabase
      .from('customer_payments')
      .select('*')
      .eq('customer_id', result.customer_id)
      .order('month_number');

    if (paymentError) {
      console.error('❌ Error checking payments:', paymentError);
    } else {
      console.log(`✅ Payment schedule created: ${payments?.length || 0} months`);
      if (payments?.length > 0) {
        console.log(`   - First payment: Month ${payments[0].month_number}, Amount: ₹${payments[0].payment_amount}`);
        console.log(`   - Last payment: Month ${payments[payments.length-1].month_number}, Amount: ₹${payments[payments.length-1].payment_amount}`);
      }
    }

    console.log('\n🎉 Customer creation test completed successfully!');

  } catch (error) {
    console.error('💥 Test failed with error:', error);
    console.error('Stack trace:', error.stack);
  }
}

// Alternative function check without RPC
async function checkFunctionsDirectly() {
  console.log('\n🔍 Checking functions directly...');
  
  try {
    // Try to call the function with minimal data to see if it exists
    const { data, error } = await supabase.rpc('create_customer_final', {
      p_name: '',
      p_mobile: '',
      p_state: '',
      p_city: '',
      p_pincode: '',
      p_address: '',
      p_customer_id: '',
      p_password: '',
      p_parent_promoter_id: '00000000-0000-0000-0000-000000000000',
      p_email: null
    });

    if (error) {
      if (error.message.includes('function') && error.message.includes('does not exist')) {
        console.error('❌ Function create_customer_final does not exist!');
        return false;
      } else {
        console.log('✅ Function exists (got validation error as expected)');
        console.log('Error (expected):', error.message);
        return true;
      }
    }
    
    console.log('✅ Function exists and returned:', data);
    return true;
  } catch (error) {
    console.error('❌ Error checking function:', error);
    return false;
  }
}

// Run the tests
async function runTests() {
  console.log('🚀 Starting Customer Creation Diagnostics\n');
  
  // Check function existence first
  const functionExists = await checkFunctionsDirectly();
  
  if (!functionExists) {
    console.log('\n❌ Cannot proceed with tests - create_customer_final function is missing!');
    console.log('💡 Need to deploy the database function first.');
    return;
  }
  
  // Run full test
  await testCustomerCreation();
}

runTests().catch(console.error);
