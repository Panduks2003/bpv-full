/**
 * Unified Toast & Alert Service for Admin Dashboard
 * 
 * Provides centralized notification management with consistent styling,
 * behavior, and messaging across all admin components.
 * 
 * Features:
 * - Standardized toast types (success, error, warning, info)
 * - Auto-dismiss with configurable duration
 * - Queue management for multiple toasts
 * - Responsive design with smooth animations
 * - Backend error mapping
 * - Consistent message formatting
 */

import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { CheckCircle, AlertCircle, AlertTriangle, Info, X } from 'lucide-react';

// Toast types with consistent styling
export const TOAST_TYPES = {
  SUCCESS: 'success',
  ERROR: 'error', 
  WARNING: 'warning',
  INFO: 'info'
};

// Default configuration
const DEFAULT_CONFIG = {
  duration: 4000, // 4 seconds
  position: 'top-right',
  maxToasts: 5,
  showCloseButton: true,
  pauseOnHover: true
};

// Common message templates
export const MESSAGE_TEMPLATES = {
  OPERATION_SUCCESS: 'Operation completed successfully',
  OPERATION_FAILED: 'Operation failed. Please try again',
  NETWORK_ERROR: 'Network error. Please check your connection',
  SERVER_ERROR: 'Server error. Please try again later'
};

// Basic error code mapping
export const ERROR_CODE_MAPPING = {
  400: { type: TOAST_TYPES.WARNING, message: 'Invalid request. Please check your input' },
  401: { type: TOAST_TYPES.ERROR, message: 'Unauthorized action' },
  403: { type: TOAST_TYPES.ERROR, message: 'Access denied' },
  404: { type: TOAST_TYPES.WARNING, message: 'Resource not found' },
  500: { type: TOAST_TYPES.ERROR, message: MESSAGE_TEMPLATES.SERVER_ERROR }
};

// Toast Context
const ToastContext = createContext();

// Custom hook to use toast service
export const useToast = () => {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
};

// Individual Toast Component
const Toast = ({ id, type, title, message, duration, onClose, showCloseButton, pauseOnHover }) => {
  const [isVisible, setIsVisible] = useState(false);
  const [isPaused, setIsPaused] = useState(false);

  useEffect(() => {
    // Trigger entrance animation
    const timer = setTimeout(() => setIsVisible(true), 10);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    if (!duration || isPaused) return;

    const timer = setTimeout(() => {
      handleClose();
    }, duration);

    return () => clearTimeout(timer);
  }, [duration, isPaused]);

  const handleClose = () => {
    setIsVisible(false);
    setTimeout(() => onClose(id), 300); // Wait for exit animation
  };

  const getToastConfig = () => {
    switch (type) {
      case TOAST_TYPES.SUCCESS:
        return {
          icon: CheckCircle,
          bgColor: 'bg-[#16A34A]/10',
          borderColor: 'border-[#16A34A]/20',
          iconColor: 'text-[#16A34A]',
          titleColor: 'text-[#F8FAFC]',
          messageColor: 'text-[#CBD5E1]'
        };
      case TOAST_TYPES.ERROR:
        return {
          icon: AlertCircle,
          bgColor: 'bg-[#EF4444]/10',
          borderColor: 'border-[#EF4444]/20',
          iconColor: 'text-[#EF4444]',
          titleColor: 'text-[#F8FAFC]',
          messageColor: 'text-[#CBD5E1]'
        };
      case TOAST_TYPES.WARNING:
        return {
          icon: AlertTriangle,
          bgColor: 'bg-[#F59E0B]/10',
          borderColor: 'border-[#F59E0B]/20',
          iconColor: 'text-[#F59E0B]',
          titleColor: 'text-[#F8FAFC]',
          messageColor: 'text-[#CBD5E1]'
        };
      case TOAST_TYPES.INFO:
      default:
        return {
          icon: Info,
          bgColor: 'bg-[#9B5DE5]/10',
          borderColor: 'border-[#9B5DE5]/20',
          iconColor: 'text-[#9B5DE5]',
          titleColor: 'text-[#F8FAFC]',
          messageColor: 'text-[#CBD5E1]'
        };
    }
  };

  const config = getToastConfig();
  const IconComponent = config.icon;

  return (
    <div
      className={`
        transform transition-all duration-300 ease-in-out backdrop-blur-sm
        ${isVisible ? 'translate-x-0 opacity-100' : 'translate-x-full opacity-0'}
        ${config.bgColor} ${config.borderColor}
        border rounded-lg shadow-lg p-4 mb-3 min-w-[320px] max-w-[480px]
      `}
      onMouseEnter={() => pauseOnHover && setIsPaused(true)}
      onMouseLeave={() => pauseOnHover && setIsPaused(false)}
    >
      <div className="flex items-start space-x-3">
        <IconComponent className={`w-5 h-5 ${config.iconColor} flex-shrink-0 mt-0.5`} />
        
        <div className="flex-1 min-w-0">
          {title && (
            <h4 className={`font-semibold text-sm ${config.titleColor} mb-1`}>
              {title}
            </h4>
          )}
          <p className={`text-sm ${config.messageColor} leading-relaxed`}>
            {message}
          </p>
        </div>

        {showCloseButton && (
          <button
            onClick={handleClose}
            className={`${config.iconColor} hover:opacity-70 transition-opacity flex-shrink-0`}
            aria-label="Close notification"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>
    </div>
  );
};

// Toast Container Component
const ToastContainer = ({ toasts, position, onClose, config }) => {
  const getPositionClasses = () => {
    switch (position) {
      case 'top-left':
        return 'top-6 left-6';
      case 'top-center':
        return 'top-6 left-1/2 transform -translate-x-1/2';
      case 'top-right':
      default:
        return 'top-6 right-6';
      case 'bottom-left':
        return 'bottom-6 left-6';
      case 'bottom-center':
        return 'bottom-6 left-1/2 transform -translate-x-1/2';
      case 'bottom-right':
        return 'bottom-6 right-6';
    }
  };

  if (toasts.length === 0) return null;

  return (
    <div className={`fixed z-50 ${getPositionClasses()}`}>
      <div className="space-y-2">
        {toasts.map((toast) => (
          <Toast
            key={toast.id}
            {...toast}
            onClose={onClose}
            showCloseButton={config.showCloseButton}
            pauseOnHover={config.pauseOnHover}
          />
        ))}
      </div>
    </div>
  );
};

// Toast Provider Component
export const ToastProvider = ({ children, config = {} }) => {
  const [toasts, setToasts] = useState([]);
  const mergedConfig = { ...DEFAULT_CONFIG, ...config };

  const addToast = useCallback((toast) => {
    const id = Date.now() + Math.random();
    const newToast = {
      id,
      duration: mergedConfig.duration,
      ...toast
    };

    setToasts(prev => {
      const updated = [...prev, newToast];
      // Limit number of toasts
      if (updated.length > mergedConfig.maxToasts) {
        return updated.slice(-mergedConfig.maxToasts);
      }
      return updated;
    });

    return id;
  }, [mergedConfig]);

  const removeToast = useCallback((id) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  }, []);

  const clearAllToasts = useCallback(() => {
    setToasts([]);
  }, []);

  // Convenience methods for different toast types
  const showSuccess = useCallback((message, title = 'Success') => {
    return addToast({ type: TOAST_TYPES.SUCCESS, title, message });
  }, [addToast]);

  const showError = useCallback((message, title = 'Error') => {
    return addToast({ type: TOAST_TYPES.ERROR, title, message });
  }, [addToast]);

  const showWarning = useCallback((message, title = 'Warning') => {
    return addToast({ type: TOAST_TYPES.WARNING, title, message });
  }, [addToast]);

  const showInfo = useCallback((message, title = 'Info') => {
    return addToast({ type: TOAST_TYPES.INFO, title, message });
  }, [addToast]);

  // Handle backend errors with automatic mapping
  const handleApiError = useCallback((error, fallbackMessage = MESSAGE_TEMPLATES.OPERATION_FAILED) => {
    let toastConfig = { type: TOAST_TYPES.ERROR, title: 'Error' };
    
    if (error?.response?.status) {
      const statusCode = error.response.status;
      const mapping = ERROR_CODE_MAPPING[statusCode];
      if (mapping) {
        toastConfig = { ...toastConfig, ...mapping };
      }
    } else if (error?.message) {
      toastConfig.message = error.message;
    } else {
      toastConfig.message = fallbackMessage;
    }

    return addToast(toastConfig);
  }, [addToast]);

  // Handle successful operations
  const handleSuccess = useCallback((message) => {
    return showSuccess(message);
  }, [showSuccess]);

  const value = {
    // Core methods
    addToast,
    removeToast,
    clearAllToasts,
    
    // Convenience methods
    showSuccess,
    showError,
    showWarning,
    showInfo,
    
    // Specialized methods
    handleApiError,
    handleSuccess,
    
    // State
    toasts,
    config: mergedConfig
  };

  return (
    <ToastContext.Provider value={value}>
      {children}
      <ToastContainer
        toasts={toasts}
        position={mergedConfig.position}
        onClose={removeToast}
        config={mergedConfig}
      />
    </ToastContext.Provider>
  );
};

// Export utility functions for direct use
export const createToastService = (config = {}) => {
  return {
    success: (message, title = 'Success') => ({ type: TOAST_TYPES.SUCCESS, title, message }),
    error: (message, title = 'Error') => ({ type: TOAST_TYPES.ERROR, title, message }),
    warning: (message, title = 'Warning') => ({ type: TOAST_TYPES.WARNING, title, message }),
    info: (message, title = 'Info') => ({ type: TOAST_TYPES.INFO, title, message })
  };
};

export default ToastProvider;
