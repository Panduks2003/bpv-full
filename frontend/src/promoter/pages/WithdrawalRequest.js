import React, { useState, useEffect } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import { useNavigate } from 'react-router-dom';
import { supabase } from "../../common/services/supabaseClient"
import PromoterNavbar from '../components/PromoterNavbar';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { SkeletonFullPage } from '../components/skeletons';
import { 
  Wallet, 
  DollarSign, 
  Clock, 
  CheckCircle,
  XCircle,
  AlertCircle,
  CreditCard,
  Building2,
  Calendar,
  History,
  Plus,
  Eye,
  Download
} from 'lucide-react';

function WithdrawalRequest() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  useScrollAnimation();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showWithdrawalForm, setShowWithdrawalForm] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [withdrawalAmount, setWithdrawalAmount] = useState('');
  const [withdrawalReason, setWithdrawalReason] = useState('');
  const [selectedBank, setSelectedBank] = useState('');
  const [requestedDate, setRequestedDate] = useState(new Date().toISOString().split('T')[0]);
  const [submitting, setSubmitting] = useState(false);
  
  // Real data states
  const [accountBalance, setAccountBalance] = useState({
    available: 0,
    pending: 0,
    total: 0,
    minimumWithdrawal: 500
  });
  const [bankAccounts, setBankAccounts] = useState([]);
  const [withdrawalHistory, setWithdrawalHistory] = useState([]);

  // Load data from Supabase
  useEffect(() => {
    if (user?.id) {
      loadWithdrawalData();
    }
  }, [user]);

  // Auto-refresh data every 30 seconds to catch status updates
  useEffect(() => {
    if (user?.id) {
      const interval = setInterval(() => {
        loadWithdrawalData();
      }, 30000); // 30 seconds

      return () => clearInterval(interval);
    }
  }, [user]);

  const loadWithdrawalData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Initialize default values
      let totalEarnings = 0;
      let paymentsData = [];
      let commissionsData = [];
      
      // Try to get promoter's earnings from payments table (with fallback)
      try {
        const { data, error } = await supabase
          .from('payments')
          .select('amount, payment_type, status')
          .eq('promoter_id', user.id);
        
        if (error) {
          // Use fallback data or promoter_wallet if available
        } else {
          paymentsData = data || [];
        }
      } catch (err) {
        // Payments query failed, using fallback
      }
      
      // Try to get commissions data (with fallback)
      try {
        const { data, error } = await supabase
          .from('commissions')
          .select('commission_amount, status')
          .eq('promoter_id', user.id);
        
        if (error) {
          // Try alternative: affiliate_commissions table
          try {
            const { data: altData, error: altError } = await supabase
              .from('affiliate_commissions')
              .select('amount, status')
              .eq('recipient_id', user.id);
            
            if (!altError && altData) {
              // Map affiliate_commissions to expected format
              commissionsData = altData.map(item => ({
                ...item,
                commission_amount: item.amount // affiliate_commissions uses 'amount'
              }));
            }
          } catch (altErr) {
            // Alternative commissions query also failed
          }
        } else {
          commissionsData = data || [];
        }
      } catch (err) {
        // Commissions query failed, using fallback
      }
      
      // Try promoter_wallet as fallback for balance calculation
      try {
        const { data: walletData, error: walletError } = await supabase
          .from('promoter_wallet')
          .select('balance, total_earned, total_withdrawn')
          .eq('promoter_id', user.id)
          .single();
        
        if (!walletError && walletData) {
          totalEarnings = walletData.total_earned || 0;
        }
      } catch (walletErr) {
        // Promoter wallet not available, calculating from transactions
      }
      
      // Calculate available balance (fallback calculation if wallet data not available)
      if (totalEarnings === 0) {
        totalEarnings = [
          ...(paymentsData || []).filter(p => p.payment_type === 'credit' && p.status === 'completed'),
          ...(commissionsData || []).filter(c => c.status === 'credited' || c.status === 'completed')
        ].reduce((sum, item) => {
          // Handle both amount and commission_amount fields
          const amount = item.amount || item.commission_amount || 0;
          return sum + parseFloat(amount);
        }, 0);
      }
      
      // Get withdrawal requests (with fallback for missing columns)
      let withdrawalsData = [];
      try {
        const { data, error } = await supabase
          .from('withdrawal_requests')
          .select(`
            id,
            request_number,
            amount,
            status,
            reason,
            created_at,
            processed_at,
            transaction_id,
            rejection_reason,
            bank_details,
            admin_notes
          `)
          .eq('promoter_id', user.id)
          .order('created_at', { ascending: false });
        
        if (error) {
          // Fallback to basic columns only
          const { data: basicData, error: basicError } = await supabase
            .from('withdrawal_requests')
            .select('id, request_number, amount, status, reason, created_at')
            .eq('promoter_id', user.id)
            .order('created_at', { ascending: false });
          
          if (!basicError) {
            withdrawalsData = basicData || [];
          }
        } else {
          withdrawalsData = data || [];
        }
      } catch (err) {
        withdrawalsData = [];
      }
      
      
      const totalWithdrawn = (withdrawalsData || [])
        .filter(w => w.status === 'completed')
        .reduce((sum, w) => sum + (w.amount || 0), 0);
      
      const approvedPendingPayment = (withdrawalsData || [])
        .filter(w => w.status === 'approved')
        .reduce((sum, w) => sum + (w.amount || 0), 0);
      
      const pendingWithdrawals = (withdrawalsData || [])
        .filter(w => w.status === 'pending')
        .reduce((sum, w) => sum + (w.amount || 0), 0);
      
      const availableBalance = totalEarnings - totalWithdrawn - pendingWithdrawals - approvedPendingPayment;
      
      setAccountBalance({
        available: Math.max(0, availableBalance),
        pending: pendingWithdrawals,
        approved: approvedPendingPayment,
        total: totalEarnings - totalWithdrawn,
        minimumWithdrawal: 500
      });
      
      // Transform withdrawal history (handle missing columns gracefully)
      const transformedHistory = (withdrawalsData || []).map(withdrawal => ({
        id: withdrawal.id,
        requestNumber: withdrawal.request_number || 'N/A',
        amount: parseFloat(withdrawal.amount) || 0,
        status: withdrawal.status || 'pending',
        reason: withdrawal.reason || 'No reason provided',
        requestDate: withdrawal.created_at,
        processedDate: withdrawal.processed_at || null,
        transactionId: withdrawal.transaction_id || null,
        rejectionReason: withdrawal.rejection_reason || null,
        adminNotes: withdrawal.admin_notes || null
      }));
      
      setWithdrawalHistory(transformedHistory);
      
      // Get bank accounts from promoter profile (with fallback)
      let promoterData = null;
      try {
        const { data, error } = await supabase
          .from('profiles')
          .select('bank_accounts')
          .eq('id', user.id)
          .eq('role', 'promoter')
          .single();
        
        if (error) {
          // Try without bank_accounts column
          const { data: basicProfile } = await supabase
            .from('profiles')
            .select('id, name')
            .eq('id', user.id)
            .single();
          promoterData = basicProfile;
        } else {
          promoterData = data;
        }
      } catch (err) {
        // Profile query failed, using fallback
      }
      
      // Set bank accounts (use profile data or default)
      const profileBankAccounts = promoterData?.bank_accounts || [];
      const defaultBankAccounts = profileBankAccounts.length > 0 ? profileBankAccounts : [
        {
          id: 1,
          bankName: 'State Bank of India',
          accountNumber: '****1234',
          accountHolder: user.name || 'Promoter',
          ifsc: 'SBIN0001234',
          isDefault: true
        }
      ];
      
      setBankAccounts(defaultBankAccounts);
      
    } catch (err) {
      setError('Failed to load withdrawal data');
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-4 h-4 text-green-400" />;
      case 'approved':
        return <CheckCircle className="w-4 h-4 text-blue-400" />;
      case 'pending':
        return <Clock className="w-4 h-4 text-yellow-400" />;
      case 'rejected':
        return <XCircle className="w-4 h-4 text-red-400" />;
      default:
        return <Clock className="w-4 h-4 text-gray-400" />;
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed':
        return 'bg-green-500/20 text-green-400 border-green-500/30';
      case 'approved':
        return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
      case 'pending':
        return 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30';
      case 'rejected':
        return 'bg-red-500/20 text-red-400 border-red-500/30';
      default:
        return 'bg-gray-500/20 text-gray-400 border-gray-500/30';
    }
  };

  const handleWithdrawalSubmit = async (e) => {
    e.preventDefault();
    
    if (!withdrawalAmount || !selectedBank) {
      alert('Please fill in all required fields');
      return;
    }
    
    const amount = parseFloat(withdrawalAmount);
    if (amount < accountBalance.minimumWithdrawal) {
      alert(`Minimum withdrawal amount is ₹${accountBalance.minimumWithdrawal}`);
      return;
    }
    
    if (amount > accountBalance.available) {
      alert('Insufficient balance for this withdrawal');
      return;
    }
    
    try {
      setSubmitting(true);
      
      // Verify user is authenticated
      if (!user || !user.id) {
        throw new Error('Not authenticated. Please log in again.');
      }
      
      const selectedBankAccount = bankAccounts.find(bank => bank.id == selectedBank);
      
      const { data, error } = await supabase
        .from('withdrawal_requests')
        .insert({
          promoter_id: user.id, // Use user.id from context (already set to auth.uid())
          amount: amount,
          reason: withdrawalReason || 'Withdrawal request',
          requested_date: requestedDate,
          status: 'pending',
          bank_details: {
            bank_name: selectedBankAccount?.bankName,
            account_number: selectedBankAccount?.accountNumber,
            account_holder: selectedBankAccount?.accountHolder,
            ifsc: selectedBankAccount?.ifsc
          }
          // Don't set created_at - let database default handle it
          // Don't set id - UUID will be auto-generated by database
        })
        .select()
        .single();
      
      if (error) throw error;
      
      alert('Withdrawal request submitted successfully! You will receive a confirmation email shortly.');
      
      // Reset form and reload data
      setShowWithdrawalForm(false);
      setWithdrawalAmount('');
      setWithdrawalReason('');
      setSelectedBank('');
      setRequestedDate(new Date().toISOString().split('T')[0]);
      
      // Reload withdrawal data
      await loadWithdrawalData();
      
    } catch (error) {
      alert('Failed to submit withdrawal request: ' + error.message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <>
      <SharedStyles />
      <PromoterNavbar />
      <UnifiedBackground>
        <div>
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-orange-500/5 via-transparent to-yellow-500/5"></div>
            <div className="relative max-w-6xl mx-auto px-6 pt-40 pb-12">
              {/* Clean Header */}
              <div className="text-center mb-6" data-animate>
                <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">
                  Withdrawal Request
                </h1>
                <p className="text-gray-300 mb-6">Manage your withdrawal requests and earnings</p>
                
                {error && (
                  <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4 mb-4 max-w-2xl mx-auto">
                    <p className="text-red-400 flex items-center justify-center">
                      <XCircle className="w-5 h-5 mr-2" />
                      {error}
                    </p>
                  </div>
                )}
                
                {/* Action Buttons */}
                <div className="flex justify-center gap-4">
                  <button
                    onClick={() => setShowWithdrawalForm(true)}
                    disabled={loading || accountBalance.available < accountBalance.minimumWithdrawal}
                    className="inline-flex items-center justify-center px-6 py-3 bg-gradient-to-r from-orange-500 to-yellow-500 text-white font-semibold rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <Plus className="w-5 h-5 mr-2" />
                    New Withdrawal Request
                  </button>
                  
                  <button
                    onClick={() => {
                      loadWithdrawalData();
                    }}
                    disabled={loading}
                    className="inline-flex items-center justify-center px-4 py-3 bg-gradient-to-r from-blue-500 to-indigo-500 text-white font-semibold rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <History className="w-5 h-5 mr-2" />
                    Refresh Status
                  </button>
                </div>
              </div>

            {/* Enhanced Balance Overview */}
            {loading ? (
              <div className="mb-12">
                <SkeletonFullPage type="withdrawals" />
              </div>
            ) : (
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-12" data-animate>
              <UnifiedCard className="p-8 bg-gradient-to-br from-green-500/10 to-emerald-500/10 border border-green-500/30 hover:border-green-400/50 transition-all duration-300">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-green-300 text-sm font-semibold uppercase tracking-wider">Available Balance</p>
                    <p className="text-4xl font-bold text-white mt-2">₹{accountBalance.available.toLocaleString()}</p>
                  </div>
                  <div className="w-16 h-16 bg-green-500/20 rounded-xl flex items-center justify-center">
                    <Wallet className="w-8 h-8 text-green-400" />
                  </div>
                </div>
                <div className="flex items-center mt-6 text-sm">
                  <div className="w-2 h-2 bg-green-400 rounded-full mr-2"></div>
                  <span className="text-green-300">Ready for withdrawal</span>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-8 bg-gradient-to-br from-yellow-500/10 to-orange-500/10 border border-yellow-500/30 hover:border-yellow-400/50 transition-all duration-300">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-yellow-300 text-sm font-semibold uppercase tracking-wider">Pending Withdrawals</p>
                    <p className="text-4xl font-bold text-white mt-2">₹{accountBalance.pending.toLocaleString()}</p>
                  </div>
                  <div className="w-16 h-16 bg-yellow-500/20 rounded-xl flex items-center justify-center">
                    <Clock className="w-8 h-8 text-yellow-400" />
                  </div>
                </div>
                <div className="flex items-center mt-6 text-sm">
                  <div className="w-2 h-2 bg-yellow-400 rounded-full mr-2"></div>
                  <span className="text-yellow-300">{withdrawalHistory.filter(w => w.status === 'pending').length} requests processing</span>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6 bg-gradient-to-br from-blue-500/10 to-indigo-500/10 border border-blue-500/30 hover:border-blue-400/50 transition-all duration-300">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-blue-300 text-sm font-semibold uppercase tracking-wider">Approved</p>
                    <p className="text-3xl font-bold text-white mt-2">₹{(accountBalance.approved || 0).toLocaleString()}</p>
                  </div>
                  <div className="w-12 h-12 bg-blue-500/20 rounded-xl flex items-center justify-center">
                    <CheckCircle className="w-6 h-6 text-blue-400" />
                  </div>
                </div>
                <div className="flex items-center mt-4 text-sm">
                  <div className="w-2 h-2 bg-blue-400 rounded-full mr-2"></div>
                  <span className="text-blue-300">Awaiting payment</span>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6 bg-gradient-to-br from-purple-500/10 to-pink-500/10 border border-purple-500/30 hover:border-purple-400/50 transition-all duration-300">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-purple-300 text-sm font-semibold uppercase tracking-wider">Total Balance</p>
                    <p className="text-3xl font-bold text-white mt-2">₹{accountBalance.total.toLocaleString()}</p>
                  </div>
                  <div className="w-12 h-12 bg-purple-500/20 rounded-xl flex items-center justify-center">
                    <DollarSign className="w-6 h-6 text-purple-400" />
                  </div>
                </div>
                <div className="flex items-center mt-4 text-sm">
                  <div className="w-2 h-2 bg-purple-400 rounded-full mr-2"></div>
                  <span className="text-purple-300">Net earnings balance</span>
                </div>
              </UnifiedCard>
            </div>
            )}


            {/* Enhanced Withdrawal History */}
            <UnifiedCard className="overflow-hidden border border-slate-700/50 bg-gradient-to-br from-slate-800/50 to-slate-900/50" data-animate>
              <div className="p-8 border-b border-slate-700/50 bg-gradient-to-r from-slate-800/80 to-slate-900/80">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-3xl font-bold text-white mb-2">Withdrawal History</h3>
                    <p className="text-gray-300 text-lg">Real-time withdrawal requests and status from Supabase database</p>
                  </div>
                  <div className="flex items-center space-x-4">
                    <div className="text-right">
                      <p className="text-2xl font-bold text-purple-400">{withdrawalHistory.length}</p>
                      <p className="text-sm text-gray-400">Total Requests</p>
                    </div>
                    <UnifiedButton 
                      variant="secondary" 
                      className="flex items-center space-x-2 bg-gradient-to-r from-blue-500/20 to-purple-500/20 border border-blue-500/30 hover:border-blue-400/50"
                    >
                      <Download className="w-4 h-4" />
                      <span>Export Report</span>
                    </UnifiedButton>
                  </div>
                </div>
              </div>
              {withdrawalHistory.length === 0 ? (
                <div className="flex items-center justify-center py-20">
                  <div className="text-center">
                    <Wallet className="w-16 h-16 text-gray-600 mx-auto mb-4" />
                    <p className="text-gray-400 text-lg mb-2">No withdrawal requests found</p>
                    <p className="text-gray-500 text-sm">
                      Create your first withdrawal request to see your history here.
                    </p>
                  </div>
                </div>
              ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-slate-800/50">
                    <tr>
                      <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Request ID
                      </th>
                      <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Amount
                      </th>
                      <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Bank Account
                      </th>
                      <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Request Date
                      </th>
                      <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Status
                      </th>
                      <th className="px-6 py-4 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-700/50">
                    {withdrawalHistory.map((request) => (
                      <tr key={request.id} className="hover:bg-gray-800/30 transition-colors">
                        <td className="px-6 py-4">
                          <div className="flex items-center space-x-3">
                            <div className="w-8 h-8 bg-purple-500/20 rounded-lg flex items-center justify-center">
                              <CreditCard className="w-4 h-4 text-purple-400" />
                            </div>
                            <div>
                              <p className="text-white font-medium">{request.requestNumber}</p>
                              <p className="text-gray-400 text-sm">{request.reason}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <span className="text-white font-semibold">₹{request.amount.toLocaleString()}</span>
                        </td>
                        <td className="px-6 py-4 text-gray-300">
                          {request.bankAccount}
                        </td>
                        <td className="px-6 py-4 text-gray-300">
                          <div>
                            <p>{request.requestDate ? new Date(request.requestDate).toLocaleDateString() : 'N/A'}</p>
                            <p className="text-xs text-gray-500">
                              {request.requestDate ? new Date(request.requestDate).toLocaleTimeString() : ''}
                            </p>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center space-x-2">
                            {getStatusIcon(request.status)}
                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${getStatusColor(request.status)}`}>
                              {request.status.charAt(0).toUpperCase() + request.status.slice(1)}
                            </span>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <button
                            onClick={() => setSelectedRequest(request)}
                            className="text-green-400 hover:text-green-300 transition-colors"
                          >
                            <Eye className="w-4 h-4" />
                          </button>
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

        {/* New Withdrawal Request Modal */}
        {showWithdrawalForm && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
            <UnifiedCard className="w-full max-w-md">
              <div className="p-6">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="text-xl font-semibold text-white">New Withdrawal Request</h3>
                  <button
                    onClick={() => setShowWithdrawalForm(false)}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <XCircle className="w-5 h-5" />
                  </button>
                </div>

                <form onSubmit={handleWithdrawalSubmit} className="space-y-4">
                  <div>
                    <label className="block text-gray-400 text-sm mb-2">Withdrawal Amount</label>
                    <input
                      type="number"
                      value={withdrawalAmount}
                      onChange={(e) => setWithdrawalAmount(e.target.value)}
                      className="w-full px-4 py-2 bg-gray-800/50 border border-gray-700/50 rounded-lg text-white focus:outline-none focus:border-green-500/50"
                      placeholder="Enter amount"
                      min={accountBalance.minimumWithdrawal}
                      max={accountBalance.available}
                      required
                    />
                    <p className="text-gray-500 text-xs mt-1">
                      Minimum: ₹{accountBalance.minimumWithdrawal.toLocaleString()} | Available: ₹{accountBalance.available.toLocaleString()}
                    </p>
                  </div>

                  <div>
                    <label className="block text-gray-400 text-sm mb-2">Bank Account</label>
                    <select
                      value={selectedBank}
                      onChange={(e) => setSelectedBank(e.target.value)}
                      className="w-full px-4 py-2 bg-gray-800/50 border border-gray-700/50 rounded-lg text-white focus:outline-none focus:border-green-500/50"
                      required
                    >
                      <option value="">Select bank account</option>
                      {bankAccounts.map((account) => (
                        <option key={account.id} value={account.id}>
                          {account.bankName} ({account.accountNumber})
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-gray-400 text-sm mb-2">Requested Date</label>
                    <input
                      type="date"
                      value={requestedDate}
                      onChange={(e) => setRequestedDate(e.target.value)}
                      className="w-full px-4 py-2 bg-gray-800/50 border border-gray-700/50 rounded-lg text-white focus:outline-none focus:border-green-500/50"
                      min={new Date().toISOString().split('T')[0]}
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-gray-400 text-sm mb-2">Reason (Optional)</label>
                    <textarea
                      value={withdrawalReason}
                      onChange={(e) => setWithdrawalReason(e.target.value)}
                      className="w-full px-4 py-2 bg-gray-800/50 border border-gray-700/50 rounded-lg text-white focus:outline-none focus:border-green-500/50"
                      placeholder="Enter reason for withdrawal"
                      rows="3"
                    />
                  </div>

                  <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-lg p-4">
                    <div className="flex items-start space-x-3">
                      <AlertCircle className="w-5 h-5 text-yellow-400 mt-0.5" />
                      <div className="text-sm">
                        <p className="text-yellow-400 font-medium">Processing Information</p>
                        <p className="text-gray-300 mt-1">
                          Withdrawal requests are processed within 2-3 business days. 
                          You will receive a confirmation email once processed.
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="flex justify-end space-x-3 pt-4">
                    <UnifiedButton
                      type="button"
                      variant="secondary"
                      onClick={() => setShowWithdrawalForm(false)}
                    >
                      Cancel
                    </UnifiedButton>
                    <UnifiedButton 
                      type="submit" 
                      disabled={submitting}
                      className="disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {submitting ? (
                        <>
                          <div className="animate-spin rounded-full h-4 w-4 border-2 border-white/30 border-t-white mr-2"></div>
                          Submitting...
                        </>
                      ) : (
                        'Submit Request'
                      )}
                    </UnifiedButton>
                  </div>
                </form>
              </div>
            </UnifiedCard>
          </div>
        )}

        {/* Request Details Modal */}
        {selectedRequest && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
            <UnifiedCard className="w-full max-w-md">
              <div className="p-6">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="text-xl font-semibold text-white">Request Details</h3>
                  <button
                    onClick={() => setSelectedRequest(null)}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <XCircle className="w-5 h-5" />
                  </button>
                </div>

                <div className="space-y-4">
                  <div className="flex items-center space-x-3 p-4 bg-gray-800/50 rounded-lg">
                    <div className="w-10 h-10 bg-purple-500/20 rounded-lg flex items-center justify-center">
                      <CreditCard className="w-5 h-5 text-purple-400" />
                    </div>
                    <div>
                      <p className="text-white font-medium">Request ID: {selectedRequest.id}</p>
                      <p className="text-gray-400 text-sm">{selectedRequest.reason}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-gray-400 text-sm">Amount</p>
                      <p className="text-lg font-semibold text-white">₹{selectedRequest.amount.toLocaleString()}</p>
                    </div>
                    <div>
                      <p className="text-gray-400 text-sm">Status</p>
                      <div className="flex items-center space-x-2">
                        {getStatusIcon(selectedRequest.status)}
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${getStatusColor(selectedRequest.status)}`}>
                          {selectedRequest.status.charAt(0).toUpperCase() + selectedRequest.status.slice(1)}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div>
                    <p className="text-gray-400 text-sm">Bank Account</p>
                    <p className="text-white">{selectedRequest.bankAccount}</p>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-gray-400 text-sm">Request Date</p>
                      <p className="text-white">{new Date(selectedRequest.requestDate).toLocaleDateString()}</p>
                    </div>
                    {selectedRequest.processedDate && (
                      <div>
                        <p className="text-gray-400 text-sm">Processed Date</p>
                        <p className="text-white">{new Date(selectedRequest.processedDate).toLocaleDateString()}</p>
                      </div>
                    )}
                  </div>

                  {selectedRequest.transactionId && (
                    <div>
                      <p className="text-gray-400 text-sm">Transaction ID</p>
                      <p className="text-white font-mono">{selectedRequest.transactionId}</p>
                    </div>
                  )}

                  {selectedRequest.rejectionReason && (
                    <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
                      <div className="flex items-start space-x-3">
                        <XCircle className="w-5 h-5 text-red-400 mt-0.5" />
                        <div>
                          <p className="text-red-400 font-medium text-sm">Rejection Reason</p>
                          <p className="text-gray-300 text-sm mt-1">{selectedRequest.rejectionReason}</p>
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                <div className="flex justify-end mt-6">
                  <UnifiedButton
                    onClick={() => setSelectedRequest(null)}
                    variant="secondary"
                  >
                    Close
                  </UnifiedButton>
                </div>
              </div>
            </UnifiedCard>
          </div>
        )}
        </div>
      </UnifiedBackground>
    </>
  );
}

export default WithdrawalRequest;
