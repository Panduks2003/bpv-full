import React, { useState, useEffect } from 'react';
import { Shield, Clock, AlertTriangle, CheckCircle } from 'lucide-react';

const SecurityAlert = ({ 
  initialSeconds = 38, 
  message = "For security purposes, you can only request this after", 
  onComplete = null,
  type = "security" // "security", "warning", "success"
}) => {
  const [timeLeft, setTimeLeft] = useState(initialSeconds);
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    if (timeLeft <= 0) {
      if (onComplete) onComplete();
      return;
    }

    const timer = setInterval(() => {
      setTimeLeft(prev => prev - 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [timeLeft, onComplete]);

  const formatTime = (seconds) => {
    if (seconds <= 0) return "0s";
    if (seconds < 60) return `${seconds}s`;
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}m ${remainingSeconds}s`;
  };

  const getAlertStyles = () => {
    switch (type) {
      case "warning":
        return {
          container: "bg-gradient-to-r from-yellow-50 to-orange-50 border-yellow-200",
          icon: "text-yellow-600",
          text: "text-yellow-800",
          accent: "text-yellow-600",
          progress: "bg-yellow-500"
        };
      case "success":
        return {
          container: "bg-gradient-to-r from-green-50 to-emerald-50 border-green-200",
          icon: "text-green-600",
          text: "text-green-800",
          accent: "text-green-600",
          progress: "bg-green-500"
        };
      default: // security
        return {
          container: "bg-gradient-to-r from-blue-50 to-indigo-50 border-blue-200",
          icon: "text-blue-600",
          text: "text-blue-800",
          accent: "text-blue-600",
          progress: "bg-blue-500"
        };
    }
  };

  const getIcon = () => {
    switch (type) {
      case "warning":
        return <AlertTriangle className="w-5 h-5" />;
      case "success":
        return <CheckCircle className="w-5 h-5" />;
      default:
        return <Shield className="w-5 h-5" />;
    }
  };

  const styles = getAlertStyles();
  const progressPercentage = ((initialSeconds - timeLeft) / initialSeconds) * 100;

  if (!isVisible || timeLeft <= 0) {
    return null;
  }

  return (
    <div className={`fixed top-4 right-4 max-w-md w-full mx-4 z-50 animate-in slide-in-from-right duration-300`}>
      <div className={`relative overflow-hidden rounded-xl border-2 ${styles.container} shadow-lg backdrop-blur-sm`}>
        {/* Progress bar */}
        <div className="absolute top-0 left-0 h-1 bg-gray-200 w-full">
          <div 
            className={`h-full ${styles.progress} transition-all duration-1000 ease-linear`}
            style={{ width: `${progressPercentage}%` }}
          />
        </div>

        <div className="p-4 pt-6">
          <div className="flex items-start space-x-3">
            {/* Icon */}
            <div className={`flex-shrink-0 ${styles.icon}`}>
              {getIcon()}
            </div>

            {/* Content */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between mb-2">
                <h4 className={`text-sm font-semibold ${styles.text}`}>
                  Security Cooldown
                </h4>
                <button
                  onClick={() => setIsVisible(false)}
                  className={`${styles.icon} hover:opacity-70 transition-opacity`}
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <p className={`text-sm ${styles.text} mb-3`}>
                {message}
              </p>

              {/* Countdown display */}
              <div className="flex items-center space-x-2">
                <Clock className={`w-4 h-4 ${styles.icon}`} />
                <div className="flex items-baseline space-x-1">
                  <span className={`text-lg font-bold ${styles.accent} font-mono`}>
                    {formatTime(timeLeft)}
                  </span>
                  <span className={`text-xs ${styles.text} opacity-75`}>
                    remaining
                  </span>
                </div>
              </div>

              {/* Additional info */}
              <div className={`mt-2 text-xs ${styles.text} opacity-60`}>
                This helps protect your account from automated requests
              </div>
            </div>
          </div>
        </div>

        {/* Subtle animation effect */}
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white to-transparent opacity-10 animate-pulse" />
      </div>
    </div>
  );
};

// Toast-style version for inline use
export const SecurityToast = ({ 
  seconds = 38, 
  message = "Security cooldown active",
  onComplete = null 
}) => {
  const [timeLeft, setTimeLeft] = useState(seconds);

  useEffect(() => {
    if (timeLeft <= 0) {
      if (onComplete) onComplete();
      return;
    }

    const timer = setInterval(() => {
      setTimeLeft(prev => prev - 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [timeLeft, onComplete]);

  if (timeLeft <= 0) return null;

  return (
    <div className="inline-flex items-center space-x-2 bg-blue-50 text-blue-700 px-3 py-2 rounded-lg border border-blue-200">
      <Shield className="w-4 h-4" />
      <span className="text-sm">
        {message} ({timeLeft}s)
      </span>
    </div>
  );
};

// Modal version for blocking interactions
export const SecurityModal = ({ 
  isOpen = true,
  seconds = 38,
  title = "Security Verification",
  message = "For security purposes, please wait before making another request.",
  onComplete = null,
  onClose = null
}) => {
  const [timeLeft, setTimeLeft] = useState(seconds);

  useEffect(() => {
    if (timeLeft <= 0) {
      if (onComplete) onComplete();
      return;
    }

    const timer = setInterval(() => {
      setTimeLeft(prev => prev - 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [timeLeft, onComplete]);

  if (!isOpen || timeLeft <= 0) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl p-6 max-w-md w-full mx-4 shadow-2xl">
        <div className="text-center">
          <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <Shield className="w-8 h-8 text-blue-600" />
          </div>
          
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            {title}
          </h3>
          
          <p className="text-gray-600 mb-6">
            {message}
          </p>

          <div className="bg-gray-50 rounded-lg p-4 mb-4">
            <div className="flex items-center justify-center space-x-2">
              <Clock className="w-5 h-5 text-blue-600" />
              <span className="text-2xl font-bold text-blue-600 font-mono">
                {Math.floor(timeLeft / 60)}:{(timeLeft % 60).toString().padStart(2, '0')}
              </span>
            </div>
            <div className="text-sm text-gray-500 mt-1">
              Time remaining
            </div>
          </div>

          {onClose && (
            <button
              onClick={onClose}
              className="text-gray-500 hover:text-gray-700 text-sm"
            >
              Dismiss
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default SecurityAlert;
