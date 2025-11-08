/**
 * Optimized Query Hook
 * Provides caching, rate limiting, and performance monitoring for database queries
 * Designed for high-concurrency applications
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { useOptimizedQuery as useScalabilityQuery } from '../context/ScalabilityContext';
import { supabase } from '../services/supabaseClient';

export const useOptimizedQuery = (table, operation, params = {}, options = {}) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [cached, setCached] = useState(false);
  
  const optimizedQuery = useScalabilityQuery();
  const abortControllerRef = useRef(null);
  const queryKeyRef = useRef(null);

  const {
    enabled = true,
    refetchOnMount = true,
    refetchOnWindowFocus = false,
    staleTime = 5 * 60 * 1000, // 5 minutes
    cacheTime = 10 * 60 * 1000, // 10 minutes
    retry = 3,
    retryDelay = 1000,
    onSuccess,
    onError,
    ...queryOptions
  } = options;

  // Generate unique query key
  const generateQueryKey = useCallback(() => {
    return `${table}_${operation}_${JSON.stringify(params)}`;
  }, [table, operation, params]);

  // Execute query with optimizations
  const executeQuery = useCallback(async (signal) => {
    if (!enabled) return;

    const queryKey = generateQueryKey();
    queryKeyRef.current = queryKey;

    try {
      setLoading(true);
      setError(null);

      const result = await optimizedQuery(table, operation, params, {
        ...queryOptions,
        signal
      });

      // Only update state if this is still the current query
      if (queryKeyRef.current === queryKey && !signal?.aborted) {
        setData(result.data);
        setCached(result.cached || false);
        
        if (onSuccess) {
          onSuccess(result.data);
        }
      }

    } catch (err) {
      // Only update state if this is still the current query
      if (queryKeyRef.current === queryKey && !signal?.aborted) {
        setError(err);
        
        if (onError) {
          onError(err);
        }
      }
    } finally {
      if (queryKeyRef.current === queryKey && !signal?.aborted) {
        setLoading(false);
      }
    }
  }, [table, operation, params, enabled, optimizedQuery, queryOptions, onSuccess, onError, generateQueryKey]);

  // Refetch function
  const refetch = useCallback(async () => {
    // Cancel previous request
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    // Create new abort controller
    abortControllerRef.current = new AbortController();
    
    await executeQuery(abortControllerRef.current.signal);
  }, [executeQuery]);

  // Initial fetch and dependency changes
  useEffect(() => {
    if (!enabled) {
      setLoading(false);
      return;
    }

    // Cancel previous request
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    // Create new abort controller
    abortControllerRef.current = new AbortController();
    
    executeQuery(abortControllerRef.current.signal);

    // Cleanup function
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
    };
  }, [executeQuery, enabled]);

  // Handle window focus refetch
  useEffect(() => {
    if (!refetchOnWindowFocus) return;

    const handleFocus = () => {
      if (document.visibilityState === 'visible') {
        refetch();
      }
    };

    document.addEventListener('visibilitychange', handleFocus);
    window.addEventListener('focus', handleFocus);

    return () => {
      document.removeEventListener('visibilitychange', handleFocus);
      window.removeEventListener('focus', handleFocus);
    };
  }, [refetch, refetchOnWindowFocus]);

  return {
    data,
    loading,
    error,
    cached,
    refetch,
    isStale: cached && Date.now() - (data?._cacheTime || 0) > staleTime
  };
};

// Hook for mutations (insert, update, delete)
export const useOptimizedMutation = (table, operation, options = {}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  
  const optimizedQuery = useScalabilityQuery();
  
  const {
    onSuccess,
    onError,
    onSettled,
    ...mutationOptions
  } = options;

  const mutate = useCallback(async (params) => {
    try {
      setLoading(true);
      setError(null);

      const result = await optimizedQuery(table, operation, params, {
        ...mutationOptions,
        useCache: false // Mutations shouldn't use cache
      });

      if (onSuccess) {
        onSuccess(result.data);
      }

      return result;

    } catch (err) {
      setError(err);
      
      if (onError) {
        onError(err);
      }
      
      throw err;
    } finally {
      setLoading(false);
      
      if (onSettled) {
        onSettled();
      }
    }
  }, [table, operation, optimizedQuery, mutationOptions, onSuccess, onError, onSettled]);

  return {
    mutate,
    loading,
    error
  };
};

// Hook for real-time subscriptions with optimization
export const useOptimizedSubscription = (table, filter = {}, options = {}) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const subscriptionRef = useRef(null);
  
  const {
    enabled = true,
    onInsert,
    onUpdate,
    onDelete,
    onError: onErrorCallback
  } = options;

  useEffect(() => {
    if (!enabled) {
      setLoading(false);
      return;
    }

    const setupSubscription = async () => {
      try {
        // Initial data fetch
        const { data: initialData, error: fetchError } = await supabase
          .from(table)
          .select('*')
          .match(filter);

        if (fetchError) throw fetchError;
        
        setData(initialData || []);
        setLoading(false);

        // Setup real-time subscription
        const subscription = supabase
          .channel(`${table}_subscription`)
          .on('postgres_changes', {
            event: '*',
            schema: 'public',
            table: table,
            filter: Object.keys(filter).length > 0 
              ? Object.entries(filter).map(([key, value]) => `${key}=eq.${value}`).join(',')
              : undefined
          }, (payload) => {
            const { eventType, new: newRecord, old: oldRecord } = payload;
            
            setData(currentData => {
              let updatedData = [...currentData];
              
              switch (eventType) {
                case 'INSERT':
                  updatedData.push(newRecord);
                  if (onInsert) onInsert(newRecord);
                  break;
                  
                case 'UPDATE':
                  const updateIndex = updatedData.findIndex(item => item.id === newRecord.id);
                  if (updateIndex !== -1) {
                    updatedData[updateIndex] = newRecord;
                  }
                  if (onUpdate) onUpdate(newRecord, oldRecord);
                  break;
                  
                case 'DELETE':
                  updatedData = updatedData.filter(item => item.id !== oldRecord.id);
                  if (onDelete) onDelete(oldRecord);
                  break;
              }
              
              return updatedData;
            });
          })
          .subscribe();

        subscriptionRef.current = subscription;

      } catch (err) {
        setError(err);
        setLoading(false);
        
        if (onErrorCallback) {
          onErrorCallback(err);
        }
      }
    };

    setupSubscription();

    return () => {
      if (subscriptionRef.current) {
        supabase.removeChannel(subscriptionRef.current);
        subscriptionRef.current = null;
      }
    };
  }, [table, JSON.stringify(filter), enabled, onInsert, onUpdate, onDelete, onErrorCallback]);

  return {
    data,
    loading,
    error
  };
};

// Hook for paginated queries with optimization
export const useOptimizedPagination = (table, options = {}) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(0);
  
  const optimizedQuery = useScalabilityQuery();
  
  const {
    pageSize = 20,
    orderBy = 'created_at',
    ascending = false,
    filter = {},
    enabled = true
  } = options;

  const loadMore = useCallback(async () => {
    if (loading || !hasMore || !enabled) return;

    try {
      setLoading(true);
      setError(null);

      const result = await optimizedQuery(table, 'select', {
        columns: '*',
        eq: filter,
        order: { column: orderBy, ascending },
        range: { from: page * pageSize, to: (page + 1) * pageSize - 1 }
      });

      const newData = result.data || [];
      
      setData(currentData => [...currentData, ...newData]);
      setHasMore(newData.length === pageSize);
      setPage(currentPage => currentPage + 1);

    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [table, page, pageSize, orderBy, ascending, filter, loading, hasMore, enabled, optimizedQuery]);

  const reset = useCallback(() => {
    setData([]);
    setPage(0);
    setHasMore(true);
    setError(null);
  }, []);

  // Load initial data
  useEffect(() => {
    if (enabled && data.length === 0 && page === 0) {
      loadMore();
    }
  }, [enabled, data.length, page, loadMore]);

  return {
    data,
    loading,
    error,
    hasMore,
    loadMore,
    reset
  };
};

export default useOptimizedQuery;
