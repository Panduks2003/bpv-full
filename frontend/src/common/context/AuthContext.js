import React, { createContext, useState, useContext, useEffect } from 'react';
import { supabase } from "../services/supabaseClient"
import authService from '../services/authService';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [session, setSession] = useState(null);

  // Optimized function to load user profile with caching
  const loadUserProfile = async (authUser) => {
    try {
      // Check cache first
      const cachedProfile = sessionStorage.getItem(`profile_${authUser.id}`);
      if (cachedProfile) {
        return JSON.parse(cachedProfile);
      }
      
      // Reduced timeout for faster fallback
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Profile loading timeout')), 5000);
      });
      
      const profilePromise = supabase
        .from('profiles')
        .select('*')
        .eq('id', authUser.id)
        .single();
      
      const { data: profile, error } = await Promise.race([profilePromise, timeoutPromise]);
      
      if (error || !profile) {
        
        // Fallback: create basic profile from auth user
        const fallbackProfile = {
          id: authUser.id,
          email: authUser.email,
          name: authUser.email.split('@')[0],
          role: authUser.email.includes('admin') ? 'admin' : 
                authUser.email.includes('promoter') ? 'promoter' : 'customer'
        };
        
        return fallbackProfile;
      }
      
      const userProfile = {
        id: authUser.id,
        email: profile.email,
        name: profile.name,
        role: profile.role
      };

      // Cache the profile for faster subsequent loads
      sessionStorage.setItem(`profile_${authUser.id}`, JSON.stringify(userProfile));
      
      return userProfile;
      
    } catch (error) {
      
      // Fallback profile
      const fallbackProfile = {
        id: authUser.id,
        email: authUser.email,
        name: authUser.email.split('@')[0],
        role: authUser.email.includes('admin') ? 'admin' : 
              authUser.email.includes('promoter') ? 'promoter' : 'customer'
      };
      
      return fallbackProfile;
    }
  };

  // Optimized initial session loading
  useEffect(() => {
    const getInitialSession = async () => {
      try {
        // Set loading to false quickly if no cached session
        const cachedSession = sessionStorage.getItem('supabase_session');
        if (!cachedSession) {
          setLoading(false);
          return;
        }
        
        const { data: { session } } = await supabase.auth.getSession();
        
        if (session?.user) {
          setSession(session);
          
          // Load profile asynchronously to not block UI
          loadUserProfile(session.user)
            .then(profile => {
              setUser(profile);
              setLoading(false);
            })
            .catch(error => {
              setLoading(false);
            });
        } else {
          setLoading(false);
        }
      } catch (error) {
        setLoading(false);
      }
    };
    getInitialSession();
  }, []);

  // Optimized auth state listener
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' && session?.user) {
        setSession(session);
        sessionStorage.setItem('supabase_session', 'true');
        
        // Load profile asynchronously
        loadUserProfile(session.user)
          .then(profile => setUser(profile))
          .catch(error => {});
      } else if (event === 'SIGNED_OUT') {
        setSession(null);
        setUser(null);
        sessionStorage.removeItem('supabase_session');
        // Clear profile cache
        Object.keys(sessionStorage).forEach(key => {
          if (key.startsWith('profile_')) {
            sessionStorage.removeItem(key);
          }
        });
      }
      
      setLoading(false);
    });
    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const login = async (identifier, password, role = null, method = null) => {
    
    try {
      let userProfile;
      
      if (role === 'customer') {
        // Customer login with Card No
        userProfile = await authService.loginWithCardNo(identifier, password);
      } else if (role === 'promoter') {
        // Promoter login - ONLY Promoter ID method
        userProfile = await authService.loginWithPromoterID(identifier, password);
      } else {
        // Admin login with email
        userProfile = await authService.login(identifier, password);
      }
      
      // For customer/promoter logins using local sessions, manually set user state
      // (Admin logins use Supabase Auth and are handled by auth state listener)
      if (role === 'customer' || role === 'promoter') {
        setUser(userProfile);
        setSession(authService.getCurrentSession());
      }
      
      
      // User state will be updated by the auth state change listener
      return userProfile;
      
    } catch (error) {
      throw error;
    }
  };

  const logout = async () => {
    try {
      await supabase.auth.signOut();
      setUser(null);
      setSession(null);
      
      // Clear all cached data
      sessionStorage.removeItem('supabase_session');
      Object.keys(sessionStorage).forEach(key => {
        if (key.startsWith('profile_')) {
          sessionStorage.removeItem(key);
        }
      });
      
    } catch (error) {
    }
  };

  const value = {
    user,
    loading,
    session,
    login,
    logout
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export default AuthContext;
