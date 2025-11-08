/**
 * PIN REQUEST SERVICE
 * ===================
 * Service for handling PIN request and approval workflow
 */

import { supabase } from '../common/services/supabaseClient';
import pinTransactionService from './pinTransactionService';

// =====================================================
// CONSTANTS
// =====================================================

export const PIN_REQUEST_STATUS = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected'
};

export const PIN_REQUEST_CONFIG = {
  [PIN_REQUEST_STATUS.PENDING]: {
    emoji: '🟡',
    label: 'Pending',
    color: 'yellow',
    description: 'Waiting for admin approval'
  },
  [PIN_REQUEST_STATUS.APPROVED]: {
    emoji: '🟢',
    label: 'Approved',
    color: 'green',
    description: 'PINs allocated successfully'
  },
  [PIN_REQUEST_STATUS.REJECTED]: {
    emoji: '🔴',
    label: 'Rejected',
    color: 'red',
    description: 'Request declined by admin'
  }
};

// =====================================================
// PIN REQUEST FUNCTIONS
// =====================================================

/**
 * Submit a new PIN request
 */
export const submitPinRequest = async (promoterId, requestedPins, reason = null) => {
  try {
    console.log('🔄 Submitting PIN request:', { promoterId, requestedPins, reason });

    const { data, error } = await supabase.rpc('submit_pin_request', {
      p_promoter_id: promoterId,
      p_requested_pins: requestedPins,
      p_reason: reason
    });

    if (error) {
      // Check if it's a missing function error, try direct table insert
      if (error.code === '42883' || error.code === 'PGRST202') {
        console.warn('submit_pin_request function not found. Using direct table insert.');
        
        // Validate input first
        if (!requestedPins || requestedPins <= 0 || requestedPins > 1000) {
          throw new Error('Requested PINs must be between 1 and 1000');
        }

        // Check for pending requests
        const { data: pendingCheck } = await supabase
          .from('pin_requests')
          .select('id')
          .eq('promoter_id', promoterId)
          .eq('status', 'pending');

        if (pendingCheck && pendingCheck.length > 0) {
          throw new Error('You already have a pending PIN request. Please wait for admin approval.');
        }

        // Insert directly into table (using existing schema)
        const { data: insertData, error: insertError } = await supabase
          .from('pin_requests')
          .insert({
            promoter_id: promoterId,
            quantity: requestedPins, // Use 'quantity' instead of 'requested_pins'
            reason: reason || 'PIN request submitted', // Ensure reason is never null
            category: 'standard', // Required field
            urgency: 'normal' // Required field
          })
          .select('*')
          .single();

        if (insertError) throw insertError;

        return {
          success: true,
          request_id: insertData.id,
          request_number: insertData.request_id, // Use existing 'request_id' field
          message: 'PIN request submitted successfully'
        };
      }
      
      // Check if it's a missing function error
      if (error.message?.includes('does not exist')) {
        throw new Error('PIN request system is not set up. Please contact administrator to run the database setup.');
      }
      console.error('❌ PIN request submission failed:', error);
      throw error;
    }

    if (!data.success) {
      console.error('❌ PIN request returned error:', data.error);
      throw new Error(data.error || 'PIN request submission failed');
    }

    console.log('✅ PIN request submitted successfully:', data);
    return data;

  } catch (error) {
    console.error('❌ PIN request service error:', error);
    throw error;
  }
};

/**
 * Get PIN requests for a promoter or all requests (admin)
 */
export const getPinRequests = async (promoterId = null, status = null, limit = 50) => {
  try {
    // First try to check if table exists by querying it directly
    const { data: tableCheck, error: tableError } = await supabase
      .from('pin_requests')
      .select('id')
      .limit(1);

    // If table doesn't exist or RLS is blocking, return empty array
    if (tableError && (tableError.code === '42P01' || tableError.code === '42703' || tableError.code === 'PGRST106' || tableError.code === 'PGRST301')) {
      console.warn('PIN requests table not found or RLS policies blocking access. Please run the database setup script.');
      return [];
    }

    // If table exists, use the RPC function
    const { data, error } = await supabase.rpc('get_pin_requests', {
      p_promoter_id: promoterId,
      p_status: status,
      p_limit: limit
    });

    if (error) {
      // Check if it's a missing function error, fallback to direct query
      if (error.code === '42883' || error.code === 'PGRST202') {
        console.warn('get_pin_requests function not found. Using direct table query.');
        
        // Use simple query without complex joins to avoid relationship issues
        console.warn('Using simple query without joins to avoid relationship issues.');
        
        let simpleQuery = supabase
          .from('pin_requests')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(limit);

        if (promoterId) {
          simpleQuery = simpleQuery.eq('promoter_id', promoterId);
        }
        if (status) {
          simpleQuery = simpleQuery.eq('status', status);
        }

        const { data: directData, error: directError } = await simpleQuery;
        
        if (directError) {
          // If table doesn't exist or RLS is blocking, return empty array
          if (directError.code === '42P01' || directError.code === 'PGRST200' || directError.code === 'PGRST301') {
            console.warn('pin_requests table not found, relationships missing, or RLS blocking access. Returning empty array.');
            return [];
          }
          throw directError;
        }

        // Transform the data to match expected format (map existing schema)
        return directData.map(request => ({
          ...request,
          // Map existing schema to expected format
          requested_pins: request.quantity, // Map quantity to requested_pins
          request_number: request.request_id, // Map request_id to request_number
          approved_by: request.processed_by, // Map processed_by to approved_by
          approved_at: request.response_date, // Map response_date to approved_at
          
          promoter_name: 'Promoter', // Will be filled by separate query if needed
          promoter_email: 'promoter@example.com', // Will be filled by separate query if needed
          admin_name: null, // Will be filled by separate query if needed
          statusConfig: PIN_REQUEST_CONFIG[request.status] || {
            emoji: '❓',
            label: 'Unknown',
            color: 'gray',
            description: 'Unknown status'
          },
          formattedRequestNumber: request.formatted_request_id || `REQ-${String(request.request_id || request.request_number).padStart(3, '0')}`,
          formattedDate: new Date(request.created_at).toLocaleDateString(),
          formattedTime: new Date(request.created_at).toLocaleTimeString([], { 
            hour: '2-digit', 
            minute: '2-digit' 
          })
        }));
      }
      
      // Check if it's a missing table/function error
      if (error.message?.includes('does not exist') || error.code === '42703') {
        console.warn('PIN requests table/function not found. Returning empty array.');
        return [];
      }
      throw error;
    }

    // Transform data for UI display
    const transformedData = data.map(request => ({
      ...request,
      statusConfig: PIN_REQUEST_CONFIG[request.status] || {
        emoji: '❓',
        label: 'Unknown',
        color: 'gray',
        description: 'Unknown status'
      },
      formattedRequestNumber: request.formatted_request_id || `REQ-${String(request.request_number).padStart(3, '0')}`,
      formattedDate: new Date(request.created_at).toLocaleDateString(),
      formattedTime: new Date(request.created_at).toLocaleTimeString([], { 
        hour: '2-digit', 
        minute: '2-digit' 
      })
    }));

    return transformedData;

  } catch (error) {
    console.error('❌ Failed to get PIN requests:', error);
    throw error;
  }
};

/**
 * Approve a PIN request (Admin only)
 */
export const approvePinRequest = async (requestId, adminId, adminNotes = null) => {
  try {
    console.log('🔄 Approving PIN request:', { requestId, adminId, adminNotes });

    const { data, error } = await supabase.rpc('approve_pin_request', {
      p_request_id: requestId,
      p_admin_id: adminId,
      p_admin_notes: adminNotes
    });

    if (error) {
      // If RPC function doesn't exist, use manual approval process
      if (error.code === '42883' || error.code === 'PGRST202') {
        console.warn('approve_pin_request function not found. Using manual approval process.');
        return await manualApproveRequest(requestId, adminId, adminNotes);
      }
      console.error('❌ PIN request approval failed:', error);
      throw error;
    }

    if (!data.success) {
      console.error('❌ PIN request approval returned error:', data.error);
      throw new Error(data.error || 'PIN request approval failed');
    }

    console.log('✅ PIN request approved successfully:', data);
    return data;

  } catch (error) {
    console.error('❌ PIN request approval service error:', error);
    throw error;
  }
};

/**
 * Manual approval process when RPC function is not available
 */
const manualApproveRequest = async (requestId, adminId, adminNotes) => {
  // Get the request details
  const { data: request, error: requestError } = await supabase
    .from('pin_requests')
    .select('*')
    .eq('id', requestId)
    .eq('status', 'pending')
    .single();

  if (requestError || !request) {
    throw new Error('Request not found or already processed');
  }

  console.log('📋 Request data for approval:', request);

  // Use the unified PIN transaction service to allocate PINs
  const pinResult = await pinTransactionService.adminAllocatePins(
    request.promoter_id,
    request.quantity || request.requested_pins, // Use quantity (existing schema) or requested_pins
    adminId
  );

  if (!pinResult.success) {
    throw new Error(`Failed to allocate PINs: ${pinResult.error}`);
  }

  // Update the request status (using existing schema)
  const { error: updateError } = await supabase
    .from('pin_requests')
    .update({
      status: 'approved',
      processed_by: adminId, // Use existing field name
      admin_notes: adminNotes,
      response_date: new Date().toISOString() // Use existing field name
    })
    .eq('id', requestId);

  if (updateError) {
    throw new Error(`Failed to update request status: ${updateError.message}`);
  }

  return {
    success: true,
    request_id: requestId,
    promoter_id: request.promoter_id,
    allocated_pins: request.requested_pins,
    new_balance: pinResult.balance_after,
    message: 'PIN request approved and PINs allocated successfully'
  };
};

/**
 * Reject a PIN request (Admin only)
 */
export const rejectPinRequest = async (requestId, adminId, adminNotes = null) => {
  try {
    console.log('🔄 Rejecting PIN request:', { requestId, adminId, adminNotes });

    const { data, error } = await supabase.rpc('reject_pin_request', {
      p_request_id: requestId,
      p_admin_id: adminId,
      p_admin_notes: adminNotes
    });

    if (error) {
      // If RPC function doesn't exist, use manual rejection process
      if (error.code === '42883' || error.code === 'PGRST202') {
        console.warn('reject_pin_request function not found. Using manual rejection process.');
        return await manualRejectRequest(requestId, adminId, adminNotes);
      }
      console.error('❌ PIN request rejection failed:', error);
      throw error;
    }

    if (!data.success) {
      console.error('❌ PIN request rejection returned error:', data.error);
      throw new Error(data.error || 'PIN request rejection failed');
    }

    console.log('✅ PIN request rejected successfully:', data);
    return data;

  } catch (error) {
    console.error('❌ PIN request rejection service error:', error);
    throw error;
  }
};

/**
 * Manual rejection process when RPC function is not available
 */
const manualRejectRequest = async (requestId, adminId, adminNotes) => {
  // Get the request details
  const { data: request, error: requestError } = await supabase
    .from('pin_requests')
    .select('*')
    .eq('id', requestId)
    .eq('status', 'pending')
    .single();

  if (requestError || !request) {
    throw new Error('Request not found or already processed');
  }

  // Update the request status (using existing schema)
  const { error: updateError } = await supabase
    .from('pin_requests')
    .update({
      status: 'rejected',
      processed_by: adminId, // Use existing field name
      admin_notes: adminNotes || 'Request rejected by admin',
      response_date: new Date().toISOString() // Use existing field name
    })
    .eq('id', requestId);

  if (updateError) {
    throw new Error(`Failed to update request status: ${updateError.message}`);
  }

  return {
    success: true,
    request_id: requestId,
    promoter_id: request.promoter_id,
    message: 'PIN request rejected'
  };
};

/**
 * Get PIN request statistics
 */
export const getPinRequestStats = async (promoterId = null) => {
  try {
    const requests = await getPinRequests(promoterId);
    
    const stats = {
      totalRequests: requests.length,
      pendingRequests: requests.filter(r => r.status === PIN_REQUEST_STATUS.PENDING).length,
      approvedRequests: requests.filter(r => r.status === PIN_REQUEST_STATUS.APPROVED).length,
      rejectedRequests: requests.filter(r => r.status === PIN_REQUEST_STATUS.REJECTED).length,
      totalPinsRequested: requests.reduce((sum, r) => sum + r.requested_pins, 0),
      totalPinsApproved: requests
        .filter(r => r.status === PIN_REQUEST_STATUS.APPROVED)
        .reduce((sum, r) => sum + r.requested_pins, 0)
    };

    return stats;

  } catch (error) {
    console.error('❌ Failed to get PIN request stats:', error);
    // Return empty stats if system is not set up yet
    return {
      totalRequests: 0,
      pendingRequests: 0,
      approvedRequests: 0,
      rejectedRequests: 0,
      totalPinsRequested: 0,
      totalPinsApproved: 0
    };
  }
};

/**
 * Check if promoter has pending requests
 */
export const hasPendingRequests = async (promoterId) => {
  try {
    const pendingRequests = await getPinRequests(promoterId, PIN_REQUEST_STATUS.PENDING, 1);
    return pendingRequests.length > 0;
  } catch (error) {
    console.error('❌ Failed to check pending requests:', error);
    // Return false if system is not set up yet
    return false;
  }
};

/**
 * Real-time PIN requests subscription
 */
export const subscribeToPinRequests = (callback, promoterId = null) => {
  let filter = '';
  if (promoterId) {
    filter = `promoter_id=eq.${promoterId}`;
  }

  const subscription = supabase
    .channel('pin-requests-changes')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'pin_requests',
        filter: filter
      },
      (payload) => {
        console.log('📡 PIN requests change detected:', payload);
        callback(payload);
      }
    )
    .subscribe();

  return subscription;
};

/**
 * Format PIN request for display
 */
export const formatPinRequest = (request) => {
  return {
    ...request,
    displayTitle: `${request.formattedRequestNumber} - ${request.requested_pins} PIN${request.requested_pins > 1 ? 's' : ''}`,
    displayStatus: `${request.statusConfig.emoji} ${request.statusConfig.label}`,
    displayDate: `${request.formattedDate} at ${request.formattedTime}`,
    displayReason: request.reason || 'No reason provided'
  };
};

/**
 * Validate PIN request input
 */
export const validatePinRequest = (requestedPins, reason = '') => {
  const errors = [];

  if (!requestedPins || requestedPins <= 0) {
    errors.push('Requested PINs must be greater than 0');
  }

  if (requestedPins > 1000) {
    errors.push('Cannot request more than 1000 PINs at once');
  }

  if (reason && reason.length > 500) {
    errors.push('Reason must be less than 500 characters');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
};

export default {
  submitPinRequest,
  getPinRequests,
  approvePinRequest,
  rejectPinRequest,
  getPinRequestStats,
  hasPendingRequests,
  subscribeToPinRequests,
  formatPinRequest,
  validatePinRequest,
  PIN_REQUEST_STATUS,
  PIN_REQUEST_CONFIG
};
