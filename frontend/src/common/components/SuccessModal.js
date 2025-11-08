import React from 'react';
import { CheckCircle, X } from 'lucide-react';

/**
 * Clean, centered success modal for important notifications
 * Perfect for promoter creation, customer creation, etc.
 */
const SuccessModal = ({ 
  isOpen, 
  onClose, 
  title, 
  message, 
  details = null,
  autoClose = true,
  autoCloseDelay = 5000 
}) => {
  // Auto close functionality
  React.useEffect(() => {
    if (isOpen && autoClose) {
      const timer = setTimeout(() => {
        onClose();
      }, autoCloseDelay);
      
      return () => clearTimeout(timer);
    }
  }, [isOpen, autoClose, autoCloseDelay, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-[9999]">
      <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 transform animate-in zoom-in-95 duration-200">
        {/* Header */}
        <div className="relative p-6 text-center border-b border-gray-100">
          <button
            onClick={onClose}
            className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
          
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <CheckCircle className="w-8 h-8 text-[#16A34A]" />
          </div>
          
          <h3 className="text-xl font-semibold text-gray-900 mb-2">
            {title}
          </h3>
        </div>

        {/* Content */}
        <div className="p-6 text-center">
          <div className="space-y-3">
            {message && (
              <p className="text-gray-600 leading-relaxed">
                {message}
              </p>
            )}
            
            {details && (
              <div className="bg-gray-50 rounded-lg p-4 text-left">
                <div className="space-y-2 text-sm">
                  {details.split('\n').map((line, index) => (
                    <div key={index} className="flex justify-between">
                      <span className="font-medium text-gray-700">
                        {line.split(':')[0]}:
                      </span>
                      <span className="text-gray-900 font-mono">
                        {line.split(':')[1]?.trim()}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
          
          {autoClose && (
            <p className="text-xs text-gray-400 mt-4">
              This message will close automatically in {autoCloseDelay / 1000} seconds
            </p>
          )}
        </div>

        {/* Footer */}
        <div className="p-6 pt-0 text-center">
          <button
            onClick={onClose}
            className="w-full bg-[#16A34A] hover:bg-[#15803D] text-white font-medium py-3 px-6 rounded-lg transition-colors"
          >
            Got it!
          </button>
        </div>
      </div>
    </div>
  );
};

export default SuccessModal;
