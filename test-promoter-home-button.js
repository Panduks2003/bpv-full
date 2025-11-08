// =====================================================
// TEST PROMOTER HOME CREATE BUTTON FIX
// =====================================================
// Run this in browser console on http://localhost:3002/promoter/home

console.log('🧪 Testing Promoter Home - Create Promoter Button Fix');
console.log('URL should be: http://localhost:3002/promoter/home');
console.log('');

// Function to test the Create Promoter button functionality
async function testCreatePromoterButton() {
    console.log('🔧 Step 1: Checking if we\'re on the correct page...');
    
    const currentUrl = window.location.href;
    if (!currentUrl.includes('/promoter/home')) {
        console.error('❌ Wrong page! Please navigate to http://localhost:3002/promoter/home');
        return false;
    }
    
    console.log('✅ On correct page:', currentUrl);
    
    // Check if Create Promoter button exists
    console.log('🔧 Step 2: Looking for Create Promoter button...');
    
    const createPromoterButtons = Array.from(document.querySelectorAll('button')).filter(btn => 
        btn.textContent.includes('Create Promoter')
    );
    
    if (createPromoterButtons.length === 0) {
        console.error('❌ Create Promoter button not found on page');
        return false;
    }
    
    console.log('✅ Found Create Promoter button(s):', createPromoterButtons.length);
    
    // Test button click functionality
    console.log('🔧 Step 3: Testing button click...');
    
    const button = createPromoterButtons[0];
    
    // Check if button has click handler
    const hasClickHandler = button.onclick || button.getAttribute('onclick');
    if (!hasClickHandler) {
        console.log('ℹ️ Button uses React event handlers (normal for React apps)');
    }
    
    // Simulate button click
    try {
        console.log('🖱️ Simulating button click...');
        button.click();
        
        // Wait a moment for modal to appear
        setTimeout(() => {
            // Check if modal appeared
            const modal = document.querySelector('[class*="fixed"][class*="inset-0"]');
            const promoterForm = document.querySelector('form');
            
            if (modal || promoterForm) {
                console.log('✅ Modal/Form appeared after button click');
                console.log('✅ Create Promoter button is working correctly!');
                
                // Check for form fields
                const nameField = document.querySelector('input[name="name"], input[placeholder*="name" i]');
                const phoneField = document.querySelector('input[name="phone"], input[placeholder*="phone" i]');
                const passwordField = document.querySelector('input[type="password"]');
                
                console.log('📋 Form fields found:');
                console.log('  - Name field:', nameField ? '✅' : '❌');
                console.log('  - Phone field:', phoneField ? '✅' : '❌');
                console.log('  - Password field:', passwordField ? '✅' : '❌');
                
                // Close modal if it has a close button
                const closeButton = document.querySelector('button[class*="close"], button[aria-label*="close" i]');
                if (closeButton) {
                    console.log('🔄 Closing modal...');
                    closeButton.click();
                }
                
                return true;
            } else {
                console.error('❌ Modal/Form did not appear after button click');
                console.log('🔍 Checking for JavaScript errors...');
                return false;
            }
        }, 1000);
        
    } catch (error) {
        console.error('❌ Error clicking button:', error);
        return false;
    }
}

// Function to test backend connectivity
async function testBackendConnectivity() {
    console.log('🔧 Step 4: Testing backend connectivity...');
    
    try {
        const response = await fetch('http://localhost:5001/api/health');
        const data = await response.json();
        
        if (data.status === 'ok') {
            console.log('✅ Backend service is running and accessible');
            return true;
        } else {
            console.error('❌ Backend service health check failed');
            return false;
        }
    } catch (error) {
        console.error('❌ Backend service not accessible:', error.message);
        console.log('⚠️ Promoter creation will fall back to direct signUp method');
        return false;
    }
}

// Function to check auth context
async function checkAuthContext() {
    console.log('🔧 Step 5: Checking auth context...');
    
    try {
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            console.error('❌ Supabase client not available');
            return false;
        }
        
        const { data: session } = await supabase.auth.getSession();
        if (session?.session?.user) {
            const user = session.session.user;
            console.log('✅ User authenticated:', user.email);
            console.log('✅ Auth context ready for promoter creation');
            return true;
        } else {
            console.error('❌ No authenticated user found');
            console.log('Please login as a promoter first');
            return false;
        }
    } catch (error) {
        console.error('❌ Error checking auth context:', error);
        return false;
    }
}

// Main test function
async function runPromoterHomeTest() {
    console.log('🚀 Starting Promoter Home Create Button Test...');
    console.log('');
    
    const results = {
        button: false,
        backend: false,
        auth: false
    };
    
    // Test auth context first
    results.auth = await checkAuthContext();
    
    // Test backend connectivity
    results.backend = await testBackendConnectivity();
    
    // Test button functionality
    results.button = await testCreatePromoterButton();
    
    console.log('');
    console.log('📊 TEST RESULTS:');
    console.log('='.repeat(40));
    console.log(`Auth Context: ${results.auth ? '✅ PASS' : '❌ FAIL'}`);
    console.log(`Backend Service: ${results.backend ? '✅ PASS' : '⚠️ FALLBACK'}`);
    console.log(`Create Button: ${results.button ? '✅ PASS' : '❌ FAIL'}`);
    console.log('='.repeat(40));
    
    if (results.auth && results.button) {
        console.log('🎉 CREATE PROMOTER BUTTON IS WORKING!');
        console.log('');
        console.log('✅ You can now create promoters from the promoter home page');
        console.log('✅ Backend service provides optimal experience');
        console.log('✅ Fallback method available if backend unavailable');
        console.log('');
        console.log('🚀 Try clicking "Create Promoter" button to test it live!');
    } else {
        console.log('⚠️ Some issues detected:');
        if (!results.auth) {
            console.log('  - Please login as a promoter first');
        }
        if (!results.button) {
            console.log('  - Create Promoter button may have issues');
        }
        console.log('');
        console.log('🔧 Please check the issues above and try again');
    }
    
    return results;
}

// Export for manual testing
window.testPromoterHomeButton = runPromoterHomeTest;

// Auto-run the test
console.log('🔄 Auto-running test...');
runPromoterHomeTest();
