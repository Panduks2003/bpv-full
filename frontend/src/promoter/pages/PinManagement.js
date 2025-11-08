import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import { useUnifiedToast } from "../../common/services/unifiedToastService";
import { useNavigate } from 'react-router-dom';
import pinTransactionService, { PIN_ACTION_TYPES } from '../../services/pinTransactionService';
import pinRequestService from '../../services/pinRequestService';
import { 
  PinBalance, 
  PinTransactionTable, 
  PinStatsCards, 
  PinBalanceWidget,
  ActionTypeBadge,
  PinChangeIndicator 
} from '../../components/PinComponents';
import PinRequestModal from '../../components/PinRequestModal';
import PinRequestTable from '../../components/PinRequestTable';
import { usePinManagement } from '../../hooks/usePinSync';
import PromoterNavbar from '../components/PromoterNavbar';
import { SkeletonFullPage } from '../components/skeletons';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { 
  Shield, Users, Clock, CheckCircle, AlertCircle, XCircle, Eye, Plus,
  Filter, Download, Copy, Send, Calendar, Target, TrendingUp,
  Search, RefreshCw, DollarSign, User, FileText, ArrowUpRight,
  ArrowDownLeft, MessageSquare, Award, Pin
} from 'lucide-react';

// Helper function to format PIN request IDs consistently with global sequencing
const formatPinRequestId = (request, allRequests) => {
  // Sort all requests by creation date to get global order
  const globalOrder = [...allRequests].sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
  
  // Find the global index of this request
  const globalIndex = globalOrder.findIndex(r => r.id === request.id);
  
  // Create globally sequential PIN request IDs: PIN_REQ-01, PIN_REQ-02, etc.
  const sequentialNumber = String(globalIndex + 1).padStart(2, '0');
  return `PIN_REQ-${sequentialNumber}`;
};

function PinManagement() {
  const { user } = useAuth();
  const { showSuccess, showError } = useUnifiedToast();
  const navigate = useNavigate();
  useScrollAnimation();

  // Tab management
  const [activeTab, setActiveTab] = useState('requests');

  // Search and filters
  const [searchTerm, setSearchTerm] = useState('');
  const [actionTypeFilter, setActionTypeFilter] = useState('all');

  // PIN request modal
  const [showRequestModal, setShowRequestModal] = useState(false);
  
  // PIN requests state
  const [pinRequests, setPinRequests] = useState([]);
  const [allPinRequests, setAllPinRequests] = useState([]); // For global sequencing
  const [requestsLoading, setRequestsLoading] = useState(false);
  const [requestStats, setRequestStats] = useState({
    totalRequests: 0,
    pendingRequests: 0,
    approvedRequests: 0,
    rejectedRequests: 0
  });

  // Toast notifications

  // Real-time PIN management using unified hooks
  const { balance, transactions, stats, refreshAll, loading } = usePinManagement(user?.id, {
    autoRefresh: true,
    refreshInterval: 30000,
    enableRealtime: true
  });



  // Filter transactions based on search and action type
  const filteredTransactions = transactions.transactions?.filter(transaction => {
    const matchesSearch = !searchTerm || 
      transaction.transaction_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      transaction.note.toLowerCase().includes(searchTerm.toLowerCase()) ||
      transaction.action_type.toLowerCase().includes(searchTerm.toLowerCase());
      transaction.note.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesActionType = actionTypeFilter === 'all' || 
      transaction.action_type === actionTypeFilter;
    
    return matchesSearch && matchesActionType;
  }) || [];

  // Load PIN requests
  const loadPinRequests = async () => {
    try {
      setRequestsLoading(true);
      // Load all requests for global sequencing, then filter for display
      const allRequests = await pinRequestService.getPinRequests(null, null, 100);
      const userRequests = allRequests.filter(request => request.promoter_id === user.id);
      const stats = await pinRequestService.getPinRequestStats(user.id);
      
      // Store all requests for global sequencing, but set user requests for display
      setAllPinRequests(allRequests);
      setPinRequests(userRequests);
      setRequestStats(stats);
    } catch (error) {
      showError('Failed to load PIN requests. Please try again.');
    } finally {
      setRequestsLoading(false);
    }
  };

  // Load PIN requests when component mounts
  useEffect(() => {
    if (user?.id) {
      loadPinRequests();
    }
  }, [user?.id]);

  // Manual refresh function
  const handleRefresh = () => {
    refreshAll();
    loadPinRequests();
    showSuccess('PIN data refreshed successfully.');
  };

  // PIN request handlers
  const handleRequestSuccess = (message) => {
    showSuccess(message);
    loadPinRequests(); // Reload requests after successful submission
    refreshAll(); // Refresh PIN balance in case of immediate approval
  };

  const handleRequestError = (message) => {
    showError(message);
  };

  // Show skeleton while loading
  if (loading || requestsLoading) {
    return (
      <>
        <SharedStyles />
        <PromoterNavbar />
        <UnifiedBackground>
          <SkeletonFullPage type="pin-management" />
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
                <h1 className="text-4xl font-bold text-white mb-2">PIN Management</h1>
                <p className="text-gray-300">Monitor your PIN balance and request new PINs</p>
              </div>
              <UnifiedButton
                onClick={() => setShowRequestModal(true)}
                className="flex items-center space-x-2"
              >
                <Plus className="w-5 h-5" />
                <span>Request PINs</span>
              </UnifiedButton>
            </div>

            {/* Tab Navigation */}
            <div className="flex space-x-1 mb-8" data-animate>
              {[
                { id: 'requests', label: 'Transaction History', icon: FileText },
                { id: 'pin-requests', label: 'PIN Requests', icon: Send }
              ].map((tab) => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={`flex items-center space-x-2 px-6 py-3 rounded-lg font-medium transition-all duration-300 ${
                      activeTab === tab.id
                        ? 'bg-gradient-to-r from-indigo-500 to-purple-600 text-white shadow-lg'
                        : 'bg-gray-800/50 text-gray-400 hover:bg-gray-700/50 hover:text-white'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    <span>{tab.label}</span>
                  </button>
                );
              })}
            </div>

            {/* PIN Balance Display */}
            <div className="mb-8" data-animate>
              <UnifiedCard variant="glassDark" className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm mb-1">Current PIN Balance</p>
                    <h2 className="text-4xl font-bold text-white">{balance.balance || 0}</h2>
                    <p className="text-gray-500 text-xs mt-1">
                      Last updated: {balance.lastUpdated ? new Date(balance.lastUpdated).toLocaleTimeString() : 'Never'}
                    </p>
                  </div>
                  <div className="bg-gradient-to-br from-indigo-500 to-purple-600 p-4 rounded-full">
                    <Pin className="w-8 h-8 text-white" />
                  </div>
                </div>
              </UnifiedCard>
            </div>

            {/* Stats Cards - Using Unified Component */}
            <div className="mb-8" data-animate>
              <PinStatsCards 
                stats={{
                  totalTransactions: transactions.transactions?.length || 0,
                  customerCreations: transactions.transactions?.filter(t => t.action_type === 'customer_creation').reduce((total, t) => total + Math.abs(t.pin_change_value || 0), 0) || 0,
                  adminAllocations: transactions.transactions?.filter(t => t.action_type === 'admin_allocation').reduce((total, t) => total + Math.abs(t.pin_change_value || 0), 0) || 0,
                  adminDeductions: transactions.transactions?.filter(t => t.action_type === 'admin_deduction').reduce((total, t) => total + Math.abs(t.pin_change_value || 0), 0) || 0,
                  totalPinsAllocated: transactions.transactions?.filter(t => t.action_type === 'admin_allocation').reduce((total, t) => total + Math.abs(t.pin_change_value || 0), 0) || 0,
                  totalPinsDeducted: transactions.transactions?.filter(t => t.action_type !== 'admin_allocation').reduce((total, t) => total + Math.abs(t.pin_change_value || 0), 0) || 0
                }}
                loading={loading}
              />
            </div>

            {/* Search and Filters */}
            <UnifiedCard className="p-6 mb-8" variant="glassDark" data-animate>
              <div className="flex flex-col md:flex-row gap-4">
                <div className="flex-1 relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                  <input
                    type="text"
                    placeholder="Search by transaction ID or notes..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>
                <div className="md:w-48">
                  <select
                    value={actionTypeFilter}
                    onChange={(e) => setActionTypeFilter(e.target.value)}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-green-500"
                  >
                    <option value="all">All Actions</option>
                    <option value="customer_creation">Customer Creation</option>
                    <option value="admin_allocation">Admin Allocation</option>
                    <option value="admin_deduction">Admin Deduction</option>
                  </select>
                </div>
              </div>
            </UnifiedCard>

            {/* Transaction History Tab */}
            {activeTab === 'requests' && (
              <UnifiedCard className="overflow-hidden" variant="glassDark" data-animate>
                {loading ? (
                  <div className="flex items-center justify-center py-20">
                    <div className="text-center">
                      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-400 mx-auto mb-4"></div>
                      <p className="text-gray-400">Loading transaction history...</p>
                    </div>
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-gray-800/50">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Transaction ID</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Pins</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Action Type</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Notes</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-700/50">
                        {filteredTransactions.length === 0 ? (
                          <tr>
                            <td colSpan="5" className="px-6 py-12 text-center text-gray-400">
                              No transactions found
                            </td>
                          </tr>
                        ) : (
                          filteredTransactions.map((transaction) => (
                            <tr key={transaction.id} className="hover:bg-gray-800/30 transition-colors">
                              <td className="px-6 py-4 whitespace-nowrap">
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                                  {transaction.transaction_id}
                                </span>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="flex items-center">
                                  <Pin className={`w-4 h-4 mr-2 ${transaction.pin_change_value > 0 ? 'text-green-400' : 'text-red-400'}`} />
                                  <span className={`text-lg font-bold ${transaction.pin_change_value > 0 ? 'text-green-300' : 'text-red-300'}`}>
                                    {transaction.pin_change_value > 0 ? '+' : ''}{transaction.pin_change_value}
                                  </span>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                  transaction.action_type === 'customer_creation' ? 'bg-blue-100 text-blue-800' :
                                  transaction.action_type === 'admin_allocation' ? 'bg-green-100 text-green-800' :
                                  transaction.action_type === 'admin_deduction' ? 'bg-red-100 text-red-800' :
                                  'bg-gray-100 text-gray-800'
                                }`}>
                                  {transaction.action_type === 'customer_creation' ? '❌ Customer Creation' :
                                   transaction.action_type === 'admin_allocation' ? '✅ Admin Allocation' :
                                   transaction.action_type === 'admin_deduction' ? '❌ Admin Deduction' :
                                   '❓ Unknown'}
                                </span>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                {transaction.created_at ? new Date(transaction.created_at).toLocaleDateString() : 'N/A'}
                              </td>
                              <td className="px-6 py-4 text-sm text-gray-300 max-w-xs truncate">
                                {transaction.note || 'No notes'}
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>
                )}
              </UnifiedCard>
            )}

            {/* PIN Requests Tab */}
            {activeTab === 'pin-requests' && (
              <UnifiedCard className="overflow-hidden" variant="glassDark" data-animate>
                {requestsLoading ? (
                  <div className="flex items-center justify-center py-20">
                    <div className="text-center">
                      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-400 mx-auto mb-4"></div>
                      <p className="text-gray-400">Loading PIN requests...</p>
                    </div>
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-gray-800/50">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Request ID</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">PINs</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Reason</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-700/50">
                        {pinRequests.length === 0 ? (
                          <tr>
                            <td colSpan="5" className="px-6 py-12 text-center text-gray-400">
                              No PIN requests found. Submit your first request to get started!
                            </td>
                          </tr>
                        ) : (
                          pinRequests.map((request, index) => (
                            <tr key={request.id} className="hover:bg-gray-800/30 transition-colors">
                              <td className="px-6 py-4 whitespace-nowrap">
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                                  {formatPinRequestId(request, allPinRequests)}
                                </span>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="flex items-center">
                                  <Pin className="w-4 h-4 mr-2 text-blue-400" />
                                  <span className="text-lg font-bold text-white">
                                    {request.requested_pins || request.quantity}
                                  </span>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                  request.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                                  request.status === 'approved' ? 'bg-green-100 text-green-800' :
                                  request.status === 'rejected' ? 'bg-red-100 text-red-800' :
                                  'bg-gray-100 text-gray-800'
                                }`}>
                                  {request.status === 'pending' ? '⏳ Pending' :
                                   request.status === 'approved' ? '✅ Approved' :
                                   request.status === 'rejected' ? '❌ Rejected' :
                                   '❓ Unknown'}
                                </span>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                {request.created_at ? new Date(request.created_at).toLocaleDateString() : 'N/A'}
                              </td>
                              <td className="px-6 py-4 text-sm text-gray-300 max-w-xs truncate">
                                {request.reason || 'No reason provided'}
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>
                )}
              </UnifiedCard>
            )}
          </div>
        </div>


        {/* PIN Request Modal */}
        <PinRequestModal
          isOpen={showRequestModal}
          onClose={() => setShowRequestModal(false)}
          promoterId={user?.id}
          onSuccess={handleRequestSuccess}
          onError={handleRequestError}
        />
      </UnifiedBackground>
    </>
  );
}

export default PinManagement;
