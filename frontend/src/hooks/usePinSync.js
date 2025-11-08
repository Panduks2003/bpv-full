/**
 * REAL-TIME PIN SYNCHRONIZATION HOOK
 * ==================================
 * Provides real-time PIN balance and transaction updates across all components
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import pinTransactionService from '../services/pinTransactionService';

/**
 * Hook for real-time PIN balance synchronization
 */
export const usePinBalance = (userId, options = {}) => {
  const {
    autoRefresh = true,
    refreshInterval = 30000,
    enableRealtime = true
  } = options;

  const [balance, setBalance] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);
  
  const subscriptionRef = useRef(null);
  const intervalRef = useRef(null);

  // Load initial balance
  const loadBalance = useCallback(async () => {
    if (!userId) return;

    try {
      setLoading(true);
      setError(null);
      
      const currentBalance = await pinTransactionService.getUserPinBalance(userId);
      setBalance(currentBalance);
      setLastUpdated(new Date());
      
    } catch (err) {
      console.error('Failed to load PIN balance:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  // Manual refresh function
  const refresh = useCallback(() => {
    loadBalance();
  }, [loadBalance]);

  // Set up real-time subscription
  useEffect(() => {
    if (!userId || !enableRealtime) return;

    const subscription = pinTransactionService.subscribeToPinBalance(userId, (payload) => {
      console.log('📡 PIN balance change detected:', payload);
      
      // Refresh balance when changes are detected
      loadBalance();
    });

    subscriptionRef.current = subscription;

    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe();
      }
    };
  }, [userId, enableRealtime, loadBalance]);

  // Set up auto-refresh interval
  useEffect(() => {
    if (!autoRefresh || !userId) return;

    const interval = setInterval(() => {
      loadBalance();
    }, refreshInterval);

    intervalRef.current = interval;

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [autoRefresh, refreshInterval, loadBalance, userId]);

  // Initial load
  useEffect(() => {
    loadBalance();
  }, [loadBalance]);

  return {
    balance,
    loading,
    error,
    lastUpdated,
    refresh
  };
};

/**
 * Hook for real-time PIN transactions synchronization
 */
export const usePinTransactions = (userId, options = {}) => {
  const {
    limit = 50,
    autoRefresh = true,
    refreshInterval = 60000,
    enableRealtime = true,
    filters = {}
  } = options;

  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);
  
  const subscriptionRef = useRef(null);
  const intervalRef = useRef(null);

  // Load transactions
  const loadTransactions = useCallback(async () => {
    if (!userId) return;

    try {
      setLoading(true);
      setError(null);
      
      const transactionData = await pinTransactionService.getUserPinTransactions(userId, limit);
      setTransactions(transactionData);
      setLastUpdated(new Date());
      
    } catch (err) {
      console.error('Failed to load PIN transactions:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [userId, limit]);

  // Manual refresh function
  const refresh = useCallback(() => {
    loadTransactions();
  }, [loadTransactions]);

  // Set up real-time subscription
  useEffect(() => {
    if (!userId || !enableRealtime) return;

    const subscription = pinTransactionService.subscribeToPinTransactions((payload) => {
      console.log('📡 PIN transactions change detected:', payload);
      
      // Refresh transactions when changes are detected
      loadTransactions();
    }, userId);

    subscriptionRef.current = subscription;

    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe();
      }
    };
  }, [userId, enableRealtime, loadTransactions]);

  // Set up auto-refresh interval
  useEffect(() => {
    if (!autoRefresh || !userId) return;

    const interval = setInterval(() => {
      loadTransactions();
    }, refreshInterval);

    intervalRef.current = interval;

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [autoRefresh, refreshInterval, loadTransactions, userId]);

  // Initial load
  useEffect(() => {
    loadTransactions();
  }, [loadTransactions]);

  return {
    transactions,
    loading,
    error,
    lastUpdated,
    refresh
  };
};

/**
 * Hook for PIN statistics synchronization
 */
export const usePinStats = (userId = null, options = {}) => {
  const {
    autoRefresh = true,
    refreshInterval = 120000, // 2 minutes for stats
    enableRealtime = false // Stats don't need real-time updates
  } = options;

  const [stats, setStats] = useState({
    totalTransactions: 0,
    customerCreations: 0,
    adminAllocations: 0,
    adminDeductions: 0,
    totalPinsAllocated: 0,
    totalPinsDeducted: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);
  
  const intervalRef = useRef(null);

  // Load statistics
  const loadStats = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const statsData = await pinTransactionService.getPinTransactionStats(userId);
      setStats(statsData);
      setLastUpdated(new Date());
      
    } catch (err) {
      console.error('Failed to load PIN stats:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  // Manual refresh function
  const refresh = useCallback(() => {
    loadStats();
  }, [loadStats]);

  // Set up auto-refresh interval
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(() => {
      loadStats();
    }, refreshInterval);

    intervalRef.current = interval;

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [autoRefresh, refreshInterval, loadStats]);

  // Initial load
  useEffect(() => {
    loadStats();
  }, [loadStats]);

  return {
    stats,
    loading,
    error,
    lastUpdated,
    refresh
  };
};

/**
 * Combined hook for complete PIN management
 */
export const usePinManagement = (userId, options = {}) => {
  const balanceHook = usePinBalance(userId, options);
  const transactionsHook = usePinTransactions(userId, options);
  const statsHook = usePinStats(userId, options);

  const refreshAll = useCallback(() => {
    balanceHook.refresh();
    transactionsHook.refresh();
    statsHook.refresh();
  }, [balanceHook.refresh, transactionsHook.refresh, statsHook.refresh]);

  return {
    balance: balanceHook,
    transactions: transactionsHook,
    stats: statsHook,
    refreshAll,
    loading: balanceHook.loading || transactionsHook.loading || statsHook.loading
  };
};

export default {
  usePinBalance,
  usePinTransactions,
  usePinStats,
  usePinManagement
};
