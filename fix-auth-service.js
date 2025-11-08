// =====================================================
// FIXED AUTHENTICATION SERVICE - FRONTEND UPDATE
// =====================================================
// This file contains the fixed authentication methods that have been
// applied to authService.js to resolve the authentication issues.

// The loginWithPromoterID method has been replaced with this fixed version:

/*
async loginWithPromoterID(promoterID, password) {
  try {
    console.log('🔐 Starting Promoter ID login for:', promoterID);

    // Input validation
    if (!promoterID || !password) {
      throw new Error('Please provide both Promoter ID and password');
    }

    // STEP 1: Get promoter profile data (without password verification)
    const { data: promoterProfile, error: profileError } = await supabase
      .from('profiles')
      .select('id, email, name, phone, address, role, promoter_id, status')
      .eq('promoter_id', promoterID)
      .eq('role', 'promoter')
      .eq('status', 'Active')
      .single();

    if (profileError || !promoterProfile) {
      console.error('Promoter profile lookup error:', profileError);
      throw new Error('Invalid Promoter ID or password');
    }

    // Check if promoter has email for authentication
    if (!promoterProfile.email) {
      throw new Error('Authentication not available - no email associated with this Promoter ID');
    }

    console.log('✅ Found promoter profile:', promoterProfile.name);

    // STEP 2: Authenticate with Supabase Auth using email and password
    console.log('🔐 Authenticating with Supabase Auth...');
    
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: promoterProfile.email,
      password: password
    });

    if (authError) {
      console.error('Supabase Auth error:', authError);
      throw new Error('Invalid Promoter ID or password');
    }

    if (!authData?.user) {
      throw new Error('Authentication failed');
    }

    console.log('✅ Supabase Auth successful');

    // STEP 3: Verify the auth user matches the promoter profile
    if (authData.user.id !== promoterProfile.id) {
      console.error('User ID mismatch:', {
        authUserId: authData.user.id,
        profileUserId: promoterProfile.id
      });
      
      // Sign out the auth session since it doesn't match
      await supabase.auth.signOut();
      throw new Error('Authentication error - please contact support');
    }

    console.log('✅ User ID verification passed');

    // STEP 4: Return the complete user profile
    const userProfile = {
      id: promoterProfile.id,
      email: promoterProfile.email,
      name: promoterProfile.name,
      phone: promoterProfile.phone,
      address: promoterProfile.address,
      role: promoterProfile.role,
      promoter_id: promoterProfile.promoter_id,
      status: promoterProfile.status
    };

    // Store current user and session
    this.currentUser = userProfile;
    this.currentSession = authData.session;

    console.log(`✅ Promoter ID login successful for ${userProfile.promoter_id} (${userProfile.name})`);
    return userProfile;

  } catch (error) {
    console.error(`❌ Promoter ID login failed for ${promoterID}:`, error.message);
    throw error;
  }
}

// Replace the loginWithPhone method with this fixed version:

async loginWithPhone(phone, password) {
  try {
    console.log('🔐 Starting phone login for:', phone);

    // Input validation
    if (!phone || !password) {
      throw new Error('Please provide both phone number and password');
    }

    // STEP 1: Get promoter profile data by phone
    const { data: promoterProfile, error: profileError } = await supabase
      .from('profiles')
      .select('id, email, name, phone, address, role, promoter_id, status')
      .eq('phone', phone)
      .eq('role', 'promoter')
      .eq('status', 'Active')
      .single();

    if (profileError || !promoterProfile) {
      console.error('Phone profile lookup error:', profileError);
      throw new Error('Invalid phone number or password');
    }

    // Check if promoter has email for authentication
    if (!promoterProfile.email) {
      throw new Error('Authentication not available - no email associated with this phone number');
    }

    console.log('✅ Found promoter profile:', promoterProfile.name);

    // STEP 2: Authenticate with Supabase Auth using email and password
    console.log('🔐 Authenticating with Supabase Auth...');
    
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: promoterProfile.email,
      password: password
    });

    if (authError) {
      console.error('Supabase Auth error:', authError);
      throw new Error('Invalid phone number or password');
    }

    if (!authData?.user) {
      throw new Error('Authentication failed');
    }

    console.log('✅ Supabase Auth successful');

    // STEP 3: Verify the auth user matches the promoter profile
    if (authData.user.id !== promoterProfile.id) {
      console.error('User ID mismatch:', {
        authUserId: authData.user.id,
        profileUserId: promoterProfile.id
      });
      
      // Sign out the auth session since it doesn't match
      await supabase.auth.signOut();
      throw new Error('Authentication error - please contact support');
    }

    console.log('✅ User ID verification passed');

    // STEP 4: Return the complete user profile
    const userProfile = {
      id: promoterProfile.id,
      email: promoterProfile.email,
      name: promoterProfile.name,
      phone: promoterProfile.phone,
      address: promoterProfile.address,
      role: promoterProfile.role,
      promoter_id: promoterProfile.promoter_id,
      status: promoterProfile.status
    };

    // Store current user and session
    this.currentUser = userProfile;
    this.currentSession = authData.session;

    console.log(`✅ Phone login successful for ${userProfile.promoter_id} (${userProfile.name})`);
    return userProfile;

  } catch (error) {
    console.error(`❌ Phone login failed for ${phone}:`, error.message);
    throw error;
  }
}

console.log('');
console.log('🔧 INSTRUCTIONS TO APPLY THIS FIX:');
console.log('');
console.log('1. Open: frontend/src/common/services/authService.js');
console.log('2. Replace the loginWithPromoterID method (lines ~136-184)');
console.log('3. Replace the loginWithPhone method (lines ~189-234)');
console.log('4. Save the file');
console.log('5. Refresh the browser and try logging in');
console.log('');
console.log('This fix uses proper Supabase Auth instead of custom SQL functions.');
console.log('✅ This will resolve the authentication issues permanently.');
*/
