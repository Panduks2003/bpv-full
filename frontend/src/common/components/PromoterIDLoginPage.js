import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Leaf, Eye, EyeOff, User, Lock, AlertCircle, CheckCircle } from 'lucide-react';

/**
 * PromoterIDLoginPage - New Promoter ID-centric login system
 * 
 * Features:
 * - Primary login method: Promoter ID + Password
 * - Clean, focused UI for Promoter ID authentication
 * - Fallback options for email login (admins/customers)
 * - Real-time validation and user feedback
 * - Responsive design with modern UI
 */

export default function PromoterIDLoginPage() {
  const [loginData, setLoginData] = useState({
    identifier: '',
    password: '',
    loginMethod: 'promoter_id' // Default to Promoter ID
  });
  
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  const navigate = useNavigate();
  const { login } = useAuth();

  // Handle input changes with real-time validation
  const handleInputChange = (field, value) => {
    setLoginData(prev => ({ ...prev, [field]: value }));
    
    // Clear errors when user starts typing
    if (error) setError('');
    if (success) setSuccess('');
    
    // Real-time Promoter ID format validation
    if (field === 'identifier' && loginData.loginMethod === 'promoter_id') {
      if (value && !/^BPVP\d*$/i.test(value)) {
        setError('Promoter ID should start with BPVP followed by numbers (e.g., BPVP01)');
      } else {
        setError('');
      }
    }
  };

  // Handle login method change
  const handleMethodChange = (method) => {
    setLoginData(prev => ({ 
      ...prev, 
      loginMethod: method,
      identifier: '' // Clear identifier when switching methods
    }));
    setError('');
    setSuccess('');
  };

  // Handle form submission
  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const { identifier, password, loginMethod } = loginData;

      // Input validation
      if (!identifier.trim() || !password.trim()) {
        throw new Error('Please provide both identifier and password');
      }

      // Method-specific validation
      if (loginMethod === 'promoter_id') {
        if (!/^BPVP\d+$/i.test(identifier)) {
          throw new Error('Please enter a valid Promoter ID (e.g., BPVP01, BPVP02)');
        }
      } else if (loginMethod === 'email') {
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier)) {
          throw new Error('Please enter a valid email address');
        }
      }

      console.log(`🔐 Attempting ${loginMethod} login for:`, identifier);

      // Determine role and method for AuthContext
      let role = null;
      let method = null;

      if (loginMethod === 'promoter_id') {
        role = 'promoter';
        method = 'promoter_id';
      } else if (loginMethod === 'email') {
        // Determine role based on email domain or let backend handle it
        if (identifier.includes('admin')) {
          role = 'admin';
        } else {
          role = null; // Let backend determine
        }
        method = 'email';
      }

      // Attempt login
      const userProfile = await login(identifier, password, role, method);

      if (userProfile) {
        setSuccess(`Welcome back, ${userProfile.name}!`);
        
        // Redirect based on role
        setTimeout(() => {
          if (userProfile.role === 'admin') {
            navigate('/admin/dashboard');
          } else if (userProfile.role === 'promoter') {
            navigate('/promoter/dashboard');
          } else if (userProfile.role === 'customer') {
            navigate('/customer');
          } else {
            navigate('/dashboard');
          }
        }, 1000);
      }

    } catch (err) {
      console.error('Login error:', err);
      setError(err.message || 'Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  // Get placeholder text based on login method
  const getPlaceholder = () => {
    switch (loginData.loginMethod) {
      case 'promoter_id':
        return 'Enter your Promoter ID (e.g., BPVP01)';
      case 'email':
        return 'Enter your email address';
      default:
        return 'Enter identifier';
    }
  };

  // Get input type based on login method
  const getInputType = () => {
    return loginData.loginMethod === 'email' ? 'email' : 'text';
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 to-red-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        {/* Header */}
        <div className="text-center">
          <div className="flex justify-center mb-4">
            <div className="flex items-center">
              <Leaf className="h-12 w-12 text-orange-600" />
              <span className="ml-2 text-2xl font-bold text-gray-900">BrightPlanet</span>
            </div>
          </div>
          <h2 className="text-3xl font-extrabold text-gray-900">
            Welcome Back
          </h2>
          <p className="mt-2 text-sm text-gray-600">
            Sign in to your account using your Promoter ID
          </p>
        </div>

        {/* Login Method Selector */}
        <div className="bg-white rounded-lg p-1 shadow-sm border">
          <div className="grid grid-cols-2 gap-1">
            <button
              type="button"
              onClick={() => handleMethodChange('promoter_id')}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-all ${
                loginData.loginMethod === 'promoter_id'
                  ? 'bg-orange-600 text-white shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <User className="w-4 h-4 inline mr-2" />
              Promoter ID
            </button>
            <button
              type="button"
              onClick={() => handleMethodChange('email')}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-all ${
                loginData.loginMethod === 'email'
                  ? 'bg-orange-600 text-white shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              Email Login
            </button>
          </div>
        </div>

        {/* Login Form */}
        <form className="mt-8 space-y-6" onSubmit={handleLogin}>
          <div className="space-y-4">
            {/* Identifier Input */}
            <div>
              <label htmlFor="identifier" className="block text-sm font-medium text-gray-700 mb-1">
                {loginData.loginMethod === 'promoter_id' ? 'Promoter ID' : 'Email Address'}
              </label>
              <div className="relative">
                <input
                  id="identifier"
                  name="identifier"
                  type={getInputType()}
                  autoComplete={loginData.loginMethod === 'email' ? 'email' : 'username'}
                  required
                  className="relative block w-full px-4 py-3 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
                  placeholder={getPlaceholder()}
                  value={loginData.identifier}
                  onChange={(e) => handleInputChange('identifier', e.target.value.toUpperCase())}
                />
                {loginData.loginMethod === 'promoter_id' && (
                  <User className="absolute right-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                )}
              </div>
            </div>

            {/* Password Input */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
                Password
              </label>
              <div className="relative">
                <input
                  id="password"
                  name="password"
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  required
                  className="relative block w-full px-4 py-3 pr-12 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
                  placeholder="Enter your password"
                  value={loginData.password}
                  onChange={(e) => handleInputChange('password', e.target.value)}
                />
                <button
                  type="button"
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? (
                    <EyeOff className="h-5 w-5" />
                  ) : (
                    <Eye className="h-5 w-5" />
                  )}
                </button>
              </div>
            </div>
          </div>

          {/* Error Message */}
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start space-x-3">
              <AlertCircle className="h-5 w-5 text-red-400 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-red-600">{error}</div>
            </div>
          )}

          {/* Success Message */}
          {success && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-start space-x-3">
              <CheckCircle className="h-5 w-5 text-green-400 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-green-600">{success}</div>
            </div>
          )}

          {/* Forgot Password Link */}
          <div className="flex items-center justify-between">
            <div className="text-sm">
              <Link 
                to="/forgot-password" 
                className="font-medium text-orange-600 hover:text-orange-500 transition-colors"
              >
                Forgot your password?
              </Link>
            </div>
          </div>

          {/* Submit Button */}
          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-lg text-white bg-gradient-to-r from-orange-600 to-red-600 hover:from-orange-700 hover:to-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
            >
              {loading ? (
                <div className="flex items-center space-x-2">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  <span>Signing in...</span>
                </div>
              ) : (
                <div className="flex items-center space-x-2">
                  <Lock className="w-4 h-4" />
                  <span>Sign In</span>
                </div>
              )}
            </button>
          </div>

          {/* Help Text for Promoter ID */}
          {loginData.loginMethod === 'promoter_id' && (
            <div className="mt-4 p-4 bg-orange-50 border border-orange-200 rounded-lg">
              <h4 className="text-sm font-medium text-orange-800 mb-2">
                🎯 New Login System
              </h4>
              <ul className="text-xs text-orange-700 space-y-1">
                <li>• Use your Promoter ID (e.g., BPVP01, BPVP02) to login</li>
                <li>• This is now the primary and recommended login method</li>
                <li>• Your email and phone are stored for reference only</li>
                <li>• Contact support if you don't know your Promoter ID</li>
              </ul>
            </div>
          )}

          {/* Demo Accounts */}
          <div className="mt-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-300" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-orange-50 text-gray-500">Demo Accounts</span>
              </div>
            </div>
            <div className="mt-4 grid grid-cols-1 gap-2">
              <button
                type="button"
                onClick={() => {
                  setLoginData(prev => ({
                    ...prev,
                    identifier: 'admin@brightplanet.com',
                    password: 'admin123',
                    loginMethod: 'email'
                  }));
                }}
                className="w-full text-left px-3 py-2 border border-gray-300 rounded-md text-sm text-gray-700 hover:bg-gray-50 transition-colors"
              >
                <strong>Admin:</strong> admin@brightplanet.com
              </button>
              <button
                type="button"
                onClick={() => {
                  setLoginData(prev => ({
                    ...prev,
                    identifier: 'BPVP01',
                    password: 'promoter123',
                    loginMethod: 'promoter_id'
                  }));
                }}
                className="w-full text-left px-3 py-2 border border-orange-300 bg-orange-50 rounded-md text-sm text-orange-700 hover:bg-orange-100 transition-colors"
              >
                <strong>Promoter:</strong> BPVP01 (Promoter ID)
              </button>
            </div>
          </div>
        </form>

        {/* Footer */}
        <div className="text-center">
          <p className="text-xs text-gray-500">
            Need help? Contact support or check your Promoter ID with your admin.
          </p>
        </div>
      </div>
    </div>
  );
}
