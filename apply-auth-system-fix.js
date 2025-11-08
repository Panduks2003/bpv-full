// =====================================================
// APPLY PROMOTER AUTHENTICATION SYSTEM FIX
// =====================================================
// Run this in browser console to apply the comprehensive fix

console.log('🔧 Applying Promoter Authentication System Fix');
console.log('This will fix login issues for ALL promoters');
console.log('');

async function applyAuthSystemFix() {
    try {
        console.log('🔍 Checking Supabase client...');
        
        // Get supabase client
        const supabaseModule = await import('./src/common/services/supabaseClient.js');
        const { supabase } = supabaseModule;
        
        if (!supabase) {
            throw new Error('Supabase client not found');
        }
        
        console.log('✅ Supabase client found');
        
        // Since we can't execute raw SQL directly from frontend,
        // we'll provide instructions and test the current system
        
        console.log('');
        console.log('📋 STEP 1: Apply SQL Fix');
        console.log('1. Go to Supabase Dashboard > SQL Editor');
        console.log('2. Copy content from: database/fix-promoter-auth-system.sql');
        console.log('3. Execute the SQL script');
        console.log('4. Come back and run: testAuthSystem()');
        console.log('');
        
        // Test current promoters
        console.log('🔍 Checking existing promoters...');
        const { data: promoters, error: promotersError } = await supabase
            .from('profiles')
            .select('promoter_id, name, email, phone, status')
            .eq('role', 'promoter')
            .order('created_at', { ascending: false })
            .limit(5);
        
        if (promotersError) {
            console.error('❌ Error fetching promoters:', promotersError);
            return;
        }
        
        console.log(`📊 Found ${promoters?.length || 0} recent promoters:`);
        promoters?.forEach(promoter => {
            console.log(`  • ${promoter.promoter_id} - ${promoter.name} (${promoter.status})`);
        });
        
        // Test authentication functions
        console.log('');
        console.log('🧪 Testing authentication functions...');
        
        if (promoters && promoters.length > 0) {
            const testPromoter = promoters[0];
            console.log(`Testing with ${testPromoter.promoter_id}...`);
            
            // Test diagnostic function
            try {
                const { data: diagnostic, error: diagError } = await supabase.rpc('diagnose_promoter_auth', {
                    p_promoter_id: testPromoter.promoter_id
                });
                
                if (diagError) {
                    console.log('❌ Diagnostic function not available yet - apply SQL fix first');
                } else {
                    console.log('✅ Diagnostic result:', diagnostic);
                }
            } catch (e) {
                console.log('❌ Diagnostic function not available - apply SQL fix first');
            }
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        console.log('');
        console.log('📋 MANUAL STEPS:');
        console.log('1. Go to Supabase Dashboard');
        console.log('2. SQL Editor');
        console.log('3. Execute: database/fix-promoter-auth-system.sql');
    }
}

// Test the authentication system after applying the fix
async function testAuthSystem() {
    try {
        const supabaseModule = await import('./src/common/services/supabaseClient.js');
        const { supabase } = supabaseModule;
        
        console.log('🧪 Testing Authentication System...');
        
        // Get recent promoters
        const { data: promoters, error } = await supabase
            .from('profiles')
            .select('promoter_id, name, email, phone')
            .eq('role', 'promoter')
            .order('created_at', { ascending: false })
            .limit(3);
        
        if (error) {
            console.error('❌ Error fetching promoters:', error);
            return;
        }
        
        console.log(`Testing with ${promoters?.length || 0} promoters:`);
        
        for (const promoter of promoters || []) {
            console.log(`\n🔍 Testing ${promoter.promoter_id} (${promoter.name}):`);
            
            // Test diagnostic function
            try {
                const { data: diagnostic, error: diagError } = await supabase.rpc('diagnose_promoter_auth', {
                    p_promoter_id: promoter.promoter_id
                });
                
                if (diagError) {
                    console.log('  ❌ Diagnostic failed:', diagError.message);
                } else {
                    console.log('  📊 Diagnosis:', diagnostic.diagnosis);
                    if (diagnostic.profile_exists && diagnostic.auth_exists) {
                        console.log('  ✅ Ready for login');
                    } else if (diagnostic.profile_exists && !diagnostic.auth_exists) {
                        console.log('  ⚠️ Missing auth user - needs manual fix');
                    } else {
                        console.log('  ❌ Profile issues detected');
                    }
                }
            } catch (e) {
                console.log('  ❌ Diagnostic function not available');
            }
        }
        
        console.log('');
        console.log('🎯 NEXT STEPS:');
        console.log('1. For promoters with "Missing auth user":');
        console.log('   - Go to Supabase Dashboard > Authentication > Users');
        console.log('   - Add user with the promoter\'s email');
        console.log('   - Use the profile ID as the user ID');
        console.log('2. For promoters marked "Ready for login":');
        console.log('   - Try logging in with promoter ID/phone/email + password');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
    }
}

// Quick fix for specific promoter
async function fixSpecificPromoter(promoterId) {
    try {
        const supabaseModule = await import('./src/common/services/supabaseClient.js');
        const { supabase } = supabaseModule;
        
        console.log(`🔧 Fixing ${promoterId}...`);
        
        // Get promoter details
        const { data: promoter, error } = await supabase
            .from('profiles')
            .select('*')
            .eq('promoter_id', promoterId)
            .single();
        
        if (error) {
            console.error('❌ Promoter not found:', error);
            return;
        }
        
        console.log(`✅ Found promoter: ${promoter.name} (${promoter.email})`);
        
        // Check if auth user exists
        const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();
        
        if (authError) {
            console.log('❌ Cannot check auth users - need admin privileges');
            console.log('💡 Manual fix required in Supabase Dashboard');
            return;
        }
        
        const authUser = authUsers.users.find(user => user.id === promoter.id);
        
        if (authUser) {
            console.log('✅ Auth user exists - login should work');
        } else {
            console.log('❌ Auth user missing - creating...');
            
            try {
                const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
                    email: promoter.email,
                    password: 'TempPass123!',
                    email_confirm: true,
                    user_metadata: {
                        name: promoter.name,
                        phone: promoter.phone,
                        promoter_id: promoter.promoter_id
                    }
                });
                
                if (createError) {
                    console.error('❌ Failed to create auth user:', createError);
                } else {
                    console.log('✅ Auth user created successfully!');
                    console.log('🔑 Temporary password: TempPass123!');
                    console.log(`📧 Login with: ${promoter.email} + TempPass123!`);
                    console.log(`🆔 Or with: ${promoterId} + TempPass123!`);
                }
            } catch (createError) {
                console.error('❌ Auth user creation failed:', createError);
            }
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

// Auto-run the fix
applyAuthSystemFix();

// Make functions available globally
window.applyAuthSystemFix = applyAuthSystemFix;
window.testAuthSystem = testAuthSystem;
window.fixSpecificPromoter = fixSpecificPromoter;

console.log('');
console.log('💡 Available functions:');
console.log('  - applyAuthSystemFix() - Apply the comprehensive fix');
console.log('  - testAuthSystem() - Test after applying SQL fix');
console.log('  - fixSpecificPromoter("BPVP24") - Fix a specific promoter');
console.log('');
console.log('🎯 RECOMMENDED WORKFLOW:');
console.log('1. Apply SQL fix in Supabase Dashboard');
console.log('2. Run: testAuthSystem()');
console.log('3. For broken promoters: fixSpecificPromoter("PROMOTER_ID")');
