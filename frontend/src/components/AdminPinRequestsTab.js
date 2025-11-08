/**
 * ADMIN PIN REQUESTS TAB COMPONENT
 * =================================
 * Admin interface for managing PIN requests (approve/reject)
 */

import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle, Clock, User, Calendar, MessageSquare, Pin } from 'lucide-react';
import { UnifiedCard, UnifiedButton } from '../common/components/SharedTheme';
import PinRequestTable from './PinRequestTable';
import pinRequestService from '../services/pinRequestService';
import pinTransactionService from '../services/pinTransactionService';

const AdminPinRequestsTab = ({ adminId, onSuccess, onError }) => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(false);
  const [stats, setStats] = useState({
    totalRequests: 0,
    pendingRequests: 0,
    approvedRequests: 0,
    rejectedRequests: 0
  });
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [showApprovalModal, setShowApprovalModal] = useState(false);
  const [approvalAction, setApprovalAction] = useState(null); // 'approve' or 'reject'
  const [adminNotes, setAdminNotes] = useState('');
  const [processing, setProcessing] = useState(false);

  // Load all PIN requests
  const loadRequests = async () => {
    try {
      setLoading(true);
      const [allRequests, requestStats] = await Promise.all([
        pinRequestService.getPinRequests(), // Get all requests for admin
        pinRequestService.getPinRequestStats() // Get overall stats
      ]);
      
      setRequests(allRequests);
      setStats(requestStats);
    } catch (error) {
      console.error('Failed to load PIN requests:', error);
      onError('Failed to load PIN requests');
    } finally {
      setLoading(false);
    }
  };

  // Load requests on component mount
  useEffect(() => {
    loadRequests();
  }, []);

  // Handle approve/reject action
  const handleAction = (request, action) => {
    setSelectedRequest(request);
    setApprovalAction(action);
    setAdminNotes('');
    setShowApprovalModal(true);
  };

  // Process the approval/rejection
  const processRequest = async () => {
    if (!selectedRequest || !approvalAction) return;

    try {
      setProcessing(true);
      
      if (approvalAction === 'approve') {
        // Approve and allocate PINs
        const result = await pinRequestService.approvePinRequest(
          selectedRequest.id,
          adminId,
          adminNotes || null
        );
        
        onSuccess(`PIN Request Approved!\n\nRequest: ${selectedRequest.formattedRequestNumber}\nPINs Allocated: ${selectedRequest.requested_pins}\nNew Balance: ${result.new_balance}`);
      } else {
        // Reject request
        await pinRequestService.rejectPinRequest(
          selectedRequest.id,
          adminId,
          adminNotes || 'Request rejected by admin'
        );
        
        onSuccess(`PIN Request Rejected!\n\nRequest: ${selectedRequest.formattedRequestNumber}\nReason: ${adminNotes || 'No reason provided'}`);
      }

      // Reload requests to show updated status
      await loadRequests();
      
      // Close modal
      setShowApprovalModal(false);
      setSelectedRequest(null);
      setApprovalAction(null);
      setAdminNotes('');

    } catch (error) {
      console.error('Failed to process request:', error);
      onError(`Failed to ${approvalAction} request: ${error.message}`);
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <UnifiedCard className="p-6 bg-gradient-to-br from-blue-500/10 to-indigo-500/10 border border-blue-500/30">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-300 text-sm font-semibold uppercase tracking-wider">Total Requests</p>
              <p className="text-3xl font-bold text-white mt-1">{stats.totalRequests}</p>
            </div>
            <div className="w-12 h-12 bg-blue-500/20 rounded-xl flex items-center justify-center">
              <Pin className="w-6 h-6 text-blue-400" />
            </div>
          </div>
        </UnifiedCard>

        <UnifiedCard className="p-6 bg-gradient-to-br from-yellow-500/10 to-orange-500/10 border border-yellow-500/30">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-yellow-300 text-sm font-semibold uppercase tracking-wider">Pending</p>
              <p className="text-3xl font-bold text-white mt-1">{stats.pendingRequests}</p>
            </div>
            <div className="w-12 h-12 bg-yellow-500/20 rounded-xl flex items-center justify-center">
              <Clock className="w-6 h-6 text-yellow-400" />
            </div>
          </div>
        </UnifiedCard>

        <UnifiedCard className="p-6 bg-gradient-to-br from-green-500/10 to-emerald-500/10 border border-green-500/30">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-300 text-sm font-semibold uppercase tracking-wider">Approved</p>
              <p className="text-3xl font-bold text-white mt-1">{stats.approvedRequests}</p>
            </div>
            <div className="w-12 h-12 bg-green-500/20 rounded-xl flex items-center justify-center">
              <CheckCircle className="w-6 h-6 text-green-400" />
            </div>
          </div>
        </UnifiedCard>

        <UnifiedCard className="p-6 bg-gradient-to-br from-red-500/10 to-pink-500/10 border border-red-500/30">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-red-300 text-sm font-semibold uppercase tracking-wider">Rejected</p>
              <p className="text-3xl font-bold text-white mt-1">{stats.rejectedRequests}</p>
            </div>
            <div className="w-12 h-12 bg-red-500/20 rounded-xl flex items-center justify-center">
              <XCircle className="w-6 h-6 text-red-400" />
            </div>
          </div>
        </UnifiedCard>
      </div>

      {/* PIN Requests Table */}
      <UnifiedCard className="overflow-hidden" variant="glassDark">
        <div className="p-6 border-b border-gray-700/50">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-2xl font-semibold text-white">PIN Requests Management</h3>
              <p className="text-gray-300 text-sm mt-1">
                Review and process promoter PIN requests
              </p>
            </div>
            <UnifiedButton
              onClick={loadRequests}
              className="flex items-center space-x-2 bg-orange-600 hover:bg-orange-700"
              disabled={loading}
            >
              <Clock className="w-4 h-4" />
              <span>Refresh</span>
            </UnifiedButton>
          </div>
        </div>
        <div className="p-6">
          <PinRequestTable 
            requests={requests}
            loading={loading}
            showPromoter={true}
            emptyMessage="No PIN requests found"
            onApprove={(request) => handleAction(request, 'approve')}
            onReject={(request) => handleAction(request, 'reject')}
            showActions={true}
          />
        </div>
      </UnifiedCard>

      {/* Approval/Rejection Modal */}
      {showApprovalModal && selectedRequest && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <UnifiedCard className="w-full max-w-md" variant="glassDark">
            <div className="p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center space-x-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                    approvalAction === 'approve' 
                      ? 'bg-gradient-to-r from-green-500 to-emerald-500' 
                      : 'bg-gradient-to-r from-red-500 to-pink-500'
                  }`}>
                    {approvalAction === 'approve' ? (
                      <CheckCircle className="w-5 h-5 text-white" />
                    ) : (
                      <XCircle className="w-5 h-5 text-white" />
                    )}
                  </div>
                  <h3 className="text-xl font-semibold text-white">
                    {approvalAction === 'approve' ? 'Approve' : 'Reject'} PIN Request
                  </h3>
                </div>
                <button
                  onClick={() => setShowApprovalModal(false)}
                  disabled={processing}
                  className="text-gray-300 hover:text-white transition-colors disabled:opacity-50"
                >
                  <XCircle className="w-5 h-5" />
                </button>
              </div>

              {/* Request Details */}
              <div className="bg-gray-800/50 rounded-lg p-4 mb-6">
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-gray-300">Request ID:</span>
                    <span className="text-white font-mono">{selectedRequest.formattedRequestNumber}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-gray-300">Promoter:</span>
                    <span className="text-white">{selectedRequest.promoter_name}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-gray-300">Requested PINs:</span>
                    <span className="text-orange-400 font-bold">{selectedRequest.requested_pins}</span>
                  </div>
                  <div className="flex items-start justify-between">
                    <span className="text-gray-300">Reason:</span>
                    <span className="text-white text-right max-w-xs">
                      {selectedRequest.reason || 'No reason provided'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Admin Notes */}
              <div className="mb-6">
                <label className="block text-gray-300 text-sm font-medium mb-2">
                  Admin Notes {approvalAction === 'reject' && <span className="text-red-400">*</span>}
                </label>
                <textarea
                  value={adminNotes}
                  onChange={(e) => setAdminNotes(e.target.value)}
                  placeholder={
                    approvalAction === 'approve' 
                      ? 'Optional notes about the approval...' 
                      : 'Reason for rejection (required)...'
                  }
                  rows={3}
                  disabled={processing}
                  className="w-full px-4 py-3 bg-gray-800/50 border border-gray-700/50 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-orange-500/20 resize-none transition-colors disabled:opacity-50"
                />
              </div>

              {/* Action Buttons */}
              <div className="flex justify-end space-x-3">
                <UnifiedButton
                  variant="secondary"
                  onClick={() => setShowApprovalModal(false)}
                  disabled={processing}
                >
                  Cancel
                </UnifiedButton>
                <UnifiedButton
                  onClick={processRequest}
                  disabled={processing || (approvalAction === 'reject' && !adminNotes.trim())}
                  className={`flex items-center space-x-2 ${
                    approvalAction === 'approve'
                      ? 'bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700'
                      : 'bg-gradient-to-r from-red-500 to-pink-600 hover:from-red-600 hover:to-pink-700'
                  } disabled:opacity-50 disabled:cursor-not-allowed`}
                >
                  {processing ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-2 border-white/30 border-t-white"></div>
                      <span>Processing...</span>
                    </>
                  ) : (
                    <>
                      {approvalAction === 'approve' ? (
                        <CheckCircle className="w-4 h-4" />
                      ) : (
                        <XCircle className="w-4 h-4" />
                      )}
                      <span>{approvalAction === 'approve' ? 'Approve & Allocate' : 'Reject Request'}</span>
                    </>
                  )}
                </UnifiedButton>
              </div>
            </div>
          </UnifiedCard>
        </div>
      )}
    </div>
  );
};

export default AdminPinRequestsTab;
