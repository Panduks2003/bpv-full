// Script to apply the commission fix SQL to Supabase
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Read SQL file
const sqlFile = fs.readFileSync('./database/fix-commission-null-customer-id.sql', 'utf8');

// Create Supabase client
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL || process.env.SUPABASE_URL;
const supabaseKey = process.env.REACT_APP_SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: Supabase URL or key not found in environment variables');
  console.log('Please ensure REACT_APP_SUPABASE_URL and REACT_APP_SUPABASE_SERVICE_KEY are set');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function applyFix() {
  console.log('Applying commission fix to database...');
  
  try {
    // Execute the SQL directly using Supabase's rpc call
    const { data, error } = await supabase.rpc('exec_sql', { sql: sqlFile });
    
    if (error) {
      console.error('Error applying SQL fix:', error);
      return;
    }
    
    console.log('Commission fix applied successfully!');
    console.log('The following functions have been updated:');
    console.log('1. distribute_affiliate_commission - Added validation for customer_id');
    console.log('2. create_customer_final - Ensures customer_id is always returned');
    
  } catch (err) {
    console.error('Exception occurred:', err);
  }
}

applyFix();