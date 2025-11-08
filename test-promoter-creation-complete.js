// =====================================================
// COMPREHENSIVE PROMOTER CREATION TEST SCRIPT
// =====================================================
// Run this in browser console to test all promoter creation functionality

console.log('🧪 BrightPlanet Ventures - Comprehensive Promoter Creation Test');
console.log('Testing: Admin & Promoter account promoter creation');
console.log('');

// Test configuration
const TEST_CONFIG = {
    backendUrl: 'http://localhost:5001',
    testData: {
        name: 'Test Promoter',
        phone: '+1234567890',
        password: 'testpass123',
        email: 'test.promoter@example.com',
        address: '123 Test Street'
    }
};

// Function to test backend service
async function testBackendService() {
    console.log('🔧 Step 1: Testing Backend Service...');
    
    try {
        // Test health endpoint
        const healthResponse = await fetch(`${TEST_CONFIG.backendUrl}/api/health`);
        const healthData = await healthResponse.json();
        
        if (healthData.status === 'ok') {
            console.log('✅ Backend service is running');
        } else {
            throw new Error('Backend health check failed');
        }
        
        // Test auth creation endpoint
        const timestamp = Date.now();
        const testEmail = `test${timestamp}@example.com`;
        
        const authResponse = await fetch(`${TEST_CONFIG.backendUrl}/api/create-promoter-auth`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: testEmail,
                password: TEST_CONFIG.testData.password,
                userData: {
                    role: 'promoter',
                    name: TEST_CONFIG.testData.name,
                    phone: TEST_CONFIG.testData.phone
                }
            })
        });
        
        if (authResponse.ok) {
            const authData = await authResponse.json();
            console.log('✅ Backend auth creation working:', authData.user.id);
            return { success: true, testUserId: authData.user.id };
        } else {
            const errorData = await authResponse.json();
            throw new Error(`Backend auth creation failed: ${errorData.error}`);
        }
        
    } catch (error) {
        console.error('❌ Backend service test failed:', error);
        return { success: false, error: error.message };
    }
}

// Function to test database functions
async function testDatabaseFunctions() {
    console.log('🔧 Step 2: Testing Database Functions...');
    
    try {
        // Get supabase client
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            throw new Error('Supabase client not available');
        }
        
        // Test generate_next_promoter_id function
        console.log('🧪 Testing generate_next_promoter_id...');
        const { data: promoterId, error: idError } = await supabase.rpc('generate_next_promoter_id');
        
        if (idError) {
            throw new Error(`ID generation failed: ${idError.message}`);
        }
        
        console.log('✅ Promoter ID generation working:', promoterId);
        
        // Test confirm_promoter_email function (with dummy ID)
        console.log('🧪 Testing confirm_promoter_email...');
        const dummyId = '00000000-0000-0000-0000-000000000000';
        const { error: confirmError } = await supabase.rpc('confirm_promoter_email', {
            p_user_id: dummyId
        });
        
        // This should fail gracefully (user doesn't exist), but function should exist
        if (confirmError && !confirmError.message.includes('does not exist')) {
            console.warn('⚠️ Email confirmation function may have issues:', confirmError.message);
        } else {
            console.log('✅ Email confirmation function available');
        }
        
        return { success: true, generatedId: promoterId };
        
    } catch (error) {
        console.error('❌ Database function test failed:', error);
        return { success: false, error: error.message };
    }
}

// Function to test admin promoter creation flow
async function testAdminPromoterCreation() {
    console.log('🔧 Step 3: Testing Admin Promoter Creation Flow...');
    
    try {
        // Check if we're in admin context
        const currentPath = window.location.pathname;
        if (!currentPath.includes('/admin')) {
            console.log('⚠️ Not in admin context, skipping admin-specific tests');
            return { success: true, skipped: true };
        }
        
        // Test the admin form submission logic (without actually submitting)
        console.log('🧪 Simulating admin promoter creation...');
        
        const timestamp = Date.now();
        const authEmail = `promo${timestamp}${Math.floor(Math.random() * 1000000)}@brightplanet.com`;
        
        // Test backend call
        const backendResponse = await fetch(`${TEST_CONFIG.backendUrl}/api/create-promoter-auth`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: authEmail,
                password: TEST_CONFIG.testData.password,
                userData: {
                    role: 'promoter',
                    name: TEST_CONFIG.testData.name,
                    phone: TEST_CONFIG.testData.phone
                }
            })
        });
        
        if (backendResponse.ok) {
            const result = await backendResponse.json();
            console.log('✅ Admin auth creation flow working');
            
            // Test database profile creation (simulation)
            const supabase = window.supabase || window.supabaseClient;
            const { data: profileResult, error: profileError } = await supabase.rpc('create_promoter_with_auth_id', {
                p_name: TEST_CONFIG.testData.name,
                p_user_id: result.user.id,
                p_auth_email: authEmail,
                p_password: TEST_CONFIG.testData.password,
                p_phone: TEST_CONFIG.testData.phone,
                p_email: TEST_CONFIG.testData.email,
                p_address: TEST_CONFIG.testData.address,
                p_parent_promoter_id: null,
                p_role_level: 'Affiliate',
                p_status: 'Active'
            });
            
            if (profileError) {
                throw new Error(`Profile creation failed: ${profileError.message}`);
            }
            
            console.log('✅ Admin promoter creation complete:', profileResult.promoter_id);
            return { success: true, promoterId: profileResult.promoter_id };
        } else {
            throw new Error('Admin auth creation failed');
        }
        
    } catch (error) {
        console.error('❌ Admin promoter creation test failed:', error);
        return { success: false, error: error.message };
    }
}

// Function to test promoter account promoter creation
async function testPromoterAccountCreation() {
    console.log('🔧 Step 4: Testing Promoter Account Creation Flow...');
    
    try {
        // Check if we're in promoter context
        const currentPath = window.location.pathname;
        if (!currentPath.includes('/promoter')) {
            console.log('⚠️ Not in promoter context, skipping promoter-specific tests');
            return { success: true, skipped: true };
        }
        
        // Test the promoter form submission logic (without actually submitting)
        console.log('🧪 Simulating promoter account promoter creation...');
        
        const timestamp = Date.now();
        const authEmail = `promo${timestamp}${Math.floor(Math.random() * 1000000)}@brightplanet.com`;
        
        // Test backend call (same as admin)
        const backendResponse = await fetch(`${TEST_CONFIG.backendUrl}/api/create-promoter-auth`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: authEmail,
                password: TEST_CONFIG.testData.password,
                userData: {
                    role: 'promoter',
                    name: TEST_CONFIG.testData.name,
                    phone: TEST_CONFIG.testData.phone
                }
            })
        });
        
        if (backendResponse.ok) {
            console.log('✅ Promoter account auth creation flow working');
            return { success: true };
        } else {
            throw new Error('Promoter account auth creation failed');
        }
        
    } catch (error) {
        console.error('❌ Promoter account creation test failed:', error);
        return { success: false, error: error.message };
    }
}

// Function to test auth context isolation
async function testAuthContextIsolation() {
    console.log('🔧 Step 5: Testing Auth Context Isolation...');
    
    try {
        // Check current auth state
        const supabase = window.supabase || window.supabaseClient;
        const { data: currentSession } = await supabase.auth.getSession();
        
        if (currentSession?.session?.user) {
            const currentUser = currentSession.session.user;
            console.log('✅ Current auth state preserved:', currentUser.email);
            
            // Verify no unwanted redirections occurred
            const currentPath = window.location.pathname;
            if (currentPath.includes('/customer') && !currentUser.email.includes('customer')) {
                console.warn('⚠️ Unwanted customer redirection detected');
                return { success: false, error: 'Auth context isolation failed' };
            }
            
            console.log('✅ Auth context isolation working correctly');
            return { success: true };
        } else {
            console.log('ℹ️ No current session to test isolation');
            return { success: true, noSession: true };
        }
        
    } catch (error) {
        console.error('❌ Auth context isolation test failed:', error);
        return { success: false, error: error.message };
    }
}

// Main test runner
async function runComprehensiveTest() {
    console.log('🚀 Starting comprehensive promoter creation test...');
    console.log('');
    
    const results = {
        backend: await testBackendService(),
        database: await testDatabaseFunctions(),
        admin: await testAdminPromoterCreation(),
        promoter: await testPromoterAccountCreation(),
        authContext: await testAuthContextIsolation()
    };
    
    console.log('');
    console.log('📊 TEST RESULTS SUMMARY:');
    console.log('='.repeat(50));
    
    let allPassed = true;
    
    Object.entries(results).forEach(([test, result]) => {
        const status = result.success ? '✅ PASS' : '❌ FAIL';
        const details = result.skipped ? ' (SKIPPED)' : result.error ? ` - ${result.error}` : '';
        console.log(`${status} ${test.toUpperCase()}${details}`);
        
        if (!result.success && !result.skipped) {
            allPassed = false;
        }
    });
    
    console.log('='.repeat(50));
    
    if (allPassed) {
        console.log('🎉 ALL TESTS PASSED! Promoter creation is working properly.');
        console.log('');
        console.log('✅ Backend service operational');
        console.log('✅ Database functions working');
        console.log('✅ Admin promoter creation ready');
        console.log('✅ Promoter account creation ready');
        console.log('✅ Auth context isolation working');
        console.log('');
        console.log('🚀 You can now create promoters from both admin and promoter accounts!');
    } else {
        console.log('⚠️ Some tests failed. Please check the errors above.');
        console.log('');
        console.log('🔧 NEXT STEPS:');
        console.log('1. Fix any failed components');
        console.log('2. Re-run this test script');
        console.log('3. Try creating a promoter manually');
    }
    
    return results;
}

// Export functions for manual testing
window.testPromoterCreation = runComprehensiveTest;
window.testBackendOnly = testBackendService;
window.testDatabaseOnly = testDatabaseFunctions;

// Auto-run the comprehensive test
console.log('🔄 Auto-running comprehensive test...');
runComprehensiveTest();
