import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import { useUnifiedToast } from "../../common/services/unifiedToastService";
import { useNavigate } from 'react-router-dom';
import PromoterNavbar from '../components/PromoterNavbar';
import { SkeletonFullPage } from '../components/skeletons';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import commissionService, { COMMISSION_CONFIG } from '../../services/commissionService';
import supabase from '../../common/services/supabaseClient';
import { 
  Wallet, 
  DollarSign, 
  TrendingUp, 
  Award,
  Clock, 
  CheckCircle,
  XCircle,
  AlertCircle,
  Calendar,
  Filter,
  Download,
  RefreshCw,
  Users,
  Target,
  Gift
} from 'lucide-react';

function CommissionHistory() {
  const { user } = useAuth();
  const { showSuccess, showError } = useUnifiedToast();
  const navigate = useNavigate();
  useScrollAnimation();

  // State management
  const [loading, setLoading] = useState(true);
  const [commissionData, setCommissionData] = useState({
    promoter_id: user?.id,
    wallet_balance: 0,
    total_earned: 0,
    commission_count: 0,
    recent_commissions: []
  });
  const [customerNames, setCustomerNames] = useState({});
  const [customerIds, setCustomerIds] = useState({});
  const [filters, setFilters] = useState({
    level: '',
    status: '',
    dateFrom: '',
    dateTo: ''
  });


  // Fetch customer names and IDs
  const fetchCustomerData = async (customerIds) => {
    try {
      const custNames = {};
      const custIds = {};
      
      // Fetch customer names and IDs
      for (const customerId of customerIds) {
        // Get name and customer_id from profiles
        const { data: profileData, error } = await supabase
          .from('profiles')
          .select('name, customer_id, promoter_id')
          .eq('id', customerId)
          .single();
        
        if (profileData && !error) {
          custNames[customerId] = profileData.name;
          // Use customer_id if it exists, otherwise use promoter_id, otherwise truncated UUID
          custIds[customerId] = profileData.customer_id || profileData.promoter_id || (customerId.substring(0, 8) + '...');
        }
      }
      
      setCustomerNames(custNames);
      setCustomerIds(custIds);
    } catch (error) {
      // Error fetching customer data
    }
  };

  // Load commission data
  const loadCommissionData = async () => {
    try {
      setLoading(true);
      
      // Step 1: Check what's actually in the database for this user
      const { data: directCommissions, error: commissionError } = await supabase
        .from('affiliate_commissions')
        .select('*')
        .eq('recipient_id', user.id)
        .eq('status', 'credited');
      
      const directTotal = directCommissions?.reduce((sum, comm) => {
        const amount = parseFloat(comm.amount) || 0;
        return sum + amount;
      }, 0) || 0;
      
      // Step 2: Use direct calculation if we have data, otherwise try commission service
      let result;
      
      if (directCommissions && directCommissions.length > 0) {
        // Use the actual data from the direct query
        result = {
          success: true,
          data: {
            promoter_id: user.id,
            wallet_balance: directTotal,
            total_earned: directTotal,
            commission_count: directCommissions.length,
            recent_commissions: directCommissions
          }
        };
      } else {
        result = await commissionService.getPromoterCommissionSummary(user.id);
      }
      
      if (result.success) {
        // Parse the service data
        const serviceWalletBalance = parseFloat(result.data.wallet_balance) || 0;
        const serviceTotalEarned = parseFloat(result.data.total_earned) || 0;
        const serviceCommissionCount = parseInt(result.data.commission_count) || 0;
        
        // Ensure all numeric fields have default values
        const safeData = {
          promoter_id: result.data.promoter_id || user?.id,
          wallet_balance: serviceWalletBalance || directTotal,
          total_earned: serviceTotalEarned || directTotal,
          commission_count: serviceCommissionCount || (directCommissions?.length || 0),
          recent_commissions: result.data.recent_commissions || []
        };
        
        // If service returned zeros but we have direct data, use direct data
        if (safeData.total_earned === 0 && directTotal > 0) {
          safeData.wallet_balance = directTotal;
          safeData.total_earned = directTotal;
          safeData.commission_count = directCommissions?.length || 0;
        }
        
        setCommissionData(safeData);
        
        // Fetch customer names and IDs
        if (result.data.recent_commissions && result.data.recent_commissions.length > 0) {
          const customerIds = result.data.recent_commissions.map(c => c.customer_id).filter(Boolean);
          if (customerIds.length > 0) {
            await fetchCustomerData([...new Set(customerIds)]);
          }
        }
      } else {
        // Use direct calculation as complete fallback
        const fallbackData = {
          promoter_id: user?.id,
          wallet_balance: directTotal,
          total_earned: directTotal,
          commission_count: directCommissions?.length || 0,
          recent_commissions: directCommissions || []
        };
        setCommissionData(fallbackData);
      }
      
    } catch (error) {
      // Try to use direct calculation even if there's an error
      try {
        const { data: directCommissions } = await supabase
          .from('affiliate_commissions')
          .select('amount, status, level, created_at, customer_id')
          .eq('recipient_id', user.id)
          .eq('status', 'credited')
          .order('created_at', { ascending: false });
        
        const directTotal = directCommissions?.reduce((sum, comm) => sum + parseFloat(comm.amount), 0) || 0;
        
        if (directTotal > 0) {
          const emergencyData = {
            promoter_id: user?.id,
            wallet_balance: directTotal,
            total_earned: directTotal,
            commission_count: directCommissions?.length || 0,
            recent_commissions: directCommissions || []
          };
          setCommissionData(emergencyData);
        } else {
          showError('Failed to load commission data. Please try again.');
        }
      } catch (emergencyError) {
        showError('Failed to load commission data. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  // Load data on component mount
  useEffect(() => {
    if (user?.id) {
      loadCommissionData();
    }
  }, [user?.id]);

  // Handle refresh
  const handleRefresh = () => {
    loadCommissionData();
    showSuccess('Commission data refreshed successfully.');
  };

  // Get status icon and color
  const getStatusDisplay = (status) => {
    switch (status) {
      case 'credited':
        return { icon: CheckCircle, color: 'text-green-400', bg: 'bg-green-500/20', label: 'Credited' };
      case 'pending':
        return { icon: Clock, color: 'text-yellow-400', bg: 'bg-yellow-500/20', label: 'Pending' };
      case 'failed':
        return { icon: XCircle, color: 'text-red-400', bg: 'bg-red-500/20', label: 'Failed' };
      default:
        return { icon: AlertCircle, color: 'text-gray-400', bg: 'bg-gray-500/20', label: 'Unknown' };
    }
  };

  // Get level display
  const getLevelDisplay = (level) => {
    const config = COMMISSION_CONFIG.LEVELS[level];
    return config ? `Level ${level} - ${config.description}` : `Level ${level}`;
  };

  // Format currency
  const formatCurrency = (amount) => {
    const numAmount = parseFloat(amount) || 0;
    return `₹${numAmount.toLocaleString('en-IN')}`;
  };

  // Show loading skeleton
  if (loading) {
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
        <div className="min-h-screen pt-40 px-8 pb-8">
          <div className="max-w-7xl mx-auto">
            
            {/* Header */}
            <div className="flex justify-between items-center mb-8" data-animate>
              <div>
                <h1 className="text-4xl font-bold text-white mb-2">Commission History</h1>
                <p className="text-gray-300">Track your affiliate commission earnings</p>
              </div>
              <UnifiedButton
                onClick={handleRefresh}
                className="flex items-center space-x-2"
              >
                <RefreshCw className="w-5 h-5" />
                <span>Refresh</span>
              </UnifiedButton>
            </div>

            {/* Commission Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8" data-animate>
              
              {/* Wallet Balance */}
              <UnifiedCard className="p-6 bg-gradient-to-br from-green-500/10 to-emerald-500/10 border border-green-500/30 hover:border-green-400/50 transition-all duration-300">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-green-300 text-sm font-semibold uppercase tracking-wider">Wallet Balance</p>
                    <p className="text-3xl font-bold text-white mt-2">{formatCurrency(commissionData.wallet_balance)}</p>
                  </div>
                  <div className="w-12 h-12 bg-green-500/20 rounded-xl flex items-center justify-center">
                    <Wallet className="w-6 h-6 text-green-400" />
                  </div>
                </div>
                <div className="flex items-center mt-4 text-sm">
                  <div className="w-2 h-2 bg-green-400 rounded-full mr-2"></div>
                  <span className="text-green-300">Available for withdrawal</span>
                </div>
              </UnifiedCard>

              {/* Total Earned */}
              <UnifiedCard className="p-6 bg-gradient-to-br from-orange-500/10 to-yellow-500/10 border border-orange-500/30 hover:border-orange-400/50 transition-all duration-300">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-orange-300 text-sm font-semibold uppercase tracking-wider">Total Earned</p>
                    <p className="text-3xl font-bold text-white mt-2">{formatCurrency(commissionData.total_earned)}</p>
                  </div>
                  <div className="w-12 h-12 bg-orange-500/20 rounded-xl flex items-center justify-center">
                    <TrendingUp className="w-6 h-6 text-orange-400" />
                  </div>
                </div>
                <div className="flex items-center mt-4 text-sm">
                  <div className="w-2 h-2 bg-orange-400 rounded-full mr-2"></div>
                  <span className="text-orange-300">Lifetime earnings</span>
                </div>
              </UnifiedCard>

              {/* Commission Count */}
              <UnifiedCard className="p-6 bg-gradient-to-br from-purple-500/10 to-pink-500/10 border border-purple-500/30 hover:border-purple-400/50 transition-all duration-300">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-purple-300 text-sm font-semibold uppercase tracking-wider">Commissions</p>
                    <p className="text-3xl font-bold text-white mt-2">{commissionData.commission_count}</p>
                  </div>
                  <div className="w-12 h-12 bg-purple-500/20 rounded-xl flex items-center justify-center">
                    <Award className="w-6 h-6 text-purple-400" />
                  </div>
                </div>
                <div className="flex items-center mt-4 text-sm">
                  <div className="w-2 h-2 bg-purple-400 rounded-full mr-2"></div>
                  <span className="text-purple-300">Total received</span>
                </div>
              </UnifiedCard>

              {/* Average Commission */}
              <UnifiedCard className="p-6 bg-gradient-to-br from-blue-500/10 to-indigo-500/10 border border-blue-500/30 hover:border-blue-400/50 transition-all duration-300">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-blue-300 text-sm font-semibold uppercase tracking-wider">Average</p>
                    <p className="text-3xl font-bold text-white mt-2">
                      {formatCurrency(commissionData.commission_count > 0 ? commissionData.total_earned / commissionData.commission_count : 0)}
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-blue-500/20 rounded-xl flex items-center justify-center">
                    <Target className="w-6 h-6 text-blue-400" />
                  </div>
                </div>
                <div className="flex items-center mt-4 text-sm">
                  <div className="w-2 h-2 bg-blue-400 rounded-full mr-2"></div>
                  <span className="text-blue-300">Per commission</span>
                </div>
              </UnifiedCard>

            </div>

            {/* Commission History Table */}
            <UnifiedCard className="overflow-hidden" variant="glassDark" data-animate>
              <div className="p-6 border-b border-gray-700/50">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-2xl font-semibold text-white">Recent Commissions</h3>
                    <p className="text-gray-300 text-sm mt-1">
                      Your latest affiliate commission earnings
                    </p>
                  </div>
                  <div className="flex items-center space-x-3">
                    <UnifiedButton
                      onClick={() => navigate('/promoter/pin-management')}
                      className="flex items-center space-x-2 bg-gradient-to-r from-orange-500 to-yellow-500"
                    >
                      <Gift className="w-4 h-4" />
                      <span>PIN Management</span>
                    </UnifiedButton>
                  </div>
                </div>
              </div>
              
              <div className="overflow-x-auto">
                {commissionData.recent_commissions.length === 0 ? (
                  <div className="p-12 text-center">
                    <Award className="w-16 h-16 text-gray-500 mx-auto mb-4" />
                    <h3 className="text-xl font-semibold text-gray-400 mb-2">No Commissions Yet</h3>
                    <p className="text-gray-500">
                      Start building your network to earn affiliate commissions!
                    </p>
                  </div>
                ) : (
                  <table className="w-full">
                    <thead className="bg-gray-800/50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Level</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Customer</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Amount</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Note</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-700/50">
                      {commissionData.recent_commissions.map((commission) => {
                        const statusDisplay = getStatusDisplay(commission.status);
                        const StatusIcon = statusDisplay.icon;
                        
                        return (
                          <tr key={commission.id} className="hover:bg-gray-800/30 transition-colors">
                            <td className="px-6 py-4 whitespace-nowrap text-center">
                              <div className="w-10 h-10 bg-gradient-to-r from-orange-500 to-yellow-500 rounded-full flex items-center justify-center text-white font-bold text-lg mx-auto">
                                {commission.level}
                              </div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <div className="text-sm">
                                <div className="text-white font-medium">
                                  {commission.customer?.name || 'Unknown Customer'}
                                </div>
                                <div className="text-gray-400 text-xs mt-1">
                                  {commission.customer?.customer_id || `C-${String(commission.customer_id || '').slice(-4)}`}
                                </div>
                              </div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <div className="text-lg font-bold text-green-300">
                                {formatCurrency(commission.amount)}
                              </div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${statusDisplay.bg} ${statusDisplay.color} border border-current/30`}>
                                <StatusIcon className="w-3 h-3 mr-1" />
                                {statusDisplay.label}
                              </span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                              {new Date(commission.created_at).toLocaleDateString('en-IN', {
                                year: 'numeric',
                                month: 'short',
                                day: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit'
                              })}
                            </td>
                            <td className="px-6 py-4 text-sm text-gray-400 max-w-xs truncate">
                              {commission.note || 'No notes'}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                )}
              </div>
            </UnifiedCard>

          </div>
        </div>


      </UnifiedBackground>
    </>
  );
}

export default CommissionHistory;
