import React, { useState, useEffect, useCallback, memo } from 'react';
import { X, Loader, AlertCircle, CheckCircle, Eye, EyeOff } from 'lucide-react';
import { UnifiedButton } from './SharedTheme';
import { supabase } from "../services/supabaseClient"

// Memoized form field component
const FormField = memo(({ 
  label, 
  type = 'text', 
  value, 
  onChange, 
  error, 
  placeholder, 
  disabled = false,
  required = false,
  options = null,
  validationStatus = null
}) => {
  const fieldId = `field-${label.toLowerCase().replace(/\s+/g, '-')}`;
  const [showPassword, setShowPassword] = useState(false);
  
  // Determine the actual input type
  const inputType = type === 'password' ? (showPassword ? 'text' : 'password') : type;
  
  return (
    <div className="space-y-1">
      <label htmlFor={fieldId} className="block text-sm font-medium text-gray-300">
        {label} {required && <span className="text-red-400">*</span>}
      </label>
      
      {type === 'select' ? (
        <select
          id={fieldId}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          disabled={disabled}
          className={`w-full px-3 py-2 bg-gray-700 border rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500 transition-colors ${
            error ? 'border-red-500' : validationStatus === 'valid' ? 'border-green-500' : 'border-gray-600'
          } ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}
        >
          <option value="">{placeholder || `Select ${label}`}</option>
          {options?.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      ) : type === 'textarea' ? (
        <textarea
          id={fieldId}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          disabled={disabled}
          rows={3}
          className={`w-full px-3 py-2 bg-gray-700 border rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500 transition-colors resize-none ${
            error ? 'border-red-500' : validationStatus === 'valid' ? 'border-green-500' : 'border-gray-600'
          } ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}
        />
      ) : (
        <div className="relative">
          <input
            id={fieldId}
            type={inputType}
            value={value}
            onChange={(e) => onChange(e.target.value)}
            placeholder={placeholder}
            disabled={disabled}
            className={`w-full px-3 py-2 bg-gray-700 border rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500 transition-colors ${
              error ? 'border-red-500' : validationStatus === 'valid' ? 'border-green-500' : 'border-gray-600'
            } ${disabled ? 'opacity-50 cursor-not-allowed' : ''} ${(validationStatus || type === 'password') ? 'pr-10' : ''}`}
          />
          
          {/* Password visibility toggle */}
          {type === 'password' && (
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-300 focus:outline-none"
              tabIndex={-1}
            >
              {showPassword ? (
                <EyeOff className="w-4 h-4" />
              ) : (
                <Eye className="w-4 h-4" />
              )}
            </button>
          )}
          
          {/* Validation status icons (for non-password fields) */}
          {validationStatus && type !== 'password' && (
            <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
              {validationStatus === 'checking' && (
                <Loader className="w-4 h-4 text-orange-400 animate-spin" />
              )}
              {validationStatus === 'valid' && (
                <CheckCircle className="w-4 h-4 text-green-400" />
              )}
              {validationStatus === 'invalid' && (
                <AlertCircle className="w-4 h-4 text-red-400" />
              )}
            </div>
          )}
        </div>
      )}
      
      {error && (
        <p className="text-red-400 text-sm flex items-center space-x-1">
          <AlertCircle className="w-3 h-3" />
          <span>{error}</span>
        </p>
      )}
    </div>
  );
});

const UnifiedCustomerForm = memo(({ 
  isOpen, 
  onClose, 
  onSubmit, 
  promoters = [], 
  isEditing = false, 
  initialData = null,
  currentUserRole = 'admin'
}) => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    mobile: '',
    state: '',
    city: '',
    pincode: '',
    address: '',
    cardNo: '', // Customer ID (Card No)
    password: 'password123', // Auto-assigned default password
    parentPromoter: '',
    savingPlan: '₹1000 per month for 20 months' // Fixed saving plan
  });

  const [formErrors, setFormErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [cardNoValidation, setCardNoValidation] = useState(null);

  // Initialize form data when editing
  useEffect(() => {
    if (isEditing && initialData) {
      setFormData({
        name: initialData.name || '',
        email: initialData.email || '',
        mobile: initialData.phone || initialData.mobile || '',
        state: initialData.state || '',
        city: initialData.city || '',
        pincode: initialData.pincode || '',
        address: initialData.address || '',
        cardNo: initialData.customer_id || initialData.cardNo || '',
        password: 'password123', // Auto-assigned default password for editing
        parentPromoter: initialData.promoter_id || initialData.parentPromoter || '',
        savingPlan: '₹1000 per month for 20 months' // Fixed saving plan
      });
    } else if (!isEditing) {
      // Reset form for new customer, but preserve parentPromoter from initialData
      setFormData({
        name: '',
        email: '',
        mobile: '',
        state: '',
        city: '',
        pincode: '',
        address: '',
        cardNo: '',
        password: 'password123', // Auto-assigned default password
        parentPromoter: initialData?.parentPromoter || '',
        savingPlan: '₹1000 per month for 20 months' // Fixed saving plan
      });
    }
  }, [isEditing, initialData, isOpen]);

  // Debounced Card No uniqueness check
  const checkCardNoUniqueness = useCallback(
    debounce(async (cardNo) => {
      // Clear validation if empty or too short
      if (!cardNo || cardNo.length < 3) {
        setCardNoValidation(null);
        return;
      }

      // Validate format first
      const cleanCardNo = cardNo.trim().toUpperCase();
      if (!/^[A-Z0-9]+$/.test(cleanCardNo)) {
        setCardNoValidation('invalid');
        return;
      }

      setCardNoValidation('checking');
      
      try {
        const { data, error } = await supabase
          .from('profiles')
          .select('id, customer_id')
          .eq('customer_id', cleanCardNo)
          .eq('role', 'customer');

        if (error) {
          console.error('Error checking Card No uniqueness:', error);
          setCardNoValidation('invalid');
          return;
        }

        // If editing, exclude current customer from uniqueness check
        const existingCustomer = data?.find(customer => 
          isEditing ? customer.id !== initialData?.id : true
        );

        setCardNoValidation(existingCustomer ? 'invalid' : 'valid');
      } catch (error) {
        console.error('Card No validation error:', error);
        setCardNoValidation('invalid');
      }
    }, 300), // Reduced debounce time for faster feedback
    [isEditing, initialData?.id]
  );

  // Handle Card No change with validation
  const handleCardNoChange = useCallback((value) => {
    // Convert to uppercase and remove invalid characters in real-time
    const cleanValue = value.toUpperCase().replace(/[^A-Z0-9]/g, '');
    
    setFormData(prev => ({ ...prev, cardNo: cleanValue }));
    
    // Clear previous error
    if (formErrors.cardNo) {
      setFormErrors(prev => ({ ...prev, cardNo: null }));
    }
    
    // Trigger uniqueness check
    checkCardNoUniqueness(cleanValue);
  }, [checkCardNoUniqueness, formErrors.cardNo]);


  // Form field update handler
  const updateField = useCallback((field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    
    // Clear field error when user starts typing
    if (formErrors[field]) {
      setFormErrors(prev => ({ ...prev, [field]: null }));
    }
  }, [formErrors]);

  // Enhanced form validation with security hardening
  const validateForm = useCallback(() => {
    const errors = {};

    // Required field validation with enhanced security checks
    if (!formData.name || !formData.name.trim()) {
      errors.name = 'Name is required';
    } else if (formData.name.trim().length < 2) {
      errors.name = 'Name must be at least 2 characters';
    } else if (formData.name.trim().length > 100) {
      errors.name = 'Name must be less than 100 characters';
    } else if (!/^[a-zA-Z\s.'-]+$/.test(formData.name.trim())) {
      errors.name = 'Name can only contain letters, spaces, dots, hyphens and apostrophes';
    }
    
    // Enhanced email validation (optional but strict when provided)
    if (formData.email && formData.email.trim()) {
      const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
      if (!emailRegex.test(formData.email.trim())) {
        errors.email = 'Invalid email format';
      } else if (formData.email.trim().length > 255) {
        errors.email = 'Email must be less than 255 characters';
      }
    }
    
    // Enhanced mobile validation
    if (!formData.mobile || !formData.mobile.trim()) {
      errors.mobile = 'Mobile number is required';
    } else if (!/^[6-9]\d{9}$/.test(formData.mobile.trim())) {
      errors.mobile = 'Invalid mobile number (10 digits, starting with 6-9)';
    }
    
    // Enhanced state validation
    if (!formData.state || !formData.state.trim()) {
      errors.state = 'State is required';
    } else if (formData.state.trim().length > 100) {
      errors.state = 'State name is too long';
    }
    
    // Enhanced city validation
    if (!formData.city || !formData.city.trim()) {
      errors.city = 'City is required';
    } else if (formData.city.trim().length > 100) {
      errors.city = 'City name is too long';
    } else if (!/^[a-zA-Z\s.'-]+$/.test(formData.city.trim())) {
      errors.city = 'City name contains invalid characters';
    }
    
    // Enhanced pincode validation
    if (!formData.pincode || !formData.pincode.trim()) {
      errors.pincode = 'Pincode is required';
    } else if (!/^\d{6}$/.test(formData.pincode.trim())) {
      errors.pincode = 'Invalid pincode (exactly 6 digits required)';
    }
    
    // Enhanced address validation
    if (!formData.address || !formData.address.trim()) {
      errors.address = 'Address is required';
    } else if (formData.address.trim().length < 10) {
      errors.address = 'Address must be at least 10 characters';
    } else if (formData.address.trim().length > 500) {
      errors.address = 'Address must be less than 500 characters';
    }
    
    // Enhanced customer ID validation
    if (!formData.cardNo || !formData.cardNo.trim()) {
      errors.cardNo = 'Card No is required';
    } else {
      const cardNo = formData.cardNo.trim().toUpperCase();
      
      // Length validation
      if (cardNo.length < 3) {
        errors.cardNo = 'Card No must be at least 3 characters';
      } else if (cardNo.length > 20) {
        errors.cardNo = 'Card No must be maximum 20 characters';
      }
      // Format validation - only letters and numbers
      else if (!/^[A-Z0-9]+$/.test(cardNo)) {
        errors.cardNo = 'Card No can only contain letters and numbers (no spaces or special characters)';
      }
      // Uniqueness validation
      else if (cardNoValidation === 'invalid') {
        errors.cardNo = 'This Card No is already taken. Please choose a different one.';
      } else if (cardNoValidation === 'checking') {
        errors.cardNo = 'Checking if Card No is available...';
      }
    }
    
    // Enhanced password validation (only for new customers)
    if (!isEditing) {
      if (!formData.password || !formData.password.trim()) {
        errors.password = 'Password is required';
      } else if (formData.password.length < 6) {
        errors.password = 'Password must be at least 6 characters';
      } else if (formData.password.length > 128) {
        errors.password = 'Password must be less than 128 characters';
      } else if (!/(?=.*[a-zA-Z])/.test(formData.password)) {
        errors.password = 'Password must contain at least one letter';
      }
    }
    
    // Parent promoter validation
    if (!formData.parentPromoter) {
      errors.parentPromoter = 'Parent Promoter is required';
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  }, [formData, cardNoValidation, isEditing]);

  // Handle form submission with data sanitization
  const handleSubmit = useCallback(async (e) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    if (cardNoValidation !== 'valid' && !isEditing) return;

    setSubmitting(true);
    
    try {
      // Sanitize and prepare form data
      const sanitizedFormData = {
        name: formData.name?.trim() || '',
        email: formData.email?.trim() || '',
        mobile: formData.mobile?.trim() || '',
        state: formData.state?.trim() || '',
        city: formData.city?.trim() || '',
        pincode: formData.pincode?.trim() || '',
        address: formData.address?.trim() || '',
        cardNo: formData.cardNo?.trim().toUpperCase() || '',
        password: formData.password || '', // Don't trim passwords as spaces might be intentional
        parentPromoter: formData.parentPromoter || '',
        savingPlan: formData.savingPlan || '₹1000 per month for 20 months'
      };

      // Additional client-side validation before submission
      if (sanitizedFormData.name.length < 2 || sanitizedFormData.name.length > 100) {
        throw new Error('Invalid name length');
      }
      
      if (!/^[6-9]\d{9}$/.test(sanitizedFormData.mobile)) {
        throw new Error('Invalid mobile number format');
      }
      
      if (!/^[A-Z0-9]{3,20}$/.test(sanitizedFormData.cardNo)) {
        throw new Error('Invalid customer ID format');
      }
      
      if (!/^\d{6}$/.test(sanitizedFormData.pincode)) {
        throw new Error('Invalid pincode format');
      }

      await onSubmit(sanitizedFormData);
      
      // Reset form after successful submission
      if (!isEditing) {
        setFormData({
          name: '',
          email: '',
          mobile: '',
          state: '',
          city: '',
          pincode: '',
          address: '',
          cardNo: '',
          password: 'password123', // Auto-assigned default password
          parentPromoter: '',
          savingPlan: '₹1000 per month for 20 months'
        });
        setCardNoValidation(null);
      }
      
      setFormErrors({});
    } catch (error) {
      console.error('Form submission error:', error);
      // Set form error to display to user
      setFormErrors(prev => ({
        ...prev,
        submit: error.message || 'Failed to submit form. Please check your input and try again.'
      }));
    } finally {
      setSubmitting(false);
    }
  }, [formData, validateForm, cardNoValidation, isEditing, onSubmit]);

  // Prepare promoter options
  const promoterOptions = promoters.map(promoter => {
    const isAdmin = promoter.isAdmin || promoter.role === 'admin';
    const promoterId = promoter.id || promoter._id;
    const promoterName = promoter.name || 'Unknown';
    
    return {
      value: promoterId,
      label: isAdmin 
        ? `👑 ${promoterName} (Admin)`
        : `${promoter.promoter_id || 'ID-' + promoterId.slice(-6)} - ${promoterName}`
    };
  });

  // Debug logging removed to prevent console spam

  // Auto-select first promoter if none selected and only one option available
  React.useEffect(() => {
    if (!formData.parentPromoter && promoterOptions.length === 1) {
      updateField('parentPromoter', promoterOptions[0].value);
    }
  }, [promoterOptions, formData.parentPromoter]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div className="bg-gray-800 rounded-lg w-full max-w-2xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-700">
          <h3 className="text-xl font-semibold text-white">
            {isEditing ? 'Edit Customer' : 'Create New Customer'}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-white transition-colors"
            disabled={submitting}
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto max-h-[calc(90vh-120px)]">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Name */}
            <FormField
              label="Name"
              value={formData.name}
              onChange={(value) => updateField('name', value)}
              error={formErrors.name}
              placeholder="Enter full name"
              required
            />

            {/* Email (Optional) */}
            <FormField
              label="Email (Optional)"
              type="email"
              value={formData.email}
              onChange={(value) => updateField('email', value)}
              error={formErrors.email}
              placeholder="Enter email address (for information only)"
              disabled={isEditing}
            />

            {/* Mobile */}
            <FormField
              label="Mobile"
              type="tel"
              value={formData.mobile}
              onChange={(value) => updateField('mobile', value)}
              error={formErrors.mobile}
              placeholder="Enter 10-digit mobile number"
              required
            />

            {/* Card No (Customer ID) */}
            <FormField
              label="Card No"
              value={formData.cardNo}
              onChange={handleCardNoChange}
              error={formErrors.cardNo}
              placeholder="Enter Card No"
              validationStatus={cardNoValidation}
              disabled={isEditing}
              required
            />

            {/* State */}
            <FormField
              label="State"
              type="select"
              value={formData.state}
              onChange={(value) => updateField('state', value)}
              error={formErrors.state}
              placeholder="Select state"
              options={[
                { value: 'Andhra Pradesh', label: 'Andhra Pradesh' },
                { value: 'Arunachal Pradesh', label: 'Arunachal Pradesh' },
                { value: 'Assam', label: 'Assam' },
                { value: 'Bihar', label: 'Bihar' },
                { value: 'Chhattisgarh', label: 'Chhattisgarh' },
                { value: 'Goa', label: 'Goa' },
                { value: 'Gujarat', label: 'Gujarat' },
                { value: 'Haryana', label: 'Haryana' },
                { value: 'Himachal Pradesh', label: 'Himachal Pradesh' },
                { value: 'Jharkhand', label: 'Jharkhand' },
                { value: 'Karnataka', label: 'Karnataka' },
                { value: 'Kerala', label: 'Kerala' },
                { value: 'Madhya Pradesh', label: 'Madhya Pradesh' },
                { value: 'Maharashtra', label: 'Maharashtra' },
                { value: 'Manipur', label: 'Manipur' },
                { value: 'Meghalaya', label: 'Meghalaya' },
                { value: 'Mizoram', label: 'Mizoram' },
                { value: 'Nagaland', label: 'Nagaland' },
                { value: 'Odisha', label: 'Odisha' },
                { value: 'Punjab', label: 'Punjab' },
                { value: 'Rajasthan', label: 'Rajasthan' },
                { value: 'Sikkim', label: 'Sikkim' },
                { value: 'Tamil Nadu', label: 'Tamil Nadu' },
                { value: 'Telangana', label: 'Telangana' },
                { value: 'Tripura', label: 'Tripura' },
                { value: 'Uttar Pradesh', label: 'Uttar Pradesh' },
                { value: 'Uttarakhand', label: 'Uttarakhand' },
                { value: 'West Bengal', label: 'West Bengal' },
                { value: 'Delhi', label: 'Delhi' },
                { value: 'Jammu and Kashmir', label: 'Jammu and Kashmir' },
                { value: 'Ladakh', label: 'Ladakh' }
              ]}
              required
            />

            {/* City */}
            <FormField
              label="City"
              value={formData.city}
              onChange={(value) => updateField('city', value)}
              error={formErrors.city}
              placeholder="Enter city"
              required
            />

            {/* Pincode */}
            <FormField
              label="Pincode"
              value={formData.pincode}
              onChange={(value) => updateField('pincode', value)}
              error={formErrors.pincode}
              placeholder="Enter 6-digit pincode"
              required
            />

            {/* Parent Promoter */}
            <FormField
              label="Parent Promoter"
              type="select"
              value={formData.parentPromoter}
              onChange={(value) => updateField('parentPromoter', value)}
              error={formErrors.parentPromoter}
              options={promoterOptions}
              placeholder={promoterOptions.length === 1 ? "Auto-selected (you are the parent)" : "Select parent promoter"}
              disabled={promoterOptions.length === 1 || isEditing} // Disable if only one option OR when editing
              required
            />

            {/* Saving Plan (Fixed) */}
            <FormField
              label="Saving Plan"
              type="select"
              value={formData.savingPlan}
              onChange={() => {}} // Read-only
              options={[{ value: '₹1000 per month for 20 months', label: '₹1000 per month for 20 months' }]}
              disabled={true}
              required
            />
          </div>

          {/* Address */}
          <FormField
            label="Address"
            type="textarea"
            value={formData.address}
            onChange={(value) => updateField('address', value)}
            error={formErrors.address}
            placeholder="Enter complete address"
            required
          />

          {/* Password is automatically set to 'password123' - no UI field needed */}

          {/* Form Actions */}
          <div className="flex justify-end space-x-3 pt-6 border-t border-gray-700">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
              disabled={submitting}
            >
              Cancel
            </button>
            <UnifiedButton
              type="submit"
              disabled={submitting || (cardNoValidation === 'checking') || (!isEditing && cardNoValidation !== 'valid')}
              className="flex items-center space-x-2"
            >
              {submitting ? (
                <>
                  <Loader className="w-4 h-4 animate-spin" />
                  <span>{isEditing ? 'Updating...' : 'Creating...'}</span>
                </>
              ) : (
                <span>{isEditing ? 'Update Customer' : 'Create Customer'}</span>
              )}
            </UnifiedButton>
          </div>
        </form>
      </div>
    </div>
  );
});

// Debounce utility function
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

export default UnifiedCustomerForm;
