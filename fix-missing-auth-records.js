// =====================================================
// FIX MISSING AUTH RECORDS - BROWSER CONSOLE
// =====================================================
// Run this in browser console on admin page to fix the auth-profile link

console.log('🔧 Fixing Missing Authentication Records...');

async function fixMissingAuthRecords() {
    try {
        // First, let's check what we have for BPVP26
        console.log('🔍 Checking current state for BPVP26...');
        
        // We know from the logs:
        const promoterId = 'BPVP26';
        const authUserId = '6d9f4d10-ce1b-470b-94c4-a1c870e71f5f';
        const email = 'officialpanduks06@gmail.com';
        const phone = '7411195267';
        
        console.log('📊 Known data:');
        console.log(`   • Promoter ID: ${promoterId}`);
        console.log(`   • Auth User ID: ${authUserId}`);
        console.log(`   • Email: ${email}`);
        console.log(`   • Phone: ${phone}`);
        
        // Create the SQL to fix the authentication records
        const fixSQL = `
-- Fix authentication records for BPVP26
DO $$
DECLARE
    promoter_record RECORD;
    auth_user_record RECORD;
BEGIN
    -- Get the promoter profile
    SELECT * INTO promoter_record 
    FROM profiles 
    WHERE promoter_id = '${promoterId}';
    
    IF NOT FOUND THEN
        RAISE NOTICE 'Promoter ${promoterId} not found in profiles';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Found promoter profile: % (ID: %)', promoter_record.name, promoter_record.id;
    
    -- Check if auth user exists
    SELECT * INTO auth_user_record 
    FROM auth.users 
    WHERE id = '${authUserId}';
    
    IF NOT FOUND THEN
        RAISE NOTICE 'Auth user ${authUserId} not found';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Found auth user: %', auth_user_record.email;
    
    -- Update the profile to ensure it's linked to the auth user
    UPDATE profiles 
    SET id = '${authUserId}'
    WHERE promoter_id = '${promoterId}';
    
    RAISE NOTICE 'Updated profile to link with auth user';
    
    -- Verify the connection
    IF EXISTS(
        SELECT 1 FROM profiles p
        JOIN auth.users au ON p.id = au.id
        WHERE p.promoter_id = '${promoterId}'
    ) THEN
        RAISE NOTICE '✅ Auth-Profile link verified successfully';
    ELSE
        RAISE NOTICE '❌ Auth-Profile link verification failed';
    END IF;
    
END $$;

-- Test the authentication functions
SELECT 'Testing authentication...' as status;

-- Test promoter ID authentication function
SELECT 
    'Promoter ID Auth Test' as test_type,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM profiles p
            JOIN auth.users au ON p.id = au.id
            WHERE p.promoter_id = '${promoterId}'
        ) THEN 'READY'
        ELSE 'MISSING_LINK'
    END as result;
`;

        console.log('🔧 Applying authentication fix...');
        console.log('');
        console.log('📋 MANUAL STEPS REQUIRED:');
        console.log('1. Go to Supabase Dashboard → SQL Editor');
        console.log('2. Copy and paste this SQL:');
        console.log('');
        console.log(fixSQL);
        console.log('');
        console.log('3. Execute the SQL');
        console.log('4. Try logging in again');
        
        // Also provide a simpler direct fix
        console.log('');
        console.log('🚀 ALTERNATIVE SIMPLE FIX:');
        console.log('If the above is complex, try this simpler SQL:');
        console.log('');
        console.log(`UPDATE profiles 
SET id = '${authUserId}' 
WHERE promoter_id = '${promoterId}';`);
        
        return true;

    } catch (error) {
        console.error('❌ Error:', error);
        return false;
    }
}

// Execute the fix
fixMissingAuthRecords();
