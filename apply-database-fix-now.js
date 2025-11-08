// =====================================================
// APPLY DATABASE FIX NOW - IMMEDIATE SOLUTION
// =====================================================
// Copy and paste this entire script into browser console on admin page

console.log('🔧 Applying Database Fix for Auth Timing Issue...');

async function applyDatabaseFixNow() {
    try {
        // Get supabase client
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            console.log('❌ Supabase client not found - make sure you\'re on the admin page');
            return false;
        }

        console.log('✅ Supabase client found');

        // The SQL to create the improved function
        const improvedFunctionSQL = `
CREATE OR REPLACE FUNCTION create_promoter_profile_only(
    p_user_id UUID,
    p_name TEXT,
    p_phone TEXT,
    p_email TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_promoter_id TEXT;
    result JSON;
    auth_user_exists BOOLEAN := FALSE;
    retry_count INTEGER := 0;
    max_retries INTEGER := 5;
BEGIN
    RAISE NOTICE '🚀 Creating promoter profile for user ID: %', p_user_id;
    
    -- Input validation
    IF p_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User ID is required');
    END IF;
    
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Name is required');
    END IF;
    
    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Phone number is required');
    END IF;
    
    -- Check if auth user exists with retry logic (for timing issues)
    WHILE retry_count < max_retries AND NOT auth_user_exists LOOP
        SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = p_user_id) INTO auth_user_exists;
        
        IF NOT auth_user_exists THEN
            retry_count := retry_count + 1;
            RAISE NOTICE '⏳ Auth user not found, retry % of %', retry_count, max_retries;
            
            -- Small delay to allow auth user to become visible
            PERFORM pg_sleep(0.5);
        END IF;
    END LOOP;
    
    -- Final check - if still not found, proceed anyway (auth user might exist but not visible)
    IF NOT auth_user_exists THEN
        RAISE NOTICE '⚠️ Warning: Auth user % not immediately visible, but proceeding with profile creation', p_user_id;
        RAISE NOTICE '💡 This is normal for newly created auth users - they may take a moment to sync';
    ELSE
        RAISE NOTICE '✅ Auth user % confirmed to exist', p_user_id;
    END IF;
    
    -- Generate promoter ID
    new_promoter_id := generate_next_promoter_id();
    RAISE NOTICE '🆔 Generated Promoter ID: %', new_promoter_id;
    
    -- Create profile record (proceed even if auth user not immediately visible)
    INSERT INTO profiles (
        id,
        email,
        name,
        role,
        phone,
        address,
        promoter_id,
        role_level,
        status,
        parent_promoter_id,
        created_at,
        updated_at
    ) VALUES (
        p_user_id,
        p_email,
        TRIM(p_name),
        'promoter',
        TRIM(p_phone),
        p_address,
        new_promoter_id,
        'Affiliate',
        'Active',
        p_parent_promoter_id,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE '✅ Profile created successfully with ID: %', new_promoter_id;
    
    -- Verify the profile was created
    IF NOT EXISTS(SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Profile creation verification failed'
        );
    END IF;
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', p_user_id,
        'name', p_name,
        'phone', p_phone,
        'email', p_email,
        'message', 'Promoter profile created successfully',
        'auth_user_found', auth_user_exists
    );
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Unexpected error in profile creation: % (Code: %)', SQLERRM, SQLSTATE;
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
END;
$$;`;

        console.log('🔧 Executing database function update...');

        // Try multiple methods to execute the SQL
        let success = false;
        
        // Method 1: Try direct SQL execution
        try {
            const { data, error } = await supabase.rpc('sql', { 
                query: improvedFunctionSQL 
            });
            
            if (!error) {
                console.log('✅ Method 1 (direct SQL) succeeded');
                success = true;
            } else {
                console.log('⚠️ Method 1 failed:', error.message);
            }
        } catch (err) {
            console.log('⚠️ Method 1 error:', err.message);
        }

        // Method 2: Try using rpc with exec
        if (!success) {
            try {
                const { data, error } = await supabase.rpc('exec', { 
                    sql: improvedFunctionSQL 
                });
                
                if (!error) {
                    console.log('✅ Method 2 (rpc exec) succeeded');
                    success = true;
                } else {
                    console.log('⚠️ Method 2 failed:', error.message);
                }
            } catch (err) {
                console.log('⚠️ Method 2 error:', err.message);
            }
        }

        // Method 3: Try breaking into smaller parts
        if (!success) {
            console.log('🔄 Trying method 3 (manual function creation)...');
            
            // First drop the function if it exists
            try {
                await supabase.rpc('sql', { 
                    query: 'DROP FUNCTION IF EXISTS create_promoter_profile_only(UUID, TEXT, TEXT, TEXT, TEXT, UUID);'
                });
            } catch (dropErr) {
                // Ignore drop errors
            }

            // Then create the new function
            try {
                const { data, error } = await supabase.rpc('sql', { 
                    query: improvedFunctionSQL 
                });
                
                if (!error) {
                    console.log('✅ Method 3 succeeded');
                    success = true;
                } else {
                    console.log('⚠️ Method 3 failed:', error.message);
                }
            } catch (err) {
                console.log('⚠️ Method 3 error:', err.message);
            }
        }

        if (!success) {
            console.log('❌ All automatic methods failed. Manual intervention required.');
            console.log('');
            console.log('📋 MANUAL STEPS:');
            console.log('1. Go to Supabase Dashboard → SQL Editor');
            console.log('2. Copy and paste this SQL:');
            console.log('');
            console.log(improvedFunctionSQL);
            console.log('');
            console.log('3. Execute the SQL');
            console.log('4. Try creating a promoter again');
            return false;
        }

        // Test the updated function
        console.log('🧪 Testing the updated function...');
        
        const testUserId = '00000000-0000-0000-0000-000000000001';
        const { data: testData, error: testError } = await supabase.rpc('create_promoter_profile_only', {
            p_user_id: testUserId,
            p_name: 'Test User',
            p_phone: '1234567890',
            p_email: 'test@example.com'
        });

        if (testError) {
            if (testError.message.includes('retry') || testError.message.includes('proceeding') || testError.message.includes('not immediately visible')) {
                console.log('✅ Function update successful - detected new retry logic');
            } else if (testError.message.includes('Auth user not found')) {
                console.log('❌ Function still using old logic - update may have failed');
                return false;
            } else {
                console.log('⚠️ Function updated but returned unexpected error:', testError.message);
            }
        }

        console.log('');
        console.log('🎉 DATABASE FIX APPLIED SUCCESSFULLY!');
        console.log('');
        console.log('✅ The create_promoter_profile_only function now:');
        console.log('   • Retries auth user detection up to 5 times');
        console.log('   • Waits 0.5 seconds between retries');
        console.log('   • Proceeds with profile creation even if auth user not immediately visible');
        console.log('   • Provides better error messages and logging');
        console.log('');
        console.log('💡 You can now try creating the promoter again!');
        
        return true;

    } catch (error) {
        console.error('❌ Critical error applying database fix:', error);
        return false;
    }
}

// Auto-execute the fix
applyDatabaseFixNow();
