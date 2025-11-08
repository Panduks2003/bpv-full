import React, { useState, useEffect, useCallback, memo } from 'react';
import { CheckCircle, Clock, X } from 'lucide-react';
import { UnifiedButton, UnifiedCard } from './SharedTheme';
import { supabase } from "../services/supabaseClient"

// Memoized payment row component
const PaymentRow = memo(({ payment, onMarkPaid, currentUser, isAdmin, readOnly = false }) => {
  const [marking, setMarking] = useState(false);
  const [notes, setNotes] = useState('');
  const [showNotesInput, setShowNotesInput] = useState(false);

  const handleMarkPaid = async () => {
    if (payment.status === 'paid') return;
    
    setMarking(true);
    try {
      await onMarkPaid(payment.month_number, notes);
      setShowNotesInput(false);
      setNotes('');
    } catch (error) {
    } finally {
      setMarking(false);
    }
  };

  const getStatusBadge = (status) => {
    if (status === 'paid') {
      return (
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-500/20 text-green-400">
          <CheckCircle className="w-3 h-3 mr-1" />
          Paid
        </span>
      );
    }
    return (
      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-500/20 text-yellow-400">
        <Clock className="w-3 h-3 mr-1" />
        Pending
      </span>
    );
  };

  return (
    <tr className="hover:bg-gray-700/30 transition-colors">
      <td className="px-4 py-3 text-white font-medium">Month {payment.month_number}</td>
      <td className="px-4 py-3 text-white">₹{(payment.amount || payment.payment_amount || 1000)?.toLocaleString()}</td>
      <td className="px-4 py-3">{getStatusBadge(payment.status)}</td>
      <td className="px-4 py-3 text-gray-300">
        {payment.payment_date ? new Date(payment.payment_date).toLocaleDateString() : '-'}
      </td>
      <td className="px-4 py-3 text-gray-300">
        {payment.marked_by_name || '-'}
      </td>
      <td className="px-4 py-3 text-gray-300 max-w-xs truncate">
        {payment.notes || '-'}
      </td>
      <td className="px-4 py-3">
        {payment.status === 'pending' && isAdmin && !readOnly && (
          <div className="flex items-center space-x-2">
            {!showNotesInput ? (
              <UnifiedButton
                onClick={() => setShowNotesInput(true)}
                className="px-3 py-1 text-xs bg-green-600 hover:bg-green-700"
                disabled={marking}
              >
                Mark Paid
              </UnifiedButton>
            ) : (
              <div className="flex items-center space-x-2">
                <input
                  type="text"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Optional notes"
                  className="px-2 py-1 text-xs bg-gray-700 border border-gray-600 rounded text-white w-24"
                />
                <UnifiedButton
                  onClick={handleMarkPaid}
                  className="px-2 py-1 text-xs bg-green-600 hover:bg-green-700"
                  disabled={marking}
                >
                  {marking ? '...' : '✓'}
                </UnifiedButton>
                <button
                  onClick={() => {
                    setShowNotesInput(false);
                    setNotes('');
                  }}
                  className="text-gray-400 hover:text-white"
                >
                  <X className="w-3 h-3" />
                </button>
              </div>
            )}
          </div>
        )}
      </td>
    </tr>
  );
});

const PaymentManager = memo(({ 
  customerId, 
  customerName, 
  isOpen, 
  onClose, 
  currentUser,
  readOnly = false
}) => {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Load payment history
  const loadPayments = useCallback(async () => {
    if (!customerId) {
      return;
    }

    setLoading(true);
    setError(null);
    
    try {
      // First get the payments
      const { data: paymentsData, error: paymentsError } = await supabase
        .from('customer_payments')
        .select('*')
        .eq('customer_id', customerId)
        .order('month_number', { ascending: true });

      if (paymentsError) {
        throw paymentsError;
      }
      
      // Get unique marked_by user IDs
      const markedByIds = [...new Set(paymentsData?.filter(p => p.marked_by).map(p => p.marked_by) || [])];
      
      let userNames = {};
      if (markedByIds.length > 0) {
        // Get user names for marked_by IDs
        const { data: usersData, error: usersError } = await supabase
          .from('profiles')
          .select('id, name')
          .in('id', markedByIds);
          
        if (!usersError && usersData) {
          userNames = Object.fromEntries(usersData.map(user => [user.id, user.name]));
        } else if (usersError) {
          console.error('❌ Error loading user names:', usersError);
        }
      }
      
      // Transform data to include marked_by_name
      const paymentsWithNames = (paymentsData || []).map(payment => ({
        ...payment,
        marked_by_name: payment.marked_by ? (userNames[payment.marked_by] || 'Unknown User') : null
      }));
      
      setPayments(paymentsWithNames);
    } catch (error) {
      setError('Failed to load payment history');
    } finally {
      setLoading(false);
    }
  }, [customerId]);

  // Mark payment as paid
  const handleMarkPaid = useCallback(async (monthNumber, notes = '') => {
    try {
      const { error } = await supabase
        .from('customer_payments')
        .update({
          status: 'paid',
          payment_date: new Date().toISOString(),
          marked_by: currentUser?.id,
          notes: notes || null,
          updated_at: new Date().toISOString()
        })
        .eq('customer_id', customerId)
        .eq('month_number', monthNumber);

      if (error) throw error;
      

      // Reload payments to reflect changes
      await loadPayments();
      
    } catch (error) {
      throw error;
    }
  }, [customerId, currentUser?.id, loadPayments]);

  // Load payments when modal opens
  useEffect(() => {
    if (isOpen && customerId) {
      loadPayments();
    }
  }, [isOpen, customerId, loadPayments]);

  // Calculate payment summary
  const paymentSummary = React.useMemo(() => {
    const totalPayments = payments.length;
    const paidPayments = payments.filter(p => p.status === 'paid').length;
    const pendingPayments = totalPayments - paidPayments;
    const totalPaidAmount = payments
      .filter(p => p.status === 'paid')
      .reduce((sum, p) => sum + (parseFloat(p.amount || p.payment_amount) || 1000), 0);

    return {
      totalPayments,
      paidPayments,
      pendingPayments,
      totalPaidAmount,
      completionPercentage: totalPayments > 0 ? (paidPayments / totalPayments) * 100 : 0
    };
  }, [payments]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div className="bg-gray-800 rounded-lg w-full max-w-6xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-700">
          <div>
            <h3 className="text-xl font-semibold text-white">Payment Management</h3>
            <p className="text-gray-400 mt-1">
              {customerName} - ₹1000 per month for 20 months
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Payment Summary */}
        <div className="p-6 border-b border-gray-700">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <UnifiedCard className="p-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-green-400">
                  {paymentSummary.paidPayments}
                </div>
                <div className="text-sm text-gray-400">Paid</div>
              </div>
            </UnifiedCard>
            
            <UnifiedCard className="p-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-yellow-400">
                  {paymentSummary.pendingPayments}
                </div>
                <div className="text-sm text-gray-400">Pending</div>
              </div>
            </UnifiedCard>
            
            <UnifiedCard className="p-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-blue-400">
                  ₹{paymentSummary.totalPaidAmount.toLocaleString()}
                </div>
                <div className="text-sm text-gray-400">Total Paid</div>
              </div>
            </UnifiedCard>
            
            <UnifiedCard className="p-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-orange-400">
                  {paymentSummary.completionPercentage.toFixed(0)}%
                </div>
                <div className="text-sm text-gray-400">Complete</div>
              </div>
            </UnifiedCard>
          </div>

          {/* Progress Bar */}
          <div className="mt-4">
            <div className="flex justify-between text-sm text-gray-400 mb-2">
              <span>Payment Progress</span>
              <span>{paymentSummary.paidPayments} of {paymentSummary.totalPayments} months</span>
            </div>
            <div className="w-full bg-gray-700 rounded-full h-2">
              <div 
                className="bg-gradient-to-r from-green-500 to-blue-500 h-2 rounded-full transition-all duration-300"
                style={{ width: `${paymentSummary.completionPercentage}%` }}
              ></div>
            </div>
          </div>
        </div>

        {/* Payment History Table */}
        <div className="p-6 overflow-y-auto max-h-[calc(90vh-400px)]">
          {loading ? (
            <div className="flex items-center justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-2 border-orange-400 border-t-transparent"></div>
              <span className="ml-3 text-white">Loading payment history...</span>
            </div>
          ) : error ? (
            <div className="text-center py-8">
              <div className="text-red-400 mb-2">{error}</div>
              <UnifiedButton onClick={loadPayments} className="text-sm">
                Retry
              </UnifiedButton>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-700">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase">Month</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase">Amount</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase">Status</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase">Payment Date</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase">Marked By</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase">Notes</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-300 uppercase">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-gray-800 divide-y divide-gray-700">
                  {payments.map((payment) => (
                    <PaymentRow
                      key={payment.month_number}
                      payment={payment}
                      onMarkPaid={handleMarkPaid}
                      currentUser={currentUser}
                      isAdmin={currentUser?.role === 'admin'}
                      readOnly={readOnly}
                    />
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end p-6 border-t border-gray-700">
          <UnifiedButton
            onClick={onClose}
            variant="secondary"
          >
            Close
          </UnifiedButton>
        </div>
      </div>
    </div>
  );
});

export default PaymentManager;
