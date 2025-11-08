/**
 * Authentication Service
 * Supports email/password login and Customer ID (Card No) login
 */

import { supabase } from './supabaseClient';

class AuthService {
  constructor() {
    this.currentUser = null;
    this.currentSession = null;
  }

  /**
   * Simple email/password login
   */
  async login(email, password) {
    try {
      console.log('Login attempt with email:', email);
      
      // Input validation
      if (!email || !password) {
        console.error('Missing email or password');
        throw new Error('Please provide both email and password');
      }

      // Validate email format
      if (!/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(email)) {
        console.error('Invalid email format:', email);
        throw new Error('Please enter a valid email address');
      }

      console.log('Attempting to sign in with Supabase...');
      console.log('Supabase URL:', process.env.REACT_APP_SUPABASE_URL);
      
      // Attempt authentication with Supabase
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email,
        password: password
      });
      
      console.log('Supabase response:', { data, error });

      if (error) {
        
        // Provide user-friendly error messages
        if (error.message.includes('Invalid login credentials')) {
          throw new Error('Invalid email or password');
        } else if (error.message.includes('Email not confirmed')) {
          throw new Error('Please check your email and click the confirmation link before signing in.');
        } else if (error.message.includes('Too many requests')) {
          throw new Error('Too many login attempts. Please wait a few minutes before trying again.');
        } else {
          throw new Error(`Login failed: ${error.message}`);
        }
      }

      if (!data.user) {
        throw new Error('Login failed: No user data received');
      }

      // Get user profile from database
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', data.user.id)
        .single();

      if (profileError || !profile) {
        throw new Error('Could not load user profile');
      }

      // Note: is_active field removed from schema - all users are considered active

      // Create user profile object
      const userProfile = {
        id: data.user.id,
        email: profile.email,
        name: profile.name,
        role: profile.role
      };

      // Store current user and session
      this.currentUser = userProfile;
      this.currentSession = data.session;

      return userProfile;

    } catch (error) {
      throw error;
    }
  }

  /**
   * Customer login with Card No (Customer ID) and password
   * Uses database function for direct authentication with Supabase Auth
   */
  async loginWithCardNo(cardNo, password) {
    try {

      // Input validation
      if (!cardNo || !password) {
        throw new Error('Please provide both Customer ID and password');
      }

      // Call the database function for Card No authentication
      const { data, error } = await supabase.rpc('authenticate_customer_by_card_no', {
        p_customer_id: cardNo,
        p_password: password
      });

      if (error) {
        throw new Error('Authentication failed. Please check your Customer ID and password.');
      }

      if (!data || !data.success) {
        throw new Error(data?.error || 'Invalid Customer ID or password');
      }

      const userProfile = data.user;

      // Create a local session object for authentication state
      // Note: We skip Supabase Auth session since customer passwords use pgcrypto hashing
      // which Supabase Auth doesn't support (it uses pbkdf2)
      const localSession = {
        access_token: `local_session_${userProfile.id}`,
        token_type: 'bearer',
        user: {
          id: userProfile.id,
          email: data.auth_email
        },
        expires_at: Math.floor(Date.now() / 1000) + (3600 * 24) // 24 hours
      };

      // Store current user and session
      this.currentUser = userProfile;
      this.currentSession = localSession;

      return userProfile;

    } catch (error) {
      throw error;
    }
  }

  /**
   * Promoter login with Promoter ID and password (ONLY METHOD)
   * Uses database function for direct authentication
   */
  async loginWithPromoterID(promoterID, password) {
    try {

      // Input validation
      if (!promoterID || !password) {
        throw new Error('Please provide both Promoter ID and password');
      }

      // Validate Promoter ID format (BPVP followed by digits)
      if (!/^BPVP\d+$/i.test(promoterID)) {
        throw new Error('Invalid Promoter ID format. Expected format: BPVP01, BPVP02, etc.');
      }

      // Call the database function for Promoter ID authentication
      const { data, error } = await supabase.rpc('authenticate_promoter_by_id_only', {
        p_promoter_id: promoterID.toUpperCase(),
        p_password: password
      });

      if (error) {
        throw new Error('Authentication failed. Please check your Promoter ID and password.');
      }

      if (!data || !data.success) {
        throw new Error(data?.error || 'Invalid Promoter ID or password');
      }

      const userProfile = data.user;

      // Create a local session object for authentication state
      // Note: We skip Supabase Auth session since promoter passwords use pgcrypto hashing
      // which Supabase Auth doesn't support (it uses pbkdf2)
      const localSession = {
        access_token: `local_session_${userProfile.id}`,
        token_type: 'bearer',
        user: {
          id: userProfile.id,
          email: data.auth_email
        },
        expires_at: Math.floor(Date.now() / 1000) + (3600 * 24) // 24 hours
      };

      // Store current user and session
      this.currentUser = userProfile;
      this.currentSession = localSession;

      return userProfile;

    } catch (error) {
      throw error;
    }
  }

  /**
   * Logout user
   */
  async logout() {
    try {
      // Sign out from Supabase
      const { error } = await supabase.auth.signOut();
      if (error) {
      }

      // Clear local state
      this.currentUser = null;
      this.currentSession = null;

    } catch (error) {
      // Clear local state even if server logout fails
      this.currentUser = null;
      this.currentSession = null;
    }
  }

  /**
   * Get current user
   */
  getCurrentUser() {
    return this.currentUser;
  }

  /**
   * Get current session
   */
  getCurrentSession() {
    return this.currentSession;
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated() {
    return !!this.currentUser && !!this.currentSession;
  }

  /**
   * Validate current session
   */
  async validateSession() {
    try {
      const { data: { session }, error } = await supabase.auth.getSession();
      
      if (error || !session) {
        this.currentUser = null;
        this.currentSession = null;
        return false;
      }

      this.currentSession = session;
      return true;
    } catch (error) {
      return false;
    }
  }
}

// Create singleton instance
const authService = new AuthService();

// Export the service
export default authService;
