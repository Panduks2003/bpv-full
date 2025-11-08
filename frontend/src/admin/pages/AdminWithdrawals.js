import React, { useState, useEffect, useCallback, useMemo, memo } from 'react';
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
import { 
  DollarSign, 
  Clock, 
  CheckCircle, 
  XCircle, 
  Search, 
  Filter,
  Eye,
  AlertCircle,
  Calendar,
  User,
  Phone,
  Mail,
  History
} from 'lucide-react';
import { 
  SkeletonWithdrawalCard, 
  SkeletonPageHeader, 
  SkeletonSearchFilters,
  SkeletonFullPage 
} from '../components/skeletons';
import { supabase } from "../../common/services/supabaseClient"
import { useToast } from '../services/toastService';

// Memoized status badge component
const StatusBadge = memo(({ status }) => {
  const statusConfig = useMemo(() => ({
    pending: { color: 'bg-yellow-500', icon: Clock, text: 'Pending' },
    approved: { color: 'bg-blue-500', icon: CheckCircle, text: 'Approved' },
    completed: { color: 'bg-green-500', icon: CheckCircle, text: 'Completed' },
    rejected: { color: 'bg-red-500', icon: XCircle, text: 'Rejected' }
  }), []);

  const config = statusConfig[status] || statusConfig.pending;
  const IconComponent = config.icon;

  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium text-white ${config.color}`}>
      <IconComponent className="w-3 h-3 mr-1" />
      {config.text}
    </span>
  );
});

function AdminWithdrawals() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const { showSuccess, showError, showWarning, handleApiError } = useToast();
  useScrollAnimation();

  // State management
  const [withdrawalRequests, setWithdrawalRequests] = useState([]);
  const [statusFilter, setStatusFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [actionNotes, setActionNotes] = useState('');
  const [transactionId, setTransactionId] = useState('');
  const [rejectionReason, setRejectionReason] = useState('');

  // Search functionality
  const [searchTerm, setSearchTerm] = useState('');
  const [filteredRequests, setFilteredRequests] = useState([]);
  
  // Modal management
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [showModal, setShowModal] = useState(false);

  // Load withdrawal requests from Supabase
  useEffect(() => {
    loadWithdrawalRequests();
  }, []);

  // Filter and search logic
  useEffect(() => {
    let filtered = withdrawalRequests || [];

    // Search filter
    if (searchTerm) {
      filtered = filtered.filter(request => {
        const name = (request?.profiles?.name || '').toLowerCase();
        const id = (request?.id || '').toString().toLowerCase();
        const searchLower = (searchTerm || '').toLowerCase();
        return name.includes(searchLower) || id.includes(searchLower);
      });
    }

    // Status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter(request => 
        (request?.status || 'pending') === statusFilter
      );
    }

    setFilteredRequests(filtered);
  }, [withdrawalRequests, searchTerm, statusFilter]);

  const loadWithdrawalRequests = async () => {
    try {
      setLoading(true);
      
      // Query withdrawal requests from Supabase
      // Note: You'll need to create a withdrawal_requests table in your database
      const { data, error } = await supabase
        .from('withdrawal_requests')
        .select(`
          *,
          profiles!withdrawal_requests_promoter_id_fkey(
            name,
            email,
            phone,
            promoter_id
          )
        `)
        .order('created_at', { ascending: false });

      if (error) {
        // For now, show empty state since table doesn't exist yet
        setWithdrawalRequests([]);
      } else {
        setWithdrawalRequests(data || []);
      }
    } catch (error) {
      setWithdrawalRequests([]);
    } finally {
      setLoading(false);
    }
  };

  // Apply status filter to the search results
  const finalFilteredRequests = useMemo(() => {
    if (statusFilter === 'all') {
      return filteredRequests;
    }
    return filteredRequests.filter(request => request.status === statusFilter);
  }, [filteredRequests, statusFilter]);

  // Calculate summary statistics
  const totalRequests = withdrawalRequests.length;
  const pendingRequests = withdrawalRequests.filter(r => r.status === 'pending').length;
  const approvedRequests = withdrawalRequests.filter(r => r.status === 'approved').length;
  const completedAmount = withdrawalRequests
    .filter(r => r.status === 'completed')
    .reduce((sum, r) => sum + (r.amount || 0), 0);
  const rejectedRequests = withdrawalRequests.filter(r => r.status === 'rejected').length;

  // Handle approve/reject/complete actions
  const handleAction = async (requestId, action) => {
    try {
      let updateData = {
        status: action,
        processed_at: new Date().toISOString(),
        processed_by: user.id
      };

      if (action === 'approved' && actionNotes) {
        updateData.admin_notes = actionNotes;
      } else if (action === 'rejected' && rejectionReason) {
        updateData.rejection_reason = rejectionReason;
        updateData.admin_notes = actionNotes;
      } else if (action === 'completed' && transactionId) {
        updateData.transaction_id = transactionId;
        updateData.completed_at = new Date().toISOString();
        updateData.admin_notes = actionNotes;
      }

      
      const { data, error } = await supabase
        .from('withdrawal_requests')
        .update(updateData)
        .eq('id', requestId)
        .select();

      if (error) {
        alert('Failed to update withdrawal request: ' + error.message);
        return;
      }
      // Notification system removed - withdrawal status updated successfully

      alert(`Withdrawal request ${action} successfully!`);
      
      // Reset form and reload data
      closeActionModal();
      loadWithdrawalRequests();
    } catch (error) {
      alert('An error occurred while updating the request.');
    }
  };

  // Additional modal state
  const [actionType, setActionType] = useState('');

  const openActionModal = useCallback((request, action) => {
    setSelectedRequest(request);
    setActionType(action);
    setShowModal(true);
  }, []);

  const viewDetails = useCallback((request) => {
    setSelectedRequest(request);
    setShowModal(true);
  }, []);

  const closeActionModal = useCallback(() => {
    setShowModal(false);
    setActionNotes('');
    setTransactionId('');
    setRejectionReason('');
    setSelectedRequest(null);
  }, []);

  const closeDetailsModal = useCallback(() => {
    setShowModal(false);
    setSelectedRequest(null);
  }, []);


  if (loading) {
    return (
      <>
        <SharedStyles />
        <AdminNavbar />
        <SkeletonFullPage type="cards" />
      </>
    );
  }

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
                <h1 className="text-4xl font-bold text-white mb-2">Withdrawal Management</h1>
                <p className="text-gray-300">Process withdrawal requests and manage approval workflows</p>
              </div>
            </div>

            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8" data-animate>
              <UnifiedCard className="p-6 bg-white/95 border border-gray-200 shadow-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-600 text-sm font-medium">Total Requests</p>
                    <p className="text-3xl font-bold text-gray-900 mt-1">{totalRequests}</p>
                  </div>
                  <div className="w-14 h-14 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg">
                    <DollarSign className="w-7 h-7 text-white" />
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6 bg-white/95 border border-gray-200 shadow-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-600 text-sm font-medium">Pending Requests</p>
                    <p className="text-3xl font-bold text-gray-900 mt-1">{pendingRequests}</p>
                  </div>
                  <div className="w-14 h-14 bg-gradient-to-r from-yellow-500 to-orange-600 rounded-xl flex items-center justify-center shadow-lg">
                    <Clock className="w-7 h-7 text-white" />
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6 bg-white/95 border border-gray-200 shadow-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-600 text-sm font-medium">Approved Requests</p>
                    <p className="text-3xl font-bold text-gray-900 mt-1">{approvedRequests}</p>
                  </div>
                  <div className="w-14 h-14 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg">
                    <CheckCircle className="w-7 h-7 text-white" />
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6 bg-white/95 border border-gray-200 shadow-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-600 text-sm font-medium">Completed Amount</p>
                    <p className="text-3xl font-bold text-gray-900 mt-1">₹{completedAmount.toLocaleString()}</p>
                  </div>
                  <div className="w-14 h-14 bg-gradient-to-r from-green-500 to-emerald-600 rounded-xl flex items-center justify-center shadow-lg">
                    <DollarSign className="w-7 h-7 text-white" />
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6 bg-white/95 border border-gray-200 shadow-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-600 text-sm font-medium">Rejected Requests</p>
                    <p className="text-3xl font-bold text-gray-900 mt-1">{rejectedRequests}</p>
                  </div>
                  <div className="w-14 h-14 bg-gradient-to-r from-red-500 to-pink-600 rounded-xl flex items-center justify-center shadow-lg">
                    <XCircle className="w-7 h-7 text-white" />
                  </div>
                </div>
              </UnifiedCard>
            </div>

            {/* Search and Filters */}
            <UnifiedCard className="p-6 mb-8" data-animate>
              <div className="flex flex-col md:flex-row gap-4">
                <div className="flex-1 relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                  <input
                    type="text"
                    placeholder="Search by promoter name or request ID..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>
                <div className="flex gap-4">
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-green-500"
                  >
                    <option value="all">All Status</option>
                    <option value="pending">Pending</option>
                    <option value="approved">Approved</option>
                    <option value="completed">Completed</option>
                    <option value="rejected">Rejected</option>
                  </select>
                </div>
              </div>
            </UnifiedCard>

            {/* Withdrawal Requests Table */}
            <UnifiedCard className="overflow-hidden" data-animate>
              {finalFilteredRequests.length === 0 ? (
                <div className="p-12 text-center">
                  <AlertCircle className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-white mb-2">No Withdrawal Requests</h3>
                  <p className="text-gray-400">
                    {withdrawalRequests.length === 0 
                      ? "No withdrawal requests have been submitted yet." 
                      : "No requests match your current filters."
                    }
                  </p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-700">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Request ID</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Promoter Details</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Amount</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Request Date</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="bg-gray-800 divide-y divide-gray-700">
                      {finalFilteredRequests.map((request) => (
                        <tr key={request.id} className="hover:bg-gray-700">
                          <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-white">
                            <p className="font-semibold">{request.request_number || 'N/A'}</p>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                            <div>
                              <p className="text-white font-medium">{request.profiles?.name || 'Unknown'}</p>
                              <p className="text-xs text-gray-400">{request.profiles?.promoter_id || 'No ID'}</p>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-white font-semibold">
                            ₹{(request.amount || 0).toLocaleString()}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <StatusBadge status={request.status} />
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                            {new Date(request.created_at || Date.now()).toLocaleDateString()}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                            <div className="flex space-x-2">
                              <button
                                onClick={() => viewDetails(request)}
                                className="text-blue-400 hover:text-blue-300 transition-colors"
                              >
                                <Eye className="w-4 h-4" />
                              </button>
                              {request.status === 'pending' && (
                                <>
                                  <button
                                    onClick={() => openActionModal(request, 'approved')}
                                    className="text-green-400 hover:text-green-300 transition-colors"
                                    title="Approve Request"
                                  >
                                    <CheckCircle className="w-4 h-4" />
                                  </button>
                                  <button
                                    onClick={() => openActionModal(request, 'rejected')}
                                    className="text-red-400 hover:text-red-300 transition-colors"
                                    title="Reject Request"
                                  >
                                    <XCircle className="w-4 h-4" />
                                  </button>
                                </>
                              )}
                              {request.status === 'approved' && (
                                <button
                                  onClick={() => openActionModal(request, 'completed')}
                                  className="text-blue-400 hover:text-blue-300 transition-colors"
                                  title="Mark as Completed"
                                >
                                  <DollarSign className="w-4 h-4" />
                                </button>
                              )}
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </UnifiedCard>
          </div>
        </div>

        {/* Action Modal */}
        {showModal && selectedRequest && actionType && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
            <UnifiedCard className="w-full max-w-md">
              <div className="p-6">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="text-xl font-semibold text-white">
                    {actionType === 'approved' && 'Approve Withdrawal Request'}
                    {actionType === 'rejected' && 'Reject Withdrawal Request'}
                    {actionType === 'completed' && 'Mark as Completed'}
                  </h3>
                  <button
                    onClick={closeActionModal}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <XCircle className="w-5 h-5" />
                  </button>
                </div>

                <div className="space-y-4 mb-6">
                  <div className="bg-gray-800/50 p-4 rounded-lg">
                    <p className="text-gray-400 text-sm">Request Details</p>
                    <p className="text-white font-medium">Amount: ₹{selectedRequest.amount?.toLocaleString()}</p>
                    <p className="text-gray-300 text-sm">Promoter: {selectedRequest.profiles?.name}</p>
                    <p className="text-gray-300 text-sm">Request ID: {selectedRequest.request_number || selectedRequest.id}</p>
                  </div>

                  {actionType === 'rejected' && (
                    <div>
                      <label className="block text-gray-400 text-sm mb-2">Rejection Reason *</label>
                      <textarea
                        value={rejectionReason}
                        onChange={(e) => setRejectionReason(e.target.value)}
                        className="w-full px-4 py-2 bg-gray-800/50 border border-gray-700/50 rounded-lg text-white focus:outline-none focus:border-red-500/50"
                        placeholder="Enter reason for rejection..."
                        rows="3"
                        required
                      />
                    </div>
                  )}

                  {actionType === 'completed' && (
                    <div>
                      <label className="block text-gray-400 text-sm mb-2">Transaction ID *</label>
                      <input
                        type="text"
                        value={transactionId}
                        onChange={(e) => setTransactionId(e.target.value)}
                        className="w-full px-4 py-2 bg-gray-800/50 border border-gray-700/50 rounded-lg text-white focus:outline-none focus:border-green-500/50"
                        placeholder="Enter transaction/reference ID..."
                        required
                      />
                    </div>
                  )}

                  <div>
                    <label className="block text-gray-400 text-sm mb-2">Admin Notes (Optional)</label>
                    <textarea
                      value={actionNotes}
                      onChange={(e) => setActionNotes(e.target.value)}
                      className="w-full px-4 py-2 bg-gray-800/50 border border-gray-700/50 rounded-lg text-white focus:outline-none focus:border-blue-500/50"
                      placeholder="Add any additional notes..."
                      rows="2"
                    />
                  </div>
                </div>

                <div className="flex justify-end space-x-3">
                  <UnifiedButton
                    variant="secondary"
                    onClick={closeActionModal}
                  >
                    Cancel
                  </UnifiedButton>
                  <UnifiedButton
                    onClick={() => handleAction(selectedRequest.id, actionType)}
                    disabled={actionType === 'rejected' && !rejectionReason || actionType === 'completed' && !transactionId}
                    className={`${
                      actionType === 'approved' ? 'bg-green-600 hover:bg-green-700' :
                      actionType === 'rejected' ? 'bg-red-600 hover:bg-red-700' :
                      'bg-blue-600 hover:bg-blue-700'
                    } disabled:opacity-50 disabled:cursor-not-allowed`}
                  >
                    {actionType === 'approved' && 'Approve Request'}
                    {actionType === 'rejected' && 'Reject Request'}
                    {actionType === 'completed' && 'Mark Completed'}
                  </UnifiedButton>
                </div>
              </div>
            </UnifiedCard>
          </div>
        )}

        {/* Details Modal */}
        {showModal && selectedRequest && !actionType && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
            <UnifiedCard className="w-full max-w-2xl">
              <div className="p-6">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="text-xl font-semibold text-white">Withdrawal Request Details</h3>
                  <button
                    onClick={closeDetailsModal}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <XCircle className="w-5 h-5" />
                  </button>
                </div>

                <div className="space-y-6">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-gray-400 text-sm">Request ID</p>
                      <p className="text-white font-mono">{selectedRequest.id}</p>
                    </div>
                    <div>
                      <p className="text-gray-400 text-sm">Status</p>
                      <div className="mt-1"><StatusBadge status={selectedRequest.status} /></div>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-gray-400 text-sm">Amount</p>
                      <p className="text-2xl font-bold text-white">₹{selectedRequest.amount?.toLocaleString()}</p>
                    </div>
                    <div>
                      <p className="text-gray-400 text-sm">Promoter</p>
                      <p className="text-white">{selectedRequest.profiles?.name}</p>
                      <p className="text-gray-300 text-sm">{selectedRequest.profiles?.email}</p>
                    </div>
                  </div>

                  <div>
                    <p className="text-gray-400 text-sm">Reason</p>
                    <p className="text-white">{selectedRequest.reason || 'No reason provided'}</p>
                  </div>

                  {selectedRequest.bank_details && (
                    <div>
                      <p className="text-gray-400 text-sm">Bank Details</p>
                      <div className="bg-gray-800/50 p-4 rounded-lg mt-1">
                        <p className="text-white">Bank: {selectedRequest.bank_details.bank_name}</p>
                        <p className="text-white">Account: {selectedRequest.bank_details.account_number}</p>
                        <p className="text-white">Holder: {selectedRequest.bank_details.account_holder}</p>
                        <p className="text-white">IFSC: {selectedRequest.bank_details.ifsc}</p>
                      </div>
                    </div>
                  )}

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-gray-400 text-sm">Request Date</p>
                      <p className="text-white">{new Date(selectedRequest.created_at).toLocaleString()}</p>
                    </div>
                    {selectedRequest.processed_at && (
                      <div>
                        <p className="text-gray-400 text-sm">Processed Date</p>
                        <p className="text-white">{new Date(selectedRequest.processed_at).toLocaleString()}</p>
                      </div>
                    )}
                  </div>

                  {selectedRequest.completed_at && (
                    <div>
                      <p className="text-gray-400 text-sm">Completed Date</p>
                      <p className="text-white">{new Date(selectedRequest.completed_at).toLocaleString()}</p>
                    </div>
                  )}

                  {selectedRequest.transaction_id && (
                    <div>
                      <p className="text-gray-400 text-sm">Transaction ID</p>
                      <p className="text-white font-mono">{selectedRequest.transaction_id}</p>
                    </div>
                  )}

                  {selectedRequest.admin_notes && (
                    <div>
                      <p className="text-gray-400 text-sm">Admin Notes</p>
                      <p className="text-white">{selectedRequest.admin_notes}</p>
                    </div>
                  )}

                  {selectedRequest.rejection_reason && (
                    <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
                      <p className="text-red-400 text-sm font-medium">Rejection Reason</p>
                      <p className="text-white mt-1">{selectedRequest.rejection_reason}</p>
                    </div>
                  )}
                </div>

                <div className="flex justify-end mt-6">
                  <UnifiedButton
                    variant="secondary"
                    onClick={closeDetailsModal}
                  >
                    Close
                  </UnifiedButton>
                </div>
              </div>
            </UnifiedCard>
          </div>
        )}
      </UnifiedBackground>
    </>
  );
}

export default AdminWithdrawals;
