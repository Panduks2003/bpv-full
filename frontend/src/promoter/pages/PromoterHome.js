import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from "../../common/context/AuthContext";
import { useUnifiedToast } from "../../common/services/unifiedToastService";
import PromoterNavbar from '../components/PromoterNavbar';
import UnifiedPromoterForm from '../../components/UnifiedPromoterForm';
import UnifiedCustomerForm from '../../common/components/UnifiedCustomerForm';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { SkeletonFullPage } from '../components/skeletons';
import { db, supabase } from "../../common/services/supabaseClient"
import logger from '../../common/utils/logger';
import commissionService from '../../services/commissionService';
import { 
  Users, 
  Award,
  Gift,
  CreditCard,
  UserPlus,
  Plus,
  DollarSign,
  Eye,
  EyeOff,
  RefreshCw
} from 'lucide-react';

function PromoterHome() {
  const { user, logout } = useAuth();
  const { showSuccess, showError } = useUnifiedToast();
  const navigate = useNavigate();
  useScrollAnimation();

  const [dashboardStats, setDashboardStats] = useState({
    totalCustomers: 0,
    totalPromoters: 0,
    currentLevel: 'Bronze',
    availablePins: 0
  });
  const [showCreatePromoter, setShowCreatePromoter] = useState(false);
  const [showCreateCustomer, setShowCreateCustomer] = useState(false);
  const [availablePins, setAvailablePins] = useState(0);
  const [loadingPins, setLoadingPins] = useState(true);
  
  useScrollAnimation();

  // Handle customer form submission using new pin-based system
  const handleCustomerSubmit = async (formData) => {
    try {
      // Check if promoter has sufficient pins before creating customer
      if (availablePins < 1) {
        throw new Error(`Insufficient pins to create customer. You need 1 pin but only have ${availablePins} pins available. Please request more pins from admin.`);
      }
      
      // Create new customer using the same function as admin
      const { data: result, error } = await supabase.rpc('create_customer_final', {
        p_name: formData.name,
        p_mobile: formData.mobile,
        p_state: formData.state,
        p_city: formData.city,
        p_pincode: formData.pincode,
        p_address: formData.address,
        p_customer_id: formData.cardNo,
        p_password: formData.password,
        p_parent_promoter_id: user?.id, // Current promoter as parent
        p_email: formData.email || null
      });
      
      if (error || !result?.success) {
        throw new Error(result?.error || error?.message || 'Failed to create customer');
      }
      
      // Show clean success message using unified toast (same as admin)
      showSuccess(
        `Customer created successfully and is ready to use.\n\nCustomer ID: ${formData.cardNo}\nName: ${formData.name}\nLogin: Use Customer ID + Password`
      );
      
      // Update local pin count
      setAvailablePins(prev => prev - 1);

      // Reload dashboard data and close modal
      await loadDashboardData();
      
      // Force a small delay to ensure database changes are reflected
      setTimeout(async () => {
        await loadDashboardData();
      }, 1000);
      
      setShowCreateCustomer(false);
      
    } catch (error) {
      showError(`Failed to create customer: ${error.message}`);
    }
  };

  const loadDashboardData = useCallback(async () => {
    const startTime = performance.now();
    try {
      logger.info('Loading dashboard data', { userId: user?.id });
      
      // Load real data from Supabase - force fresh data by querying directly
      const [customersResult, promoterResult, allPromotersResult] = await Promise.all([
        supabase.from('profiles').select('id, name, customer_id, parent_promoter_id, created_at').eq('role', 'customer'),
        supabase.from('profiles').select('*').eq('id', user?.id).eq('role', 'promoter').single(),
        supabase.from('profiles').select('*').eq('role', 'promoter').eq('parent_promoter_id', user?.id)
      ]);

      logger.debug('Dashboard data loaded', {
        userId: user?.id,
        customersCount: customersResult?.data?.length || 0,
        promotersCount: allPromotersResult?.data?.length || 0,
        hasPromoterData: !!promoterResult?.data
      });
      
      // Handle errors
      if (customersResult.error) {
        logger.error('Error loading customers', { error: customersResult.error, userId: user?.id });
      }

      if (promoterResult.error) {
        logger.error('Error loading promoter data', { error: promoterResult.error, userId: user?.id });
      }

      // Filter customers that belong to this promoter
      const myCustomers = (customersResult.data || []).filter(customer => {
        return customer?.parent_promoter_id === user?.id;
      });

      // Calculate real stats from actual data
      const totalCustomers = myCustomers.length;
      const totalPromoters = allPromotersResult.data?.length || 0;
      
      // Get promoter level from profile or default to Bronze
      const promoterProfile = promoterResult.data;
      const currentLevel = promoterProfile?.business_category || 'Bronze';
      const availablePins = promoterProfile?.pins || 0;
      
      const stats = {
        totalCustomers,
        totalPromoters,
        currentLevel,
        availablePins
      };

      setDashboardStats(stats);
      setAvailablePins(availablePins);
      
      const endTime = performance.now();
      logger.performance('Dashboard data load', endTime - startTime);
      logger.dataLoad('Dashboard', totalCustomers + totalPromoters, endTime - startTime);
    } catch (error) {
      logger.error('Error loading dashboard data', { error: error.message, userId: user?.id });
      showError('Failed to load dashboard data. Please refresh the page.');
    } finally {
      setLoadingPins(false);
    }
  }, [user?.id]);

  // Load dashboard data on component mount
  useEffect(() => {
    if (user?.id) {
      loadDashboardData();
    }
  }, [user, loadDashboardData]);


  const handleCreatePromoter = () => {
    setShowCreatePromoter(true);
  };

  const handleCreateCustomer = () => {
    setShowCreateCustomer(true);
  };

  const handleCardClick = (route) => {
    navigate(route);
  };

  const overviewCards = [
    {
      title: 'Total Customers',
      value: dashboardStats.totalCustomers,
      description: 'Active customers',
      icon: Users,
      color: 'from-blue-500 to-blue-600',
      route: '/promoter/my-customers'
    },
    {
      title: 'My Promoters',
      value: dashboardStats.totalPromoters,
      description: 'Direct promoters',
      icon: Award,
      color: 'from-purple-500 to-purple-600',
      route: '/promoter/my-promoters'
    },
    {
      title: 'Available Pins',
      value: availablePins,
      description: loadingPins ? 'Loading...' : (availablePins === 0 ? 'No pins available' : 'Ready to use'),
      icon: Gift,
      color: availablePins > 0 ? 'from-orange-500 to-orange-600' : 'from-red-500 to-red-600',
      route: '/promoter/pin-management'
    }
  ];

  // Show skeleton while loading
  if (loadingPins) {
    return (
      <>
        <SharedStyles />
        <PromoterNavbar />
        <UnifiedBackground>
          <SkeletonFullPage type="dashboard" />
        </UnifiedBackground>
      </>
    );
  }

  return (
    <>
      <SharedStyles />
      <PromoterNavbar />
      <UnifiedBackground>
        <div>
          {/* Main Content */}
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-orange-500/5 via-transparent to-yellow-500/5"></div>
            <div className="relative max-w-6xl mx-auto px-6 pt-40 pb-12">
              {/* Clean Welcome Section */}
              <div className="text-center mb-6" data-animate>
                <div className="flex items-center justify-center gap-4 mb-2">
                  <h1 className="text-3xl md:text-4xl font-bold text-white">
                    Welcome, <span className="text-transparent bg-clip-text bg-gradient-to-r from-orange-400 to-yellow-400">{user?.name || 'Promoter'}</span>
                  </h1>
                  <button
                    onClick={loadDashboardData}
                    className="p-2 bg-orange-500/20 hover:bg-orange-500/30 rounded-lg transition-colors"
                    title="Refresh dashboard data"
                  >
                    <RefreshCw className="w-5 h-5 text-orange-400" />
                  </button>
                </div>
                <p className="text-gray-300 mb-6">Manage your network and grow your business</p>
                
                {/* Action Buttons */}
                <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                  <button
                    onClick={handleCreatePromoter}
                    className="w-full sm:w-auto inline-flex items-center justify-center px-6 py-3 bg-gradient-to-r from-orange-500 to-yellow-500 text-white font-semibold rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105"
                  >
                    <UserPlus className="w-5 h-5 mr-2" />
                    Create Promoter
                  </button>
                  <button
                    onClick={handleCreateCustomer}
                    disabled={availablePins <= 0}
                    className={`w-full sm:w-auto inline-flex items-center justify-center px-6 py-3 text-white font-semibold rounded-lg shadow-lg transition-all duration-300 ${
                      availablePins <= 0 
                        ? 'bg-gray-500 cursor-not-allowed opacity-50' 
                        : 'bg-gradient-to-r from-green-500 to-green-600 hover:shadow-xl hover:scale-105'
                    }`}
                    title={availablePins <= 0 ? "No pins available - Request pins from admin" : `Create New Customer (${availablePins} pins available)`}
                  >
                    <Plus className="w-5 h-5 mr-2" />
                    Create Customer
                    {availablePins > 0 && (
                      <span className="ml-2 bg-white/20 px-2 py-1 rounded-full text-xs">
                        {availablePins} pins
                      </span>
                    )}
                  </button>
                </div>
              </div>

              {/* Stats Overview */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                {overviewCards.map((card, index) => {
                  const IconComponent = card.icon;
                  return (
                    <UnifiedCard 
                      key={index}
                      className="group relative overflow-hidden p-6 cursor-pointer hover:scale-[1.02] transition-all duration-300 border border-slate-700/50 hover:border-orange-400/50 bg-gradient-to-br from-slate-800/90 to-slate-900/90"
                      onClick={() => handleCardClick(card.route)}
                    >
                      <div className="relative flex items-center space-x-4">
                        <div className={`w-12 h-12 bg-gradient-to-r ${card.color} rounded-lg flex items-center justify-center shadow-lg`}>
                          <IconComponent className="w-6 h-6 text-white" />
                        </div>
                        <div className="flex-1">
                          <h3 className="text-lg font-semibold text-white mb-1">{card.title}</h3>
                          <p className="text-2xl font-bold text-white">{card.value}</p>
                          <p className="text-slate-400 text-sm">{card.description}</p>
                        </div>
                      </div>
                    </UnifiedCard>
                  );
                })}
              </div>

              {/* Quick Actions Grid */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div 
                  className="group cursor-pointer hover:scale-105 transition-all duration-300 border border-slate-700/50 hover:border-blue-400/50 bg-gradient-to-br from-slate-800/90 to-slate-900/90 p-4 rounded-xl"
                  onClick={() => navigate('/promoter/my-customers')}
                >
                  <div className="text-center">
                    <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg flex items-center justify-center mx-auto mb-3">
                      <Users className="w-6 h-6 text-white" />
                    </div>
                    <h3 className="text-sm font-semibold text-white mb-1">My Customers</h3>
                    <p className="text-slate-400 text-xs">Manage customers</p>
                  </div>
                </div>

                <div 
                  className="group cursor-pointer hover:scale-105 transition-all duration-300 border border-slate-700/50 hover:border-purple-400/50 bg-gradient-to-br from-slate-800/90 to-slate-900/90 p-4 rounded-xl"
                  onClick={() => navigate('/promoter/my-promoters')}
                >
                  <div className="text-center">
                    <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg flex items-center justify-center mx-auto mb-3">
                      <Award className="w-6 h-6 text-white" />
                    </div>
                    <h3 className="text-sm font-semibold text-white mb-1">My Promoters</h3>
                    <p className="text-slate-400 text-xs">View network</p>
                  </div>
                </div>

                <div 
                  className="group cursor-pointer hover:scale-105 transition-all duration-300 border border-slate-700/50 hover:border-orange-400/50 bg-gradient-to-br from-slate-800/90 to-slate-900/90 p-4 rounded-xl"
                  onClick={() => navigate('/promoter/pin-management')}
                >
                  <div className="text-center">
                    <div className={`w-12 h-12 bg-gradient-to-r ${availablePins > 0 ? 'from-orange-500 to-orange-600' : 'from-red-500 to-red-600'} rounded-lg flex items-center justify-center mx-auto mb-3`}>
                      <Gift className="w-6 h-6 text-white" />
                    </div>
                    <h3 className="text-sm font-semibold text-white mb-1">Pin Management</h3>
                    <p className="text-slate-400 text-xs">Manage pins</p>
                  </div>
                </div>

                <div 
                  className="group cursor-pointer hover:scale-105 transition-all duration-300 border border-slate-700/50 hover:border-green-400/50 bg-gradient-to-br from-slate-800/90 to-slate-900/90 p-4 rounded-xl"
                  onClick={() => navigate('/promoter/withdrawal-request')}
                >
                  <div className="text-center">
                    <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-green-600 rounded-lg flex items-center justify-center mx-auto mb-3">
                      <CreditCard className="w-6 h-6 text-white" />
                    </div>
                    <h3 className="text-sm font-semibold text-white mb-1">Withdrawals</h3>
                    <p className="text-slate-400 text-xs">Request withdrawal</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Create Promoter Modal */}
        {showCreatePromoter && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <UnifiedPromoterForm
              isOpen={showCreatePromoter}
              onClose={() => setShowCreatePromoter(false)}
              onSubmit={async (formData) => {
                try {
                  
                  // Validate required fields
                  if (!formData.name || formData.name.trim() === '') {
                    throw new Error('Name is required for promoter creation.');
                  }
                  
                  if (!formData.password || formData.password.trim() === '') {
                    throw new Error('Password is required for promoter creation.');
                  }
                  
                  if (!formData.phone || formData.phone.trim() === '') {
                    throw new Error('Phone number is required for promoter creation.');
                  }
                  
                  // Step 1: Generate unique auth email
                  const timestamp = Date.now();
                  const randomNum = Math.floor(Math.random() * 1000000);
                  let authEmail = `promo${timestamp}${randomNum}@brightplanet.com`;
                  
                  // Step 2: Create auth user via backend service to avoid auth state changes
                  
                  let authData, authError;
                  
                  try {
                    // Try to create user via backend service first (if available)
                    const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';
                    const backendResponse = await fetch(`${API_URL}/create-promoter-auth`, {
                      method: 'POST',
                      headers: { 'Content-Type': 'application/json' },
                      body: JSON.stringify({
                        email: authEmail,
                        password: formData.password,
                        userData: {
                          role: 'promoter',
                          name: formData.name,
                          phone: formData.phone
                        }
                      })
                    });
                    
                    if (backendResponse.ok) {
                      const result = await backendResponse.json();
                      authData = { user: result.user };
                    } else {
                      throw new Error('Backend service not available');
                    }
                    
                  } catch (backendError) {
                    
                    // Fallback to direct signUp
                    const signUpResult = await supabase.auth.signUp({
                      email: authEmail,
                      password: formData.password,
                      options: {
                        emailRedirectTo: undefined,
                        data: {
                          role: 'promoter',
                          name: formData.name,
                          phone: formData.phone
                        }
                      }
                    });
                    
                    authData = signUpResult.data;
                    authError = signUpResult.error;
                  }
                  
                  if (authError) {
                    console.error('❌ Auth creation error:', authError);
                    if (authError.message?.includes('already registered')) {
                      throw new Error(`Email ${authEmail} is already registered. Please try again.`);
                    }
                    throw new Error('Failed to create auth user: ' + authError.message);
                  }
                  
                  if (!authData.user) {
                    throw new Error('Failed to create auth user: No user data returned');
                  }
                  
                  // Step 2b: Manually confirm the email in database (like admin does)
                  const { error: confirmError } = await supabase.rpc('confirm_promoter_email', {
                    p_user_id: authData.user.id
                  });
                  
                  if (confirmError) {
                    // Continue anyway - this is not critical for promoter creation
                  }
                  
                  // Step 3: Create promoter profile in database
                  const { data: result, error } = await supabase.rpc('create_promoter_with_auth_id', {
                    p_name: formData.name.trim(),
                    p_user_id: authData.user.id,
                    p_auth_email: authEmail,
                    p_password: formData.password.trim(),
                    p_phone: formData.phone.trim(),
                    p_email: formData.email && formData.email.trim() ? formData.email.trim() : null,
                    p_address: formData.address && formData.address.trim() ? formData.address.trim() : null,
                    p_parent_promoter_id: user.id, // Current promoter as parent
                    p_role_level: 'Affiliate',
                    p_status: 'Active'
                  });
                  
                  if (error) {
                    throw error;
                  }
                  
                  if (!result || !result.success) {
                    throw new Error(result?.error || 'Failed to create promoter profile');
                  }
                  
                  // Show clean success message
                  showSuccess(`Promoter created successfully and is ready to use.\n\nPromoter ID: ${result.promoter_id}\nName: ${result.name}\nLogin: Use Promoter ID + Password`);
                  
                  // Reload dashboard data and close modal
                  await loadDashboardData();
                  setShowCreatePromoter(false);
                  
                } catch (error) {
                  showError(`Failed to create promoter: ${error.message}`);
                }
              }}
              promoters={[{
                id: user.id,
                name: user.name || 'Current Promoter',
                promoter_id: user.promoter_id || 'CURRENT',
                isCurrentUser: true
              }]} // Current promoter as default parent
              adminUsers={[]} // No admin users in promoter context
            />
          </div>
        )}

        {/* Create Customer Modal - Using UnifiedCustomerForm */}
        <UnifiedCustomerForm
          isOpen={showCreateCustomer}
          onClose={() => setShowCreateCustomer(false)}
          onSubmit={handleCustomerSubmit}
          promoters={[{
            id: user?.id,
            name: user?.name || 'Current Promoter',
            promoter_id: user?.promoter_id || 'CURRENT',
            role: 'promoter'
          }]} // Current promoter as the only option
          isEditing={false}
          initialData={{
            parentPromoter: user?.id // Pre-select current promoter
          }}
        />


      </UnifiedBackground>
    </>
  );
}

export default PromoterHome;
