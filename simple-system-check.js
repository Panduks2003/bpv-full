// =====================================================
// SIMPLE SYSTEM CHECK - WORKS FROM ANY PAGE
// =====================================================
// Copy and paste this in browser console

console.log('🔍 System Check - Promoter Creation Fix Status');
console.log('');

// Check 1: Are we on the right domain?
const currentUrl = window.location.href;
console.log('📍 Current URL:', currentUrl);

if (!currentUrl.includes('localhost:3000') && !currentUrl.includes('localhost:3001') && !currentUrl.includes('localhost:3002')) {
    console.log('❌ You need to be on one of your app URLs:');
    console.log('   • http://localhost:3000 (Admin Panel)');
    console.log('   • http://localhost:3001 (Promoter Panel)');
    console.log('   • http://localhost:3002 (Customer Panel)');
    console.log('');
    console.log('🎯 Go to: http://localhost:3000/admin');
    console.log('Then run this script again');
} else {
    console.log('✅ You are on the correct domain');
    
    // Check 2: Look for Supabase client in various locations
    console.log('');
    console.log('🔍 Looking for Supabase client...');
    
    let supabaseFound = false;
    let supabaseLocation = '';
    
    if (window.supabase) {
        supabaseFound = true;
        supabaseLocation = 'window.supabase';
    } else if (window.supabaseClient) {
        supabaseFound = true;
        supabaseLocation = 'window.supabaseClient';
    } else {
        // Try to find it in React components
        const reactRoot = document.querySelector('#root');
        if (reactRoot) {
            const reactFiberKey = Object.keys(reactRoot).find(key => key.startsWith('__reactFiber'));
            if (reactFiberKey) {
                console.log('🔍 Found React app, checking for Supabase in context...');
            }
        }
    }
    
    if (supabaseFound) {
        console.log('✅ Supabase client found at:', supabaseLocation);
        
        // Test basic connection
        try {
            const supabase = window.supabase || window.supabaseClient;
            console.log('🧪 Testing Supabase connection...');
            
            // Simple test query
            supabase.from('profiles').select('count', { count: 'exact', head: true }).limit(1)
                .then(({ count, error }) => {
                    if (error) {
                        console.log('❌ Supabase connection error:', error.message);
                    } else {
                        console.log('✅ Supabase connection working');
                        console.log('📊 Total profiles in database:', count);
                    }
                })
                .catch(err => {
                    console.log('❌ Connection test failed:', err.message);
                });
                
        } catch (e) {
            console.log('❌ Error testing Supabase:', e.message);
        }
        
    } else {
        console.log('❌ Supabase client not found in global scope');
        console.log('💡 This usually means:');
        console.log('   1. You\'re not on the admin page');
        console.log('   2. The React app hasn\'t loaded yet');
        console.log('   3. The app is still starting up');
    }
    
    // Check 3: Look for signs that the fix has been applied
    console.log('');
    console.log('🔍 Checking if the fix has been applied...');
    
    // Check if we can see the updated code in the page source
    const scripts = Array.from(document.querySelectorAll('script'));
    const hasAdminPromotersScript = scripts.some(script => 
        script.src && script.src.includes('AdminPromoters')
    );
    
    if (hasAdminPromotersScript) {
        console.log('✅ AdminPromoters script found in page');
    } else {
        console.log('⚠️ AdminPromoters script not found - may need to navigate to admin page');
    }
    
    // Check 4: Instructions based on current page
    console.log('');
    console.log('🎯 NEXT STEPS:');
    
    if (currentUrl.includes('/admin')) {
        console.log('✅ You are on the admin page');
        console.log('1. Hard refresh this page (Ctrl+F5 or Cmd+Shift+R)');
        console.log('2. Try creating a new promoter');
        console.log('3. Look for "🔧 Using signUp method" in console logs');
        console.log('4. Use a different email than officialpanduks06@gmail.com');
    } else {
        console.log('📍 Navigate to: http://localhost:3000/admin');
        console.log('1. Go to the admin page');
        console.log('2. Hard refresh the page');
        console.log('3. Try creating a new promoter');
    }
}

console.log('');
console.log('🔧 TROUBLESHOOTING:');
console.log('• If Supabase not found: Navigate to http://localhost:3000/admin');
console.log('• If still getting 403 errors: Hard refresh the page (Ctrl+F5)');
console.log('• If "admin.createUser" still appears: Clear browser cache');
console.log('• Success indicator: Look for "🔧 Using signUp method" in logs');

// Quick function to navigate to admin page
window.goToAdmin = function() {
    window.location.href = 'http://localhost:3000/admin';
};

console.log('');
console.log('💡 Quick function available:');
console.log('  - goToAdmin() - Navigate to admin page');
