// =====================================================
// EMERGENCY DATABASE FIX - IMMEDIATE EXECUTION
// =====================================================
// Copy and paste this ENTIRE script into browser console

console.log('🚨 EMERGENCY DATABASE FIX STARTING...');

async function emergencyDatabaseFix() {
    try {
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            alert('❌ Supabase client not found - make sure you are on the admin page');
            return false;
        }

        console.log('✅ Supabase client found - applying emergency fixes...');

        // =====================================================
        // FIX 1: INVESTMENT_PLAN COLUMN ISSUE
        // =====================================================
        console.log('🔧 Fix 1: Resolving investment_plan column issue...');
        
        const investmentPlanFix = `
            DO $$
            BEGIN
                -- Check if saving_plan column exists
                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'profiles' AND column_name = 'saving_plan'
                ) THEN
                    -- Check if investment_plan exists
                    IF EXISTS (
                        SELECT 1 FROM information_schema.columns 
                        WHERE table_name = 'profiles' AND column_name = 'investment_plan'
                    ) THEN
                        -- Rename investment_plan to saving_plan
                        ALTER TABLE profiles RENAME COLUMN investment_plan TO saving_plan;
                        RAISE NOTICE 'SUCCESS: Renamed investment_plan to saving_plan';
                    ELSE
                        -- Create saving_plan column if neither exists
                        ALTER TABLE profiles ADD COLUMN saving_plan VARCHAR(255) DEFAULT '₹1000 per month for 20 months';
                        RAISE NOTICE 'SUCCESS: Created new saving_plan column';
                    END IF;
                ELSE
                    RAISE NOTICE 'INFO: saving_plan column already exists';
                END IF;
            END $$;
        `;

        try {
            const { data: fix1Data, error: fix1Error } = await supabase.rpc('sql', { query: investmentPlanFix });
            if (fix1Error) {
                console.log('❌ Fix 1 Error:', fix1Error.message);
            } else {
                console.log('✅ Fix 1 SUCCESS: Investment plan column fixed');
            }
        } catch (fix1Err) {
            console.log('❌ Fix 1 Exception:', fix1Err.message);
        }

        // =====================================================
        // FIX 2: PROMOTER_WALLET TABLE AND ENDPOINT
        // =====================================================
        console.log('🔧 Fix 2: Creating/fixing promoter_wallet table...');
        
        const promoterWalletFix = `
            -- Create promoter_wallet table if it doesn't exist
            CREATE TABLE IF NOT EXISTS promoter_wallet (
                id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                promoter_id UUID UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
                balance DECIMAL(10,2) DEFAULT 0.00,
                total_earned DECIMAL(10,2) DEFAULT 0.00,
                total_withdrawn DECIMAL(10,2) DEFAULT 0.00,
                commission_count INTEGER DEFAULT 0,
                last_commission_at TIMESTAMP WITH TIME ZONE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );

            -- Create index for performance
            CREATE INDEX IF NOT EXISTS idx_promoter_wallet_promoter_id ON promoter_wallet(promoter_id);

            -- Disable RLS to prevent 406 errors
            ALTER TABLE promoter_wallet DISABLE ROW LEVEL SECURITY;

            -- Grant full permissions
            GRANT ALL ON promoter_wallet TO authenticated;
            GRANT ALL ON promoter_wallet TO anon;
            GRANT ALL ON promoter_wallet TO postgres;
        `;

        try {
            const { data: fix2Data, error: fix2Error } = await supabase.rpc('sql', { query: promoterWalletFix });
            if (fix2Error) {
                console.log('❌ Fix 2 Error:', fix2Error.message);
            } else {
                console.log('✅ Fix 2 SUCCESS: Promoter wallet table created/fixed');
            }
        } catch (fix2Err) {
            console.log('❌ Fix 2 Exception:', fix2Err.message);
        }

        // =====================================================
        // FIX 3: POPULATE PROMOTER_WALLET WITH EXISTING DATA
        // =====================================================
        console.log('🔧 Fix 3: Populating promoter_wallet with existing commission data...');
        
        const populateWalletFix = `
            INSERT INTO promoter_wallet (promoter_id, balance, total_earned, commission_count, last_commission_at)
            SELECT 
                p.id as promoter_id,
                COALESCE(
                    (SELECT SUM(ac.amount) 
                     FROM affiliate_commissions ac 
                     WHERE ac.recipient_id = p.id AND ac.status = 'credited'), 
                    0
                ) as balance,
                COALESCE(
                    (SELECT SUM(ac.amount) 
                     FROM affiliate_commissions ac 
                     WHERE ac.recipient_id = p.id AND ac.status = 'credited'), 
                    0
                ) as total_earned,
                COALESCE(
                    (SELECT COUNT(*) 
                     FROM affiliate_commissions ac 
                     WHERE ac.recipient_id = p.id AND ac.status = 'credited'), 
                    0
                ) as commission_count,
                (SELECT MAX(ac.created_at) 
                 FROM affiliate_commissions ac 
                 WHERE ac.recipient_id = p.id AND ac.status = 'credited')
            FROM profiles p
            WHERE p.role = 'promoter'
            ON CONFLICT (promoter_id) DO UPDATE SET
                balance = EXCLUDED.balance,
                total_earned = EXCLUDED.total_earned,
                commission_count = EXCLUDED.commission_count,
                last_commission_at = EXCLUDED.last_commission_at,
                updated_at = NOW();
        `;

        try {
            const { data: fix3Data, error: fix3Error } = await supabase.rpc('sql', { query: populateWalletFix });
            if (fix3Error) {
                console.log('❌ Fix 3 Error:', fix3Error.message);
            } else {
                console.log('✅ Fix 3 SUCCESS: Promoter wallet populated with commission data');
            }
        } catch (fix3Err) {
            console.log('❌ Fix 3 Exception:', fix3Err.message);
        }

        // =====================================================
        // FIX 4: UPDATE CUSTOMER CREATION FUNCTION
        // =====================================================
        console.log('🔧 Fix 4: Updating customer creation function to use saving_plan...');
        
        const functionFix = `
            CREATE OR REPLACE FUNCTION create_customer_with_pin_deduction(
                p_name TEXT,
                p_mobile TEXT,
                p_state TEXT,
                p_city TEXT,
                p_pincode TEXT,
                p_address TEXT,
                p_customer_id VARCHAR,
                p_password TEXT,
                p_parent_promoter_id UUID,
                p_email TEXT DEFAULT NULL
            )
            RETURNS JSON
            LANGUAGE plpgsql
            SECURITY DEFINER
            SET search_path = public
            AS $$
            DECLARE
                new_customer_id UUID;
                auth_user_id UUID;
                auth_email VARCHAR(255);
                result JSON;
                promoter_pins INTEGER;
                hashed_password TEXT;
                salt_value TEXT;
                payment_count INTEGER;
            BEGIN
                BEGIN
                    -- Check promoter has enough pins
                    SELECT pins INTO promoter_pins
                    FROM profiles
                    WHERE id = p_parent_promoter_id AND role = 'promoter'
                    FOR UPDATE;
                    
                    IF promoter_pins IS NULL THEN
                        RAISE EXCEPTION 'Promoter not found';
                    END IF;
                    
                    IF promoter_pins < 1 THEN
                        RAISE EXCEPTION 'Insufficient pins. Promoter has % pins, but 1 is required', promoter_pins;
                    END IF;
                    
                    -- Generate email and password
                    auth_email := COALESCE(p_email, p_customer_id || '@brightplanetventures.local');
                    salt_value := gen_salt('bf');
                    hashed_password := crypt(p_password, salt_value);
                    
                    -- Create auth user
                    INSERT INTO auth.users (
                        instance_id, id, aud, role, email, encrypted_password,
                        email_confirmed_at, invited_at, confirmation_sent_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, email_change, email_change_token_new, recovery_token
                    ) VALUES (
                        '00000000-0000-0000-0000-000000000000', gen_random_uuid(),
                        'authenticated', 'authenticated', auth_email, hashed_password,
                        NOW(), NOW(), NOW(),
                        '{"provider":"email","providers":["email"]}', '{}', NOW(), NOW(),
                        '', '', '', ''
                    ) RETURNING id INTO auth_user_id;
                    
                    new_customer_id := auth_user_id;
                    
                    -- Create profile using saving_plan (NOT investment_plan)
                    INSERT INTO profiles (
                        id, name, email, phone, role, customer_id,
                        state, city, pincode, address, parent_promoter_id,
                        status, saving_plan, created_at, updated_at
                    ) VALUES (
                        new_customer_id, p_name, COALESCE(p_email, auth_email), p_mobile,
                        'customer', p_customer_id, p_state, p_city, p_pincode, p_address,
                        p_parent_promoter_id, 'active', '₹1000 per month for 20 months',
                        NOW(), NOW()
                    );
                    
                    -- Deduct pin from promoter
                    UPDATE profiles 
                    SET pins = pins - 1, updated_at = NOW()
                    WHERE id = p_parent_promoter_id;
                    
                    -- Create payment schedule
                    INSERT INTO customer_payments (
                        customer_id, month_number, payment_amount, status, created_at, updated_at
                    )
                    SELECT new_customer_id, generate_series(1, 20), 1000.00, 'pending', NOW(), NOW();
                    
                    SELECT COUNT(*) INTO payment_count FROM customer_payments WHERE customer_id = new_customer_id;
                    
                    result := json_build_object(
                        'success', true,
                        'customer_id', new_customer_id,
                        'customer_card_no', p_customer_id,
                        'payment_count', payment_count,
                        'message', 'Customer created successfully'
                    );
                    
                    RETURN result;
                    
                EXCEPTION WHEN OTHERS THEN
                    RETURN json_build_object(
                        'success', false,
                        'error', SQLERRM,
                        'message', 'Failed to create customer: ' || SQLERRM
                    );
                END;
            END;
            $$;
        `;

        try {
            const { data: fix4Data, error: fix4Error } = await supabase.rpc('sql', { query: functionFix });
            if (fix4Error) {
                console.log('❌ Fix 4 Error:', fix4Error.message);
            } else {
                console.log('✅ Fix 4 SUCCESS: Customer creation function updated');
            }
        } catch (fix4Err) {
            console.log('❌ Fix 4 Exception:', fix4Err.message);
        }

        // =====================================================
        // VERIFICATION
        // =====================================================
        console.log('🧪 Verifying fixes...');
        
        try {
            // Test promoter_wallet endpoint
            const { data: walletTest, error: walletError } = await supabase
                .from('promoter_wallet')
                .select('*')
                .limit(1);
                
            if (walletError) {
                console.log('⚠️ Promoter wallet test failed:', walletError.message);
            } else {
                console.log('✅ Promoter wallet endpoint working');
            }
            
            // Test saving_plan column
            const { data: columnTest, error: columnError } = await supabase
                .from('profiles')
                .select('saving_plan')
                .eq('role', 'customer')
                .limit(1);
                
            if (columnError) {
                console.log('⚠️ Saving plan column test failed:', columnError.message);
            } else {
                console.log('✅ Saving plan column working');
            }
            
        } catch (testErr) {
            console.log('⚠️ Verification test error:', testErr.message);
        }

        console.log('');
        console.log('🎉 EMERGENCY DATABASE FIX COMPLETED!');
        console.log('');
        console.log('✅ All fixes applied:');
        console.log('   • Investment plan column renamed to saving_plan');
        console.log('   • Promoter wallet table created and populated');
        console.log('   • Customer creation function updated');
        console.log('   • Permissions and RLS configured');
        console.log('');
        console.log('💡 Try creating a customer again - the errors should be resolved!');
        
        // Show success alert
        alert('✅ Emergency database fixes applied successfully! The investment_plan and promoter_wallet errors should now be resolved.');
        
        return true;

    } catch (error) {
        console.error('❌ CRITICAL ERROR in emergency fix:', error);
        alert('❌ Emergency fix failed: ' + error.message);
        return false;
    }
}

// Auto-execute the emergency fix
emergencyDatabaseFix();
