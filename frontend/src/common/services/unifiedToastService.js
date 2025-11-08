import React, { createContext, useContext, useState, useCallback } from 'react';
import { CheckCircle, AlertCircle, AlertTriangle, Info, X } from 'lucide-react';

/**
 * Unified Toast Service - Matches the beautiful SuccessModal style
 * Clean white background, colored icons, centered design
 */

// Toast types
export const TOAST_TYPES = {
  SUCCESS: 'success',
  ERROR: 'error',
  WARNING: 'warning',
  INFO: 'info'
};

// Toast Context
const ToastContext = createContext();

// Toast Component - Styled like the SuccessModal
const Toast = ({ id, type, title, message, onClose, autoClose = true, duration = 5000 }) => {
  const [isVisible, setIsVisible] = React.useState(true);

  // Auto close functionality
  React.useEffect(() => {
    if (autoClose) {
      const timer = setTimeout(() => {
        setIsVisible(false);
        setTimeout(() => onClose(id), 300); // Allow fade out animation
      }, duration);
      
      return () => clearTimeout(timer);
    }
  }, [autoClose, duration, id, onClose]);

  // Icon and color configuration
  const getToastConfig = () => {
    switch (type) {
      case TOAST_TYPES.SUCCESS:
        return {
          icon: CheckCircle,
          iconBg: 'bg-green-100',
          iconColor: 'text-[#16A34A]',
          buttonBg: 'bg-[#16A34A] hover:bg-[#15803D]',
          borderColor: 'border-green-200'
        };
      case TOAST_TYPES.ERROR:
        return {
          icon: AlertCircle,
          iconBg: 'bg-red-100',
          iconColor: 'text-[#EF4444]',
          buttonBg: 'bg-[#EF4444] hover:bg-[#DC2626]',
          borderColor: 'border-red-200'
        };
      case TOAST_TYPES.WARNING:
        return {
          icon: AlertTriangle,
          iconBg: 'bg-amber-100',
          iconColor: 'text-[#F59E0B]',
          buttonBg: 'bg-[#F59E0B] hover:bg-[#D97706]',
          borderColor: 'border-amber-200'
        };
      case TOAST_TYPES.INFO:
      default:
        return {
          icon: Info,
          iconBg: 'bg-purple-100',
          iconColor: 'text-[#9B5DE5]',
          buttonBg: 'bg-[#9B5DE5] hover:bg-[#8B5CF6]',
          borderColor: 'border-purple-200'
        };
    }
  };

  const config = getToastConfig();
  const IconComponent = config.icon;

  if (!isVisible) return null;

  return (
    <div className={`fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-[9999] transition-opacity duration-300 ${isVisible ? 'opacity-100' : 'opacity-0'}`}>
      <div className={`bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 transform transition-all duration-200 ${isVisible ? 'scale-100' : 'scale-95'} border ${config.borderColor}`}>
        {/* Header */}
        <div className="relative p-6 text-center border-b border-gray-100">
          <button
            onClick={() => {
              setIsVisible(false);
              setTimeout(() => onClose(id), 300);
            }}
            className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
          
          <div className={`w-16 h-16 ${config.iconBg} rounded-full flex items-center justify-center mx-auto mb-4`}>
            <IconComponent className={`w-8 h-8 ${config.iconColor}`} />
          </div>
          
          <h3 className="text-xl font-semibold text-gray-900 mb-2">
            {title}
          </h3>
        </div>

        {/* Content */}
        <div className="p-6 text-center">
          <div className="space-y-3">
            <p className="text-gray-600 leading-relaxed whitespace-pre-line">
              {message}
            </p>
          </div>
          
          {autoClose && (
            <p className="text-xs text-gray-400 mt-4">
              This message will close automatically in {duration / 1000} seconds
            </p>
          )}
        </div>

        {/* Footer */}
        <div className="p-6 pt-0 text-center">
          <button
            onClick={() => {
              setIsVisible(false);
              setTimeout(() => onClose(id), 300);
            }}
            className={`w-full ${config.buttonBg} text-white font-medium py-3 px-6 rounded-lg transition-colors`}
          >
            Got it!
          </button>
        </div>
      </div>
    </div>
  );
};

// Toast Provider Component
export const UnifiedToastProvider = ({ children }) => {
  const [toasts, setToasts] = useState([]);

  const addToast = useCallback((toast) => {
    const id = Date.now() + Math.random();
    const newToast = {
      id,
      type: TOAST_TYPES.SUCCESS,
      title: 'Notification',
      autoClose: true,
      duration: 5000,
      ...toast
    };
    
    setToasts(prev => [...prev, newToast]);
    return id;
  }, []);

  const removeToast = useCallback((id) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  }, []);

  const clearAllToasts = useCallback(() => {
    setToasts([]);
  }, []);

  // Convenience methods
  const showSuccess = useCallback((message, title = 'Success!') => {
    return addToast({ 
      type: TOAST_TYPES.SUCCESS, 
      title, 
      message,
      duration: 5000
    });
  }, [addToast]);

  const showError = useCallback((message, title = 'Error') => {
    return addToast({ 
      type: TOAST_TYPES.ERROR, 
      title, 
      message,
      duration: 7000 // Errors stay longer
    });
  }, [addToast]);

  const showWarning = useCallback((message, title = 'Warning') => {
    return addToast({ 
      type: TOAST_TYPES.WARNING, 
      title, 
      message,
      duration: 6000
    });
  }, [addToast]);

  const showInfo = useCallback((message, title = 'Information') => {
    return addToast({ 
      type: TOAST_TYPES.INFO, 
      title, 
      message,
      duration: 5000
    });
  }, [addToast]);

  const value = {
    toasts,
    addToast,
    removeToast,
    clearAllToasts,
    showSuccess,
    showError,
    showWarning,
    showInfo
  };

  return (
    <ToastContext.Provider value={value}>
      {children}
      {/* Render toasts */}
      {toasts.map((toast) => (
        <Toast
          key={toast.id}
          {...toast}
          onClose={removeToast}
        />
      ))}
    </ToastContext.Provider>
  );
};

// Hook to use toast
export const useUnifiedToast = () => {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useUnifiedToast must be used within UnifiedToastProvider');
  }
  return context;
};

// Export default hook for convenience
export default useUnifiedToast;
