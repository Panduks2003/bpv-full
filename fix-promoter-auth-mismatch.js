// =====================================================
// FIX PROMOTER AUTHENTICATION MISMATCH
// =====================================================
// Run this in browser console to fix BPVP24 authentication

console.log('🔧 Fixing BPVP24 Authentication Mismatch');
console.log('');

async function fixPromoterAuth() {
    try {
        console.log('🔍 Checking Supabase client...');
        
        // Get supabase client
        const supabaseModule = await import('./src/common/services/supabaseClient.js');
        const { supabase } = supabaseModule;
        
        if (!supabase) {
            throw new Error('Supabase client not found');
        }
        
        console.log('✅ Supabase client found');
        
        // Check if BPVP24 exists in profiles
        console.log('🔍 Checking BPVP24 profile...');
        const { data: promoterProfile, error: profileError } = await supabase
            .from('profiles')
            .select('*')
            .eq('promoter_id', 'BPVP24')
            .single();
        
        if (profileError) {
            console.error('❌ Error finding BPVP24 profile:', profileError);
            return;
        }
        
        if (!promoterProfile) {
            console.error('❌ BPVP24 profile not found');
            return;
        }
        
        console.log('✅ Found BPVP24 profile:', promoterProfile.name, promoterProfile.email);
        
        // Check if auth user exists
        console.log('🔍 Checking auth user...');
        const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();
        
        if (authError) {
            console.error('❌ Cannot check auth users:', authError);
            console.log('💡 You need admin privileges to check auth users');
        } else {
            const authUser = authUsers.users.find(user => user.id === promoterProfile.id);
            if (authUser) {
                console.log('✅ Auth user exists for BPVP24');
                console.log('🔧 The issue might be password verification');
            } else {
                console.log('❌ No auth user found for BPVP24');
                console.log('🔧 Need to create auth user');
            }
        }
        
        // Provide solutions
        console.log('');
        console.log('📋 SOLUTIONS:');
        console.log('');
        console.log('OPTION 1: Create Auth User in Supabase Dashboard');
        console.log('1. Go to Supabase Dashboard > Authentication > Users');
        console.log('2. Click "Add User"');
        console.log('3. Enter:');
        console.log(`   - Email: ${promoterProfile.email}`);
        console.log('   - Password: [Set a new password]');
        console.log(`   - User ID: ${promoterProfile.id} (Advanced settings)`);
        console.log('4. Save the user');
        console.log('5. Try logging in with the new password');
        console.log('');
        
        console.log('OPTION 2: Delete and Recreate Promoter');
        console.log('1. Delete BPVP24 from admin panel');
        console.log('2. Create again with proper email/password');
        console.log('');
        
        console.log('OPTION 3: Use Email Login Instead');
        console.log('1. Go to Supabase Dashboard > Authentication > Users');
        console.log(`2. Find user with email: ${promoterProfile.email}`);
        console.log('3. Reset password if needed');
        console.log('4. Login using email instead of promoter ID');
        console.log('');
        
        // Try to create the missing auth user programmatically
        console.log('🔄 Attempting to create auth user...');
        try {
            const { data: newAuthUser, error: createError } = await supabase.auth.admin.createUser({
                email: promoterProfile.email,
                password: 'TempPass123!', // Temporary password
                email_confirm: true,
                user_metadata: {
                    name: promoterProfile.name,
                    phone: promoterProfile.phone,
                    promoter_id: promoterProfile.promoter_id
                }
            });
            
            if (createError) {
                console.error('❌ Cannot create auth user programmatically:', createError.message);
                console.log('💡 Use manual method in Supabase Dashboard');
            } else {
                console.log('✅ Auth user created successfully!');
                console.log('🔑 Temporary password: TempPass123!');
                console.log('📧 Email:', promoterProfile.email);
                console.log('🆔 Promoter ID: BPVP24');
                console.log('');
                console.log('🎯 You can now login with:');
                console.log('   - Email + TempPass123!');
                console.log('   - BPVP24 + TempPass123!');
                console.log('   - Phone + TempPass123!');
            }
        } catch (authCreateError) {
            console.error('❌ Auth user creation failed:', authCreateError.message);
            console.log('💡 Use manual method in Supabase Dashboard');
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        console.log('');
        console.log('📋 MANUAL FIX:');
        console.log('1. Go to Supabase Dashboard');
        console.log('2. Authentication > Users');
        console.log('3. Add user with email: officialpanduks06@gmail.com');
        console.log('4. Set a password');
        console.log('5. Login with email + password');
    }
}

// Quick delete and recreate function
async function deleteAndRecreatePromoter() {
    try {
        const supabaseModule = await import('./src/common/services/supabaseClient.js');
        const { supabase } = supabaseModule;
        
        console.log('🗑️ Deleting BPVP24 profile...');
        
        const { error: deleteError } = await supabase
            .from('profiles')
            .delete()
            .eq('promoter_id', 'BPVP24');
        
        if (deleteError) {
            console.error('❌ Delete failed:', deleteError);
        } else {
            console.log('✅ BPVP24 deleted successfully');
            console.log('💡 Now recreate the promoter from admin panel with proper credentials');
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

// Auto-run the fix
fixPromoterAuth();

// Make functions available globally
window.fixPromoterAuth = fixPromoterAuth;
window.deleteAndRecreatePromoter = deleteAndRecreatePromoter;

console.log('');
console.log('💡 Available functions:');
console.log('  - fixPromoterAuth() - Diagnose and fix auth issues');
console.log('  - deleteAndRecreatePromoter() - Delete BPVP24 and recreate');
console.log('');
console.log('🎯 RECOMMENDED: Use Supabase Dashboard to create auth user manually');
