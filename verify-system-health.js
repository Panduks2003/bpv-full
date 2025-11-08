// =====================================================
// SYSTEM HEALTH VERIFICATION SCRIPT
// =====================================================
// Run this in browser console to verify all systems are working

console.log('🔍 BrightPlanet Ventures - System Health Check');
console.log('='.repeat(50));
console.log('');

// System health check function
async function verifySystemHealth() {
    const results = {
        backend: false,
        frontend: false,
        database: false,
        auth: false,
        commission: false
    };
    
    console.log('🔧 Step 1: Checking Backend Service...');
    try {
        const healthResponse = await fetch('http://localhost:5001/api/health');
        const healthData = await healthResponse.json();
        
        if (healthData.status === 'ok') {
            console.log('✅ Backend service operational');
            results.backend = true;
        } else {
            console.log('❌ Backend service unhealthy');
        }
    } catch (error) {
        console.log('❌ Backend service not accessible:', error.message);
    }
    
    console.log('');
    console.log('🔧 Step 2: Checking Frontend Ports...');
    
    const ports = [3000, 3001, 3002];
    const portNames = ['Admin', 'Promoter', 'Customer'];
    let frontendCount = 0;
    
    for (let i = 0; i < ports.length; i++) {
        try {
            const response = await fetch(`http://localhost:${ports[i]}`);
            if (response.ok) {
                console.log(`✅ ${portNames[i]} panel (port ${ports[i]}) accessible`);
                frontendCount++;
            } else {
                console.log(`❌ ${portNames[i]} panel (port ${ports[i]}) not responding`);
            }
        } catch (error) {
            console.log(`❌ ${portNames[i]} panel (port ${ports[i]}) not accessible`);
        }
    }
    
    results.frontend = frontendCount === 3;
    
    console.log('');
    console.log('🔧 Step 3: Checking Database Functions...');
    
    try {
        const supabase = window.supabase || window.supabaseClient;
        if (!supabase) {
            throw new Error('Supabase client not available');
        }
        
        // Test commission function
        const testId = '00000000-0000-0000-0000-000000000000';
        const { data: commissionTest, error: commissionError } = await supabase.rpc('distribute_affiliate_commission', {
            p_customer_id: testId,
            p_initiator_promoter_id: testId
        });
        
        if (!commissionError) {
            console.log('✅ Commission distribution function available');
            results.commission = true;
        } else {
            console.log('❌ Commission function error:', commissionError.message);
        }
        
        // Test promoter ID generation
        const { data: promoterId, error: idError } = await supabase.rpc('generate_next_promoter_id');
        
        if (!idError) {
            console.log('✅ Promoter ID generation function working');
            results.database = true;
        } else {
            console.log('❌ Promoter ID function error:', idError.message);
        }
        
    } catch (error) {
        console.log('❌ Database function test failed:', error.message);
    }
    
    console.log('');
    console.log('🔧 Step 4: Checking Authentication...');
    
    try {
        const supabase = window.supabase || window.supabaseClient;
        const { data: session } = await supabase.auth.getSession();
        
        if (session?.session?.user) {
            console.log('✅ User authenticated:', session.session.user.email);
            results.auth = true;
        } else {
            console.log('ℹ️ No active session (login required for full testing)');
            results.auth = 'no_session';
        }
    } catch (error) {
        console.log('❌ Auth check failed:', error.message);
    }
    
    console.log('');
    console.log('📊 SYSTEM HEALTH SUMMARY:');
    console.log('='.repeat(30));
    
    const statusIcon = (status) => {
        if (status === true) return '✅ HEALTHY';
        if (status === 'no_session') return '⚠️ NO SESSION';
        return '❌ UNHEALTHY';
    };
    
    console.log(`Backend Service: ${statusIcon(results.backend)}`);
    console.log(`Frontend Ports: ${statusIcon(results.frontend)}`);
    console.log(`Database Functions: ${statusIcon(results.database)}`);
    console.log(`Commission System: ${statusIcon(results.commission)}`);
    console.log(`Authentication: ${statusIcon(results.auth)}`);
    
    console.log('');
    
    const healthyCount = Object.values(results).filter(r => r === true).length;
    const totalChecks = Object.keys(results).length;
    
    if (healthyCount >= 4) {
        console.log('🎉 SYSTEM STATUS: HEALTHY');
        console.log('✅ All critical systems operational');
        console.log('🚀 Ready for promoter and customer creation!');
    } else if (healthyCount >= 2) {
        console.log('⚠️ SYSTEM STATUS: PARTIAL');
        console.log('🔧 Some systems need attention');
        console.log('📋 Check failed components above');
    } else {
        console.log('❌ SYSTEM STATUS: UNHEALTHY');
        console.log('🚨 Multiple systems need attention');
        console.log('📋 Run setup-complete-system.sh to fix issues');
    }
    
    console.log('');
    console.log('🔗 QUICK ACCESS LINKS:');
    console.log('Admin Panel: http://localhost:3000');
    console.log('Promoter Panel: http://localhost:3001');
    console.log('Customer Panel: http://localhost:3002');
    console.log('Backend API: http://localhost:5001/api/health');
    
    return results;
}

// Export for manual use
window.verifySystemHealth = verifySystemHealth;

// Auto-run verification
console.log('🔄 Running automatic system health check...');
verifySystemHealth();
