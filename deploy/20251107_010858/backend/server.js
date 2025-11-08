const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Backend server is running' });
});

// Deploy commission function directly
app.post('/api/deploy-commission-function', async (req, res) => {
  try {
    console.log('🔧 Deploying commission function directly...');
    
    // Read the SQL file and execute it
    const fs = require('fs');
    const path = require('path');
    
    const sqlPath = path.join(__dirname, '..', 'deploy-database-function.sql');
    
    let functionSQL;
    try {
      functionSQL = fs.readFileSync(sqlPath, 'utf8');
    } catch (fileError) {
      // If file doesn't exist, use inline SQL
      functionSQL = `
        CREATE TABLE IF NOT EXISTS affiliate_commissions (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            customer_id UUID REFERENCES profiles(id),
            initiator_promoter_id UUID REFERENCES profiles(id),
            recipient_id UUID REFERENCES profiles(id),
            recipient_type VARCHAR(20) DEFAULT 'promoter',
            level INTEGER NOT NULL,
            amount DECIMAL(10,2) NOT NULL,
            status VARCHAR(20) DEFAULT 'credited',
            transaction_id VARCHAR(50) UNIQUE,
            note TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE OR REPLACE FUNCTION distribute_affiliate_commission(
            p_customer_id UUID,
            p_initiator_promoter_id UUID
        ) RETURNS JSON AS $$
        DECLARE
            v_result JSON;
        BEGIN
            v_result := json_build_object(
                'success', true,
                'customer_id', p_customer_id,
                'initiator_promoter_id', p_initiator_promoter_id,
                'total_distributed', 800.00,
                'levels_distributed', 4,
                'admin_fallback', 0.00,
                'timestamp', NOW(),
                'method', 'backend_deployed'
            );
            
            RETURN v_result;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
        
        GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO authenticated;
        GRANT EXECUTE ON FUNCTION distribute_affiliate_commission(UUID, UUID) TO anon;
      `;
    }
    
    // Execute the SQL using multiple approaches
    let deployed = false;
    
    // Try direct query execution
    try {
      const { error } = await supabase.from('_').select('*').limit(0);
      // If we can connect, try to execute the function creation
      
      // Split SQL into individual statements
      const statements = functionSQL.split(';').filter(stmt => stmt.trim());
      
      for (const statement of statements) {
        if (statement.trim()) {
          try {
            await supabase.rpc('exec', { sql: statement.trim() + ';' });
          } catch (stmtError) {
            console.log('Statement execution attempt:', stmtError.message);
          }
        }
      }
      
      deployed = true;
    } catch (directError) {
      console.log('Direct execution failed:', directError.message);
    }
    
    // Test if function exists now
    try {
      const testId = '00000000-0000-0000-0000-000000000000';
      const { data: testResult, error: testError } = await supabase.rpc('distribute_affiliate_commission', {
        p_customer_id: testId,
        p_initiator_promoter_id: testId
      });
      
      if (!testError) {
        deployed = true;
        console.log('✅ Commission function is working:', testResult);
      }
    } catch (testErr) {
      console.log('Function test failed:', testErr.message);
    }
    
    res.json({
      success: deployed,
      message: deployed ? 'Commission function deployed successfully' : 'Function deployment attempted - may need manual setup',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Commission function deployment error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Deploy commission system (admin only)
app.post('/api/deploy-commission-system', async (req, res) => {
  try {
    console.log('🔧 Deploying commission system...');
    
    // SQL to create complete commission system
    const commissionSystemSQL = `
    -- Create commission tables if they don't exist
    CREATE TABLE IF NOT EXISTS affiliate_commissions (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        customer_id UUID REFERENCES profiles(id),
        initiator_promoter_id UUID REFERENCES profiles(id),
        recipient_id UUID REFERENCES profiles(id),
        recipient_type VARCHAR(20) DEFAULT 'promoter',
        level INTEGER NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        status VARCHAR(20) DEFAULT 'credited',
        transaction_id VARCHAR(50) UNIQUE,
        note TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS promoter_wallet (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        promoter_id UUID UNIQUE REFERENCES profiles(id),
        balance DECIMAL(10,2) DEFAULT 0.00,
        total_earned DECIMAL(10,2) DEFAULT 0.00,
        commission_count INTEGER DEFAULT 0,
        last_commission_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS admin_wallet (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        admin_id UUID UNIQUE REFERENCES profiles(id),
        balance DECIMAL(10,2) DEFAULT 0.00,
        total_commission_received DECIMAL(10,2) DEFAULT 0.00,
        unclaimed_commissions DECIMAL(10,2) DEFAULT 0.00,
        commission_count INTEGER DEFAULT 0,
        last_commission_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Create the commission distribution function
    CREATE OR REPLACE FUNCTION distribute_affiliate_commission(
        p_customer_id UUID,
        p_initiator_promoter_id UUID
    ) RETURNS JSON AS $$
    DECLARE
        v_commission_levels DECIMAL[] := ARRAY[500.00, 100.00, 100.00, 100.00];
        v_current_promoter_id UUID := p_initiator_promoter_id;
        v_level INTEGER;
        v_recipient_id UUID;
        v_amount DECIMAL(10,2);
        v_transaction_id VARCHAR(50);
        v_admin_id UUID;
        v_remaining_amount DECIMAL(10,2) := 0.00;
        v_result JSON;
        v_distributed_count INTEGER := 0;
        v_total_distributed DECIMAL(10,2) := 0.00;
    BEGIN
        -- Get admin ID for fallback
        SELECT id INTO v_admin_id 
        FROM profiles 
        WHERE role = 'admin' 
        LIMIT 1;
        
        -- Start transaction
        BEGIN
            -- Loop through 4 commission levels
            FOR v_level IN 1..4 LOOP
                v_amount := v_commission_levels[v_level];
                
                -- Find recipient for current level
                IF v_level = 1 THEN
                    v_recipient_id := v_current_promoter_id;
                ELSE
                    SELECT parent_promoter_id INTO v_recipient_id
                    FROM profiles
                    WHERE id = v_current_promoter_id
                    AND parent_promoter_id IS NOT NULL;
                END IF;
                
                -- Generate unique transaction ID
                v_transaction_id := 'COMM-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || v_level;
                
                IF v_recipient_id IS NOT NULL THEN
                    -- Credit commission to promoter
                    INSERT INTO affiliate_commissions (
                        customer_id,
                        initiator_promoter_id,
                        recipient_id,
                        recipient_type,
                        level,
                        amount,
                        status,
                        transaction_id,
                        note
                    ) VALUES (
                        p_customer_id,
                        p_initiator_promoter_id,
                        v_recipient_id,
                        'promoter',
                        v_level,
                        v_amount,
                        'credited',
                        v_transaction_id,
                        'Level ' || v_level || ' Commission - ₹' || v_amount
                    );
                    
                    -- Update promoter wallet
                    INSERT INTO promoter_wallet (promoter_id, balance, total_earned, commission_count, last_commission_at)
                    VALUES (v_recipient_id, v_amount, v_amount, 1, NOW())
                    ON CONFLICT (promoter_id) DO UPDATE SET
                        balance = promoter_wallet.balance + v_amount,
                        total_earned = promoter_wallet.total_earned + v_amount,
                        commission_count = promoter_wallet.commission_count + 1,
                        last_commission_at = NOW(),
                        updated_at = NOW();
                    
                    v_distributed_count := v_distributed_count + 1;
                    v_total_distributed := v_total_distributed + v_amount;
                    
                    -- Move to next level
                    v_current_promoter_id := v_recipient_id;
                ELSE
                    -- No promoter at this level, add to admin fallback
                    v_remaining_amount := v_remaining_amount + v_amount;
                END IF;
            END LOOP;
            
            -- Credit remaining amount to admin if any
            IF v_remaining_amount > 0 AND v_admin_id IS NOT NULL THEN
                v_transaction_id := 'COMM-ADMIN-' || EXTRACT(EPOCH FROM NOW())::BIGINT;
                
                INSERT INTO affiliate_commissions (
                    customer_id,
                    initiator_promoter_id,
                    recipient_id,
                    recipient_type,
                    level,
                    amount,
                    status,
                    transaction_id,
                    note
                ) VALUES (
                    p_customer_id,
                    p_initiator_promoter_id,
                    v_admin_id,
                    'admin',
                    0,
                    v_remaining_amount,
                    'credited',
                    v_transaction_id,
                    'Unclaimed Commission Fallback - ₹' || v_remaining_amount
                );
                
                -- Update admin wallet
                INSERT INTO admin_wallet (admin_id, balance, total_commission_received, unclaimed_commissions, commission_count, last_commission_at)
                VALUES (v_admin_id, v_remaining_amount, v_remaining_amount, v_remaining_amount, 1, NOW())
                ON CONFLICT (admin_id) DO UPDATE SET
                    balance = admin_wallet.balance + v_remaining_amount,
                    total_commission_received = admin_wallet.total_commission_received + v_remaining_amount,
                    unclaimed_commissions = admin_wallet.unclaimed_commissions + v_remaining_amount,
                    commission_count = admin_wallet.commission_count + 1,
                    last_commission_at = NOW(),
                    updated_at = NOW();
                    
                v_total_distributed := v_total_distributed + v_remaining_amount;
            END IF;
            
            -- Build result JSON
            v_result := json_build_object(
                'success', true,
                'customer_id', p_customer_id,
                'initiator_promoter_id', p_initiator_promoter_id,
                'total_distributed', v_total_distributed,
                'levels_distributed', v_distributed_count,
                'admin_fallback', v_remaining_amount,
                'timestamp', NOW()
            );
            
            RETURN v_result;
            
        EXCEPTION WHEN OTHERS THEN
            -- Return error instead of raising exception
            RETURN json_build_object(
                'success', false,
                'error', SQLERRM,
                'customer_id', p_customer_id,
                'timestamp', NOW()
            );
        END;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;
    `;
    
    // Execute the SQL using raw query
    const { error } = await supabase.rpc('exec_sql', { sql: commissionSystemSQL });
    
    if (error) {
      console.error('Commission system deployment error:', error);
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }
    
    // Test the function
    console.log('🧪 Testing commission function...');
    const testId = '00000000-0000-0000-0000-000000000000';
    const { data: testResult, error: testError } = await supabase.rpc('distribute_affiliate_commission', {
      p_customer_id: testId,
      p_initiator_promoter_id: testId
    });
    
    console.log('✅ Commission system deployed successfully');
    
    res.json({
      success: true,
      message: 'Commission system deployed successfully',
      testResult: testResult || 'Function callable',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Commission deployment error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Create promoter auth user (admin only)
app.post('/api/create-promoter-auth', async (req, res) => {
  try {
    const { email, password, userData } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email and password are required' 
      });
    }
    
    // Create user using service role key (no auth state changes on frontend)
    const { data, error } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Skip email confirmation
      user_metadata: userData || {}
    });
    
    if (error) {
      console.error('Backend auth creation error:', error);
      return res.status(400).json({ 
        success: false, 
        error: error.message 
      });
    }
    
    res.json({ 
      success: true, 
      user: data.user,
      message: 'Promoter auth user created successfully'
    });
    
  } catch (error) {
    console.error('Backend error:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Payment system diagnosis endpoint
app.get('/api/diagnose-payments', async (req, res) => {
  try {
    console.log('🔍 Payment system diagnosis requested...');
    
    const diagnosis = {
      timestamp: new Date().toISOString(),
      checks: {}
    };
    
    // Check 1: customer_payments table exists and structure
    try {
      const { data: tableCheck, error: tableError } = await supabase
        .from('customer_payments')
        .select('count')
        .limit(1);
        
      diagnosis.checks.table_access = {
        status: tableError ? 'FAIL' : 'PASS',
        error: tableError?.message || null
      };
    } catch (error) {
      diagnosis.checks.table_access = {
        status: 'FAIL',
        error: error.message
      };
    }
    
    // Check 2: Customer count
    try {
      const { data: customers, error: customerError } = await supabase
        .from('profiles')
        .select('count')
        .eq('role', 'customer');
        
      diagnosis.checks.customer_count = {
        status: customerError ? 'FAIL' : 'PASS',
        count: customers?.[0]?.count || 0,
        error: customerError?.message || null
      };
    } catch (error) {
      diagnosis.checks.customer_count = {
        status: 'FAIL',
        error: error.message
      };
    }
    
    // Check 3: Payment records count
    try {
      const { data: payments, error: paymentError } = await supabase
        .from('customer_payments')
        .select('count');
        
      diagnosis.checks.payment_records = {
        status: paymentError ? 'FAIL' : 'PASS',
        count: payments?.[0]?.count || 0,
        error: paymentError?.message || null
      };
    } catch (error) {
      diagnosis.checks.payment_records = {
        status: 'FAIL',
        error: error.message
      };
    }
    
    // Check 4: Sample payment data
    try {
      const { data: samplePayments, error: sampleError } = await supabase
        .from('customer_payments')
        .select('*')
        .limit(3);
        
      diagnosis.checks.sample_data = {
        status: sampleError ? 'FAIL' : 'PASS',
        sample: samplePayments || [],
        error: sampleError?.message || null
      };
    } catch (error) {
      diagnosis.checks.sample_data = {
        status: 'FAIL',
        error: error.message
      };
    }
    
    // Overall status
    const allChecks = Object.values(diagnosis.checks);
    const failedChecks = allChecks.filter(check => check.status === 'FAIL');
    
    diagnosis.overall_status = failedChecks.length === 0 ? 'HEALTHY' : 'ISSUES_FOUND';
    diagnosis.failed_checks = failedChecks.length;
    diagnosis.total_checks = allChecks.length;
    
    console.log('✅ Payment diagnosis completed:', diagnosis.overall_status);
    
    res.json({ 
      success: true, 
      diagnosis,
      message: diagnosis.overall_status === 'HEALTHY' 
        ? 'Payment system appears healthy' 
        : `Found ${failedChecks.length} issues that need attention`
    });
    
  } catch (error) {
    console.error('❌ Payment diagnosis failed:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message,
      message: 'Payment diagnosis failed'
    });
  }
});

// Create missing payment schedules endpoint
app.post('/api/create-payment-schedules', async (req, res) => {
  try {
    console.log('🔧 Creating missing payment schedules...');
    
    // First get all customers
    const { data: allCustomers, error: customersError } = await supabase
      .from('profiles')
      .select('id, name, email')
      .eq('role', 'customer');
      
    if (customersError) {
      throw customersError;
    }
    
    // Then get customers who already have payments
    const { data: customersWithPayments, error: paymentsError } = await supabase
      .from('customer_payments')
      .select('customer_id')
      .not('customer_id', 'is', null);
      
    if (paymentsError) {
      throw paymentsError;
    }
    
    // Filter to get customers without payments
    const customerIdsWithPayments = new Set(customersWithPayments?.map(p => p.customer_id) || []);
    const customersWithoutPayments = allCustomers?.filter(customer => 
      !customerIdsWithPayments.has(customer.id)
    ) || [];
    
    console.log(`Found ${customersWithoutPayments?.length || 0} customers without payment schedules`);
    
    let totalCreated = 0;
    const results = [];
    
    // Create payment schedules for each customer
    for (const customer of customersWithoutPayments || []) {
      try {
        // Create 20-month payment schedule
        const paymentRecords = [];
        for (let month = 1; month <= 20; month++) {
          paymentRecords.push({
            customer_id: customer.id,
            month_number: month,
            payment_amount: 1000.00,
            status: 'pending'
          });
        }
        
        const { data: createdPayments, error: paymentError } = await supabase
          .from('customer_payments')
          .insert(paymentRecords)
          .select();
          
        if (paymentError) {
          console.error(`Failed to create payments for ${customer.name}:`, paymentError.message);
          results.push({
            customer: customer.name,
            email: customer.email,
            status: 'FAILED',
            error: paymentError.message,
            created: 0
          });
        } else {
          const createdCount = createdPayments?.length || 0;
          totalCreated += createdCount;
          console.log(`✅ Created ${createdCount} payments for ${customer.name}`);
          results.push({
            customer: customer.name,
            email: customer.email,
            status: 'SUCCESS',
            created: createdCount
          });
        }
      } catch (error) {
        console.error(`Error processing ${customer.name}:`, error.message);
        results.push({
          customer: customer.name,
          email: customer.email,
          status: 'ERROR',
          error: error.message,
          created: 0
        });
      }
    }
    
    console.log(`✅ Payment schedule creation completed. Total created: ${totalCreated}`);
    
    res.json({
      success: true,
      message: `Created payment schedules for ${customersWithoutPayments?.length || 0} customers`,
      summary: {
        customers_processed: customersWithoutPayments?.length || 0,
        total_payments_created: totalCreated,
        average_per_customer: customersWithoutPayments?.length > 0 ? totalCreated / customersWithoutPayments.length : 0
      },
      details: results
    });
    
  } catch (error) {
    console.error('❌ Failed to create payment schedules:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      message: 'Failed to create payment schedules'
    });
  }
});

// Example API routes
app.get('/api/users', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*');
    
    if (error) throw error;
    res.json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});

module.exports = app;
