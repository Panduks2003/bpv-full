// =====================================================
// FIX ADMIN LOGIN ACCESS - BROWSER CONSOLE SCRIPT
// =====================================================
// Run this script in browser console to fix login issues

console.log('🔧 BrightPlanet Ventures - Admin Login Fix');
console.log('Fixing login access for admin users');
console.log('');

// Function to check and fix admin login
async function fixAdminLogin() {
    try {
        console.log('🔍 Checking Supabase client...');
        
        // Get supabase client
        const supabaseModule = await import('./src/common/services/supabaseClient.js');
        const { supabase } = supabaseModule;
        
        if (!supabase) {
            throw new Error('Supabase client not found');
        }
        
        console.log('✅ Supabase client found');
        
        // Check existing admin users
        console.log('🔍 Checking existing admin users...');
        const { data: adminUsers, error: adminError } = await supabase
            .from('profiles')
            .select('id, email, name, role')
            .eq('role', 'admin');
        
        if (adminError) {
            console.error('❌ Error checking admin users:', adminError);
            return;
        }
        
        console.log('📊 Found admin users:', adminUsers?.length || 0);
        adminUsers?.forEach(user => {
            console.log(`  - ${user.email} (${user.name})`);
        });
        
        // Check if the email you're trying to use exists
        const targetEmail = 'officialpanduks06@gmail.com';
        const existingUser = adminUsers?.find(user => user.email === targetEmail);
        
        if (existingUser) {
            console.log(`✅ User ${targetEmail} exists in profiles`);
            console.log('🔧 The issue might be with the password or Supabase Auth');
            console.log('');
            console.log('📋 SOLUTIONS:');
            console.log('1. Try using the default admin account: admin@brightplanetventures.com');
            console.log('2. Reset password in Supabase Dashboard:');
            console.log('   - Go to Authentication > Users');
            console.log(`   - Find ${targetEmail}`);
            console.log('   - Click "Reset Password"');
            console.log('3. Or create a new password for this user');
        } else {
            console.log(`❌ User ${targetEmail} not found in profiles`);
            console.log('🔧 Need to create this user or use existing admin');
            console.log('');
            console.log('📋 SOLUTIONS:');
            console.log('1. Use existing admin account: admin@brightplanetventures.com');
            console.log('2. Create the missing user in Supabase Dashboard');
        }
        
        // Try the default admin account
        console.log('');
        console.log('🧪 Testing default admin account...');
        const defaultAdmin = adminUsers?.find(user => user.email === 'admin@brightplanetventures.com');
        
        if (defaultAdmin) {
            console.log('✅ Default admin account exists: admin@brightplanetventures.com');
            console.log('💡 Try logging in with:');
            console.log('   Email: admin@brightplanetventures.com');
            console.log('   Password: [Check your Supabase Dashboard or use password reset]');
        } else {
            console.log('❌ Default admin account not found');
            console.log('🔧 Need to create admin user');
        }
        
        // Provide manual creation instructions
        console.log('');
        console.log('📋 MANUAL USER CREATION:');
        console.log('1. Go to Supabase Dashboard > Authentication > Users');
        console.log('2. Click "Add User"');
        console.log('3. Enter email and password');
        console.log('4. After creating, go to SQL Editor and run:');
        console.log('');
        console.log(`INSERT INTO profiles (id, email, name, role, phone, created_at, updated_at)
VALUES (
    (SELECT id FROM auth.users WHERE email = '${targetEmail}'),
    '${targetEmail}',
    'Admin User',
    'admin',
    '9999999999',
    NOW(),
    NOW()
);`);
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        console.log('');
        console.log('📋 ALTERNATIVE SOLUTIONS:');
        console.log('1. Check if you have the correct password');
        console.log('2. Try admin@brightplanetventures.com instead');
        console.log('3. Reset password in Supabase Dashboard');
        console.log('4. Create new admin user in Supabase Dashboard');
    }
}

// Quick password reset function
async function resetPassword(email) {
    try {
        const supabaseModule = await import('./src/common/services/supabaseClient.js');
        const { supabase } = supabaseModule;
        
        console.log(`🔄 Sending password reset to ${email}...`);
        
        const { error } = await supabase.auth.resetPasswordForEmail(email);
        
        if (error) {
            console.error('❌ Password reset failed:', error.message);
        } else {
            console.log('✅ Password reset email sent!');
            console.log('📧 Check your email for reset instructions');
        }
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

// Auto-run the fix
fixAdminLogin();

// Make functions available globally
window.fixAdminLogin = fixAdminLogin;
window.resetPassword = resetPassword;

console.log('');
console.log('💡 Available functions:');
console.log('  - fixAdminLogin() - Check admin users and get solutions');
console.log('  - resetPassword("email@example.com") - Send password reset');
console.log('');
console.log('🎯 QUICK SOLUTIONS:');
console.log('1. Try: admin@brightplanetventures.com (default admin)');
console.log('2. Run: resetPassword("officialpanduks06@gmail.com")');
console.log('3. Create user manually in Supabase Dashboard');
