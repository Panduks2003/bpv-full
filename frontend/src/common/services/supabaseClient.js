/**
 * Single Shared Supabase Client Instance
 * This is the ONLY file that should create a Supabase client
 * All other files should import from here to prevent multiple GoTrueClient instances
 */

import { createClient } from '@supabase/supabase-js';

// Use Create React App environment variables (REACT_APP_ prefix for client-side)
const SUPABASE_URL = process.env.REACT_APP_SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.REACT_APP_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  throw new Error('Supabase configuration required. Please check your .env file.');
}

// Create single Supabase client instance with optimized configuration
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    flowType: 'pkce' // More secure auth flow
  },
  db: {
    schema: 'public'
  },
  global: {
    headers: {
      'x-client-info': 'brightplanet-ventures@1.0.0'
    }
  },
  realtime: {
    params: {
      eventsPerSecond: 10 // Limit real-time events to prevent overwhelming
    }
  }
});

// Auth helpers
export const auth = {
  // Sign up new user
  signUp: async (email, password, userData = {}) => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: userData
      }
    })
    return { data, error }
  },

  // Sign in user (supports email, phone, promoter ID, or customer ID)
  signIn: async (identifier, password) => {
    let email = identifier;
    
    // If identifier looks like a promoter ID (BPVP##), find the email
    if (identifier.match(/^BPVP\d+$/i)) {
      const { data: promoterData, error: promoterError } = await supabase
        .from('promoters')
        .select('id')
        .ilike('promoter_id', identifier)
        .single();
      
      if (promoterError || !promoterData) {
        return { data: null, error: { message: 'Invalid promoter ID' } };
      }
      
      // Get email from profiles
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('email')
        .eq('id', promoterData.id)
        .single();
      
      if (profileError || !profileData) {
        return { data: null, error: { message: 'Promoter profile not found' } };
      }
      
      email = profileData.email;
    }
    // If identifier looks like a customer ID (BPVC##), find the email
    else if (identifier.match(/^BPVC\d+$/i)) {
      const { data: customerData, error: customerError } = await supabase
        .from('customers')
        .select('id')
        .ilike('customer_id', identifier)
        .single();
      
      if (customerError || !customerData) {
        return { data: null, error: { message: 'Invalid customer ID' } };
      }
      
      // Get email from profiles
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('email')
        .eq('id', customerData.id)
        .single();
      
      if (profileError || !profileData) {
        return { data: null, error: { message: 'Customer profile not found' } };
      }
      
      email = profileData.email;
    }
    // If identifier looks like a phone number, find the email
    else if (identifier.match(/^[6-9]\d{9}$/)) {
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('email')
        .eq('phone', identifier)
        .single();
      
      if (profileError || !profileData) {
        return { data: null, error: { message: 'Phone number not found' } };
      }
      
      email = profileData.email;
    }
    
    // Now sign in with email
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    
    return { data, error };
  },

  // Sign out user
  signOut: async () => {
    const { error } = await supabase.auth.signOut()
    return { error }
  },

  // Get current user
  getCurrentUser: async () => {
    const { data: { user }, error } = await supabase.auth.getUser()
    return { user, error }
  },

  // Get current session
  getSession: async () => {
    const { data: { session }, error } = await supabase.auth.getSession()
    return { session, error }
  },

  // Update user profile
  updateUser: async (updates) => {
    const { data, error } = await supabase.auth.updateUser(updates)
    return { data, error }
  },

  // Reset password
  resetPassword: async (email) => {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`
    })
    return { data, error }
  }
}

// Database helpers
export const db = {
  // Generic select
  select: (table, columns = '*') => supabase.from(table).select(columns),

  // Generic insert
  insert: (table, data) => supabase.from(table).insert(data),

  // Generic update
  update: (table, data) => supabase.from(table).update(data),

  // Generic delete
  delete: (table) => supabase.from(table).delete(),

  // User profile operations
  profiles: {
    get: (userId) => supabase.from('profiles').select('*').eq('id', userId).single(),
    update: (userId, data) => supabase.from('profiles').update(data).eq('id', userId),
    create: (data) => supabase.from('profiles').insert(data)
  },

  // Promoter operations
  promoters: {
    // Get all promoters with profile data joined
    getAll: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select(`
          id,
          email,
          name,
          phone,
          promoter_id,
          role_level,
          status,
          parent_promoter_id,
          address,
          created_at,
          updated_at,
          promoters (
            commission_rate,
            status,
            total_sales,
            total_commission,
            business_name,
            business_category,
            business_description,
            pins,
            parent_promoter_id,
            can_create_promoters,
            can_create_customers,
            promoter_id
          )
        `)
        .eq('role', 'promoter')
        .order('created_at', { ascending: false });
      
      // Transform data to match frontend expectations
      const transformedData = data?.map(profile => ({
        id: profile.id,
        _id: profile.id, // For backward compatibility
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        promoter_id: profile.promoter_id || profile.promoters?.promoter_id, // Prioritize profiles table
        role_level: profile.role_level,
        status: profile.status,
        parent_promoter_id: profile.parent_promoter_id,
        address: profile.address,
        is_active: (profile.status === 'Active') || (profile.promoters?.status === 'active'), // Check both sources
        created_at: profile.created_at,
        updated_at: profile.updated_at,
        // Flatten promoter data (but prioritize profiles table data)
        ...profile.promoters,
        // Override with profiles table data where available
        promoter_id: profile.promoter_id || profile.promoters?.promoter_id,
        status: profile.status || profile.promoters?.status,
        parent_promoter_id: profile.parent_promoter_id || profile.promoters?.parent_promoter_id,
        // Keep nested structure for backward compatibility
        promoterData: profile.promoters
      })) || [];
      
      return { data: transformedData, error };
    },

    // Get promoter by ID with profile data joined
    getById: async (id) => {
      const { data, error } = await supabase
        .from('profiles')
        .select(`
          id,
          email,
          name,
          phone,
          promoter_id,
          role_level,
          status,
          parent_promoter_id,
          address,
          created_at,
          updated_at,
          promoters (
            commission_rate,
            status,
            total_sales,
            total_commission,
            business_name,
            business_category,
            business_description,
            pins,
            parent_promoter_id,
            can_create_promoters,
            can_create_customers,
            promoter_id
          )
        `)
        .eq('role', 'promoter')
        .eq('id', id)
        .single();
      
      if (error || !data) {
        return { data: null, error };
      }
      
      // Transform data to match frontend expectations
      const transformedData = {
        id: data.id,
        _id: data.id, // For backward compatibility
        name: data.name,
        email: data.email,
        phone: data.phone,
        promoter_id: data.promoter_id || data.promoters?.promoter_id, // Prioritize profiles table
        role_level: data.role_level,
        status: data.status,
        parent_promoter_id: data.parent_promoter_id,
        address: data.address,
        is_active: (data.status === 'Active') || (data.promoters?.status === 'active'), // Check both sources
        created_at: data.created_at,
        updated_at: data.updated_at,
        // Flatten promoter data (but prioritize profiles table data)
        ...data.promoters,
        // Override with profiles table data where available
        promoter_id: data.promoter_id || data.promoters?.promoter_id,
        status: data.status || data.promoters?.status,
        parent_promoter_id: data.parent_promoter_id || data.promoters?.parent_promoter_id,
        // Keep nested structure for backward compatibility
        promoterData: data.promoters
      };
      
      return { data: transformedData, error: null };
    },

    // Update promoter
    update: async (id, updates) => {
      const { profile: profileUpdates, promoter: promoterUpdates } = updates;
      
      let results = {};
      
      // Update profile if needed
      if (profileUpdates) {
        const { data: profileData, error: profileError } = await supabase
          .from('profiles')
          .update(profileUpdates)
          .eq('id', id)
          .select()
          .single();
        
        if (profileError) {
          return { data: null, error: profileError };
        }
        results.profile = profileData;
      }
      
      // Update promoter if needed
      if (promoterUpdates) {
        const { data: promoterData, error: promoterError } = await supabase
          .from('promoters')
          .update(promoterUpdates)
          .eq('id', id)
          .select()
          .single();
        
        if (promoterError) {
          return { data: null, error: promoterError };
        }
        results.promoter = promoterData;
      }
      
      return { data: results, error: null };
    },

    // Create new promoter (creates both profile and promoter records)
    create: async (profileData, promoterData) => {
      // First create the profile
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .insert({
          id: profileData.id,
          email: profileData.email, // Can be null for optional email
          name: profileData.name,
          role: 'promoter',
          phone: profileData.phone,
          address: profileData.address // Add address field
        })
        .select()
        .single();

      if (profileError) {
        return { data: null, error: profileError };
      }

      // Then create the promoter record
      const { data: promoter, error: promoterError } = await supabase
        .from('promoters')
        .insert({
          id: profile.id,
          business_name: promoterData.business_name,
          business_category: promoterData.business_category,
          business_description: promoterData.business_description,
          pins: promoterData.pins || 0,
          parent_promoter_id: promoterData.parent_promoter_id || null,
          can_create_promoters: promoterData.can_create_promoters !== false,
          can_create_customers: promoterData.can_create_customers !== false,
          commission_rate: promoterData.commission_rate || 0.05,
          status: promoterData.status || 'active'
        })
        .select()
        .single();

      if (promoterError) {
        // Rollback profile creation if promoter creation fails
        await supabase.from('profiles').delete().eq('id', profile.id);
        return { data: null, error: promoterError };
      }

      return { data: { profile, promoter }, error: null };
    },

    // Delete promoter (deletes both promoter and profile records)
    delete: async (id) => {
      // Delete promoter first (due to foreign key constraints)
      const { error: promoterError } = await supabase
        .from('promoters')
        .delete()
        .eq('id', id);
      
      if (promoterError) {
        return { data: null, error: promoterError };
      }
      
      // Then delete profile
      const { error: profileError } = await supabase
        .from('profiles')
        .delete()
        .eq('id', id);
      
      return { data: null, error: profileError };
    }
  },

  // Customer operations
  customers: {
    // Get all customers with profile data joined
    getAll: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select(`
          id,
          email,
          name,
          phone,
          customer_id,
          state,
          city,
          pincode,
          address,
          saving_plan,
          created_at,
          updated_at,
          customers!customers_id_fkey (
            parent_promoter,
            promoter_id,
            created_at,
            updated_at
          )
        `)
        .eq('role', 'customer')
        .order('created_at', { ascending: false });
      
      // Transform data to match frontend expectations
      const transformedData = data?.map(profile => ({
        id: profile.id,
        _id: profile.id, // For backward compatibility
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        customer_id: profile.customer_id,
        state: profile.state,
        city: profile.city,
        pincode: profile.pincode,
        address: profile.address,
        saving_plan: profile.saving_plan,
        is_active: true, // All customers are active in new system
        created_at: profile.created_at,
        updated_at: profile.updated_at,
        // Flatten customer data
        parent_promoter: profile.customers?.parent_promoter,
        promoter_id: profile.customers?.promoter_id,
        // Keep nested structure for backward compatibility
        customerData: profile.customers
      })) || [];
      
      return { data: transformedData, error };
    },

    // Get customer by ID
    getById: async (id) => {
      const { data, error } = await supabase
        .from('profiles')
        .select(`
          id,
          email,
          name,
          phone,
          customer_id,
          state,
          city,
          pincode,
          address,
          saving_plan,
          created_at,
          updated_at,
          customers!customers_id_fkey (
            parent_promoter,
            promoter_id,
            created_at,
            updated_at
          )
        `)
        .eq('id', id)
        .eq('role', 'customer')
        .single();
      
      if (!data) {
        return { data: null, error };
      }

      // Transform data to match frontend expectations
      const transformedData = {
        id: data.id,
        _id: data.id,
        name: data.name,
        email: data.email,
        phone: data.phone,
        customer_id: data.customer_id,
        state: data.state,
        city: data.city,
        pincode: data.pincode,
        address: data.address,
        saving_plan: data.saving_plan,
        is_active: true,
        created_at: data.created_at,
        updated_at: data.updated_at,
        parent_promoter: data.customers?.parent_promoter,
        promoter_id: data.customers?.promoter_id,
        customerData: data.customers
      };
      
      return { data: transformedData, error };
    },

    // Update customer
    update: async (id, updates) => {
      const { data, error } = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', id)
        .eq('role', 'customer')
        .select()
        .single();
      
      return { data, error };
    },

    // Delete customer
    delete: async (id) => {
      // Delete customer record first
      const { error: customerError } = await supabase
        .from('customers')
        .delete()
        .eq('id', id);
      
      if (customerError) {
        return { data: null, error: customerError };
      }
      
      // Then delete profile
      const { error: profileError } = await supabase
        .from('profiles')
        .delete()
        .eq('id', id);
      
      return { data: null, error: profileError };
    }
  },

  // Unified Promoter System Functions
  promoterSystem: {
    // Generate next promoter ID
    generateNextId: async () => {
      const { data, error } = await supabase.rpc('generate_next_promoter_id');
      return { data, error };
    },

    // Create unified promoter
    createPromoter: async (promoterData) => {
      const { data, error } = await supabase.rpc('create_unified_promoter', {
        p_name: promoterData.name,
        p_email: promoterData.email || null,
        p_password: promoterData.password,
        p_phone: promoterData.phone,
        p_address: promoterData.address || null,
        p_parent_promoter_id: promoterData.parentPromoter || null,
        p_role_level: promoterData.roleLevel || 'Affiliate',
        p_status: promoterData.status || 'Active'
      });
      return { data, error };
    },

    // Update promoter profile
    updatePromoter: async (promoterId, updates) => {
      const { data, error } = await supabase.rpc('update_promoter_profile', {
        p_promoter_id: promoterId,
        p_name: updates.name,
        p_email: updates.email,
        p_phone: updates.phone,
        p_address: updates.address,
        p_role_level: updates.roleLevel,
        p_status: updates.status,
        p_parent_promoter_id: updates.parentPromoter
      });
      return { data, error };
    },

    // Get promoter hierarchy
    getHierarchy: async (promoterId = null) => {
      const { data, error } = await supabase.rpc('get_promoter_hierarchy', {
        p_promoter_id: promoterId
      });
      return { data, error };
    },

    // Validate promoter hierarchy
    validateHierarchy: async (promoterId, parentPromoterId) => {
      const { data, error } = await supabase.rpc('validate_promoter_hierarchy', {
        p_promoter_id: promoterId,
        p_parent_promoter_id: parentPromoterId
      });
      return { data, error };
    }
  }
}

// Export default for convenience
export default supabase;
