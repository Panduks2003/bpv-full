import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { Eye, EyeOff, Mail, Lock, ArrowLeft } from "lucide-react";

const Login = () => {
  const [selectedRole, setSelectedRole] = useState(null);
  const [email, setEmail] = useState("");
  const [cardNo, setCardNo] = useState(""); // For customer login
  const [promoterID, setPromoterID] = useState(""); // For promoter login - ONLY method
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const { login } = useAuth();
  const navigate = useNavigate();

  const handleRoleSelect = (role) => {
    setSelectedRole(role);
    setError("");
  };

  const handleBackToRoleSelection = () => {
    setSelectedRole(null);
    setEmail("");
    setCardNo("");
    setPromoterID("");
    setPassword("");
    setError("");
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      let user;
      
      // Use different login methods based on role
      if (selectedRole === 'customer') {
        // Customer login with Card No
        user = await login(cardNo, password, 'customer');
      } else if (selectedRole === 'promoter') {
        // Promoter login - ONLY Promoter ID
        user = await login(promoterID, password, 'promoter');
      } else {
        // Admin login with email
        user = await login(email, password, 'admin');
      }
      
      // Navigate based on user role
      
      switch (user.role) {
        case 'admin':
          navigate('/admin/dashboard');
          break;
        case 'promoter':
          navigate('/promoter/dashboard');
          break;
        case 'customer':
          navigate('/customer');
          break;
        default:
          navigate('/dashboard');
      }
      
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-yellow-50 to-orange-100 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo/Header */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-gradient-to-r from-orange-500 to-yellow-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <h1 
            className="text-2xl font-bold text-slate-900 mb-2 cursor-pointer hover:text-blue-600 transition-colors"
            onClick={() => handleRoleSelect('admin')}
            title="Click to login as Admin"
          >
            BrightPlanet Ventures
          </h1>
          <p className="text-slate-600">
            {selectedRole ? `Sign in as ${selectedRole.charAt(0).toUpperCase() + selectedRole.slice(1)}` : "Choose your role to continue"}
          </p>
        </div>

        <div className="bg-white/95 backdrop-blur-sm border border-slate-200 rounded-2xl p-8 shadow-xl">
          {!selectedRole ? (
            /* Role Selection */
            <div className="space-y-4">
              <h2 className="text-xl font-semibold text-slate-900 text-center mb-6">Welcome Back</h2>
              
              {/* Promoter Role */}
              <button
                onClick={() => handleRoleSelect('promoter')}
                className="w-full group relative overflow-hidden bg-gradient-to-r from-orange-500/10 to-yellow-500/10 hover:from-orange-500/20 hover:to-yellow-500/20 border border-orange-500/30 hover:border-orange-400/50 rounded-xl p-6 transition-all duration-300"
              >
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-gradient-to-r from-orange-500 to-yellow-500 rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                    <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  </div>
                  <div className="flex-1 text-left">
                    <h3 className="text-lg font-semibold text-slate-900 group-hover:text-orange-600 transition-colors">Promoter</h3>
                    <p className="text-slate-600 text-sm">Showcase ventures and connect with investors</p>
                  </div>
                  <svg className="w-5 h-5 text-slate-600 group-hover:text-orange-600 group-hover:translate-x-1 transition-all duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </div>
              </button>

              {/* Customer Role */}
              <button
                onClick={() => handleRoleSelect('customer')}
                className="w-full group relative overflow-hidden bg-gradient-to-r from-green-500/10 to-emerald-500/10 hover:from-green-500/20 hover:to-emerald-500/20 border border-green-500/30 hover:border-green-400/50 rounded-xl p-6 transition-all duration-300"
              >
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-emerald-500 rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                    <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                  <div className="flex-1 text-left">
                    <h3 className="text-lg font-semibold text-slate-900 group-hover:text-green-600 transition-colors">Customer</h3>
                    <p className="text-slate-600 text-sm">Explore sustainable solutions and savings</p>
                  </div>
                  <svg className="w-5 h-5 text-slate-600 group-hover:text-green-600 group-hover:translate-x-1 transition-all duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </div>
              </button>
            </div>
          ) : (
            /* Login Form */
            <div>
              {/* Back Button */}
              <button
                onClick={handleBackToRoleSelection}
                className="flex items-center text-slate-600 hover:text-slate-900 mb-6 transition-colors"
              >
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back to role selection
              </button>

              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Conditional Input Field */}
                {selectedRole === 'customer' ? (
                  /* Customer ID Field */
                  <div>
                    <label htmlFor="cardNo" className="block text-sm font-medium text-slate-700 mb-2">
                      Customer ID (Card No)
                    </label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400 w-5 h-5" />
                      <input
                        id="cardNo"
                        type="text"
                        value={cardNo}
                        onChange={(e) => setCardNo(e.target.value.toUpperCase())}
                        className="w-full pl-10 pr-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 transition-colors"
                        placeholder="Enter your Customer ID (Card No)"
                        required
                      />
                    </div>
                    <p className="text-xs text-slate-500 mt-1">
                      🎯 Use your Customer ID (Card No) to login.
                    </p>
                  </div>
                ) : selectedRole === 'promoter' ? (
                  /* Promoter Login - ONLY Promoter ID */
                  <div>
                    <label htmlFor="promoterID" className="block text-sm font-medium text-slate-700 mb-2">
                      Promoter ID
                    </label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400 w-5 h-5" />
                      <input
                        id="promoterID"
                        type="text"
                        value={promoterID}
                        onChange={(e) => setPromoterID(e.target.value.toUpperCase())}
                        className="w-full pl-10 pr-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors"
                        placeholder="Enter your Promoter ID (e.g., BPVP01)"
                        required
                      />
                    </div>
                    <p className="text-xs text-slate-500 mt-1">
                      🎯 Use your Promoter ID (e.g., BPVP01) to login.
                    </p>
                  </div>
                ) : (
                  /* Email Field for Admin */
                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-slate-700 mb-2">
                      Email Address
                    </label>
                    <div className="relative">
                      <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400 w-5 h-5" />
                      <input
                        id="email"
                        type="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        className="w-full pl-10 pr-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors"
                        placeholder="Enter your email"
                        required
                      />
                    </div>
                  </div>
                )}

                {/* Password Field */}
                <div>
                  <label htmlFor="password" className="block text-sm font-medium text-slate-700 mb-2">
                    Password
                  </label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400 w-5 h-5" />
                    <input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="w-full pl-10 pr-12 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors"
                      placeholder="Enter your password"
                      required
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 transform -translate-y-1/2 text-slate-400 hover:text-slate-600"
                    >
                      {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                    </button>
                  </div>
                </div>

                {/* Error Message */}
                {error && (
                  <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                    <p className="text-red-600 text-sm">{error}</p>
                  </div>
                )}

                {/* Submit Button */}
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-semibold py-3 px-4 rounded-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {loading ? (
                    <div className="flex items-center justify-center">
                      <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
                      Signing in...
                    </div>
                  ) : (
                    `Sign In as ${selectedRole.charAt(0).toUpperCase() + selectedRole.slice(1)}`
                  )}
                </button>
              </form>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Login;
