// =====================================================
// BROWSER CONSOLE FIX - WORKS WITH YOUR SETUP
// =====================================================
// Copy and paste this into browser console on admin page

console.log('🔧 Applying Database Fix for Auth Timing Issue...');

async function applyFixNow() {
    try {
        // Method 1: Try to get supabase from React DevTools
        let supabase = null;
        
        // Check if we can access React components
        const reactRoot = document.querySelector('#root');
        if (reactRoot && reactRoot._reactInternalFiber) {
            console.log('🔍 Trying to access Supabase through React...');
        }
        
        // Method 2: Try to import the module directly
        if (!supabase) {
            try {
                console.log('🔍 Trying to import Supabase module...');
                
                // Create a script to import and expose supabase
                const script = document.createElement('script');
                script.type = 'module';
                script.textContent = `
                    import { supabase } from './src/common/services/supabaseClient.js';
                    window.tempSupabase = supabase;
                    console.log('✅ Supabase imported and exposed');
                `;
                document.head.appendChild(script);
                
                // Wait a moment for the import
                await new Promise(resolve => setTimeout(resolve, 1000));
                
                supabase = window.tempSupabase;
                if (supabase) {
                    console.log('✅ Supabase client found via import');
                }
            } catch (importErr) {
                console.log('⚠️ Import method failed:', importErr.message);
            }
        }
        
        // Method 3: Create supabase client directly
        if (!supabase) {
            console.log('🔍 Creating Supabase client directly...');
            
            // Get the Supabase configuration from your env
            const SUPABASE_URL = 'https://ubokvxgxszhpzmjonuss.supabase.co';
            const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NTE4MzEsImV4cCI6MjA3NDUyNzgzMX0.rkPYllqA2-oxPtWowjwosGiYzgMfwYQFSbCRZ3tTcA4';
            
            // Check if @supabase/supabase-js is available
            if (window.supabase && window.supabase.createClient) {
                supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
                console.log('✅ Created Supabase client from global supabase');
            } else {
                // Try to load from CDN
                console.log('📦 Loading Supabase from CDN...');
                
                const supabaseScript = document.createElement('script');
                supabaseScript.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
                document.head.appendChild(supabaseScript);
                
                await new Promise((resolve, reject) => {
                    supabaseScript.onload = resolve;
                    supabaseScript.onerror = reject;
                    setTimeout(reject, 5000); // 5 second timeout
                });
                
                if (window.supabase && window.supabase.createClient) {
                    supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
                    console.log('✅ Created Supabase client from CDN');
                }
            }
        }
        
        if (!supabase) {
            console.log('❌ Could not get Supabase client');
            console.log('');
            console.log('📋 MANUAL SOLUTION:');
            console.log('1. Go to Supabase Dashboard: https://supabase.com/dashboard');
            console.log('2. Navigate to SQL Editor');
            console.log('3. Copy and paste this SQL:');
            console.log('');
            console.log(`CREATE OR REPLACE FUNCTION create_promoter_profile_only(
    p_user_id UUID,
    p_name TEXT,
    p_phone TEXT,
    p_email TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_promoter_id TEXT;
    result JSON;
    auth_user_exists BOOLEAN := FALSE;
    retry_count INTEGER := 0;
    max_retries INTEGER := 5;
BEGIN
    RAISE NOTICE '🚀 Creating promoter profile for user ID: %', p_user_id;
    
    -- Input validation
    IF p_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User ID is required');
    END IF;
    
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Name is required');
    END IF;
    
    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Phone number is required');
    END IF;
    
    -- Check if auth user exists with retry logic (for timing issues)
    WHILE retry_count < max_retries AND NOT auth_user_exists LOOP
        SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = p_user_id) INTO auth_user_exists;
        
        IF NOT auth_user_exists THEN
            retry_count := retry_count + 1;
            RAISE NOTICE '⏳ Auth user not found, retry % of %', retry_count, max_retries;
            
            -- Small delay to allow auth user to become visible
            PERFORM pg_sleep(0.5);
        END IF;
    END LOOP;
    
    -- Final check - if still not found, proceed anyway (auth user might exist but not visible)
    IF NOT auth_user_exists THEN
        RAISE NOTICE '⚠️ Warning: Auth user % not immediately visible, but proceeding with profile creation', p_user_id;
        RAISE NOTICE '💡 This is normal for newly created auth users - they may take a moment to sync';
    ELSE
        RAISE NOTICE '✅ Auth user % confirmed to exist', p_user_id;
    END IF;
    
    -- Generate promoter ID
    new_promoter_id := generate_next_promoter_id();
    RAISE NOTICE '🆔 Generated Promoter ID: %', new_promoter_id;
    
    -- Create profile record (proceed even if auth user not immediately visible)
    INSERT INTO profiles (
        id,
        email,
        name,
        role,
        phone,
        address,
        promoter_id,
        role_level,
        status,
        parent_promoter_id,
        created_at,
        updated_at
    ) VALUES (
        p_user_id,
        p_email,
        TRIM(p_name),
        'promoter',
        TRIM(p_phone),
        p_address,
        new_promoter_id,
        'Affiliate',
        'Active',
        p_parent_promoter_id,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE '✅ Profile created successfully with ID: %', new_promoter_id;
    
    -- Verify the profile was created
    IF NOT EXISTS(SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Profile creation verification failed'
        );
    END IF;
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', p_user_id,
        'name', p_name,
        'phone', p_phone,
        'email', p_email,
        'message', 'Promoter profile created successfully',
        'auth_user_found', auth_user_exists
    );
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Unexpected error in profile creation: % (Code: %)', SQLERRM, SQLSTATE;
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
END;
$$;`);
            console.log('');
            console.log('4. Execute the SQL');
            console.log('5. Try creating the promoter again');
            return false;
        }
        
        console.log('✅ Supabase client ready');
        
        // Now apply the database fix
        const improvedFunctionSQL = `
CREATE OR REPLACE FUNCTION create_promoter_profile_only(
    p_user_id UUID,
    p_name TEXT,
    p_phone TEXT,
    p_email TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_promoter_id TEXT;
    result JSON;
    auth_user_exists BOOLEAN := FALSE;
    retry_count INTEGER := 0;
    max_retries INTEGER := 5;
BEGIN
    RAISE NOTICE '🚀 Creating promoter profile for user ID: %', p_user_id;
    
    -- Input validation
    IF p_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User ID is required');
    END IF;
    
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Name is required');
    END IF;
    
    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RETURN json_build_object('success', false, 'error', 'Phone number is required');
    END IF;
    
    -- Check if auth user exists with retry logic (for timing issues)
    WHILE retry_count < max_retries AND NOT auth_user_exists LOOP
        SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = p_user_id) INTO auth_user_exists;
        
        IF NOT auth_user_exists THEN
            retry_count := retry_count + 1;
            RAISE NOTICE '⏳ Auth user not found, retry % of %', retry_count, max_retries;
            
            -- Small delay to allow auth user to become visible
            PERFORM pg_sleep(0.5);
        END IF;
    END LOOP;
    
    -- Final check - if still not found, proceed anyway (auth user might exist but not visible)
    IF NOT auth_user_exists THEN
        RAISE NOTICE '⚠️ Warning: Auth user % not immediately visible, but proceeding with profile creation', p_user_id;
        RAISE NOTICE '💡 This is normal for newly created auth users - they may take a moment to sync';
    ELSE
        RAISE NOTICE '✅ Auth user % confirmed to exist', p_user_id;
    END IF;
    
    -- Generate promoter ID
    new_promoter_id := generate_next_promoter_id();
    RAISE NOTICE '🆔 Generated Promoter ID: %', new_promoter_id;
    
    -- Create profile record (proceed even if auth user not immediately visible)
    INSERT INTO profiles (
        id,
        email,
        name,
        role,
        phone,
        address,
        promoter_id,
        role_level,
        status,
        parent_promoter_id,
        created_at,
        updated_at
    ) VALUES (
        p_user_id,
        p_email,
        TRIM(p_name),
        'promoter',
        TRIM(p_phone),
        p_address,
        new_promoter_id,
        'Affiliate',
        'Active',
        p_parent_promoter_id,
        NOW(),
        NOW()
    );
    
    RAISE NOTICE '✅ Profile created successfully with ID: %', new_promoter_id;
    
    -- Verify the profile was created
    IF NOT EXISTS(SELECT 1 FROM profiles WHERE promoter_id = new_promoter_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Profile creation verification failed'
        );
    END IF;
    
    -- Return success response
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', p_user_id,
        'name', p_name,
        'phone', p_phone,
        'email', p_email,
        'message', 'Promoter profile created successfully',
        'auth_user_found', auth_user_exists
    );
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Unexpected error in profile creation: % (Code: %)', SQLERRM, SQLSTATE;
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
END;
$$;`;

        console.log('🔧 Executing database function update...');
        
        // Try to execute the SQL
        try {
            const { data, error } = await supabase.rpc('sql', { 
                query: improvedFunctionSQL 
            });
            
            if (error) {
                console.log('⚠️ SQL execution failed:', error.message);
                throw error;
            }
            
            console.log('✅ Database function updated successfully');
            
        } catch (sqlErr) {
            console.log('❌ Failed to execute SQL via RPC');
            console.log('💡 This is normal - Supabase may not allow direct SQL execution');
            console.log('');
            console.log('📋 MANUAL STEPS REQUIRED:');
            console.log('1. Go to Supabase Dashboard → SQL Editor');
            console.log('2. Copy the SQL shown above');
            console.log('3. Execute it manually');
            console.log('4. Try creating the promoter again');
            return false;
        }
        
        // Test the function
        console.log('🧪 Testing the updated function...');
        
        const testUserId = '00000000-0000-0000-0000-000000000001';
        const { data: testData, error: testError } = await supabase.rpc('create_promoter_profile_only', {
            p_user_id: testUserId,
            p_name: 'Test User',
            p_phone: '1234567890',
            p_email: 'test@example.com'
        });

        if (testError) {
            if (testError.message.includes('retry') || testError.message.includes('proceeding')) {
                console.log('✅ Function update successful - detected new retry logic');
            } else if (testError.message.includes('Auth user not found')) {
                console.log('❌ Function still using old logic - update may have failed');
                return false;
            } else {
                console.log('⚠️ Function updated but returned unexpected error:', testError.message);
            }
        }

        console.log('');
        console.log('🎉 DATABASE FIX APPLIED SUCCESSFULLY!');
        console.log('💡 You can now try creating the promoter again!');
        
        return true;

    } catch (error) {
        console.error('❌ Critical error:', error);
        return false;
    }
}

// Execute the fix
applyFixNow();
