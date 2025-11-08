/**
 * UNIFIED PIN TRANSACTION SERVICE
 * ================================
 * Centralized service for all PIN operations across Admin, Promoter, and Customer systems
 * Ensures complete uniformity and standardization
 */

import { supabase } from '../common/services/supabaseClient';

// =====================================================
// CONSTANTS - Standardized Action Types
// =====================================================

export const PIN_ACTION_TYPES = {
  CUSTOMER_CREATION: 'customer_creation',    // ❌ Customer Creation (- PIN)
  ADMIN_ALLOCATION: 'admin_allocation',      // ✅ Admin Allocation (+ PIN)
  ADMIN_DEDUCTION: 'admin_deduction'         // ❌ Admin Deduction (- PIN)
};

export const PIN_DISPLAY_CONFIG = {
  [PIN_ACTION_TYPES.CUSTOMER_CREATION]: {
    emoji: '❌',
    label: 'Customer Creation',
    color: 'red',
    sign: '-'
  },
  [PIN_ACTION_TYPES.ADMIN_ALLOCATION]: {
    emoji: '✅',
    label: 'Admin Allocation',
    color: 'green',
    sign: '+'
  },
  [PIN_ACTION_TYPES.ADMIN_DEDUCTION]: {
    emoji: '❌',
    label: 'Admin Deduction',
    color: 'red',
    sign: '-'
  }
};

// =====================================================
// CORE PIN TRANSACTION FUNCTIONS
// =====================================================

/**
 * Execute a PIN transaction using the unified system
 */
export const executePinTransaction = async ({
  userId,
  actionType,
  pinChangeValue,
  createdBy = null,
  relatedEntityId = null,
  relatedEntityName = null
}) => {
  try {
    console.log('🔄 Executing PIN transaction:', {
      userId,
      actionType,
      pinChangeValue,
      createdBy,
      relatedEntityId,
      relatedEntityName
    });

    const { data, error } = await supabase.rpc('execute_pin_transaction', {
      p_user_id: userId,
      p_action_type: actionType,
      p_pin_change_value: pinChangeValue,
      p_created_by: createdBy,
      p_related_entity_id: relatedEntityId,
      p_related_entity_name: relatedEntityName
    });

    if (error) {
      console.error('❌ PIN transaction failed:', error);
      throw error;
    }

    if (!data.success) {
      console.error('❌ PIN transaction returned error:', data.error);
      throw new Error(data.error || 'PIN transaction failed');
    }

    console.log('✅ PIN transaction successful:', data);
    return data;

  } catch (error) {
    console.error('❌ PIN transaction service error:', error);
    throw error;
  }
};

/**
 * Deduct PIN for customer creation
 */
export const deductPinForCustomerCreation = async (promoterId, customerId, customerName) => {
  try {
    console.log('🔄 Deducting PIN for customer creation:', { promoterId, customerId, customerName });

    const { data, error } = await supabase.rpc('deduct_pin_for_customer_creation', {
      p_promoter_id: promoterId,
      p_customer_id: customerId,
      p_customer_name: customerName
    });

    if (error) throw error;
    if (!data.success) throw new Error(data.error || 'Customer creation PIN deduction failed');

    console.log('✅ Customer creation PIN deduction successful:', data);
    return data;

  } catch (error) {
    console.error('❌ Customer creation PIN deduction failed:', error);
    throw error;
  }
};

/**
 * Admin allocate PINs to user
 */
export const adminAllocatePins = async (targetUserId, pinAmount, adminId) => {
  try {
    console.log('🔄 Admin allocating PINs:', { targetUserId, pinAmount, adminId });

    const { data, error } = await supabase.rpc('admin_allocate_pins', {
      p_target_user_id: targetUserId,
      p_pin_amount: Math.abs(pinAmount), // Ensure positive
      p_admin_id: adminId
    });

    if (error) throw error;
    if (!data.success) throw new Error(data.error || 'Admin PIN allocation failed');

    console.log('✅ Admin PIN allocation successful:', data);
    return data;

  } catch (error) {
    console.error('❌ Admin PIN allocation failed:', error);
    throw error;
  }
};

/**
 * Admin deduct PINs from user
 */
export const adminDeductPins = async (targetUserId, pinAmount, adminId) => {
  try {
    console.log('🔄 Admin deducting PINs:', { targetUserId, pinAmount, adminId });

    const { data, error } = await supabase.rpc('admin_deduct_pins', {
      p_target_user_id: targetUserId,
      p_pin_amount: Math.abs(pinAmount), // Ensure positive (function will make it negative)
      p_admin_id: adminId
    });

    if (error) throw error;
    if (!data.success) throw new Error(data.error || 'Admin PIN deduction failed');

    console.log('✅ Admin PIN deduction successful:', data);
    return data;

  } catch (error) {
    console.error('❌ Admin PIN deduction failed:', error);
    throw error;
  }
};

// =====================================================
// PIN TRANSACTION QUERIES
// =====================================================

/**
 * Get PIN transactions for a user
 */
export const getUserPinTransactions = async (userId, limit = 50) => {
  try {
    const { data, error } = await supabase
      .from('pin_transactions')
      .select(`
        id,
        transaction_id,
        action_type,
        pin_change_value,
        balance_before,
        balance_after,
        note,
        created_at,
        created_by,
        related_entity_id,
        creator:profiles!created_by(name, email)
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;

    // Transform data for UI display
    const transformedData = data.map(transaction => ({
      ...transaction,
      displayConfig: PIN_DISPLAY_CONFIG[transaction.action_type] || {
        emoji: '❓',
        label: 'Unknown',
        color: 'gray',
        sign: ''
      },
      formattedAmount: formatPinAmount(transaction.action_type, transaction.pin_change_value),
      creatorName: transaction.creator?.name || 'System'
    }));

    return transformedData;

  } catch (error) {
    console.error('❌ Failed to get user PIN transactions:', error);
    throw error;
  }
};

/**
 * Get all PIN transactions (Admin view)
 */
export const getAllPinTransactions = async (filters = {}, limit = 100) => {
  try {
    let query = supabase
      .from('pin_transactions')
      .select(`
        id,
        transaction_id,
        user_id,
        action_type,
        pin_change_value,
        balance_before,
        balance_after,
        note,
        created_at,
        created_by,
        related_entity_id,
        user:profiles!user_id(name, email, role),
        creator:profiles!created_by(name, email)
      `)
      .order('created_at', { ascending: false })
      .limit(limit);

    // Apply filters
    if (filters.actionType && filters.actionType !== 'all') {
      query = query.eq('action_type', filters.actionType);
    }

    if (filters.userId) {
      query = query.eq('user_id', filters.userId);
    }

    if (filters.dateFrom) {
      query = query.gte('created_at', filters.dateFrom);
    }

    if (filters.dateTo) {
      query = query.lte('created_at', filters.dateTo);
    }

    const { data, error } = await query;

    if (error) throw error;

    // Transform data for UI display
    const transformedData = data.map(transaction => ({
      ...transaction,
      displayConfig: PIN_DISPLAY_CONFIG[transaction.action_type] || {
        emoji: '❓',
        label: 'Unknown',
        color: 'gray',
        sign: ''
      },
      formattedAmount: formatPinAmount(transaction.action_type, transaction.pin_change_value || 0),
      userName: transaction.user?.name || 'Unknown User',
      userEmail: transaction.user?.email || 'Unknown',
      userRole: transaction.user?.role || 'unknown',
      creatorName: transaction.creator?.name || 'System'
    }));

    return transformedData;

  } catch (error) {
    console.error('❌ Failed to get all PIN transactions:', error);
    throw error;
  }
};

/**
 * Get user's current PIN balance
 */
export const getUserPinBalance = async (userId) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('pins')
      .eq('id', userId)
      .single();

    if (error) throw error;

    return data.pins || 0;

  } catch (error) {
    console.error('❌ Failed to get user PIN balance:', error);
    throw error;
  }
};

/**
 * Get PIN transaction statistics
 */
export const getPinTransactionStats = async (userId = null) => {
  try {
    let query = supabase
      .from('pin_transactions')
      .select('action_type, pin_change_value');

    if (userId) {
      query = query.eq('user_id', userId);
    }

    const { data, error } = await query;

    if (error) throw error;

    // Calculate statistics
    const stats = {
      totalTransactions: data.length,
      customerCreations: data.filter(t => t.action_type === PIN_ACTION_TYPES.CUSTOMER_CREATION).length,
      adminAllocations: data.filter(t => t.action_type === PIN_ACTION_TYPES.ADMIN_ALLOCATION).length,
      adminDeductions: data.filter(t => t.action_type === PIN_ACTION_TYPES.ADMIN_DEDUCTION).length,
      totalPinsAllocated: data
        .filter(t => t.action_type === PIN_ACTION_TYPES.ADMIN_ALLOCATION)
        .reduce((sum, t) => sum + Math.abs(t.pin_change_value), 0),
      totalPinsDeducted: data
        .filter(t => t.action_type !== PIN_ACTION_TYPES.ADMIN_ALLOCATION)
        .reduce((sum, t) => sum + Math.abs(t.pin_change_value), 0)
    };

    return stats;

  } catch (error) {
    console.error('❌ Failed to get PIN transaction stats:', error);
    throw error;
  }
};

// =====================================================
// UTILITY FUNCTIONS
// =====================================================

/**
 * Format PIN amount for display based on action type
 */
export const formatPinAmount = (actionType, pinChangeValue) => {
  // Handle null or undefined values
  if (pinChangeValue === null || pinChangeValue === undefined) {
    return '0';
  }
  
  const config = PIN_DISPLAY_CONFIG[actionType];
  if (!config) return pinChangeValue.toString();

  const absValue = Math.abs(pinChangeValue);
  
  // Force correct sign based on action type
  if (actionType === PIN_ACTION_TYPES.ADMIN_ALLOCATION) {
    return `+${absValue}`;
  } else {
    return `-${absValue}`;
  }
};

/**
 * Get display configuration for action type
 */
export const getActionTypeDisplay = (actionType) => {
  return PIN_DISPLAY_CONFIG[actionType] || {
    emoji: '❓',
    label: 'Unknown',
    color: 'gray',
    sign: ''
  };
};

/**
 * Validate PIN transaction parameters
 */
export const validatePinTransaction = (actionType, pinAmount, userId) => {
  const errors = [];

  if (!Object.values(PIN_ACTION_TYPES).includes(actionType)) {
    errors.push('Invalid action type');
  }

  if (!pinAmount || pinAmount <= 0) {
    errors.push('PIN amount must be greater than 0');
  }

  if (!userId) {
    errors.push('User ID is required');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};

/**
 * Real-time PIN balance subscription
 */
export const subscribeToPinBalance = (userId, callback) => {
  const subscription = supabase
    .channel('pin-balance-changes')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'pin_transactions',
        filter: `user_id=eq.${userId}`
      },
      (payload) => {
        console.log('📡 PIN transaction change detected:', payload);
        callback(payload);
      }
    )
    .subscribe();

  return subscription;
};

/**
 * Real-time PIN transactions subscription
 */
export const subscribeToPinTransactions = (callback, userId = null) => {
  let filter = '';
  if (userId) {
    filter = `user_id=eq.${userId}`;
  }

  const subscription = supabase
    .channel('pin-transactions-changes')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'pin_transactions',
        filter: filter
      },
      (payload) => {
        console.log('📡 PIN transactions change detected:', payload);
        callback(payload);
      }
    )
    .subscribe();

  return subscription;
};

export default {
  // Core functions
  executePinTransaction,
  deductPinForCustomerCreation,
  adminAllocatePins,
  adminDeductPins,
  
  // Query functions
  getUserPinTransactions,
  getAllPinTransactions,
  getUserPinBalance,
  getPinTransactionStats,
  
  // Utility functions
  formatPinAmount,
  getActionTypeDisplay,
  validatePinTransaction,
  
  // Real-time subscriptions
  subscribeToPinBalance,
  subscribeToPinTransactions,
  
  // Constants
  PIN_ACTION_TYPES,
  PIN_DISPLAY_CONFIG
};
