/**
 * PIN REQUEST MODAL COMPONENT
 * ============================
 * Modal for promoters to request additional PINs from admin
 */

import React, { useState, useEffect } from 'react';
import { XCircle, Send, AlertCircle, Shield, Pin } from 'lucide-react';
import { UnifiedCard, UnifiedButton } from '../common/components/SharedTheme';
import pinRequestService from '../services/pinRequestService';

const PinRequestModal = ({ 
  isOpen, 
  onClose, 
  promoterId, 
  onSuccess,
  onError 
}) => {
  const [formData, setFormData] = useState({
    requestedPins: '',
    reason: ''
  });
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [hasPending, setHasPending] = useState(false);

  // Check for pending requests when modal opens
  useEffect(() => {
    if (isOpen && promoterId) {
      checkPendingRequests();
    }
  }, [isOpen, promoterId]);

  const checkPendingRequests = async () => {
    try {
      const pending = await pinRequestService.hasPendingRequests(promoterId);
      setHasPending(pending);
    } catch (error) {
      console.error('Failed to check pending requests:', error);
    }
  };

  const validateForm = () => {
    const validation = pinRequestService.validatePinRequest(
      parseInt(formData.requestedPins), 
      formData.reason
    );

    if (!validation.isValid) {
      const errorObj = {};
      validation.errors.forEach(error => {
        if (error.includes('PINs must be greater')) {
          errorObj.requestedPins = error;
        } else if (error.includes('more than 1000')) {
          errorObj.requestedPins = error;
        } else if (error.includes('Reason')) {
          errorObj.reason = error;
        }
      });
      setErrors(errorObj);
      return false;
    }

    setErrors({});
    return true;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    if (hasPending) {
      onError('You already have a pending PIN request. Please wait for admin approval.');
      return;
    }

    setSubmitting(true);
    try {
      const result = await pinRequestService.submitPinRequest(
        promoterId,
        parseInt(formData.requestedPins),
        formData.reason || null
      );

      onSuccess(`PIN Request Submitted Successfully!\n\nRequested PINs: ${formData.requestedPins}\nStatus: Pending Admin Approval\n\nYour request will appear in the PIN Requests list with a sequential ID.`);
      
      // Reset form and close modal
      setFormData({ requestedPins: '', reason: '' });
      setErrors({});
      onClose();

    } catch (error) {
      console.error('PIN request submission failed:', error);
      onError(`Failed to Submit PIN Request\n\nError: ${error.message}`);
    } finally {
      setSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!submitting) {
      setFormData({ requestedPins: '', reason: '' });
      setErrors({});
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <UnifiedCard className="w-full max-w-md" variant="glassDark">
        <div className="p-6">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-r from-orange-500 to-yellow-500 rounded-xl flex items-center justify-center">
                <Pin className="w-5 h-5 text-white" />
              </div>
              <h3 className="text-xl font-semibold text-white">Request PINs</h3>
            </div>
            <button
              onClick={handleClose}
              disabled={submitting}
              className="text-gray-300 hover:text-white transition-colors disabled:opacity-50"
            >
              <XCircle className="w-5 h-5" />
            </button>
          </div>

          {/* Pending Request Warning */}
          {hasPending && (
            <div className="mb-6 p-4 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
              <div className="flex items-start space-x-3">
                <AlertCircle className="w-5 h-5 text-yellow-400 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-yellow-300 text-sm font-medium">Pending Request Found</p>
                  <p className="text-gray-300 text-sm mt-1">
                    You already have a pending PIN request. Please wait for admin approval before submitting a new request.
                  </p>
                </div>
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Requested PINs Input */}
            <div>
              <label className="block text-gray-300 text-sm font-medium mb-2">
                Number of PINs <span className="text-red-400">*</span>
              </label>
              <input
                type="number"
                min="1"
                max="1000"
                value={formData.requestedPins}
                onChange={(e) => setFormData({...formData, requestedPins: e.target.value})}
                placeholder="Enter quantity (e.g., 10)"
                disabled={submitting || hasPending}
                className={`w-full px-4 py-3 bg-gray-800/50 border rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 transition-colors ${
                  errors.requestedPins 
                    ? 'border-red-500/50 focus:ring-red-500/20' 
                    : 'border-gray-700/50 focus:border-orange-500/50 focus:ring-orange-500/20'
                }`}
              />
              {errors.requestedPins && (
                <p className="text-red-400 text-xs mt-1">{errors.requestedPins}</p>
              )}
              <p className="text-gray-400 text-xs mt-1">Request between 1-1000 PINs</p>
            </div>

            {/* Reason Input */}
            <div>
              <label className="block text-gray-300 text-sm font-medium mb-2">
                Purpose/Reason <span className="text-gray-500">(Optional)</span>
              </label>
              <textarea
                value={formData.reason}
                onChange={(e) => setFormData({...formData, reason: e.target.value})}
                placeholder="Explain why you need additional PINs (optional but encouraged)"
                rows={3}
                maxLength={500}
                disabled={submitting || hasPending}
                className={`w-full px-4 py-3 bg-gray-800/50 border rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 resize-none transition-colors ${
                  errors.reason 
                    ? 'border-red-500/50 focus:ring-red-500/20' 
                    : 'border-gray-700/50 focus:border-orange-500/50 focus:ring-orange-500/20'
                }`}
              />
              {errors.reason && (
                <p className="text-red-400 text-xs mt-1">{errors.reason}</p>
              )}
              <p className="text-gray-400 text-xs mt-1">
                {formData.reason.length}/500 characters
              </p>
            </div>

            {/* Info Box */}
            <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4">
              <div className="flex items-start space-x-3">
                <Shield className="w-5 h-5 text-blue-400 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-blue-300 text-sm font-medium">PIN Request Process</p>
                  <p className="text-gray-300 text-sm mt-1">
                    Your request will be sent to the admin for review. Once approved, 
                    the requested PINs will be automatically allocated to your account 
                    and you'll receive a notification.
                  </p>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex justify-end space-x-3 pt-2">
              <UnifiedButton
                type="button"
                variant="secondary"
                onClick={handleClose}
                disabled={submitting}
              >
                Cancel
              </UnifiedButton>
              <UnifiedButton
                type="submit"
                disabled={!formData.requestedPins || submitting || hasPending}
                className="flex items-center space-x-2 bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {submitting ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-2 border-white/30 border-t-white"></div>
                    <span>Submitting...</span>
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4" />
                    <span>Submit Request</span>
                  </>
                )}
              </UnifiedButton>
            </div>
          </form>
        </div>
      </UnifiedCard>
    </div>
  );
};

export default PinRequestModal;
