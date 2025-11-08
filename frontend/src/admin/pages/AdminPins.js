import React, { useState, useEffect } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import { useNavigate } from 'react-router-dom';
import AdminNavbar from '../components/AdminNavbar';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { supabase } from "../../common/services/supabaseClient"
import pinTransactionService, { PIN_ACTION_TYPES } from '../../services/pinTransactionService';
import pinRequestService from '../../services/pinRequestService';
import { Search, Plus, CheckCircle, XCircle, Clock, Eye, Send, Users, FileText, Mail, Phone, Pin, X, Loader } from 'lucide-react';
import { SkeletonTable } from '../components/skeletons';

// Helper function to format PIN request IDs
const formatPinRequestId = (request, allRequests) => {
  const globalOrder = [...allRequests].sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
  const globalIndex = globalOrder.findIndex(r => r.id === request.id);
  const sequentialNumber = String(globalIndex + 1).padStart(2, '0');
  return `PIN_REQ-${sequentialNumber}`;
};

// Helper function to display transaction IDs
const getTransactionId = (transaction) => {
  return transaction.transaction_id || transaction.requestId || `TXN-${transaction.id.slice(0, 8)}`;
};

function AdminPins() {
  const { user } = useAuth();
  useScrollAnimation();

  // State management
  const [pinRequests, setPinRequests] = useState([]); // For actual PIN requests from promoters
  const [pinTransactions, setPinTransactions] = useState([]); // For completed transactions
  const [filteredRequests, setFilteredRequests] = useState([]);
  const [filteredTransactions, setFilteredTransactions] = useState([]);
  const [promoters, setPromoters] = useState([]);
  const [filteredPromoters, setFilteredPromoters] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [activeTab, setActiveTab] = useState('pin-requests'); // 'pin-requests', 'direct', or 'requests'
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  
  // Request management states
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [selectedRequestIndex, setSelectedRequestIndex] = useState(0);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showApprovalModal, setShowApprovalModal] = useState(false);
  const [approvalData, setApprovalData] = useState({
    action: 'approve', // 'approve' or 'reject'
    adminNotes: ''
  });

  // Direct pin allocation states
  const [showPinModal, setShowPinModal] = useState(false);
  const [editingPromoter, setEditingPromoter] = useState(null);
  const [formData, setFormData] = useState({
    promoterId: '',
    pins: '',
    action: 'add' // 'add' or 'subtract'
  });
  const [formErrors, setFormErrors] = useState({});
  const [toast, setToast] = useState({ show: false, message: '', type: '' });

  // Toast utility function
  const showToast = (message, type = 'success') => {
    setToast({ show: true, message, type });
    setTimeout(() => {
      setToast({ show: false, message: '', type: '' });
    }, 4000);
  };

  // Load data on component mount and set up auto-refresh
  useEffect(() => {
    loadAllData();
    
    // Auto-refresh every 30 seconds to catch new requests
    const interval = setInterval(() => {
      loadAllData();
    }, 30000);
    
    return () => clearInterval(interval);
  }, []);

  const loadAllData = async () => {
    await Promise.all([
      loadPinRequests(),
      loadPinTransactions(), // Load PIN transactions separately
      loadPromoters()
    ]);
  };

  // Filter and search logic for PIN requests
  useEffect(() => {
    let filtered = pinRequests || [];

    // Search filter for requests
    if (searchTerm) {
      filtered = filtered.filter(request => {
        const requestId = (request.request_number || '').toLowerCase();
        const promoterEmail = (request.promoter?.email || '').toLowerCase();
        const promoterName = (request.promoter?.name || '').toLowerCase();
        const searchLower = (searchTerm || '').toLowerCase();
        return requestId.includes(searchLower) || 
               promoterEmail.includes(searchLower) || 
               promoterName.includes(searchLower);
      });
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    setFilteredRequests(filtered);
  }, [pinRequests, searchTerm]);

  // Filter and search logic for PIN transactions
  useEffect(() => {
    let filtered = pinTransactions || [];

    // Status filter for transactions
    if (statusFilter !== 'all') {
      filtered = filtered.filter(transaction => 
        (transaction.actionType || 'pending') === statusFilter
      );
    }

    // Search filter for transactions
    if (searchTerm) {
      filtered = filtered.filter(transaction => {
        const requestId = (transaction.requestId || '').toLowerCase();
        const promoterEmail = (transaction.promoterEmail || '').toLowerCase();
        const promoterName = (transaction.promoterName || '').toLowerCase();
        const searchLower = (searchTerm || '').toLowerCase();
        return requestId.includes(searchLower) || 
               promoterEmail.includes(searchLower) || 
               promoterName.includes(searchLower);
      });
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => new Date(b.requestDate) - new Date(a.requestDate));
    setFilteredTransactions(filtered);
  }, [pinTransactions, searchTerm, statusFilter]);

  // Filter and search logic for promoters in direct allocation tab
  useEffect(() => {
    let filtered = promoters || [];

    // Search filter for promoters
    if (searchTerm) {
      filtered = filtered.filter(promoter => {
        const name = (promoter.name || '').toLowerCase();
        const email = (promoter.email || '').toLowerCase();
        const promoterId = (promoter.promoter_id || '').toLowerCase();
        const phone = (promoter.phone || '').toLowerCase();
        const searchLower = (searchTerm || '').toLowerCase();
        return name.includes(searchLower) || 
               email.includes(searchLower) || 
               promoterId.includes(searchLower) ||
               phone.includes(searchLower);
      });
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    setFilteredPromoters(filtered);
  }, [promoters, searchTerm]);

  // Load PIN requests using pinRequestService
  const loadPinRequests = async () => {
    try {
      setLoading(true);
      
      // Get all PIN requests (admin view) - pass null for promoterId to get all requests
      const requests = await pinRequestService.getPinRequests(null, null, 100);
      
      setPinRequests(requests);
      setFilteredRequests(requests);
    } catch (error) {
      setPinRequests([]);
      setFilteredRequests([]);
    } finally {
      setLoading(false);
    }
  };

  // Load PIN transactions using unified service
  const loadPinTransactions = async () => {
    try {
      setLoading(true);
      
      // Use unified PIN transaction service
      const transactions = await pinTransactionService.getAllPinTransactions({
        actionType: statusFilter !== 'all' ? statusFilter : undefined
      });
      
      
      // Transform for backward compatibility with existing UI
      const transformedRequests = transactions.map(transaction => ({
        id: transaction.id,
        requestId: transaction.transaction_id,
        quantity: transaction.pin_change_value,
        status: 'completed',
        promoterId: transaction.user_id,
        promoterEmail: transaction.userEmail,
        promoterName: transaction.userName,
        promoterGeneratedId: `BPVP${String(Math.floor(Math.random() * 99)).padStart(2, '0')}`,
        requestDate: transaction.created_at,
        responseDate: transaction.created_at,
        adminNotes: transaction.note,
        actionType: transaction.action_type,
        customerName: null,
        displayConfig: transaction.displayConfig,
        formattedAmount: transaction.formattedAmount
      }));
      
      setPinTransactions(transformedRequests);
      setFilteredTransactions(transformedRequests);
      
    } catch (error) {
      setPinTransactions([]);
      setFilteredTransactions([]);
    } finally {
      setLoading(false);
    }
  };

  // Handle request approval/rejection
  const handleRequestAction = async (request, action) => {
    try {
      setSubmitting(true);
      
      if (action === 'approve') {
        // Use pinRequestService to approve the request
        await pinRequestService.approvePinRequest(
          request.id,
          user.id, // admin ID
          approvalData.adminNotes || `Request approved by admin`
        );
      } else if (action === 'reject') {
        // Use pinRequestService to reject the request
        await pinRequestService.rejectPinRequest(
          request.id,
          user.id, // admin ID
          approvalData.adminNotes || `Request rejected by admin`
        );
      }

      // Reload PIN requests to reflect changes
      await loadPinRequests();
      
      // Close modal and show success message
      setShowApprovalModal(false);
      setSelectedRequest(null);
      
      
    } catch (error) {
      // Error handled silently in production
    } finally {
      setSubmitting(false);
    }
  };

  // Load promoters from profiles table
  const loadPromoters = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, name, email, phone, pins, promoter_id, created_at')
        .eq('role', 'promoter')
        .order('created_at', { ascending: false });

      if (!error && data) {
        const transformedPromoters = data.map((promoter) => ({
          id: promoter.id,
          name: promoter.name || 'Unknown',
          email: promoter.email || 'Unknown',
          phone: promoter.phone || 'Not provided',
          promoter_id: promoter.promoter_id || 'N/A', // Use real promoter_id from database
          pins: promoter.pins || 0,
          created_at: promoter.created_at
        }));
        
        setPromoters(transformedPromoters);
        setFilteredPromoters(transformedPromoters);
      } else {
        setPromoters([]);
        setFilteredPromoters([]);
      }
    } catch (error) {
      setPromoters([]);
      setFilteredPromoters([]);
    }
  };

  // Open approval modal
  const openApprovalModal = (request, action, index) => {
    setSelectedRequest(request);
    setSelectedRequestIndex(index);
    setApprovalData({ action, adminNotes: '' });
    setShowApprovalModal(true);
  };

  // Direct pin allocation functions
  const openPinModal = (promoter = null) => {
    setEditingPromoter(promoter);
    setFormData({
      promoterId: promoter?.id || '',
      pins: '',
      action: 'add'
    });
    setFormErrors({});
    setShowPinModal(true);
  };

  const closePinModal = () => {
    setShowPinModal(false);
    setEditingPromoter(null);
    setFormData({
      promoterId: '',
      pins: '',
      action: 'add'
    });
    setFormErrors({});
  };

  // Form validation for direct pin allocation
  const validateForm = () => {
    const errors = {};
    
    if (!formData.promoterId) {
      errors.promoterId = 'Please select a promoter';
    }
    
    if (!formData.pins || formData.pins <= 0) {
      errors.pins = 'Please enter a valid number of pins';
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // Handle direct pin allocation using unified service
  const handlePinAllocation = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) return;

    setSubmitting(true);
    try {
      const promoter = promoters.find(p => p.id === formData.promoterId) || editingPromoter;
      if (!promoter) {
        throw new Error('Promoter not found');
      }

      const pinsToChange = parseInt(formData.pins);
      
      // Use unified PIN transaction service
      let result;
      if (formData.action === 'add') {
        result = await pinTransactionService.adminAllocatePins(
          promoter.id,
          pinsToChange,
          user.id
        );
      } else {
        result = await pinTransactionService.adminDeductPins(
          promoter.id,
          pinsToChange,
          user.id
        );
      }

      if (!result.success) {
        throw new Error(result.error || 'PIN transaction failed');
      }

      showToast(
        `🎉 Successfully ${formData.action === 'add' ? 'allocated' : 'deducted'} ${pinsToChange} PIN${pinsToChange > 1 ? 's' : ''} ${formData.action === 'add' ? 'to' : 'from'} ${promoter.name}!\n\nNew balance: ${result.balance_after} PINs`,
        'success'
      );
      
      closePinModal();
      await loadPromoters();
      await loadPinRequests();
      
    } catch (error) {
      showToast(`❌ Failed to ${formData.action} pins. Error: ${error.message}`, 'error');
    } finally {
      setSubmitting(false);
    }
  };


  return (
    <>
      <SharedStyles />
      <AdminNavbar />
      <UnifiedBackground>
        <div className="min-h-screen pt-40 px-8 pb-8">
          <div className="max-w-7xl mx-auto">
            {/* Header */}
            <div className="flex justify-between items-center mb-8" data-animate>
              <div>
                <h1 className="text-4xl font-bold text-white mb-2">Pin Management System</h1>
                <p className="text-gray-300">Manage pin requests and direct pin allocation</p>
              </div>
              {/* Tab Navigation */}
              <div className="flex space-x-1" data-animate>
              {[
                { id: 'pin-requests', label: 'PIN Requests', icon: Send },
                { id: 'direct', label: 'Allocate Pins', icon: Users },
                { id: 'requests', label: 'Pin History', icon: FileText }
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
            </div>



            {/* Pin History Tab */}
            {activeTab === 'requests' && (
              <>
                {/* Pin History Search */}
                <UnifiedCard className="p-6 mb-6" variant="glassDark" data-animate>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                    <input
                      type="text"
                      placeholder="Search by Transaction ID (BPV-AA-01), promoter name..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-green-500"
                    />
                  </div>
                </UnifiedCard>
                
                <UnifiedCard className="overflow-hidden" variant="glassDark" data-animate>
              {loading ? (
                <SkeletonTable rows={6} columns={5} />
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-800/50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Transaction ID</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Promoter Details</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Pins</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Action Type</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Notes</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-700/50">
                      {filteredTransactions.length === 0 ? (
                        <tr>
                          <td colSpan="6" className="px-6 py-12 text-center text-gray-400">
                            No pin transactions found
                          </td>
                        </tr>
                      ) : (
                        filteredTransactions.map((transaction, index) => (
                          <tr key={transaction.id} className="hover:bg-gray-800/30 transition-colors">
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                transaction.actionType === 'admin_allocation' ? 'bg-green-100 text-green-800' :
                                transaction.actionType === 'customer_creation' ? 'bg-blue-100 text-blue-800' :
                                transaction.actionType === 'admin_deduction' ? 'bg-red-100 text-red-800' :
                                'bg-gray-100 text-gray-800'
                              }`}>
                                {getTransactionId(transaction)}
                              </span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <div className="flex items-center">
                                <Users className="w-4 h-4 mr-2 text-blue-400" />
                                <div className="flex flex-col">
                                  <span className="text-white font-medium">{transaction.promoterName || 'Unknown'}</span>
                                  <span className="text-xs text-gray-400">
                                    {(() => {
                                      // Find the promoter in the promoters list to get the actual promoter ID
                                      const promoter = promoters.find(p => p.id === transaction.promoterId);
                                      return promoter?.promoter_id || 'No ID';
                                    })()
                                    }
                                  </span>
                                </div>
                              </div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <div className="flex items-center">
                                {(() => {
                                  // Admin allocations should show as positive (+), Customer creation should show as negative (-)
                                  let displayValue, isPositive;
                                  
                                  if (transaction.actionType === 'admin_allocation') {
                                    displayValue = Math.abs(transaction.quantity);
                                    isPositive = true;
                                  } else if (transaction.actionType === 'customer_creation') {
                                    displayValue = Math.abs(transaction.quantity);
                                    isPositive = false;
                                  } else {
                                    displayValue = transaction.quantity;
                                    isPositive = transaction.quantity > 0;
                                  }
                                  
                                  return (
                                    <>
                                      <span className={`text-sm font-medium ${isPositive ? 'text-green-300' : 'text-red-300'}`}>
                                        📌 {isPositive ? '+' : '-'}{displayValue}
                                      </span>
                                    </>
                                  );
                                })()}
                              </div>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                transaction.actionType === 'customer_creation' ? 'bg-blue-100 text-blue-800' :
                                transaction.actionType === 'admin_allocation' ? 'bg-green-100 text-green-800' :
                                transaction.actionType === 'admin_deduction' ? 'bg-red-100 text-red-800' :
                                'bg-gray-100 text-gray-800'
                              }`}>
                                {transaction.actionType === 'customer_creation' ? '👤 Customer Creation' :
                                 transaction.actionType === 'admin_allocation' ? '✅ Admin Allocation' :
                                 transaction.actionType === 'admin_deduction' ? '❌ Admin Deduction' :
                                 '❓ Unknown'}
                              </span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                              {transaction.requestDate ? new Date(transaction.requestDate).toLocaleDateString() : 'N/A'}
                            </td>
                            <td className="px-6 py-4 text-sm text-gray-300 max-w-xs truncate">
                              {transaction.adminNotes || 'No notes'}
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              )}
            </UnifiedCard>
              </>
            )}

            {/* PIN Requests Tab - Shows actual requests from promoters */}
            {activeTab === 'pin-requests' && (
              <>
                {/* PIN Requests Search */}
                <UnifiedCard className="p-6 mb-6" variant="glassDark" data-animate>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                    <input
                      type="text"
                      placeholder="Search by Request ID (PIN_REQ-01), promoter name, or reason..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </UnifiedCard>
                
                <UnifiedCard className="overflow-hidden" variant="glassDark" data-animate>
                {loading ? (
                  <SkeletonTable rows={6} columns={6} />
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-gray-800/50">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Request ID</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Promoter Details</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Requested PINs</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Reason</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Actions</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-700/50">
                        {filteredRequests.length === 0 ? (
                          <tr>
                            <td colSpan="7" className="px-6 py-12 text-center text-gray-400">
                              No PIN requests found
                            </td>
                          </tr>
                        ) : (
                          filteredRequests.map((request, index) => (
                            <tr key={request.id} className="hover:bg-gray-800/30 transition-colors">
                              <td className="px-6 py-4 whitespace-nowrap">
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                  {formatPinRequestId(request, pinRequests)}
                                </span>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="flex items-center">
                                  <Users className="w-4 h-4 mr-2 text-blue-400" />
                                  <div className="flex flex-col">
                                    <span className="text-white font-medium">{request.promoter_name || request.promoter?.name || 'Unknown'}</span>
                                    <span className="text-xs text-gray-400">
                                      {(() => {
                                        // Find the promoter in the promoters list to get the actual promoter ID
                                        const promoter = promoters.find(p => p.id === request.promoter_id);
                                        return promoter?.promoter_id || 'No ID';
                                      })()
                                      }
                                    </span>
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="flex items-center">
                                  <span className="text-sm font-medium text-blue-400">
                                    📌 +{request.requested_pins || 0}
                                  </span>
                                </div>
                              </td>
                              <td className="px-6 py-4 text-sm text-gray-300 max-w-xs truncate">
                                {request.reason || 'No reason provided'}
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                {request.created_at ? new Date(request.created_at).toLocaleDateString() : 'N/A'}
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
                              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                {request.status === 'pending' && (
                                  <div className="flex space-x-2">
                                    <button
                                      onClick={() => openApprovalModal(request, 'approve', index)}
                                      className="text-green-400 hover:text-green-300 transition-colors"
                                    >
                                      <CheckCircle className="w-5 h-5" />
                                    </button>
                                    <button
                                      onClick={() => openApprovalModal(request, 'reject', index)}
                                      className="text-red-400 hover:text-red-300 transition-colors"
                                    >
                                      <XCircle className="w-5 h-5" />
                                    </button>
                                  </div>
                                )}
                                {request.status !== 'pending' && (
                                  <span className="text-gray-500">No actions</span>
                                )}
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>
                )}
              </UnifiedCard>
              </>
            )}

            {/* Direct Allocation Tab */}
            {activeTab === 'direct' && (
              <>
                {/* Allocate Pins Search */}
                <UnifiedCard className="p-6 mb-6" variant="glassDark" data-animate>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                    <input
                      type="text"
                      placeholder="Search promoters by name, email, or ID (BPVP15)..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    />
                  </div>
                </UnifiedCard>
                
                <UnifiedCard className="overflow-hidden" variant="glassDark" data-animate>
                {loading ? (
                  <SkeletonTable rows={6} columns={5} />
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-gray-800/50">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Promoter Details</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Contact Details</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Current Pins</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Join Date</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Actions</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-700/50">
                        {filteredPromoters.length === 0 ? (
                          <tr>
                            <td colSpan="5" className="px-6 py-12 text-center text-gray-400">
                              {searchTerm ? 'No promoters found matching your search' : 'No promoters found'}
                            </td>
                          </tr>
                        ) : (
                          filteredPromoters.map((promoter) => (
                            <tr key={promoter.id} className="hover:bg-gray-800/30 transition-colors">
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="flex items-center">
                                  <Users className="w-4 h-4 mr-2 text-blue-400" />
                                  <div className="flex flex-col">
                                    <span className="text-white font-medium">{promoter.name || 'Unknown'}</span>
                                    <span className="text-xs text-gray-400">{promoter.promoter_id || 'No ID'}</span>
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <div className="space-y-1">
                                  <div className="flex items-center">
                                    <Mail className="w-3 h-3 mr-2 text-gray-400" />
                                    {promoter.email || 'No email'}
                                  </div>
                                  <div className="flex items-center">
                                    <Phone className="w-3 h-3 mr-2 text-gray-400" />
                                    {promoter.phone || 'No phone'}
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="flex items-center">
                                  <span className="text-sm font-medium text-white">📌 {promoter.pins || 0}</span>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                {promoter.created_at ? new Date(promoter.created_at).toLocaleDateString() : 'N/A'}
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                <div className="flex space-x-2">
                                  <button
                                    onClick={() => openPinModal(promoter)}
                                    className="text-purple-400 hover:text-purple-300 transition-colors"
                                    title="Allocate Pins"
                                  >
                                    <Pin className="w-4 h-4" />
                                  </button>
                                </div>
                              </td>
                            </tr>
                          ))
                        )}
                      </tbody>
                    </table>
                  </div>
                )}
              </UnifiedCard>
              </>
            )}
          </div>
        </div>

        {/* Approval Modal */}
        {showApprovalModal && selectedRequest && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <UnifiedCard className="w-full max-w-lg mx-4" variant="glassDark">
              <div className="p-6">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="text-lg font-semibold text-white">
                    {approvalData.action === 'approved' ? 'Approve' : 'Reject'} Pin Request
                  </h3>
                  <button
                    onClick={() => setShowApprovalModal(false)}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                <div className="space-y-6">
                  <div className="bg-gray-700/50 p-4 rounded-lg">
                    <div className="space-y-3 text-sm">
                      <div className="flex justify-between items-center">
                        <span className="text-gray-400">Request ID:</span>
                        <span className="text-white font-medium font-mono">{formatPinRequestId(selectedRequest, pinRequests)}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-400">User:</span>
                        <span className="text-white font-medium">{selectedRequest.promoter_name || selectedRequest.promoter?.name || 'Unknown'}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-400">Action Type:</span>
                        <span className={`px-2 py-1 rounded text-xs font-medium ${
                          (selectedRequest.action_type || selectedRequest.actionType) === PIN_ACTION_TYPES.CUSTOMER_CREATION ? 'bg-green-500/20 text-green-300' :
                          (selectedRequest.action_type || selectedRequest.actionType) === PIN_ACTION_TYPES.ADMIN_ALLOCATION ? 'bg-blue-500/20 text-blue-300' :
                          'bg-red-500/20 text-red-300'
                        }`}>
                          {(selectedRequest.action_type || selectedRequest.actionType || 'PIN_REQUEST')?.replace('_', ' ').toUpperCase()}
                        </span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-400">PIN Requested:</span>
                        <span className="font-medium text-blue-400">
                          +{selectedRequest.requested_pins || selectedRequest.pin_quantity || selectedRequest.quantity || 0}
                        </span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-400">Date:</span>
                        <span className="text-white font-medium">
                          {(selectedRequest.created_at || selectedRequest.requestDate) ? new Date(selectedRequest.created_at || selectedRequest.requestDate).toLocaleDateString() : 'N/A'}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div>
                    <label className="block text-gray-300 text-sm mb-2">
                      Admin Notes
                    </label>
                    <textarea
                      value={approvalData.adminNotes}
                      onChange={(e) => setApprovalData({...approvalData, adminNotes: e.target.value})}
                      placeholder={`Add notes for ${approvalData.action} this request...`}
                      rows={3}
                      className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-green-500 resize-none"
                    />
                  </div>
                </div>

                <div className="flex justify-end space-x-3 mt-6">
                  <UnifiedButton
                    variant="secondary"
                    onClick={() => setShowApprovalModal(false)}
                  >
                    Cancel
                  </UnifiedButton>
                  <UnifiedButton
                    onClick={() => handleRequestAction(selectedRequest, approvalData.action)}
                    disabled={submitting}
                    className={`flex items-center space-x-2 ${
                      approvalData.action === 'approved' ? 'bg-green-600 hover:bg-green-700' : 'bg-red-600 hover:bg-red-700'
                    }`}
                  >
                    {submitting ? (
                      <>
                        <Loader className="w-4 h-4 bp-animate-spin" />
                        <span>Processing...</span>
                      </>
                    ) : (
                      <>
                        {approvalData.action === 'approved' ? <CheckCircle className="w-4 h-4" /> : <XCircle className="w-4 h-4" />}
                        <span>{approvalData.action === 'approved' ? 'Approve' : 'Reject'} Request</span>
                      </>
                    )}
                  </UnifiedButton>
                </div>
              </div>
            </UnifiedCard>
          </div>
        )}

        {/* Direct Pin Allocation Modal */}
        {showPinModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <UnifiedCard className="w-full max-w-md mx-4" variant="glassDark">
              <div className="p-6">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="text-lg font-semibold text-white">
                    {editingPromoter ? `Allocate Pins - ${editingPromoter.name}` : 'Allocate Pins'}
                  </h3>
                  <button
                    onClick={closePinModal}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                <form onSubmit={handlePinAllocation} className="space-y-4">
                  {!editingPromoter && (
                    <div>
                      <label className="block text-sm font-medium text-gray-300 mb-1">
                        Select Promoter *
                      </label>
                      <select
                        value={formData.promoterId}
                        onChange={(e) => setFormData({...formData, promoterId: e.target.value})}
                        className={`w-full px-3 py-2 bg-gray-700 border rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500 ${
                          formErrors.promoterId ? 'border-red-500' : 'border-gray-600'
                        }`}
                      >
                        <option value="">Select promoter</option>
                        {promoters.map((promoter) => (
                          <option key={promoter.id} value={promoter.id}>
                            {promoter.name} ({promoter.promoter_id}) - {promoter.pins || 0} pins
                          </option>
                        ))}
                      </select>
                      {formErrors.promoterId && (
                        <p className="text-red-400 text-sm mt-1">{formErrors.promoterId}</p>
                      )}
                    </div>
                  )}

                  {editingPromoter && (
                    <div className="bg-gray-700/50 p-4 rounded-lg">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-white font-medium">{editingPromoter.name}</p>
                          <p className="text-gray-400 text-sm">{editingPromoter.promoter_id}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-gray-400 text-sm">Current Pins</p>
                          <p className="text-white font-bold text-lg">{editingPromoter.pins || 0}</p>
                        </div>
                      </div>
                    </div>
                  )}

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">
                      Action *
                    </label>
                    <select
                      value={formData.action}
                      onChange={(e) => setFormData({...formData, action: e.target.value})}
                      className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
                    >
                      <option value="add">Add Pins</option>
                      <option value="subtract">Subtract Pins</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">
                      Number of Pins *
                    </label>
                    <input
                      type="number"
                      min="1"
                      value={formData.pins}
                      onChange={(e) => setFormData({...formData, pins: e.target.value})}
                      className={`w-full px-3 py-2 bg-gray-700 border rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500 ${
                        formErrors.pins ? 'border-red-500' : 'border-gray-600'
                      }`}
                      placeholder="Enter number of pins"
                    />
                    {formErrors.pins && (
                      <p className="text-red-400 text-sm mt-1">{formErrors.pins}</p>
                    )}
                  </div>

                  <div className="flex justify-end space-x-3 pt-4">
                    <UnifiedButton
                      type="button"
                      variant="secondary"
                      onClick={closePinModal}
                    >
                      Cancel
                    </UnifiedButton>
                    <UnifiedButton
                      type="submit"
                      disabled={submitting}
                      className="flex items-center space-x-2"
                    >
                      {submitting ? (
                        <>
                          <Loader className="w-4 h-4 bp-animate-spin" />
                          <span>Processing...</span>
                        </>
                      ) : (
                        <>
                          <span>📌 {formData.action === 'add' ? 'Add Pins' : 'Subtract Pins'}</span>
                        </>
                      )}
                    </UnifiedButton>
                  </div>
                </form>
              </div>
            </UnifiedCard>
          </div>
        )}

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
                  <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                ) : (
                  <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                )}
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium whitespace-pre-line">{toast.message}</p>
              </div>
              <button
                onClick={() => setToast({ show: false, message: '', type: '' })}
                className="text-gray-400 hover:text-white transition-colors"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
        )}

      </UnifiedBackground>
    </>
  );
}

export default AdminPins;
