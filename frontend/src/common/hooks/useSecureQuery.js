/**
 * Secure Query Hook with Role-Based Access Control
 * Ensures all database queries respect user roles and permissions
 */

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { roleBasedSecurity } from '../utils/roleBasedSecurity';
import { useOptimizedQuery } from './useOptimizedQuery';

export const useSecureQuery = (table, operation, params = {}, options = {}) => {
  const { user } = useAuth();
  const [securityValidated, setSecurityValidated] = useState(false);
  const [accessDenied, setAccessDenied] = useState(false);
  const [securityError, setSecurityError] = useState(null);

  // Validate security access
  useEffect(() => {
    const validateAccess = async () => {
      if (!user) {
        setAccessDenied(true);
        setSecurityError('User not authenticated');
        return;
      }

      try {
        const validation = await roleBasedSecurity.validateAccess(
          user.id,
          table,
          operation,
          params.targetId
        );

        if (validation.allowed) {
          setSecurityValidated(true);
          setAccessDenied(false);
          setSecurityError(null);
        } else {
          setAccessDenied(true);
          setSecurityError(validation.reason);
        }
      } catch (error) {
        setAccessDenied(true);
        setSecurityError(error.message);
      }
    };

    validateAccess();
  }, [user, table, operation, params.targetId]);

  // Create secure query parameters
  const secureParams = useCallback(() => {
    if (!user || !securityValidated) return params;

    // Apply role-based filtering
    const filteredParams = { ...params };

    switch (table) {
      case 'profiles':
        if (user.role !== 'admin' && !params.targetId) {
          filteredParams.eq = { ...filteredParams.eq, id: user.id };
        }
        break;

      case 'customers':
        if (user.role === 'customer') {
          filteredParams.eq = { ...filteredParams.eq, id: user.id };
        } else if (user.role === 'promoter') {
          filteredParams.eq = { ...filteredParams.eq, promoter_id: user.id };
        }
        break;

      case 'promoters':
        if (user.role === 'promoter') {
          filteredParams.eq = { ...filteredParams.eq, id: user.id };
        }
        break;

      case 'customer_investments':
        if (user.role === 'customer') {
          filteredParams.eq = { ...filteredParams.eq, customer_id: user.id };
        } else if (user.role === 'promoter') {
          filteredParams.eq = { ...filteredParams.eq, promoter_id: user.id };
        }
        break;
    }

    return filteredParams;
  }, [user, securityValidated, params, table]);

  // Use optimized query with security validation
  const queryResult = useOptimizedQuery(
    table,
    operation,
    secureParams(),
    {
      ...options,
      enabled: securityValidated && !accessDenied
    }
  );

  return {
    ...queryResult,
    securityValidated,
    accessDenied,
    securityError,
    userRole: user?.role
  };
};

export const useSecureMutation = (table, operation, options = {}) => {
  const { user } = useAuth();
  const [securityValidated, setSecurityValidated] = useState(false);

  const validateAndExecute = useCallback(async (params) => {
    if (!user) {
      throw new Error('User not authenticated');
    }

    // Validate access for mutation
    const validation = await roleBasedSecurity.validateAccess(
      user.id,
      table,
      operation,
      params.targetId
    );

    if (!validation.allowed) {
      throw new Error(`Access denied: ${validation.reason}`);
    }

    // Apply role-based data filtering for mutations
    const secureParams = { ...params };

    // Ensure user can only modify their own data or authorized data
    switch (table) {
      case 'profiles':
        if (user.role !== 'admin') {
          secureParams.eq = { ...secureParams.eq, id: user.id };
        }
        break;

      case 'customers':
        if (user.role === 'customer') {
          secureParams.eq = { ...secureParams.eq, id: user.id };
        } else if (user.role === 'promoter' && operation === 'insert') {
          secureParams.data = { ...secureParams.data, promoter_id: user.id };
        }
        break;

      case 'promoters':
        if (user.role === 'promoter') {
          secureParams.eq = { ...secureParams.eq, id: user.id };
        }
        break;
    }

    return secureParams;
  }, [user, table, operation]);

  return {
    mutate: validateAndExecute,
    userRole: user?.role
  };
};

export default useSecureQuery;
