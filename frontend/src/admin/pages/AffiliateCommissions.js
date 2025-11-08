import React, { useState, useEffect } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import AdminNavbar from '../components/AdminNavbar';
import { SkeletonFullPage } from '../components/skeletons';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import commissionService, { COMMISSION_CONFIG } from '../../services/commissionService';
import { supabase } from "../../common/services/supabaseClient";
import { Clock, CheckCircle, XCircle, AlertCircle, Activity } from 'lucide-react';

// Format transaction ID
const formatTransactionId = (commission) => {
  if (commission.transaction_id?.match(/^COM-\d{5}$/)) {
    return commission.transaction_id;
  }
  return `COM-${String(commission.id || '').slice(0, 5).padStart(5, '0')}`;
};

function AffiliateCommissions() {
  const { user } = useAuth();
  useScrollAnimation();

  // State management
  const [loading, setLoading] = useState(true);
  const [commissionHistory, setCommissionHistory] = useState([]);
  const [filteredHistory, setFilteredHistory] = useState([]);
  const [filters, setFilters] = useState({ level: '', status: '' });
  const [promoterDetails, setPromoterDetails] = useState({});
  const [customerDetails, setCustomerDetails] = useState({});
  const [toast, setToast] = useState({ show: false, message: '', type: '' });

  // Toast utility
  const showToast = (message, type = 'success') => {
    setToast({ show: true, message, type });
    setTimeout(() => {
      setToast({ show: false, message: '', type: '' });
    }, 4000);
  };



  const loadCommissionData = async () => {
    try {
      setLoading(true);
      const historyResult = await commissionService.getCommissionHistory();
      
      if (historyResult.success) {
        setCommissionHistory(historyResult.data);
        setFilteredHistory(historyResult.data);
      } else {
        // Fallback to localStorage
        const auditTrail = JSON.parse(localStorage.getItem('commission_audit_trail') || '[]');
        setCommissionHistory(auditTrail);
        setFilteredHistory(auditTrail);
      }
    } catch (error) {
      setCommissionHistory([]);
      setFilteredHistory([]);
    } finally {
      setLoading(false);
    }
  };

  // Handle filter change
  const handleFilterChange = (key, value) => {
    setFilters(prev => ({ ...prev, [key]: value }));
  };


  // Load data on component mount
  useEffect(() => {
    loadCommissionData();
  }, []);

  // Get status display
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

  // Format currency
  const formatCurrency = (amount) => {
    return `₹${parseFloat(amount).toLocaleString('en-IN')}`;
  };

  // Show loading skeleton
  if (loading) {
    return (
      <>
        <SharedStyles />
        <AdminNavbar />
        <UnifiedBackground>
          <SkeletonFullPage type="dashboard" />
        </UnifiedBackground>
      </>
    );
  }

  return (
    <>
      <SharedStyles />
      <AdminNavbar />
      <UnifiedBackground>
        <div className="min-h-screen pt-40 px-8 pb-8">
          <div className="w-full px-4">
            
            {/* Header */}
            <div className="flex justify-between items-center mb-8" data-animate>
              <div>
                <h1 className="text-4xl font-bold text-white mb-2">Affiliate Commissions</h1>
                <p className="text-gray-300">Monitor and manage affiliate commission distributions</p>
              </div>
              {/* Filter Controls */}
              <div className="flex items-center space-x-4">
                <select
                  value={filters.level}
                  onChange={(e) => handleFilterChange('level', e.target.value)}
                  className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500"
                >
                  <option value="">All Levels</option>
                  <option value="1">Level 1 (₹500)</option>
                  <option value="2">Level 2 (₹100)</option>
                  <option value="3">Level 3 (₹100)</option>
                  <option value="4">Level 4 (₹100)</option>
                  <option value="0">Admin Fallback</option>
                </select>
                <select
                  value={filters.status}
                  onChange={(e) => handleFilterChange('status', e.target.value)}
                  className="px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500"
                >
                  <option value="">All Status</option>
                  <option value="credited">Credited</option>
                  <option value="pending">Pending</option>
                  <option value="failed">Failed</option>
                </select>
              </div>
            </div>


            {/* Commission History Table */}
            <div className="mt-8">
              
              <UnifiedCard className="overflow-hidden" variant="glassDark">
                <div className="p-6 border-b border-gray-700/50">
                  <div className="flex items-center justify-end">
                    <span className="text-sm text-gray-400">
                      {filteredHistory.length} transactions
                    </span>
                  </div>
                </div>
                  
                  <div className="overflow-x-auto">
                    {filteredHistory.length === 0 ? (
                      <div className="p-12 text-center">
                        <Activity className="w-16 h-16 text-gray-500 mx-auto mb-4" />
                        <h3 className="text-xl font-semibold text-gray-400 mb-2">No Commission History</h3>
                        <p className="text-gray-500">
                          Commission transactions will appear here once customers are created.
                        </p>
                      </div>
                    ) : (
                      <table className="w-full">
                        <thead className="bg-gray-800/50">
                          <tr>
                            <th className="px-8 py-4 text-center text-xs font-medium text-gray-300 uppercase tracking-wider w-1/6">ID</th>
                            <th className="px-8 py-4 text-left text-xs font-medium text-gray-300 uppercase tracking-wider w-1/6">Customer</th>
                            <th className="px-8 py-4 text-center text-xs font-medium text-gray-300 uppercase tracking-wider w-1/6">Level</th>
                            <th className="px-8 py-4 text-left text-xs font-medium text-gray-300 uppercase tracking-wider w-1/6">Recipient</th>
                            <th className="px-8 py-4 text-center text-xs font-medium text-gray-300 uppercase tracking-wider w-1/6">Amount</th>
                            <th className="px-8 py-4 text-center text-xs font-medium text-gray-300 uppercase tracking-wider w-1/6">Date</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-700/50">
                          {filteredHistory.map((commission, index) => {
                            const statusDisplay = getStatusDisplay(commission.status);
                            const StatusIcon = statusDisplay.icon;
                            
                            return (
                              <tr key={commission.id} className="hover:bg-gray-800/30 transition-colors">
                                <td className="px-8 py-5 whitespace-nowrap text-center">
                                  <div className="text-white font-medium font-mono text-sm">
                                    {formatTransactionId(commission)}
                                  </div>
                                </td>
                                <td className="px-8 py-5 whitespace-nowrap">
                                  <div className="flex flex-col">
                                    <span className="text-white font-medium text-sm">
                                      {customerDetails[commission.customer_id]?.name || 
                                       commission.customers?.name || 
                                       commission.customer_name || 
                                       'Unknown Customer'}
                                    </span>
                                    <span className="text-xs text-gray-400 font-mono">
                                      {customerDetails[commission.customer_id]?.customer_id || 
                                       commission.customers?.customer_id || 
                                       commission.customer_generated_id ||
                                       `C-${String(commission.customer_id || '').slice(-4)}`}
                                    </span>
                                  </div>
                                </td>
                                <td className="px-8 py-5 whitespace-nowrap text-center">
                                  <div className="flex flex-col items-center space-y-1">
                                    {/* Level Badge */}
                                    <div className={`
                                      inline-flex items-center justify-center w-8 h-8 rounded-full font-bold text-sm
                                      ${commission.level === 0 ? 'bg-gray-600 text-gray-200' :
                                        commission.level === 1 ? 'bg-green-500 text-white' :
                                        commission.level === 2 ? 'bg-blue-500 text-white' :
                                        commission.level === 3 ? 'bg-purple-500 text-white' :
                                        commission.level === 4 ? 'bg-orange-500 text-white' :
                                        'bg-gray-500 text-white'}
                                    `}>
                                      {commission.level === 0 ? 'A' : commission.level}
                                    </div>
                                    
                                    {/* Level Description */}
                                    <div className={`
                                      text-xs font-medium
                                      ${commission.level === 0 ? 'text-gray-400' :
                                        commission.level === 1 ? 'text-green-300' :
                                        commission.level === 2 ? 'text-blue-300' :
                                        commission.level === 3 ? 'text-purple-300' :
                                        commission.level === 4 ? 'text-orange-300' :
                                        'text-gray-400'}
                                    `}>
                                      {commission.level === 0 ? 'Admin' : 
                                       commission.level === 1 ? 'Direct' : 
                                       commission.level === 2 ? 'Level 2' :
                                       commission.level === 3 ? 'Level 3' :
                                       commission.level === 4 ? 'Level 4' :
                                       `Level ${commission.level}`}
                                    </div>
                                    
                                    {/* Amount Indicator */}
                                    <div className="text-xs text-gray-500 font-mono">
                                      {commission.level === 0 ? 'Fallback' : 
                                       commission.level === 1 ? '₹500' : '₹100'}
                                    </div>
                                  </div>
                                </td>
                                <td className="px-8 py-5 whitespace-nowrap">
                                  <div className="flex flex-col">
                                    <span className="text-white font-medium text-sm">
                                      {(() => {
                                        if (commission.recipient_type === 'admin') {
                                          return 'Admin';
                                        }
                                        return commission.recipient?.name || 
                                               promoterDetails[commission.promoter_id]?.name ||
                                               commission.promoter_name || 
                                               'Unknown Promoter';
                                      })()}
                                    </span>
                                    <span className="text-xs text-gray-400 font-mono">
                                      {(() => {
                                        if (commission.recipient_type === 'admin') {
                                          return 'SYSTEM';
                                        }
                                        
                                        // Try multiple sources for the real promoter ID
                                        const realPromoterId = 
                                          // From cached promoter details
                                          promoterDetails[commission.promoter_id]?.promoter_id ||
                                          promoterDetails[commission.recipient_id]?.promoter_id ||
                                          // From commission record directly
                                          commission.promoter_generated_id ||
                                          commission.recipient?.promoter_id ||
                                          // From join data if available
                                          commission.recipient?.promoter_id;
                                        
                                        if (realPromoterId && realPromoterId !== 'undefined' && realPromoterId.length > 2) {
                                          return realPromoterId;
                                        }
                                        
                                        // Enhanced fallback - try to get from recipient_id
                                        if (commission.recipient_id && promoterDetails[commission.recipient_id]) {
                                          const fallbackId = promoterDetails[commission.recipient_id].promoter_id;
                                          if (fallbackId) return fallbackId;
                                        }
                                        
                                        // Last resort fallback
                                        return commission.recipient_id ? 
                                               `ID-${String(commission.recipient_id).slice(-6).toUpperCase()}` : 
                                               'LOADING...';
                                      })()}
                                    </span>
                                  </div>
                                </td>
                                <td className="px-8 py-5 whitespace-nowrap text-center">
                                  <div className="text-lg font-bold text-green-300 font-mono">
                                    {formatCurrency(commission.amount)}
                                  </div>
                                </td>
                                <td className="px-8 py-5 whitespace-nowrap text-center">
                                  <div className="text-sm">
                                    <div className="text-white font-medium">
                                      {commission.created_at ? new Date(commission.created_at).toLocaleDateString('en-IN') : 'Unknown'}
                                    </div>
                                    <div className="text-xs text-gray-400 font-mono">
                                      {commission.created_at ? new Date(commission.created_at).toLocaleTimeString('en-IN', { 
                                        hour: '2-digit', 
                                        minute: '2-digit',
                                        hour12: true 
                                      }) : ''}
                                    </div>
                                  </div>
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
        </div>

        {/* Toast Notification */}
        {toast.show && (
          <div className={`fixed top-4 right-4 z-50 max-w-md p-4 rounded-lg shadow-lg border transition-all duration-300 ${
            toast.type === 'success' 
              ? 'bg-green-500/10 border-green-500/30 text-green-300' 
              : 'bg-red-500/10 border-red-500/30 text-red-300'
          }`}>
            <div className="flex items-start space-x-3">
              <div className={`w-6 h-6 rounded-full flex items-center justify-center ${
                toast.type === 'success' ? 'bg-green-500' : 'bg-red-500'
              }`}>
                {toast.type === 'success' ? (
                  <CheckCircle className="w-4 h-4 text-white" />
                ) : (
                  <XCircle className="w-4 h-4 text-white" />
                )}
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium whitespace-pre-line">{toast.message}</p>
              </div>
              <button
                onClick={() => setToast({ show: false, message: '', type: '' })}
                className="text-gray-400 hover:text-white transition-colors"
              >
                <XCircle className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

      </UnifiedBackground>
    </>
  );
}

export default AffiliateCommissions;
