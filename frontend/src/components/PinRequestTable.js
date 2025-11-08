/**
 * PIN REQUEST TABLE COMPONENT
 * ============================
 * Table for displaying PIN request status and history
 */

import React, { memo } from 'react';
import { FileText, Clock, CheckCircle, XCircle, User, Calendar } from 'lucide-react';

const PinRequestTable = memo(({ 
  requests, 
  loading = false,
  showPromoter = false, // For admin view
  emptyMessage = "No PIN requests found",
  onApprove = null, // Admin action callback
  onReject = null, // Admin action callback
  showActions = false // Show approve/reject buttons
}) => {
  
  const getStatusIcon = (status) => {
    switch (status) {
      case 'pending':
        return <Clock className="w-4 h-4 text-yellow-400" />;
      case 'approved':
        return <CheckCircle className="w-4 h-4 text-green-400" />;
      case 'rejected':
        return <XCircle className="w-4 h-4 text-red-400" />;
      default:
        return <FileText className="w-4 h-4 text-gray-400" />;
    }
  };

  const getStatusBadge = (request) => {
    const config = request.statusConfig;
    const colorClasses = {
      yellow: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
      green: 'bg-green-500/20 text-green-400 border-green-500/30',
      red: 'bg-red-500/20 text-red-400 border-red-500/30',
      gray: 'bg-gray-500/20 text-gray-400 border-gray-500/30'
    };

    return (
      <span className={`inline-flex items-center space-x-1 px-2.5 py-1 rounded-full text-xs font-medium border ${colorClasses[config.color]}`}>
        {getStatusIcon(request.status)}
        <span>{config.emoji} {config.label}</span>
      </span>
    );
  };

  if (loading) {
    return (
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-800/50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Request ID</th>
              {showPromoter && <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Promoter</th>}
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">PINs</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Reason</th>
              {showActions && <th className="px-6 py-3 text-center text-xs font-medium text-gray-300 uppercase tracking-wider">Actions</th>}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700/50">
            {[1, 2, 3, 4, 5].map(i => (
              <tr key={i} className="animate-pulse">
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-20"></div></td>
                {showPromoter && <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-32"></div></td>}
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-12"></div></td>
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-24"></div></td>
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-20"></div></td>
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-40"></div></td>
                {showActions && <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-24"></div></td>}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }

  if (requests.length === 0) {
    return (
      <div className="text-center py-12">
        <FileText className="w-16 h-16 text-gray-600 mb-4 mx-auto" />
        <p className="text-gray-300 text-lg mb-2">{emptyMessage}</p>
        <p className="text-gray-400 text-sm">PIN requests will appear here when submitted.</p>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-gray-800/50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Request ID</th>
            {showPromoter && (
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Promoter</th>
            )}
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">PINs</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Reason</th>
            {showPromoter && (
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Admin Response</th>
            )}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-700/50">
          {requests.map((request) => (
            <tr key={request.id} className="hover:bg-gray-800/30 transition-colors">
              {/* Request ID */}
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                  {request.formattedRequestNumber}
                </span>
              </td>
              
              {/* Promoter (Admin view only) */}
              {showPromoter && (
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center space-x-2">
                    <User className="w-4 h-4 text-gray-400" />
                    <div>
                      <div className="text-sm font-medium text-white">{request.promoter_name || 'Promoter'}</div>
                      <div className="text-xs text-gray-400">{request.promoter_email || 'Email not available'}</div>
                    </div>
                  </div>
                </td>
              )}
              
              {/* Requested PINs */}
              <td className="px-6 py-4 whitespace-nowrap">
                <div className="flex items-center space-x-2">
                  <div className="w-8 h-8 bg-orange-500/20 rounded-lg flex items-center justify-center">
                    <span className="text-orange-400 text-sm font-bold">{request.requested_pins}</span>
                  </div>
                  <span className="text-gray-300 text-sm">PIN{request.requested_pins > 1 ? 's' : ''}</span>
                </div>
              </td>
              
              {/* Status */}
              <td className="px-6 py-4 whitespace-nowrap">
                {getStatusBadge(request)}
              </td>
              
              {/* Date */}
              <td className="px-6 py-4 whitespace-nowrap">
                <div className="flex items-center space-x-2">
                  <Calendar className="w-4 h-4 text-gray-400" />
                  <div>
                    <div className="text-sm text-white">{request.formattedDate}</div>
                    <div className="text-xs text-gray-400">{request.formattedTime}</div>
                  </div>
                </div>
              </td>
              
              {/* Reason */}
              <td className="px-6 py-4 text-sm text-gray-300 max-w-xs">
                <div className="truncate" title={request.reason || 'No reason provided'}>
                  {request.reason || (
                    <span className="text-gray-500 italic">No reason provided</span>
                  )}
                </div>
              </td>
              
              {/* Admin Response (Admin view only) */}
              {showPromoter && (
                <td className="px-6 py-4 text-sm text-gray-300 max-w-xs">
                  {request.admin_notes ? (
                    <div>
                      <div className="truncate" title={request.admin_notes}>
                        {request.admin_notes}
                      </div>
                      {request.admin_name && (
                        <div className="text-xs text-gray-500 mt-1">
                          by {request.admin_name}
                        </div>
                      )}
                    </div>
                  ) : (
                    <span className="text-gray-500 italic">
                      {request.status === 'pending' ? 'Awaiting review' : 'No notes'}
                    </span>
                  )}
                </td>
              )}
              
              {/* Actions (Admin only) */}
              {showActions && (
                <td className="px-6 py-4 whitespace-nowrap text-center">
                  {request.status === 'pending' ? (
                    <div className="flex items-center justify-center space-x-2">
                      <button
                        onClick={() => onApprove && onApprove(request)}
                        className="inline-flex items-center px-3 py-1.5 bg-green-600 hover:bg-green-700 text-white text-xs font-medium rounded-lg transition-colors"
                        title="Approve and allocate PINs"
                      >
                        <CheckCircle className="w-3 h-3 mr-1" />
                        Approve
                      </button>
                      <button
                        onClick={() => onReject && onReject(request)}
                        className="inline-flex items-center px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white text-xs font-medium rounded-lg transition-colors"
                        title="Reject request"
                      >
                        <XCircle className="w-3 h-3 mr-1" />
                        Reject
                      </button>
                    </div>
                  ) : (
                    <span className="text-gray-500 text-xs italic">
                      {request.status === 'approved' ? 'Approved' : 'Rejected'}
                    </span>
                  )}
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
});

PinRequestTable.displayName = 'PinRequestTable';

export default PinRequestTable;
