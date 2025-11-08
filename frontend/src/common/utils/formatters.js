/**
 * Utility functions for formatting data display
 */

/**
 * Format currency values with Indian Rupee symbol
 * @param {number} amount - The amount to format
 * @param {boolean} compact - Whether to use compact notation (K, L, Cr)
 * @returns {string} Formatted currency string
 */
export const formatCurrency = (amount, compact = false) => {
  if (amount === 0) return '₹0';
  if (!amount) return '₹0';
  
  if (compact && amount >= 1000) {
    if (amount >= 10000000) { // 1 Crore
      return `₹${(amount / 10000000).toFixed(1)}Cr`;
    } else if (amount >= 100000) { // 1 Lakh
      return `₹${(amount / 100000).toFixed(1)}L`;
    } else if (amount >= 1000) { // 1 Thousand
      return `₹${(amount / 1000).toFixed(1)}K`;
    }
  }
  
  return `₹${amount.toLocaleString('en-IN')}`;
};

/**
 * Format percentage values
 * @param {number} value - The percentage value
 * @param {number} decimals - Number of decimal places
 * @returns {string} Formatted percentage string
 */
export const formatPercentage = (value, decimals = 1) => {
  if (!value && value !== 0) return '0%';
  const sign = value >= 0 ? '+' : '';
  return `${sign}${value.toFixed(decimals)}%`;
};

/**
 * Format large numbers with compact notation
 * @param {number} num - The number to format
 * @returns {string} Formatted number string
 */
export const formatCompactNumber = (num) => {
  if (!num && num !== 0) return '0';
  
  if (num >= 10000000) { // 1 Crore
    return `${(num / 10000000).toFixed(1)}Cr`;
  } else if (num >= 100000) { // 1 Lakh
    return `${(num / 100000).toFixed(1)}L`;
  } else if (num >= 1000) { // 1 Thousand
    return `${(num / 1000).toFixed(1)}K`;
  }
  
  return num.toLocaleString('en-IN');
};

/**
 * Format date for display
 * @param {Date|string} date - The date to format
 * @param {boolean} includeTime - Whether to include time
 * @returns {string} Formatted date string
 */
export const formatDate = (date, includeTime = false) => {
  if (!date) return 'N/A';
  
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  
  if (includeTime) {
    return dateObj.toLocaleString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }
  
  return dateObj.toLocaleDateString('en-IN', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
};

/**
 * Format time duration in human readable format
 * @param {number} seconds - Duration in seconds
 * @returns {string} Formatted duration string
 */
export const formatDuration = (seconds) => {
  if (!seconds) return '0s';
  
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;
  
  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  } else if (minutes > 0) {
    return `${minutes}m ${secs}s`;
  } else {
    return `${secs}s`;
  }
};

/**
 * Get status color class based on status value
 * @param {string} status - The status value
 * @returns {string} CSS color class
 */
export const getStatusColor = (status) => {
  const statusColors = {
    active: 'text-green-400 bg-green-500/20',
    inactive: 'text-gray-400 bg-gray-500/20',
    pending: 'text-yellow-400 bg-yellow-500/20',
    approved: 'text-green-400 bg-green-500/20',
    rejected: 'text-red-400 bg-red-500/20',
    completed: 'text-blue-400 bg-blue-500/20',
    cancelled: 'text-red-400 bg-red-500/20',
    processing: 'text-orange-400 bg-orange-500/20'
  };
  
  return statusColors[status?.toLowerCase()] || 'text-gray-400 bg-gray-500/20';
};

export default {
  formatCurrency,
  formatPercentage,
  formatCompactNumber,
  formatDate,
  formatDuration,
  getStatusColor
};
