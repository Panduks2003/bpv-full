/**
 * WALLET COMPONENTS
 * =================
 * Reusable components for wallet balance display and management
 * Used across promoter and admin interfaces
 */

import React, { useState, useEffect } from 'react';
import { 
  Wallet, 
  TrendingUp, 
  Award,
  RefreshCw,
  Eye,
  EyeOff,
  DollarSign,
  ArrowUpRight,
  ArrowDownLeft,
  Clock
} from 'lucide-react';
import { UnifiedCard, UnifiedButton } from '../common/components/SharedTheme';
import commissionService from '../services/commissionService';

/**
 * Wallet Balance Widget - Shows current wallet balance with refresh capability
 */
export const WalletBalanceWidget = ({ 
  userId, 
  userType = 'promoter', 
  title = "Wallet Balance",
  showRefresh = true,
  autoRefresh = false,
  refreshInterval = 30000,
  className = ""
}) => {
  const [balance, setBalance] = useState(0);
  const [totalEarned, setTotalEarned] = useState(0);
  const [loading, setLoading] = useState(true);
  const [showBalance, setShowBalance] = useState(true);
  const [lastUpdated, setLastUpdated] = useState(null);

  // Load wallet data
  const loadWalletData = async () => {
    try {
      setLoading(true);
      
      let result;
      if (userType === 'admin') {
        result = await commissionService.getAdminCommissionSummary();
      } else {
        result = await commissionService.getPromoterCommissionSummary(userId);
      }
      
      if (result.success) {
        setBalance(result.data.wallet_balance || 0);
        setTotalEarned(result.data.total_earned || result.data.total_received || 0);
        setLastUpdated(new Date());
      }
      
    } catch (error) {
      console.error('Error loading wallet data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Load data on mount
  useEffect(() => {
    if (userId) {
      loadWalletData();
    }
  }, [userId, userType]);

  // Auto refresh
  useEffect(() => {
    if (autoRefresh && refreshInterval > 0) {
      const interval = setInterval(loadWalletData, refreshInterval);
      return () => clearInterval(interval);
    }
  }, [autoRefresh, refreshInterval]);

  // Format currency
  const formatCurrency = (amount) => {
    return `₹${parseFloat(amount).toLocaleString('en-IN')}`;
  };

  // Handle refresh
  const handleRefresh = () => {
    loadWalletData();
  };

  return (
    <UnifiedCard className={`p-6 bg-gradient-to-br from-green-500/10 to-emerald-500/10 border border-green-500/30 hover:border-green-400/50 transition-all duration-300 ${className}`}>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className="w-12 h-12 bg-green-500/20 rounded-xl flex items-center justify-center">
            <Wallet className="w-6 h-6 text-green-400" />
          </div>
          <div>
            <p className="text-green-300 text-sm font-semibold uppercase tracking-wider">{title}</p>
            <div className="flex items-center space-x-2">
              {showBalance ? (
                <p className="text-3xl font-bold text-white">
                  {loading ? '...' : formatCurrency(balance)}
                </p>
              ) : (
                <p className="text-3xl font-bold text-white">••••••</p>
              )}
              <button
                onClick={() => setShowBalance(!showBalance)}
                className="p-1 hover:bg-gray-700 rounded transition-colors"
              >
                {showBalance ? (
                  <Eye className="w-4 h-4 text-gray-400" />
                ) : (
                  <EyeOff className="w-4 h-4 text-gray-400" />
                )}
              </button>
            </div>
          </div>
        </div>
        
        {showRefresh && (
          <UnifiedButton
            onClick={handleRefresh}
            className="p-2 bg-green-500/20 hover:bg-green-500/30"
            disabled={loading}
          >
            <RefreshCw className={`w-4 h-4 text-green-400 ${loading ? 'animate-spin' : ''}`} />
          </UnifiedButton>
        )}
      </div>

      <div className="space-y-2">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-400">Total Earned</span>
          <span className="text-green-300 font-medium">
            {showBalance ? formatCurrency(totalEarned) : '••••••'}
          </span>
        </div>
        
        {lastUpdated && (
          <div className="flex items-center justify-between text-xs">
            <span className="text-gray-500">Last Updated</span>
            <span className="text-gray-500">
              {lastUpdated.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
            </span>
          </div>
        )}
      </div>

      {autoRefresh && (
        <div className="flex items-center mt-3 text-xs">
          <div className="w-2 h-2 bg-green-400 rounded-full mr-2 animate-pulse"></div>
          <span className="text-green-300">Auto-refresh active</span>
        </div>
      )}
    </UnifiedCard>
  );
};

/**
 * Commission Summary Cards - Shows commission statistics
 */
export const CommissionSummaryCards = ({ 
  data = {}, 
  loading = false,
  className = ""
}) => {
  const formatCurrency = (amount) => {
    return `₹${parseFloat(amount || 0).toLocaleString('en-IN')}`;
  };

  const cards = [
    {
      title: 'Wallet Balance',
      value: data.wallet_balance || 0,
      icon: Wallet,
      color: 'from-green-500/10 to-emerald-500/10',
      borderColor: 'border-green-500/30',
      iconColor: 'text-green-400',
      textColor: 'text-green-300'
    },
    {
      title: 'Total Earned',
      value: data.total_earned || data.total_received || 0,
      icon: TrendingUp,
      color: 'from-orange-500/10 to-yellow-500/10',
      borderColor: 'border-orange-500/30',
      iconColor: 'text-orange-400',
      textColor: 'text-orange-300'
    },
    {
      title: 'Commissions',
      value: data.commission_count || 0,
      icon: Award,
      color: 'from-purple-500/10 to-pink-500/10',
      borderColor: 'border-purple-500/30',
      iconColor: 'text-purple-400',
      textColor: 'text-purple-300',
      isCount: true
    }
  ];

  return (
    <div className={`grid grid-cols-1 md:grid-cols-3 gap-6 ${className}`}>
      {cards.map((card, index) => {
        const Icon = card.icon;
        return (
          <UnifiedCard 
            key={index}
            className={`p-6 bg-gradient-to-br ${card.color} border ${card.borderColor} hover:border-opacity-50 transition-all duration-300`}
          >
            <div className="flex items-center justify-between">
              <div>
                <p className={`${card.textColor} text-sm font-semibold uppercase tracking-wider`}>
                  {card.title}
                </p>
                <p className="text-3xl font-bold text-white mt-2">
                  {loading ? '...' : (
                    card.isCount ? card.value : formatCurrency(card.value)
                  )}
                </p>
              </div>
              <div className={`w-12 h-12 ${card.color} rounded-xl flex items-center justify-center`}>
                <Icon className={`w-6 h-6 ${card.iconColor}`} />
              </div>
            </div>
          </UnifiedCard>
        );
      })}
    </div>
  );
};

/**
 * Transaction History Mini Widget
 */
export const TransactionHistoryWidget = ({ 
  transactions = [], 
  loading = false,
  maxItems = 5,
  className = ""
}) => {
  const formatCurrency = (amount) => {
    return `₹${parseFloat(amount).toLocaleString('en-IN')}`;
  };

  const getTransactionIcon = (type, amount) => {
    if (amount > 0) {
      return <ArrowUpRight className="w-4 h-4 text-green-400" />;
    } else {
      return <ArrowDownLeft className="w-4 h-4 text-red-400" />;
    }
  };

  const getTransactionColor = (amount) => {
    return amount > 0 ? 'text-green-300' : 'text-red-300';
  };

  return (
    <UnifiedCard className={`p-6 ${className}`} variant="glassDark">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-white">Recent Transactions</h3>
        <Clock className="w-5 h-5 text-gray-400" />
      </div>

      {loading ? (
        <div className="space-y-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-gray-700 rounded-full animate-pulse"></div>
              <div className="flex-1 space-y-1">
                <div className="h-4 bg-gray-700 rounded animate-pulse"></div>
                <div className="h-3 bg-gray-700 rounded w-2/3 animate-pulse"></div>
              </div>
              <div className="h-4 bg-gray-700 rounded w-16 animate-pulse"></div>
            </div>
          ))}
        </div>
      ) : transactions.length === 0 ? (
        <div className="text-center py-8">
          <DollarSign className="w-12 h-12 text-gray-500 mx-auto mb-3" />
          <p className="text-gray-400">No transactions yet</p>
        </div>
      ) : (
        <div className="space-y-3">
          {transactions.slice(0, maxItems).map((transaction, index) => (
            <div key={index} className="flex items-center space-x-3 p-2 rounded-lg hover:bg-gray-800/30 transition-colors">
              <div className="w-8 h-8 bg-gray-700 rounded-full flex items-center justify-center">
                {getTransactionIcon(transaction.type, transaction.amount)}
              </div>
              <div className="flex-1">
                <p className="text-white text-sm font-medium">
                  {transaction.description || transaction.note || 'Commission'}
                </p>
                <p className="text-gray-400 text-xs">
                  {new Date(transaction.created_at || transaction.date).toLocaleDateString()}
                </p>
              </div>
              <div className={`text-sm font-bold ${getTransactionColor(transaction.amount)}`}>
                {transaction.amount > 0 ? '+' : ''}{formatCurrency(Math.abs(transaction.amount))}
              </div>
            </div>
          ))}
        </div>
      )}
    </UnifiedCard>
  );
};

/**
 * Wallet Action Buttons
 */
export const WalletActionButtons = ({ 
  onWithdraw,
  onViewHistory,
  onRefresh,
  withdrawDisabled = false,
  className = ""
}) => {
  return (
    <div className={`flex flex-col sm:flex-row gap-3 ${className}`}>
      <UnifiedButton
        onClick={onWithdraw}
        disabled={withdrawDisabled}
        className="flex items-center justify-center space-x-2 bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 disabled:opacity-50"
      >
        <ArrowUpRight className="w-4 h-4" />
        <span>Withdraw</span>
      </UnifiedButton>
      
      <UnifiedButton
        onClick={onViewHistory}
        className="flex items-center justify-center space-x-2 bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700"
      >
        <Clock className="w-4 h-4" />
        <span>History</span>
      </UnifiedButton>
      
      <UnifiedButton
        onClick={onRefresh}
        className="flex items-center justify-center space-x-2 bg-gradient-to-r from-gray-600 to-gray-700 hover:from-gray-700 hover:to-gray-800"
      >
        <RefreshCw className="w-4 h-4" />
        <span>Refresh</span>
      </UnifiedButton>
    </div>
  );
};

// Export all components
export default {
  WalletBalanceWidget,
  CommissionSummaryCards,
  TransactionHistoryWidget,
  WalletActionButtons
};
