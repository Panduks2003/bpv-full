/**
 * Security Utility Module
 * Provides input validation and sanitization to prevent SQL injection
 * and other security vulnerabilities
 */

// SQL Injection patterns to detect and block
const SQL_INJECTION_PATTERNS = [
  /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE|UNION|DECLARE)\b)/gi,
  /(--|\#|\/\*|\*\/)/g,
  /('|('')|;|\\x|\\u|\\%)/g,
  /(\bOR\b|\bAND\b)\s*\d+\s*=\s*\d+/gi,
  /(\bOR\b|\bAND\b)\s*['"]?\d+['"]?\s*=\s*['"]?\d+['"]?/gi
];

// XSS patterns to detect
const XSS_PATTERNS = [
  /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
  /javascript:/gi,
  /on\w+\s*=/gi,
  /<iframe/gi
];

/**
 * Sanitize string input to prevent SQL injection
 * @param {string} input - The input string to sanitize
 * @returns {string} - Sanitized string
 */
export const sanitizeInput = (input) => {
  if (typeof input !== 'string') return input;
  
  // Remove dangerous characters
  let sanitized = input
    .replace(/[<>]/g, '') // Remove HTML tags
    .trim();
  
  return sanitized;
};

/**
 * Validate input for SQL injection attempts
 * @param {string} input - The input to validate
 * @returns {object} - {isValid: boolean, message: string}
 */
export const validateSQLInjection = (input) => {
  if (!input || typeof input !== 'string') {
    return { isValid: true, message: '' };
  }
  
  // Check for SQL injection patterns
  for (const pattern of SQL_INJECTION_PATTERNS) {
    if (pattern.test(input)) {
      return {
        isValid: false,
        message: 'Invalid input detected. Please remove special characters and SQL keywords.'
      };
    }
  }
  
  return { isValid: true, message: '' };
};

/**
 * Validate input for XSS attempts
 * @param {string} input - The input to validate
 * @returns {object} - {isValid: boolean, message: string}
 */
export const validateXSS = (input) => {
  if (!input || typeof input !== 'string') {
    return { isValid: true, message: '' };
  }
  
  // Check for XSS patterns
  for (const pattern of XSS_PATTERNS) {
    if (pattern.test(input)) {
      return {
        isValid: false,
        message: 'Invalid input detected. Please remove script tags and event handlers.'
      };
    }
  }
  
  return { isValid: true, message: '' };
};

/**
 * Comprehensive input validation
 * @param {string} input - The input to validate
 * @returns {object} - {isValid: boolean, message: string, sanitized: string}
 */
export const validateInput = (input) => {
  // SQL injection check
  const sqlCheck = validateSQLInjection(input);
  if (!sqlCheck.isValid) {
    return { ...sqlCheck, sanitized: '' };
  }
  
  // XSS check
  const xssCheck = validateXSS(input);
  if (!xssCheck.isValid) {
    return { ...xssCheck, sanitized: '' };
  }
  
  // Sanitize if valid
  const sanitized = sanitizeInput(input);
  
  return { isValid: true, message: '', sanitized };
};

/**
 * Validate email format
 * @param {string} email - Email to validate
 * @returns {object} - {isValid: boolean, message: string}
 */
export const validateEmail = (email) => {
  if (!email || typeof email !== 'string') {
    return { isValid: false, message: 'Email is required' };
  }
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  
  if (!emailRegex.test(email)) {
    return { isValid: false, message: 'Invalid email format' };
  }
  
  // Additional security check
  const securityCheck = validateInput(email);
  if (!securityCheck.isValid) {
    return securityCheck;
  }
  
  return { isValid: true, message: '' };
};

/**
 * Validate phone number
 * @param {string} phone - Phone number to validate
 * @returns {object} - {isValid: boolean, message: string}
 */
export const validatePhone = (phone) => {
  if (!phone || typeof phone !== 'string') {
    return { isValid: false, message: 'Phone number is required' };
  }
  
  // Allow digits, spaces, hyphens, parentheses, and + sign
  const phoneRegex = /^[\d\s\-\(\)\+]+$/;
  
  if (!phoneRegex.test(phone)) {
    return { isValid: false, message: 'Invalid phone number format' };
  }
  
  // Remove formatting and check length
  const digitsOnly = phone.replace(/[\s\-\(\)\+]/g, '');
  if (digitsOnly.length < 10 || digitsOnly.length > 15) {
    return { isValid: false, message: 'Phone number must be 10-15 digits' };
  }
  
  return { isValid: true, message: '' };
};

/**
 * Validate number input
 * @param {string|number} value - Value to validate
 * @param {object} options - {min, max, required}
 * @returns {object} - {isValid: boolean, message: string}
 */
export const validateNumber = (value, options = {}) => {
  const { min, max, required = true } = options;
  
  if (!value && value !== 0) {
    if (required) {
      return { isValid: false, message: 'This field is required' };
    }
    return { isValid: true, message: '' };
  }
  
  const num = Number(value);
  
  if (isNaN(num)) {
    return { isValid: false, message: 'Must be a valid number' };
  }
  
  if (min !== undefined && num < min) {
    return { isValid: false, message: `Must be at least ${min}` };
  }
  
  if (max !== undefined && num > max) {
    return { isValid: false, message: `Must be at most ${max}` };
  }
  
  return { isValid: true, message: '' };
};

/**
 * Validate form data
 * @param {object} formData - Form data to validate
 * @param {object} rules - Validation rules
 * @returns {object} - {isValid: boolean, errors: object}
 */
export const validateForm = (formData, rules) => {
  const errors = {};
  let isValid = true;
  
  for (const [field, value] of Object.entries(formData)) {
    const rule = rules[field];
    if (!rule) continue;
    
    // Required check
    if (rule.required && (!value || value.toString().trim() === '')) {
      errors[field] = `${field} is required`;
      isValid = false;
      continue;
    }
    
    // Skip validation if not required and empty
    if (!rule.required && (!value || value.toString().trim() === '')) {
      continue;
    }
    
    // Type-specific validation
    if (rule.type === 'email') {
      const emailCheck = validateEmail(value);
      if (!emailCheck.isValid) {
        errors[field] = emailCheck.message;
        isValid = false;
      }
    } else if (rule.type === 'phone') {
      const phoneCheck = validatePhone(value);
      if (!phoneCheck.isValid) {
        errors[field] = phoneCheck.message;
        isValid = false;
      }
    } else if (rule.type === 'number') {
      const numberCheck = validateNumber(value, rule);
      if (!numberCheck.isValid) {
        errors[field] = numberCheck.message;
        isValid = false;
      }
    } else {
      // General input validation
      const inputCheck = validateInput(value);
      if (!inputCheck.isValid) {
        errors[field] = inputCheck.message;
        isValid = false;
      }
    }
    
    // Custom validation
    if (rule.validate && typeof rule.validate === 'function') {
      const customCheck = rule.validate(value);
      if (!customCheck.isValid) {
        errors[field] = customCheck.message;
        isValid = false;
      }
    }
  }
  
  return { isValid, errors };
};

/**
 * Create a secure form handler
 * @param {function} onSubmit - Submit handler
 * @param {object} validationRules - Validation rules
 * @returns {function} - Secure submit handler
 */
export const createSecureFormHandler = (onSubmit, validationRules) => {
  return async (formData) => {
    // Validate form data
    const validation = validateForm(formData, validationRules);
    
    if (!validation.isValid) {
      throw new Error(Object.values(validation.errors)[0] || 'Invalid form data');
    }
    
    // Sanitize all string values
    const sanitizedData = {};
    for (const [key, value] of Object.entries(formData)) {
      if (typeof value === 'string') {
        sanitizedData[key] = sanitizeInput(value);
      } else {
        sanitizedData[key] = value;
      }
    }
    
    // Call original submit handler with sanitized data
    return await onSubmit(sanitizedData);
  };
};

export default {
  sanitizeInput,
  validateSQLInjection,
  validateXSS,
  validateInput,
  validateEmail,
  validatePhone,
  validateNumber,
  validateForm,
  createSecureFormHandler
};

