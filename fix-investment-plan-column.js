// =====================================================
// FIX INVESTMENT_PLAN COLUMN ISSUE
// =====================================================
// Copy and paste this script into browser console on admin page

console.log('🔧 Fixing investment_plan column issue...');

async function fixInvestmentPlanColumn() {
    try {
        // Get supabase client
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            console.log('❌ Supabase client not found - make sure you\'re on the admin page');
            return false;
        }

        console.log('✅ Supabase client found');

        // Step 1: Check current columns
        console.log('🔍 Checking current columns in profiles table...');
        
        const checkColumnsSQL = `
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'profiles' 
              AND column_name IN ('investment_plan', 'saving_plan')
            ORDER BY column_name;
        `;

        const { data: columns, error: columnError } = await supabase.rpc('sql', { 
            query: checkColumnsSQL 
        });

        if (columnError) {
            console.log('❌ Error checking columns:', columnError.message);
            return false;
        }

        console.log('📊 Current columns:', columns);

        // Step 2: Fix the column issue
        const fixColumnSQL = `
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
                        RAISE NOTICE 'Renamed investment_plan to saving_plan';
                    ELSE
                        -- Create saving_plan column if neither exists
                        ALTER TABLE profiles ADD COLUMN saving_plan VARCHAR(255) DEFAULT '₹1000 per month for 20 months';
                        RAISE NOTICE 'Created new saving_plan column';
                    END IF;
                ELSE
                    RAISE NOTICE 'saving_plan column already exists';
                END IF;
            END $$;
        `;

        console.log('🔧 Applying column fix...');
        
        const { data: fixResult, error: fixError } = await supabase.rpc('sql', { 
            query: fixColumnSQL 
        });

        if (fixError) {
            console.log('❌ Error applying fix:', fixError.message);
            return false;
        }

        console.log('✅ Column fix applied successfully');

        // Step 3: Verify the fix
        const { data: verifyColumns, error: verifyError } = await supabase.rpc('sql', { 
            query: checkColumnsSQL 
        });

        if (verifyError) {
            console.log('❌ Error verifying fix:', verifyError.message);
            return false;
        }

        console.log('📊 Columns after fix:', verifyColumns);

        // Step 4: Update the create_customer_final function to use saving_plan
        const updateFunctionSQL = `
            CREATE OR REPLACE FUNCTION create_customer_final(
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
                -- Start transaction
                BEGIN
                    
                    -- 1. CHECK PROMOTER HAS ENOUGH PINS
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
                    
                    -- 2. GENERATE EMAIL AND PASSWORD
                    auth_email := COALESCE(p_email, p_customer_id || '@brightplanetventures.local');
                    
                    -- Generate salt and hash password
                    salt_value := gen_salt('bf');
                    hashed_password := crypt(p_password, salt_value);
                    
                    -- 3. CREATE AUTH USER
                    BEGIN
                        INSERT INTO auth.users (
                            instance_id,
                            id,
                            aud,
                            role,
                            email,
                            encrypted_password,
                            email_confirmed_at,
                            invited_at,
                            confirmation_sent_at,
                            raw_app_meta_data,
                            raw_user_meta_data,
                            created_at,
                            updated_at,
                            confirmation_token,
                            email_change,
                            email_change_token_new,
                            recovery_token
                        )
                        VALUES (
                            '00000000-0000-0000-0000-000000000000',
                            gen_random_uuid(),
                            'authenticated',
                            'authenticated',
                            auth_email,
                            hashed_password,
                            NOW(),
                            NOW(),
                            NOW(),
                            '{"provider":"email","providers":["email"]}',
                            '{}',
                            NOW(),
                            NOW(),
                            '',
                            '',
                            '',
                            ''
                        ) RETURNING id INTO auth_user_id;
                    EXCEPTION WHEN OTHERS THEN
                        RAISE EXCEPTION 'Failed to create auth user: %', SQLERRM;
                    END;
                    
                    -- 4. CREATE PROFILE (using saving_plan column)
                    new_customer_id := auth_user_id;
                    
                    INSERT INTO profiles (
                        id,
                        name,
                        email,
                        phone,
                        role,
                        customer_id,
                        state,
                        city,
                        pincode,
                        address,
                        parent_promoter_id,
                        status,
                        saving_plan,
                        created_at,
                        updated_at
                    ) VALUES (
                        new_customer_id,
                        p_name,
                        COALESCE(p_email, auth_email),
                        p_mobile,
                        'customer',
                        p_customer_id,
                        p_state,
                        p_city,
                        p_pincode,
                        p_address,
                        p_parent_promoter_id,
                        'active',
                        '₹1000 per month for 20 months',
                        NOW(),
                        NOW()
                    );
                    
                    -- 5. DEDUCT PIN FROM PROMOTER
                    UPDATE profiles 
                    SET pins = pins - 1,
                        updated_at = NOW()
                    WHERE id = p_parent_promoter_id;
                    
                    -- 6. CREATE 20-MONTH PAYMENT SCHEDULE
                    INSERT INTO customer_payments (
                        customer_id,
                        month_number,
                        payment_amount,
                        status,
                        created_at,
                        updated_at
                    )
                    SELECT 
                        new_customer_id,
                        generate_series(1, 20),
                        1000.00,
                        'pending',
                        NOW(),
                        NOW();
                    
                    -- Verify payments were created
                    SELECT COUNT(*) INTO payment_count
                    FROM customer_payments
                    WHERE customer_id = new_customer_id;
                    
                    -- Return success result
                    result := json_build_object(
                        'success', true,
                        'customer_id', new_customer_id,
                        'customer_card_no', p_customer_id,
                        'auth_user_id', auth_user_id,
                        'payment_count', payment_count,
                        'message', 'Customer created successfully with ' || payment_count || ' payment records'
                    );
                    
                    RETURN result;
                    
                EXCEPTION WHEN OTHERS THEN
                    result := json_build_object(
                        'success', false,
                        'error', SQLERRM,
                        'message', 'Failed to create customer: ' || SQLERRM
                    );
                    RETURN result;
                END;
            END;
            $$;
        `;

        console.log('🔧 Updating create_customer_final function...');
        
        const { data: functionResult, error: functionError } = await supabase.rpc('sql', { 
            query: updateFunctionSQL 
        });

        if (functionError) {
            console.log('❌ Error updating function:', functionError.message);
            return false;
        }

        console.log('✅ Function updated successfully');

        console.log('');
        console.log('🎉 INVESTMENT_PLAN COLUMN FIX APPLIED SUCCESSFULLY!');
        console.log('');
        console.log('✅ Changes made:');
        console.log('   • Ensured saving_plan column exists in profiles table');
        console.log('   • Updated create_customer_final function to use saving_plan');
        console.log('   • Fixed column mismatch between frontend and database');
        console.log('');
        console.log('💡 You can now try creating customers again!');
        
        return true;

    } catch (error) {
        console.error('❌ Critical error fixing investment_plan column:', error);
        return false;
    }
}

// Auto-execute the fix
fixInvestmentPlanColumn();
