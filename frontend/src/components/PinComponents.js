/**
 * STANDARDIZED PIN UI COMPONENTS
 * ==============================
 * Unified components for displaying PIN information across all modules
 */

import React, { memo, useState, useEffect } from 'react';
import { Pin, TrendingUp, TrendingDown, Clock, CheckCircle, XCircle, AlertCircle } from 'lucide-react';
import { PIN_ACTION_TYPES, PIN_DISPLAY_CONFIG, formatPinAmount, getActionTypeDisplay } from '../services/pinTransactionService';

// =====================================================
// PIN BALANCE DISPLAY COMPONENT
// =====================================================

export const PinBalance = memo(({ 
  balance, 
  size = 'medium', 
  showIcon = true, 
  className = '',
  animated = false 
}) => {
  const sizeClasses = {
    small: 'text-lg',
    medium: 'text-2xl',
    large: 'text-4xl',
    xl: 'text-6xl'
  };

  const iconSizes = {
    small: 'w-4 h-4',
    medium: 'w-6 h-6', 
    large: 'w-8 h-8',
    xl: 'w-12 h-12'
  };

  return (
    <div className={`flex items-center space-x-2 ${className}`}>
      {showIcon && (
        <Pin className={`text-purple-400 ${iconSizes[size]} ${animated ? 'animate-pulse' : ''}`} />
      )}
      <span className={`font-bold text-white ${sizeClasses[size]} ${animated ? 'transition-all duration-300' : ''}`}>
        {balance || 0}
      </span>
      <span className="text-gray-400 text-sm font-normal">
        PIN{balance !== 1 ? 's' : ''}
      </span>
    </div>
  );
});

// =====================================================
// PIN CHANGE INDICATOR COMPONENT
// =====================================================

export const PinChangeIndicator = memo(({ 
  actionType, 
  amount, 
  size = 'medium',
  showIcon = true 
}) => {
  const config = getActionTypeDisplay(actionType);
  const formattedAmount = formatPinAmount(actionType, amount);
  
  const sizeClasses = {
    small: 'text-sm px-2 py-1',
    medium: 'text-base px-3 py-1.5',
    large: 'text-lg px-4 py-2'
  };

  const iconSizes = {
    small: 'w-3 h-3',
    medium: 'w-4 h-4',
    large: 'w-5 h-5'
  };

  const colorClasses = {
    green: 'bg-green-500/20 text-green-400 border-green-500/30',
    red: 'bg-red-500/20 text-red-400 border-red-500/30',
    gray: 'bg-gray-500/20 text-gray-400 border-gray-500/30'
  };

  const IconComponent = config.sign === '+' ? TrendingUp : TrendingDown;

  return (
    <div className={`
      inline-flex items-center space-x-1 rounded-full border font-medium
      ${sizeClasses[size]} 
      ${colorClasses[config.color]}
    `}>
      {showIcon && (
        <IconComponent className={iconSizes[size]} />
      )}
      <span>{formattedAmount}</span>
    </div>
  );
});

// =====================================================
// ACTION TYPE BADGE COMPONENT
// =====================================================

export const ActionTypeBadge = memo(({ 
  actionType, 
  size = 'medium',
  showEmoji = true 
}) => {
  const config = getActionTypeDisplay(actionType);
  
  const sizeClasses = {
    small: 'text-xs px-2 py-1',
    medium: 'text-sm px-2.5 py-1',
    large: 'text-base px-3 py-1.5'
  };

  const colorClasses = {
    green: 'bg-green-100 text-green-800',
    red: 'bg-red-100 text-red-800', 
    blue: 'bg-blue-100 text-blue-800',
    gray: 'bg-gray-100 text-gray-800'
  };

  // Map action types to appropriate background colors
  const getBackgroundColor = (actionType) => {
    switch (actionType) {
      case PIN_ACTION_TYPES.ADMIN_ALLOCATION:
        return 'green';
      case PIN_ACTION_TYPES.CUSTOMER_CREATION:
      case PIN_ACTION_TYPES.ADMIN_DEDUCTION:
        return 'red';
      default:
        return 'gray';
    }
  };

  const bgColor = getBackgroundColor(actionType);

  return (
    <span className={`
      inline-flex items-center space-x-1 rounded-full font-medium
      ${sizeClasses[size]}
      ${colorClasses[bgColor]}
    `}>
      {showEmoji && <span>{config.emoji}</span>}
      <span>{config.label}</span>
    </span>
  );
});

// =====================================================
// PIN TRANSACTION ROW COMPONENT
// =====================================================

export const PinTransactionRow = memo(({ 
  transaction, 
  showUser = false,
  showCreator = false,
  compact = false 
}) => {
  const config = getActionTypeDisplay(transaction.action_type);
  const formattedDate = new Date(transaction.created_at).toLocaleDateString();
  const formattedTime = new Date(transaction.created_at).toLocaleTimeString([], { 
    hour: '2-digit', 
    minute: '2-digit' 
  });

  if (compact) {
    return (
      <div className="flex items-center justify-between py-2 border-b border-gray-700/50 last:border-b-0">
        <div className="flex items-center space-x-3">
          <ActionTypeBadge actionType={transaction.action_type} size="small" />
          <span className="text-gray-300 text-sm">{transaction.note}</span>
        </div>
        <div className="flex items-center space-x-3">
          <PinChangeIndicator 
            actionType={transaction.action_type} 
            amount={transaction.pin_change_value}
            size="small"
          />
          <span className="text-gray-400 text-xs">{formattedDate}</span>
        </div>
      </div>
    );
  }

  return (
    <tr className="hover:bg-gray-800/30 transition-colors">
      <td className="px-6 py-4 whitespace-nowrap">
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
          {transaction.transaction_id}
        </span>
      </td>
      
      {showUser && (
        <td className="px-6 py-4 whitespace-nowrap">
          <div className="text-sm font-medium text-white">{transaction.userName}</div>
          <div className="text-xs text-gray-400">{transaction.userEmail}</div>
        </td>
      )}
      
      <td className="px-6 py-4 whitespace-nowrap">
        <PinChangeIndicator 
          actionType={transaction.action_type} 
          amount={transaction.pin_change_value}
        />
      </td>
      
      <td className="px-6 py-4 whitespace-nowrap">
        <ActionTypeBadge actionType={transaction.action_type} />
      </td>
      
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
        <div>{formattedDate}</div>
        <div className="text-xs text-gray-500">{formattedTime}</div>
      </td>
      
      <td className="px-6 py-4 text-sm text-gray-300 max-w-xs">
        <div className="truncate" title={transaction.note}>
          {transaction.note}
        </div>
      </td>
      
      {showCreator && (
        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
          {transaction.creatorName}
        </td>
      )}
      
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-400">
        {transaction.balance_after}
      </td>
    </tr>
  );
});

// =====================================================
// PIN STATISTICS CARDS COMPONENT
// =====================================================

export const PinStatsCards = memo(({ stats, loading = false }) => {
  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[1, 2, 3, 4].map(i => (
          <div key={i} className="bg-gray-800/50 rounded-lg p-6 animate-pulse">
            <div className="h-4 bg-gray-700 rounded mb-2"></div>
            <div className="h-8 bg-gray-700 rounded mb-4"></div>
            <div className="h-3 bg-gray-700 rounded w-2/3"></div>
          </div>
        ))}
      </div>
    );
  }

  const cards = [
    {
      title: 'Total Transactions',
      value: stats.totalTransactions,
      icon: Clock,
      color: 'purple',
      gradient: 'from-purple-500 to-pink-600'
    },
    {
      title: 'Customer Creations',
      value: stats.customerCreations,
      icon: XCircle,
      color: 'red',
      gradient: 'from-red-500 to-pink-600'
    },
    {
      title: 'Admin Allocations',
      value: stats.adminAllocations,
      icon: CheckCircle,
      color: 'green',
      gradient: 'from-green-500 to-emerald-600'
    },
    {
      title: 'Total PINs Allocated',
      value: stats.totalPinsAllocated,
      icon: TrendingUp,
      color: 'blue',
      gradient: 'from-blue-500 to-indigo-600'
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {cards.map((card, index) => {
        const Icon = card.icon;
        return (
          <div key={index} className="bg-gray-800/50 backdrop-blur-sm rounded-lg p-6 border border-gray-700/50 hover:border-gray-600/50 transition-all duration-300">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-300 text-sm font-medium">{card.title}</p>
                <p className="text-3xl font-bold text-white mt-1">{card.value}</p>
              </div>
              <div className={`w-14 h-14 bg-gradient-to-r ${card.gradient} rounded-xl flex items-center justify-center shadow-lg`}>
                <Icon className="w-7 h-7 text-white" />
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
});

// =====================================================
// PIN TRANSACTION TABLE COMPONENT
// =====================================================

export const PinTransactionTable = memo(({ 
  transactions, 
  loading = false,
  showUser = false,
  showCreator = false,
  emptyMessage = "No PIN transactions found"
}) => {
  if (loading) {
    return (
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-800/50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Transaction ID</th>
              {showUser && <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">User</th>}
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">PINs</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Action Type</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Notes</th>
              {showCreator && <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Created By</th>}
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Balance After</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-700/50">
            {[1, 2, 3, 4, 5].map(i => (
              <tr key={i} className="animate-pulse">
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-24"></div></td>
                {showUser && <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-32"></div></td>}
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-16"></div></td>
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-28"></div></td>
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-20"></div></td>
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-40"></div></td>
                {showCreator && <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-24"></div></td>}
                <td className="px-6 py-4"><div className="h-4 bg-gray-700 rounded w-12"></div></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }

  if (transactions.length === 0) {
    return (
      <div className="text-center py-12">
        <Pin className="w-16 h-16 text-gray-600 mb-4 mx-auto" />
        <p className="text-gray-300 text-lg mb-2">{emptyMessage}</p>
        <p className="text-gray-400 text-sm">PIN transactions will appear here when they occur.</p>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-gray-800/50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Transaction ID</th>
            {showUser && <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">User</th>}
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">PINs</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Action Type</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Date</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Notes</th>
            {showCreator && <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Created By</th>}
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Balance After</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-700/50">
          {transactions.map((transaction) => (
            <PinTransactionRow 
              key={transaction.id}
              transaction={transaction}
              showUser={showUser}
              showCreator={showCreator}
            />
          ))}
        </tbody>
      </table>
    </div>
  );
});

// =====================================================
// PIN BALANCE WIDGET COMPONENT
// =====================================================

export const PinBalanceWidget = memo(({ 
  userId, 
  title = "PIN Balance",
  showRefresh = true,
  autoRefresh = false,
  refreshInterval = 30000 
}) => {
  const [balance, setBalance] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadBalance = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const { getUserPinBalance } = await import('../services/pinTransactionService');
      const currentBalance = await getUserPinBalance(userId);
      setBalance(currentBalance);
      
    } catch (err) {
      console.error('Failed to load PIN balance:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (userId) {
      loadBalance();
    }
  }, [userId]);

  useEffect(() => {
    if (autoRefresh && userId) {
      const interval = setInterval(loadBalance, refreshInterval);
      return () => clearInterval(interval);
    }
  }, [autoRefresh, refreshInterval, userId]);

  if (loading) {
    return (
      <div className="bg-gray-800/50 rounded-lg p-6 animate-pulse">
        <div className="h-4 bg-gray-700 rounded mb-2 w-24"></div>
        <div className="h-8 bg-gray-700 rounded w-16"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-6">
        <div className="flex items-center space-x-2">
          <AlertCircle className="w-5 h-5 text-red-400" />
          <span className="text-red-300 text-sm">Failed to load balance</span>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gradient-to-br from-purple-500/10 to-pink-500/10 border border-purple-500/30 rounded-lg p-6">
      <div className="flex items-center justify-between mb-2">
        <h3 className="text-purple-300 text-sm font-medium uppercase tracking-wider">{title}</h3>
        {showRefresh && (
          <button
            onClick={loadBalance}
            className="text-purple-400 hover:text-purple-300 transition-colors"
            title="Refresh balance"
          >
            <Clock className="w-4 h-4" />
          </button>
        )}
      </div>
      <PinBalance balance={balance} size="large" animated />
    </div>
  );
});

export default {
  PinBalance,
  PinChangeIndicator,
  ActionTypeBadge,
  PinTransactionRow,
  PinStatsCards,
  PinTransactionTable,
  PinBalanceWidget
};
