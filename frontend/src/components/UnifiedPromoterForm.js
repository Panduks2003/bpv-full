import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { supabase } from '../common/services/supabaseClient';
import { Loader, Eye, EyeOff, CheckCircle, AlertCircle, Info, X } from 'lucide-react';

/**
 * UnifiedPromoterForm - A comprehensive, uniform promoter creation form
 * 
 * Features:
 * - Auto-generated BPVP IDs (BPVP01, BPVP02, etc.)
 * - Optional email support with shared email capability
 * - Hierarchical parent promoter selection
 * - Real-time validation and error handling
 * - Clean, consistent UI following brand guidelines
 * - Role/Level selection with default 'Affiliate'
 * - Status toggle (Active/Inactive)
 * - Comprehensive form validation
 */

const UnifiedPromoterForm = React.memo(({ 
  onSubmit, 
  onCancel, 
  loading = false,
  editingPromoter = null,
  availableParents = [],
  adminUsers = []
}) => {
  // Form state
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    hasEmail: false, // Email is now optional (metadata only)
    password: 'password123', // Auto-assigned default password
    confirmPassword: 'password123', // Auto-assigned default password
    phone: '',
    address: '',
    parentPromoter: ''
  });

  // Validation and UI state
  const [formErrors, setFormErrors] = useState({});
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // Role and status are now handled automatically by backend

  // Populate form with editing promoter data
  useEffect(() => {
    if (editingPromoter) {
      const promoterEmail = editingPromoter.email || '';
      // Check if email is a real email (not a placeholder like noemail+uuid@brightplanetventures.local)
      const hasRealEmail = promoterEmail && 
        !promoterEmail.includes('noemail+') && 
        !promoterEmail.includes('@brightplanetventures.local');
      
      setFormData({
        name: editingPromoter.name || '',
        email: hasRealEmail ? promoterEmail : '',
        hasEmail: hasRealEmail,
        password: 'password123', // Keep default password for editing
        confirmPassword: 'password123', // Keep default password for editing
        phone: editingPromoter.phone || '',
        address: editingPromoter.address || '',
        parentPromoter: editingPromoter.parent_promoter_id || ''
      });
    }
  }, [editingPromoter]);

  // Combine and format parent promoter options
  const parentPromoterOptions = useMemo(() => {
    const adminOptions = (adminUsers || []).map(admin => ({
      id: admin.id,
      label: `👑 ${admin.name} (Admin)`,
      type: 'admin'
    }));

    const promoterOptions = (availableParents || []).map(promoter => ({
      id: promoter.id || promoter._id,
      label: promoter.isCurrentUser 
        ? `${promoter.promoter_id || 'CURRENT'} - ${promoter.name} (You)`
        : `${promoter.promoter_id || 'N/A'} - ${promoter.name || 'Unknown'}`,
      type: 'promoter'
    }));

    // Admin users first, then promoters
    return [...adminOptions, ...promoterOptions];
  }, [adminUsers, availableParents]);

  // Real-time form validation
  const validateField = useCallback((fieldName, value) => {
    const errors = {};

    switch (fieldName) {
      case 'name':
        if (!value || !value.trim()) {
          errors.name = 'Name is required';
        } else if (!/^[a-zA-Z\s]+$/.test(value.trim())) {
          errors.name = 'Name must contain only letters and spaces';
        } else if (value.trim().length < 2) {
          errors.name = 'Name must be at least 2 characters';
        }
        break;

      case 'email':
        if (formData.hasEmail) {
          if (!value || !value.trim()) {
            errors.email = 'Email address is required';
          } else {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(value.trim())) {
              errors.email = 'Please enter a valid email address';
            }
          }
        }
        break;

      case 'password':
        if (!editingPromoter) { // Only validate password for new promoters
          if (!value) {
            errors.password = 'Password is required';
          } else if (value.length < 8) {
            errors.password = 'Password must be at least 8 characters';
          } else if (!/(?=.*[a-zA-Z])(?=.*\d)/.test(value)) {
            errors.password = 'Password must contain both letters and numbers';
          }
        }
        break;

      case 'confirmPassword':
        if (!editingPromoter && value !== formData.password) {
          errors.confirmPassword = 'Passwords do not match';
        }
        break;

      case 'phone':
        if (!value) {
          errors.phone = 'Phone number is required';
        } else if (!/^[6-9]\d{9}$/.test(value)) {
          errors.phone = 'Enter a valid 10-digit Indian mobile number (starting with 6-9)';
        }
        break;

      case 'parentPromoter':
        if (!value && parentPromoterOptions.length > 1) {
          errors.parentPromoter = 'Parent promoter selection is required';
        }
        break;

      default:
        break;
    }

    return errors;
  }, [formData.hasEmail, formData.password, editingPromoter, parentPromoterOptions]);

  // Handle input changes with real-time validation
  const handleInputChange = useCallback((fieldName, value) => {
    setFormData(prev => ({ ...prev, [fieldName]: value }));
    
    // Real-time validation
    const fieldErrors = validateField(fieldName, value);
    setFormErrors(prev => ({ ...prev, ...fieldErrors }));
    
    // Clear error if field is now valid
    if (!fieldErrors[fieldName] && formErrors[fieldName]) {
      setFormErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[fieldName];
        return newErrors;
      });
    }
  }, [validateField, formErrors]);

  // Comprehensive form validation
  const validateForm = useCallback(() => {
    const errors = {};

    // Validate all fields
    Object.keys(formData).forEach(fieldName => {
      const fieldErrors = validateField(fieldName, formData[fieldName]);
      Object.assign(errors, fieldErrors);
    });

    // Additional validations - promoter ID, role, and status are handled by backend

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  }, [formData, validateField, editingPromoter]);

  // Auto-select parent promoter if there's only one option
  useEffect(() => {
    if (parentPromoterOptions.length === 1 && !formData.parentPromoter) {
      setFormData(prev => ({ 
        ...prev, 
        parentPromoter: parentPromoterOptions[0].id 
      }));
    }
  }, [parentPromoterOptions, formData.parentPromoter]);

  // Handle form submission
  const handleSubmit = useCallback(async (e) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    // Prepare submission data for new Promoter ID system
    const submissionData = {
      name: formData.name,
      email: formData.hasEmail && formData.email ? formData.email : null,
      password: formData.password,
      phone: formData.phone,
      address: formData.address || null,
      parentPromoter: formData.parentPromoter || null,
      // Note: Promoter ID will be auto-generated by the backend
      useNewSystem: true // Flag to indicate using new Promoter ID system
    };

    await onSubmit(submissionData);
  }, [formData, validateForm, onSubmit]);

  return (
    <div className="bg-gray-800 rounded-lg p-6 w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-gray-700 pb-4 mb-6">
        <div>
          <h3 className="text-xl font-semibold text-white">
            {editingPromoter ? 'Edit Promoter' : 'Create New Promoter'}
          </h3>
          {editingPromoter && (
            <p className="text-gray-400 text-sm mt-1">
              Update promoter information and hierarchy
            </p>
          )}
        </div>
        <button
          type="button"
          onClick={onCancel}
          className="text-gray-400 hover:text-white transition-colors"
          disabled={loading}
        >
          <X className="w-5 h-5" />
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Promoter ID will be auto-generated after creation - no field shown */}

        {/* Name */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Full Name
            <span className="text-orange-400 ml-1">*</span>
          </label>
          <input
            type="text"
            value={formData.name}
            onChange={(e) => handleInputChange('name', e.target.value)}
            className={`w-full px-4 py-3 bg-gray-700 border rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500 ${
              formErrors.name ? 'border-red-500' : 'border-gray-600'
            }`}
            placeholder="Enter full name (letters and spaces only)"
          />
          {formErrors.name && (
            <p className="text-red-400 text-sm mt-1">{formErrors.name}</p>
          )}
        </div>

        {/* Email Field - Now Optional */}
        <div className="mb-4">
          <div className="flex items-center mb-2">
            <input
              type="checkbox"
              id="hasEmail"
              checked={formData.hasEmail}
              onChange={(e) => {
                const hasEmail = e.target.checked;
                setFormData(prev => ({ 
                  ...prev, 
                  hasEmail,
                  email: hasEmail ? prev.email : ''
                }));
                if (!hasEmail) {
                  setFormErrors(prev => {
                    const newErrors = { ...prev };
                    delete newErrors.email;
                    return newErrors;
                  });
                }
              }}
              className="mr-2 h-4 w-4 text-orange-600 focus:ring-orange-500 border-gray-600 rounded bg-gray-700"
            />
            <label htmlFor="hasEmail" className="text-sm font-medium text-gray-300">
              Add Email Address
            </label>
          </div>
          
          {formData.hasEmail && (
            <>
              <input
                type="email"
                value={formData.email}
                onChange={(e) => handleInputChange('email', e.target.value)}
                className={`w-full px-4 py-3 bg-gray-700 border rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500 ${
                  formErrors.email ? 'border-red-500' : 'border-gray-600'
                }`}
                placeholder="Enter email address (can be shared with others)"
              />
              {formErrors.email && (
                <p className="text-red-400 text-sm mt-1">{formErrors.email}</p>
              )}
            </>
          )}
          
        </div>


        {/* Phone */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Phone Number
            <span className="text-orange-400 ml-1">*</span>
          </label>
          <input
            type="tel"
            value={formData.phone}
            onChange={(e) => handleInputChange('phone', e.target.value.replace(/\D/g, '').slice(0, 10))}
            className={`w-full px-4 py-3 bg-gray-700 border rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500 ${
              formErrors.phone ? 'border-red-500' : 'border-gray-600'
            }`}
            placeholder="Enter 10-digit mobile number"
            maxLength={10}
          />
          {formErrors.phone && (
            <p className="text-red-400 text-sm mt-1">{formErrors.phone}</p>
          )}
        </div>

        {/* Address */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Address
            <span className="text-gray-500 text-xs ml-2">(Optional)</span>
          </label>
          <textarea
            value={formData.address}
            onChange={(e) => handleInputChange('address', e.target.value)}
            className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500"
            placeholder="Enter full postal address (optional)"
            rows={3}
          />
        </div>

        {/* Parent Promoter */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-2">
            Parent Promoter
            <span className="text-orange-400 ml-1">*</span>
          </label>
          <select
            value={formData.parentPromoter}
            onChange={(e) => handleInputChange('parentPromoter', e.target.value)}
            disabled={parentPromoterOptions.length === 1 || editingPromoter}
            className={`w-full px-4 py-3 bg-gray-700 border rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500 ${
              formErrors.parentPromoter ? 'border-red-500' : 'border-gray-600'
            } ${(parentPromoterOptions.length === 1 || editingPromoter) ? 'opacity-75 cursor-not-allowed' : ''}`}
          >
            {parentPromoterOptions.length === 0 && <option value="">Select parent promoter</option>}
            {parentPromoterOptions.map((option) => (
              <option key={option.id} value={option.id}>
                {option.label}
              </option>
            ))}
          </select>
          {parentPromoterOptions.length === 1 && !editingPromoter && (
            <p className="text-gray-400 text-xs mt-1">
              💡 Automatically set as your downline promoter
            </p>
          )}
          {formErrors.parentPromoter && (
            <p className="text-red-400 text-sm mt-1">{formErrors.parentPromoter}</p>
          )}
        </div>

        {/* Role and Status are automatically set by the backend */}

        {/* Form Actions */}
        <div className="flex justify-end space-x-4 pt-6 border-t border-gray-700">
          <button
            type="button"
            onClick={onCancel}
            className="px-6 py-3 text-gray-300 hover:text-white transition-colors"
            disabled={loading}
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={loading || Object.keys(formErrors).length > 0}
            className="px-6 py-3 bg-gradient-to-r from-orange-500 to-orange-600 text-white rounded-lg hover:from-orange-600 hover:to-orange-700 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
          >
            {loading ? (
              <>
                <Loader className="w-4 h-4 animate-spin" />
                <span>{editingPromoter ? 'Updating...' : 'Creating...'}</span>
              </>
            ) : (
              <>
                <CheckCircle className="w-4 h-4" />
                <span>{editingPromoter ? 'Update Promoter' : 'Create Promoter'}</span>
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
});

UnifiedPromoterForm.displayName = 'UnifiedPromoterForm';

export default UnifiedPromoterForm;
