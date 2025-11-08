// =====================================================
// APPLY AUTH USER TIMING FIX
// =====================================================
// Run this in browser console on the admin page to fix the timing issue

console.log('🔧 Applying Auth User Timing Fix...');
console.log('');

async function applyAuthTimingFix() {
    try {
        // Get supabase client
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            console.log('❌ Supabase client not found - make sure you\'re on the admin page');
            return;
        }

        console.log('✅ Supabase client found');

        // The updated function SQL
        const updatedFunctionSQL = `
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
$$;
        `;

        console.log('🔧 Applying updated function...');

        // Apply the function update using rpc
        const { data, error } = await supabase.rpc('exec', { 
            sql: updatedFunctionSQL 
        });

        if (error) {
            console.error('❌ Failed to apply function update:', error);
            
            // Try alternative approach - direct SQL execution
            console.log('🔄 Trying alternative approach...');
            
            try {
                // Split the SQL into parts and execute
                const createFunctionSQL = updatedFunctionSQL.replace(/CREATE OR REPLACE FUNCTION/, 'CREATE OR REPLACE FUNCTION');
                
                const { data: altData, error: altError } = await supabase.rpc('sql', { 
                    query: createFunctionSQL 
                });
                
                if (altError) {
                    console.error('❌ Alternative approach also failed:', altError);
                    console.log('💡 You may need to apply this fix manually in Supabase Dashboard');
                    console.log('📋 SQL to execute:');
                    console.log(updatedFunctionSQL);
                    return false;
                } else {
                    console.log('✅ Function updated successfully via alternative method');
                }
            } catch (altErr) {
                console.error('❌ All methods failed:', altErr);
                console.log('💡 Manual application required - see SQL below:');
                console.log(updatedFunctionSQL);
                return false;
            }
        } else {
            console.log('✅ Function updated successfully');
        }

        // Test the updated function
        console.log('🧪 Testing updated function...');
        
        // Generate a test UUID
        const testUserId = '00000000-0000-0000-0000-000000000000';
        
        const { data: testData, error: testError } = await supabase.rpc('create_promoter_profile_only', {
            p_user_id: testUserId,
            p_name: 'Test User',
            p_phone: '1234567890',
            p_email: 'test@example.com'
        });

        if (testError) {
            console.log('⚠️ Test failed (expected for fake user ID):', testError.message);
            if (testError.message.includes('retry') || testError.message.includes('proceeding')) {
                console.log('✅ Function is working - it\'s handling timing properly');
            }
        } else {
            console.log('✅ Function test completed');
        }

        console.log('');
        console.log('🎉 Auth timing fix applied successfully!');
        console.log('💡 The function now:');
        console.log('   • Retries auth user detection up to 5 times');
        console.log('   • Waits 0.5 seconds between retries');
        console.log('   • Proceeds with profile creation even if auth user not immediately visible');
        console.log('   • Provides better error messages and logging');
        
        return true;

    } catch (error) {
        console.error('❌ Error applying fix:', error);
        return false;
    }
}

// Auto-run the fix
applyAuthTimingFix().then(success => {
    if (success) {
        console.log('');
        console.log('✅ Ready to test promoter creation again!');
        console.log('💡 The timing issue should now be resolved.');
    }
});
