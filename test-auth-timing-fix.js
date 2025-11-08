// =====================================================
// TEST AUTH TIMING FIX
// =====================================================
// Run this in browser console on the admin page to test the fix

console.log('🧪 Testing Auth User Timing Fix...');
console.log('');

async function testAuthTimingFix() {
    try {
        // Get supabase client
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            console.log('❌ Supabase client not found - make sure you\'re on the admin page');
            return;
        }

        console.log('✅ Supabase client found');
        console.log('');

        // Test 1: Check if the updated function exists
        console.log('🔍 Test 1: Checking if updated function exists...');
        
        try {
            // Try to call the function with a test (invalid) user ID
            const testUserId = '00000000-0000-0000-0000-000000000001';
            const { data, error } = await supabase.rpc('create_promoter_profile_only', {
                p_user_id: testUserId,
                p_name: 'Test User',
                p_phone: '1234567890',
                p_email: 'test@example.com'
            });

            if (error) {
                if (error.message.includes('retry') || error.message.includes('proceeding') || error.message.includes('not immediately visible')) {
                    console.log('✅ Updated function is working - detected retry/timing logic');
                } else if (error.message.includes('Auth user not found')) {
                    console.log('❌ Old function still active - needs database update');
                    console.log('💡 Run the apply-auth-timing-fix.js script first');
                    return false;
                } else {
                    console.log('⚠️ Function exists but returned different error:', error.message);
                }
            } else {
                console.log('⚠️ Function call succeeded (unexpected with fake user ID)');
            }
        } catch (err) {
            console.log('❌ Function test failed:', err.message);
            return false;
        }

        console.log('');

        // Test 2: Create a real test promoter to verify end-to-end flow
        console.log('🔍 Test 2: Creating real test promoter...');
        
        const testEmail = `test-${Date.now()}@example.com`;
        const testPassword = 'TestPassword123!';
        
        console.log(`📧 Creating test promoter: ${testEmail}`);
        
        try {
            // Step 1: Create auth user
            console.log('🔧 Step 1: Creating auth user...');
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email: testEmail,
                password: testPassword,
                options: {
                    emailRedirectTo: undefined,
                    data: {
                        name: 'Test Promoter',
                        phone: '9876543210',
                        role: 'promoter'
                    }
                }
            });

            if (authError) {
                console.log('❌ Auth user creation failed:', authError.message);
                return false;
            }

            if (!authData?.user) {
                console.log('❌ No auth user data returned');
                return false;
            }

            const authUserId = authData.user.id;
            console.log('✅ Auth user created:', authUserId);

            // Step 2: Wait and create profile (test the timing fix)
            console.log('⏳ Step 2: Waiting 1 second then creating profile...');
            await new Promise(resolve => setTimeout(resolve, 1000));

            const { data: profileData, error: profileError } = await supabase.rpc('create_promoter_profile_only', {
                p_user_id: authUserId,
                p_name: 'Test Promoter',
                p_phone: '9876543210',
                p_email: testEmail,
                p_address: 'Test Address'
            });

            if (profileError) {
                console.log('❌ Profile creation failed:', profileError.message);
                
                // Clean up auth user
                try {
                    await supabase.auth.admin.deleteUser(authUserId);
                    console.log('🧹 Cleaned up test auth user');
                } catch (cleanupErr) {
                    console.log('⚠️ Could not clean up auth user (admin privileges needed)');
                }
                
                return false;
            }

            if (!profileData?.success) {
                console.log('❌ Profile function returned failure:', profileData);
                return false;
            }

            console.log('✅ Profile created successfully:', profileData.promoter_id);

            // Step 3: Verify the promoter exists
            console.log('🔍 Step 3: Verifying promoter exists in database...');
            
            const { data: verifyData, error: verifyError } = await supabase
                .from('profiles')
                .select('promoter_id, name, email, phone, id')
                .eq('promoter_id', profileData.promoter_id)
                .single();

            if (verifyError || !verifyData) {
                console.log('❌ Profile verification failed:', verifyError?.message);
                return false;
            }

            console.log('✅ Profile verified in database:', verifyData);

            // Step 4: Test diagnostic function
            console.log('🔍 Step 4: Testing diagnostic function...');
            
            try {
                const { data: diagnostic, error: diagError } = await supabase.rpc('diagnose_promoter_auth', {
                    p_promoter_id: profileData.promoter_id
                });

                if (diagError) {
                    console.log('⚠️ Diagnostic function not available:', diagError.message);
                } else {
                    console.log('✅ Diagnostic result:', diagnostic);
                }
            } catch (diagErr) {
                console.log('⚠️ Diagnostic function error:', diagErr.message);
            }

            // Step 5: Clean up test data
            console.log('🧹 Step 5: Cleaning up test data...');
            
            try {
                // Delete profile
                const { error: deleteError } = await supabase
                    .from('profiles')
                    .delete()
                    .eq('promoter_id', profileData.promoter_id);

                if (deleteError) {
                    console.log('⚠️ Could not delete test profile:', deleteError.message);
                } else {
                    console.log('✅ Test profile deleted');
                }

                // Delete auth user (requires admin privileges)
                try {
                    await supabase.auth.admin.deleteUser(authUserId);
                    console.log('✅ Test auth user deleted');
                } catch (authDeleteErr) {
                    console.log('⚠️ Could not delete test auth user (admin privileges needed)');
                }

            } catch (cleanupErr) {
                console.log('⚠️ Cleanup error:', cleanupErr.message);
            }

            console.log('');
            console.log('🎉 All tests passed! The auth timing fix is working correctly.');
            return true;

        } catch (testErr) {
            console.log('❌ Test failed:', testErr.message);
            return false;
        }

    } catch (error) {
        console.error('❌ Test error:', error);
        return false;
    }
}

// Auto-run the test
testAuthTimingFix().then(success => {
    console.log('');
    if (success) {
        console.log('✅ AUTH TIMING FIX VERIFICATION COMPLETE');
        console.log('💡 You can now create promoters without timing issues!');
    } else {
        console.log('❌ AUTH TIMING FIX VERIFICATION FAILED');
        console.log('💡 Check the errors above and ensure:');
        console.log('   1. The database fix was applied (run apply-auth-timing-fix.js)');
        console.log('   2. The frontend code has been updated');
        console.log('   3. You have the necessary permissions');
    }
});
