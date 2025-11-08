import React, { useState, useEffect, useCallback, useMemo, memo } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import { useNavigate } from 'react-router-dom';
import AdminNavbar from '../components/AdminNavbar';
import { 
  UnifiedBackground, 
  UnifiedCard,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { supabase } from "../../common/services/supabaseClient"
import { 
  Users, 
  UserCheck, 
  Target, 
  CreditCard,
  AlertCircle,
  Pin
} from 'lucide-react';
import { 
  SkeletonStats, 
  SkeletonManagementGrid
} from '../components/skeletons';
import { useToast } from '../services/toastService';

// Optimized dashboard card component with better space utilization
const DashboardCard = memo(({ card, index, onClick }) => {
  const IconComponent = card.icon;
  return (
    <UnifiedCard 
      key={index}
      className="group relative overflow-hidden p-4 cursor-pointer hover:shadow-lg transition-all duration-300 border border-slate-200/10 hover:border-orange-400/30 bg-white/5 backdrop-blur-sm hover:bg-white/10 h-full"
      onClick={() => onClick(card.route)}
    >
      <div className="relative h-full flex flex-col">
        <div className="flex items-center justify-between mb-3">
          <div className={`w-12 h-12 bg-gradient-to-br ${card.color} rounded-xl flex items-center justify-center shadow-lg group-hover:shadow-xl transition-all duration-300`}>
            <IconComponent className="w-6 h-6 text-white" />
          </div>
          <div className="text-right">
            <p className="text-2xl font-bold text-white leading-none">{card.value}</p>
          </div>
        </div>
        <div className="flex-1">
          <h3 className="text-sm font-semibold text-slate-200 mb-1">{card.title}</h3>
          <p className="text-slate-400 text-xs leading-relaxed">{card.description}</p>
        </div>
      </div>
      <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-orange-400/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
    </UnifiedCard>
  );
});

// Compact management grid component for single screen layout
const ManagementGrid = memo(({ onNavigate }) => {
  const managementItems = useMemo(() => [
    {
      title: 'Promoters',
      description: 'Manage promoter accounts',
      icon: Users,
      color: 'from-orange-500 to-orange-600',
      route: '/admin/promoters'
    },
    {
      title: 'Customers',
      description: 'View customer profiles',
      icon: UserCheck,
      color: 'from-yellow-500 to-yellow-600',
      route: '/admin/customers'
    },
    {
      title: 'Pin Management',
      description: 'Handle pin requests',
      icon: Pin,
      color: 'from-purple-500 to-purple-600',
      route: '/admin/pins'
    },
    {
      title: 'Withdrawals',
      description: 'Process withdrawals',
      icon: CreditCard,
      color: 'from-rose-500 to-rose-600',
      route: '/admin/withdrawals'
    }
  ], []);

  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
      {managementItems.map((item, index) => {
        const IconComponent = item.icon;
        return (
          <div 
            key={index} 
            className="group relative overflow-hidden p-5 cursor-pointer hover:shadow-lg transition-all duration-300 border border-slate-200/10 hover:border-orange-400/30 bg-white/5 backdrop-blur-sm hover:bg-white/10 h-full rounded-xl"
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              onNavigate(item.route);
            }}
            role="button"
            tabIndex={0}
            onKeyPress={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                onNavigate(item.route);
              }
            }}
          >
            <div className="relative text-center space-y-4 h-full flex flex-col">
              <div className={`w-14 h-14 bg-gradient-to-br ${item.color} rounded-xl flex items-center justify-center mx-auto shadow-lg group-hover:shadow-xl transition-all duration-300`}>
                <IconComponent className="w-7 h-7 text-white" />
              </div>
              <div className="space-y-2 flex-1">
                <h3 className="text-base font-semibold text-white">{item.title}</h3>
                <p className="text-slate-400 text-sm leading-relaxed">{item.description}</p>
              </div>
            </div>
            <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-slate-400/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
          </div>
        );
      })}
    </div>
  );
});

function AdminDashboard() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const { showError, showInfo, handleApiError } = useToast();
  
  // Simplified state management
  const [dashboardStats, setDashboardStats] = useState({
    promoters: 0,
    customers: 0,
    systemHealth: 'good'
  });
  
  const [dashboardLoading, setDashboardLoading] = useState(true);
  const [dataLoaded, setDataLoaded] = useState(false);
  const [error, setError] = useState(null);
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [missingTables, setMissingTables] = useState([]);
  const [showSetupGuide, setShowSetupGuide] = useState(false);
  
  useScrollAnimation();

  // Optimized data loading function with better error handling and caching
  const loadDashboardData = useCallback(async (showLoadingState = true) => {
    try {
      if (showLoadingState) {
        setDashboardLoading(true);
        setError(null);
      }
      
      const startTime = Date.now();
      
      // Optimized queries with minimal data selection for better performance
      const [promotersResult, customersResult] = await Promise.all([
        supabase
          .from('profiles')
          .select('*', { count: 'exact', head: true })
          .eq('role', 'promoter'),
        supabase
          .from('profiles')
          .select('*', { count: 'exact', head: true })
          .eq('role', 'customer')
      ]);
      
      const loadTime = Date.now() - startTime;
      
      // Handle errors first
      if (promotersResult.error) {
        throw new Error(`Failed to load promoters: ${promotersResult.error.message}`);
      }
      if (customersResult.error) {
        throw new Error(`Failed to load customers: ${customersResult.error.message}`);
      }
      
      const promotersCount = promotersResult.count || 0;
      const customersCount = customersResult.count || 0;
      
      const newStats = {
        promoters: promotersCount,
        customers: customersCount,
        systemHealth: 'good',
        lastUpdated: new Date().toISOString()
      };
      
      // Dashboard stats loaded successfully
      
      // Update state in batch
      setDashboardStats(newStats);
      setDataLoaded(true);
      setError(null);
      
      // Data loaded successfully - no toast needed for automatic loading
      
    } catch (error) {
      setError(error.message || 'Failed to load dashboard data');
      setDataLoaded(false); // Reset data loaded state on error
      handleApiError(error, 'Failed to load dashboard data. Retrying automatically...');
      
      // Auto-retry after 3 seconds on error
      setTimeout(() => {
        if (user) {
          // Auto-retrying data load
          loadDashboardData(false);
        }
      }, 3000);
    } finally {
      if (showLoadingState) {
        setDashboardLoading(false);
      }
    }
  }, [handleApiError]);
  
  // Single data loading effect - simplified to prevent infinite loops
  useEffect(() => {
    if (user && !dataLoaded) {
      // Loading dashboard data for authenticated user
      setError(null); // Clear any previous errors
      loadDashboardData(true);
    }
  }, [user, dataLoaded]); // Removed loadDashboardData from dependencies
  
  // Optimized auto-refresh with better performance
  useEffect(() => {
    if (!autoRefresh || !user || !dataLoaded) return;
    
    // Setting up auto-refresh
    const interval = setInterval(() => {
      // Auto-refreshing dashboard data
      loadDashboardData(false); // Background refresh without loading state
    }, 60000); // Refresh every 60 seconds
    
    return () => {
      // Clearing auto-refresh interval
      clearInterval(interval);
    };
  }, [autoRefresh, user, dataLoaded]); // Removed loadDashboardData from dependencies

  const handleLogout = useCallback(() => {
    logout();
    navigate('/login');
  }, [logout, navigate]);
  

  // Professional overview cards with enhanced descriptions
  const overviewCards = useMemo(() => [
    {
      title: 'Total Promoters',
      value: dashboardStats.promoters,
      icon: Users,
      color: 'from-orange-500 to-orange-600',
      route: '/admin/promoters',
      description: 'Active promoters managing customer relationships and driving growth'
    },
    {
      title: 'Total Customers',
      value: dashboardStats.customers,
      icon: UserCheck,
      color: 'from-yellow-500 to-yellow-600',
      route: '/admin/customers',
      description: 'Registered customers with active investment portfolios'
    }
  ], [dashboardStats]);

  const handleCardClick = useCallback((route) => {
    navigate(route);
  }, [navigate]);

  const handleNavigate = useCallback((route) => {
    navigate(route);
  }, [navigate]);

  // Background refresh handlers removed - auto-refresh works automatically

  return (
    <>
      <SharedStyles />
      <AdminNavbar />
      <UnifiedBackground>
        <div className="min-h-screen overflow-auto pt-40">

          {/* Compact Header Section */}
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-slate-900/50 via-transparent to-slate-800/30"></div>
            <div className="relative max-w-7xl mx-auto px-6 py-6">
              
              {/* Compact Dashboard Header */}
              <div className="text-center mb-6">
                <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-orange-500 to-orange-600 rounded-2xl mb-4 shadow-xl">
                  <Target className="w-8 h-8 text-white" />
                </div>
                <h1 className="text-3xl font-bold text-white mb-2 tracking-tight">
                  Admin Dashboard
                </h1>
                <p className="text-base text-slate-300 max-w-xl mx-auto">
                  Welcome back, <span className="text-orange-400 font-semibold">{user?.name || 'Administrator'}</span>
                </p>
              </div>

              {/* Error Display */}
              {error && (
                <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-lg">
                  <div className="flex items-center space-x-2 text-red-400">
                    <AlertCircle className="w-5 h-5" />
                    <span className="font-medium">Error loading dashboard data</span>
                  </div>
                  <p className="text-red-300 mt-1 text-sm">{error}</p>
                  <button
                    onClick={() => {
                      setError(null);
                      loadDashboardData(true);
                    }}
                    className="mt-3 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm transition-colors"
                  >
                    Retry Loading
                  </button>
                </div>
              )}

              {/* Optimized Full-Width Layout */}
              <div className="space-y-6">
                
                {/* Platform Overview - Full width with horizontal cards */}
                <div>
                  <div className="mb-4">
                    <h2 className="text-xl font-bold text-white">Platform Overview</h2>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {dashboardLoading && !dataLoaded ? (
                      // Branded skeleton loader for overview cards
                      <SkeletonStats count={2} />
                    ) : overviewCards && overviewCards.length > 0 ? (
                      // Show data when available
                      overviewCards.map((card, index) => (
                        <DashboardCard 
                          key={index}
                          card={card}
                          index={index}
                          onClick={handleCardClick}
                        />
                      ))
                    ) : (
                      // Show error state if no data and not loading
                      <div className="col-span-2 text-center py-8">
                        <div className="text-slate-400 mb-4">No data available</div>
                        <button 
                          onClick={() => loadDashboardData(true)}
                          className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors"
                        >
                          Retry Loading
                        </button>
                      </div>
                    )}
                  </div>
                </div>

                {/* Management Tools - Full width grid */}
                <div>
                  <div className="mb-4">
                    <h2 className="text-xl font-bold text-white mb-1">Management Tools</h2>
                    <p className="text-slate-400 text-sm">Access key administrative functions</p>
                  </div>
                  {dashboardLoading && !dataLoaded ? (
                    <SkeletonManagementGrid count={4} />
                  ) : (
                    <ManagementGrid onNavigate={handleNavigate} />
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </UnifiedBackground>
    </>
  );
}

export default AdminDashboard;
