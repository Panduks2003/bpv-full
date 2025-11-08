// =====================================================
// FIX BPVP24 AUTH USER - BROWSER CONSOLE
// =====================================================
// Run this in browser console to fix BPVP24 specifically

console.log('🔧 Fixing BPVP24 Authentication');
console.log('');

async function fixBPVP24() {
    try {
        // Get supabase client
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            console.log('❌ Supabase client not found');
            return;
        }
        
        console.log('✅ Supabase client found');
        
        // BPVP24 details from diagnostic
        const promoterData = {
            id: "77f21f45-4c2e-4890-954b-1e7b4b38a6ad",
            name: "Pandu Shirabu", 
            email: "officialpanduks06@gmail.com",
            phone: "7411195267",
            promoter_id: "BPVP24"
        };
        
        console.log('🔧 Creating auth user for BPVP24...');
        console.log('📧 Email:', promoterData.email);
        console.log('🆔 User ID:', promoterData.id);
        
        // Try to create the auth user with the specific ID
        try {
            const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
                email: promoterData.email,
                password: 'BPVP24Pass!', // Temporary password
                email_confirm: true,
                user_id: promoterData.id, // Use the existing profile ID
                user_metadata: {
                    name: promoterData.name,
                    phone: promoterData.phone,
                    promoter_id: promoterData.promoter_id
                }
            });
            
            if (createError) {
                console.error('❌ Auth user creation failed:', createError.message);
                
                // Provide manual instructions
                console.log('');
                console.log('📋 MANUAL FIX REQUIRED:');
                console.log('1. Go to Supabase Dashboard > Authentication > Users');
                console.log('2. Click "Add User"');
                console.log('3. Enter:');
                console.log(`   - Email: ${promoterData.email}`);
                console.log('   - Password: BPVP24Pass! (or your choice)');
                console.log('   - Click "Advanced Settings"');
                console.log(`   - User ID: ${promoterData.id}`);
                console.log('4. Click "Create User"');
                console.log('5. Try logging in with BPVP24 + BPVP24Pass!');
                
            } else {
                console.log('✅ Auth user created successfully!');
                console.log('🎉 BPVP24 is now ready for login!');
                console.log('');
                console.log('🔑 LOGIN CREDENTIALS:');
                console.log('   • Email: officialpanduks06@gmail.com + BPVP24Pass!');
                console.log('   • Promoter ID: BPVP24 + BPVP24Pass!');
                console.log('   • Phone: 7411195267 + BPVP24Pass!');
                console.log('');
                console.log('🌐 LOGIN URLS:');
                console.log('   • http://localhost:3001/login (Promoter Panel)');
                console.log('   • http://localhost:3001/promoter (Direct to dashboard)');
                
                // Test the fix
                console.log('');
                console.log('🧪 Verifying fix...');
                
                const { data: diagnostic, error: diagError } = await supabase.rpc('diagnose_promoter_auth', {
                    p_promoter_id: 'BPVP24'
                });
                
                if (!diagError && diagnostic) {
                    console.log('📊 New diagnosis:', diagnostic.diagnosis);
                    if (diagnostic.auth_exists) {
                        console.log('✅ Fix confirmed - auth user now exists!');
                    }
                } else {
                    console.log('⚠️ Could not verify fix, but auth user should be created');
                }
            }
            
        } catch (authError) {
            console.error('❌ Auth creation error:', authError.message);
            
            // Fallback instructions
            console.log('');
            console.log('📋 FALLBACK - Manual Creation Required:');
            console.log('Since automatic creation failed, please:');
            console.log('');
            console.log('1. Go to: https://supabase.com/dashboard');
            console.log('2. Select your project');
            console.log('3. Go to Authentication > Users');
            console.log('4. Click "Add User"');
            console.log('5. Fill in:');
            console.log(`   - Email: ${promoterData.email}`);
            console.log('   - Password: BPVP24Pass! (or your choice)');
            console.log('6. Click "Advanced Settings" and enter:');
            console.log(`   - User ID: ${promoterData.id}`);
            console.log('7. Click "Create User"');
            console.log('');
            console.log('Then try logging in with:');
            console.log('   BPVP24 + your_password');
        }
        
    } catch (error) {
        console.error('❌ Fix failed:', error.message);
        console.log('');
        console.log('📋 MANUAL STEPS REQUIRED:');
        console.log('Go to Supabase Dashboard and manually create auth user');
    }
}

// Test login after fix
async function testBPVP24Login() {
    try {
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            console.log('❌ Supabase client not found');
            return;
        }
        
        console.log('🧪 Testing BPVP24 login...');
        
        // Test with promoter ID
        try {
            const { data, error } = await supabase.rpc('authenticate_promoter_by_id', {
                p_promoter_id: 'BPVP24',
                p_password: 'BPVP24Pass!'
            });
            
            if (error) {
                console.log('❌ Login test failed:', error.message);
                console.log('💡 Try with the actual password you set');
            } else {
                console.log('✅ Login test successful!');
                console.log('🎉 BPVP24 can now login successfully');
            }
        } catch (e) {
            console.log('❌ Login function not available or password incorrect');
            console.log('💡 Try manual login on the promoter panel');
        }
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
    }
}

// Auto-run the fix
fixBPVP24();

// Make functions available
window.fixBPVP24 = fixBPVP24;
window.testBPVP24Login = testBPVP24Login;

console.log('');
console.log('💡 Available functions:');
console.log('  - fixBPVP24() - Fix BPVP24 auth user');
console.log('  - testBPVP24Login() - Test login after fix');
console.log('');
console.log('🎯 After running this:');
console.log('1. Go to http://localhost:3001/login');
console.log('2. Login with: BPVP24 + BPVP24Pass!');
console.log('3. Or use: officialpanduks06@gmail.com + BPVP24Pass!');
