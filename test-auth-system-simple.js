// =====================================================
// SIMPLE AUTH SYSTEM TEST - BROWSER CONSOLE
// =====================================================
// Run this in browser console (works with existing supabase client)

console.log('🔧 Testing Promoter Authentication System');
console.log('');

// Simple test function that uses the global supabase client
async function testAuthSystemSimple() {
    try {
        // Try to get supabase from window or global scope
        let supabase;
        
        // Check various possible locations for supabase client
        if (window.supabase) {
            supabase = window.supabase;
            console.log('✅ Found supabase in window');
        } else if (window.supabaseClient) {
            supabase = window.supabaseClient;
            console.log('✅ Found supabaseClient in window');
        } else {
            // Try to get it from the React app context
            const reactFiberKey = Object.keys(document.querySelector('#root')).find(key => key.startsWith('__reactFiber'));
            if (reactFiberKey) {
                console.log('🔍 Trying to get supabase from React context...');
            }
            
            console.log('❌ Supabase client not found in global scope');
            console.log('💡 Please run this from your application page (not a separate tab)');
            console.log('');
            console.log('📋 ALTERNATIVE: Manual SQL execution required');
            console.log('1. Go to Supabase Dashboard > SQL Editor');
            console.log('2. Execute the SQL from: database/fix-promoter-auth-system.sql');
            console.log('3. Then test login manually');
            return;
        }
        
        console.log('🔍 Testing promoter data access...');
        
        // Test basic promoter query
        const { data: promoters, error: promotersError } = await supabase
            .from('profiles')
            .select('promoter_id, name, email, phone, status, id')
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
        
        if (!promoters || promoters.length === 0) {
            console.log('❌ No promoters found to test');
            return;
        }
        
        // Test diagnostic function if available
        console.log('');
        console.log('🧪 Testing diagnostic function...');
        
        const testPromoter = promoters[0];
        try {
            const { data: diagnostic, error: diagError } = await supabase.rpc('diagnose_promoter_auth', {
                p_promoter_id: testPromoter.promoter_id
            });
            
            if (diagError) {
                console.log('❌ Diagnostic function error:', diagError.message);
                console.log('💡 SQL fix not applied yet - go to Supabase Dashboard');
            } else {
                console.log('✅ Diagnostic function works!');
                console.log('📊 Result for', testPromoter.promoter_id + ':', diagnostic);
                
                if (diagnostic.diagnosis) {
                    console.log('🔍 Diagnosis:', diagnostic.diagnosis);
                }
            }
        } catch (e) {
            console.log('❌ Diagnostic function not available:', e.message);
            console.log('💡 Apply SQL fix first');
        }
        
        // Test all promoters if diagnostic works
        if (promoters.length > 1) {
            console.log('');
            console.log('🔍 Testing all promoters...');
            
            for (const promoter of promoters) {
                try {
                    const { data: diagnostic, error } = await supabase.rpc('diagnose_promoter_auth', {
                        p_promoter_id: promoter.promoter_id
                    });
                    
                    if (!error && diagnostic) {
                        const status = diagnostic.profile_exists && diagnostic.auth_exists ? '✅' : '❌';
                        console.log(`  ${status} ${promoter.promoter_id}: ${diagnostic.diagnosis}`);
                    }
                } catch (e) {
                    console.log(`  ❓ ${promoter.promoter_id}: Cannot test (function not available)`);
                    break; // Stop testing if function doesn't exist
                }
            }
        }
        
        console.log('');
        console.log('🎯 NEXT STEPS:');
        console.log('1. If diagnostic function not available: Apply SQL fix in Supabase Dashboard');
        console.log('2. For promoters with ❌: Run fixPromoter("PROMOTER_ID")');
        console.log('3. For promoters with ✅: Try login with ID/email/phone + password');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        console.log('');
        console.log('📋 FALLBACK STEPS:');
        console.log('1. Go to Supabase Dashboard');
        console.log('2. SQL Editor');
        console.log('3. Execute: database/fix-promoter-auth-system.sql');
        console.log('4. Try login manually');
    }
}

// Fix specific promoter function
async function fixPromoter(promoterId) {
    try {
        // Get supabase client
        let supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            console.log('❌ Supabase client not found');
            return;
        }
        
        console.log(`🔧 Attempting to fix ${promoterId}...`);
        
        // Get promoter details
        const { data: promoter, error } = await supabase
            .from('profiles')
            .select('*')
            .eq('promoter_id', promoterId)
            .single();
        
        if (error) {
            console.error('❌ Promoter not found:', error.message);
            return;
        }
        
        console.log(`✅ Found promoter: ${promoter.name} (${promoter.email})`);
        
        // Try diagnostic first
        try {
            const { data: diagnostic, error: diagError } = await supabase.rpc('diagnose_promoter_auth', {
                p_promoter_id: promoterId
            });
            
            if (!diagError && diagnostic) {
                console.log('📊 Diagnosis:', diagnostic.diagnosis);
                
                if (diagnostic.auth_exists) {
                    console.log('✅ Auth user exists - login should work');
                    console.log('💡 Try logging in with:');
                    console.log(`   • Email: ${promoter.email} + password`);
                    console.log(`   • ID: ${promoterId} + password`);
                    console.log(`   • Phone: ${promoter.phone} + password`);
                    return;
                }
            }
        } catch (e) {
            console.log('⚠️ Diagnostic function not available');
        }
        
        // Manual fix instructions
        console.log('');
        console.log('📋 MANUAL FIX REQUIRED:');
        console.log('1. Go to Supabase Dashboard > Authentication > Users');
        console.log('2. Click "Add User"');
        console.log('3. Enter:');
        console.log(`   - Email: ${promoter.email}`);
        console.log('   - Password: [Set new password]');
        console.log(`   - User ID: ${promoter.id} (in Advanced settings)`);
        console.log('4. Save user');
        console.log('5. Login with new password');
        
    } catch (error) {
        console.error('❌ Fix failed:', error.message);
    }
}

// Auto-run the test
testAuthSystemSimple();

// Make functions available globally
window.testAuthSystemSimple = testAuthSystemSimple;
window.fixPromoter = fixPromoter;

console.log('💡 Available functions:');
console.log('  - testAuthSystemSimple() - Test the auth system');
console.log('  - fixPromoter("BPVP24") - Get fix instructions for specific promoter');
console.log('');
console.log('🎯 WORKFLOW:');
console.log('1. Apply SQL fix in Supabase Dashboard first');
console.log('2. Run: testAuthSystemSimple()');
console.log('3. For broken promoters: fixPromoter("PROMOTER_ID")');
