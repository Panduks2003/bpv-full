import React, { useState, useRef, useEffect } from 'react';

// ===== ADVANCED UI COMPONENTS =====

// Button Component
export const Button = ({ 
  children, 
  variant = 'primary', 
  size = 'md', 
  disabled = false,
  className = '',
  ...props 
}) => {
  const baseClasses = 'inline-flex items-center justify-center font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2';
  
  const variantClasses = {
    primary: 'bg-purple-600 hover:bg-purple-700 text-white focus:ring-purple-500',
    secondary: 'bg-blue-600 hover:bg-blue-700 text-white focus:ring-blue-500',
    outline: 'border-2 border-purple-600 text-purple-600 hover:bg-purple-600 hover:text-white focus:ring-purple-500',
    ghost: 'text-purple-600 hover:bg-purple-100 focus:ring-purple-500',
    glass: 'bg-white/10 backdrop-blur-sm border border-white/20 text-white hover:bg-white/20 focus:ring-white/50'
  };

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
    xl: 'px-8 py-4 text-xl'
  };

  const disabledClasses = disabled ? 'opacity-50 cursor-not-allowed' : '';

  return (
    <button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${disabledClasses} ${className}`}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
};

// Card Component
export const Card = ({ 
  children, 
  variant = 'default',
  className = '',
  ...props 
}) => {
  const variantClasses = {
    default: 'bg-white border border-gray-200 shadow-sm',
    glass: 'bg-white/10 backdrop-blur-sm border border-white/20',
    gradient: 'bg-gradient-to-br from-purple-50 to-blue-50 border border-purple-200'
  };

  return (
    <div 
      className={`rounded-xl ${variantClasses[variant]} ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

// Card Body Component
export const CardBody = ({ 
  children, 
  className = '',
  ...props 
}) => (
  <div className={`p-6 ${className}`} {...props}>
    {children}
  </div>
);

// Input Component
export const Input = ({ 
  type = 'text',
  variant = 'default',
  size = 'md',
  error = false,
  className = '',
  ...props 
}) => {
  const baseClasses = 'w-full rounded-lg border transition-all duration-200 focus:outline-none focus:ring-2';
  
  const variantClasses = {
    default: 'border-gray-300 focus:border-purple-500 focus:ring-purple-500/20',
    glass: 'bg-white/10 backdrop-blur-sm border-white/20 text-white placeholder-white/70 focus:border-white/50 focus:ring-white/20'
  };

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-5 py-3 text-lg'
  };

  const errorClasses = error ? 'border-red-500 focus:border-red-500 focus:ring-red-500/20' : '';

  return (
    <input
      type={type}
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${errorClasses} ${className}`}
      {...props}
    />
  );
};

// Select Component
export const Select = ({ 
  children,
  variant = 'default',
  size = 'md',
  error = false,
  className = '',
  ...props 
}) => {
  const baseClasses = 'w-full rounded-lg border transition-all duration-200 focus:outline-none focus:ring-2';
  
  const variantClasses = {
    default: 'border-gray-300 focus:border-purple-500 focus:ring-purple-500/20 bg-white',
    glass: 'bg-white/10 backdrop-blur-sm border-white/20 text-white focus:border-white/50 focus:ring-white/20'
  };

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-5 py-3 text-lg'
  };

  const errorClasses = error ? 'border-red-500 focus:border-red-500 focus:ring-red-500/20' : '';

  return (
    <select
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${errorClasses} ${className}`}
      {...props}
    >
      {children}
    </select>
  );
};

// Modal Component
export const Modal = ({ 
  isOpen, 
  onClose, 
  title, 
  children, 
  size = 'md',
  className = '' 
}) => {
  const modalRef = useRef(null);

  useEffect(() => {
    const handleEscape = (e) => {
      if (e.key === 'Escape') onClose();
    };
    
    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    }
    
    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const sizeClasses = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl',
    full: 'max-w-full mx-4'
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div 
        className="absolute inset-0 bg-black bg-opacity-50 backdrop-blur-sm"
        onClick={onClose}
      />
      <div 
        ref={modalRef}
        className={`relative bg-white rounded-xl shadow-2xl ${sizeClasses[size]} w-full mx-4 max-h-[90vh] overflow-hidden bp-animate-scaleIn ${className}`}
      >
        {title && (
          <div className="bp-card-header flex items-center justify-between">
            <h3 className="bp-heading-4">{title}</h3>
            <button
              onClick={onClose}
              className="bp-btn bp-btn-ghost bp-btn-icon-sm"
            >
              ✕
            </button>
          </div>
        )}
        <div className="bp-card-body overflow-y-auto">
          {children}
        </div>
      </div>
    </div>
  );
};

// Dropdown Component
export const Dropdown = ({ 
  trigger, 
  children, 
  position = 'bottom-left',
  className = '' 
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const positionClasses = {
    'bottom-left': 'top-full left-0 mt-2',
    'bottom-right': 'top-full right-0 mt-2',
    'top-left': 'bottom-full left-0 mb-2',
    'top-right': 'bottom-full right-0 mb-2'
  };

  return (
    <div className="relative inline-block" ref={dropdownRef}>
      <div onClick={() => setIsOpen(!isOpen)}>
        {trigger}
      </div>
      {isOpen && (
        <div className={`absolute z-50 ${positionClasses[position]} ${className}`}>
          <div className="bg-white rounded-lg shadow-xl border border-gray-200 py-2 min-w-48 bp-animate-fadeIn">
            {children}
          </div>
        </div>
      )}
    </div>
  );
};

// Dropdown Item
export const DropdownItem = ({ 
  children, 
  onClick, 
  className = '',
  ...props 
}) => (
  <button
    className={`w-full text-left px-4 py-2 text-sm hover:bg-gray-100 transition-colors ${className}`}
    onClick={onClick}
    {...props}
  >
    {children}
  </button>
);

// Tooltip Component
export const Tooltip = ({ 
  content, 
  children, 
  position = 'top',
  className = '' 
}) => {
  const [isVisible, setIsVisible] = useState(false);

  const positionClasses = {
    top: 'bottom-full left-1/2 transform -translate-x-1/2 mb-2',
    bottom: 'top-full left-1/2 transform -translate-x-1/2 mt-2',
    left: 'right-full top-1/2 transform -translate-y-1/2 mr-2',
    right: 'left-full top-1/2 transform -translate-y-1/2 ml-2'
  };

  return (
    <div 
      className="relative inline-block"
      onMouseEnter={() => setIsVisible(true)}
      onMouseLeave={() => setIsVisible(false)}
    >
      {children}
      {isVisible && (
        <div className={`absolute z-70 ${positionClasses[position]} ${className}`}>
          <div className="bg-gray-900 text-white text-xs rounded px-2 py-1 whitespace-nowrap bp-animate-fadeIn">
            {content}
          </div>
        </div>
      )}
    </div>
  );
};

// Tabs Component
export const Tabs = ({ 
  tabs, 
  activeTab, 
  onTabChange, 
  className = '' 
}) => (
  <div className={`w-full ${className}`}>
    <div className="flex border-b border-gray-200">
      {tabs.map((tab) => (
        <button
          key={tab.id}
          onClick={() => onTabChange(tab.id)}
          className={`px-4 py-2 font-medium text-sm border-b-2 transition-colors ${
            activeTab === tab.id
              ? 'border-purple-500 text-purple-600'
              : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
          }`}
        >
          {tab.label}
        </button>
      ))}
    </div>
    <div className="mt-4">
      {tabs.find(tab => tab.id === activeTab)?.content}
    </div>
  </div>
);

// Progress Bar Component
export const ProgressBar = ({ 
  value, 
  max = 100, 
  variant = 'primary',
  size = 'md',
  showLabel = false,
  className = '' 
}) => {
  const percentage = Math.min((value / max) * 100, 100);
  
  const variantClasses = {
    primary: 'bg-purple-500',
    secondary: 'bg-blue-500',
    success: 'bg-green-500',
    warning: 'bg-yellow-500',
    error: 'bg-red-500'
  };

  const sizeClasses = {
    sm: 'h-2',
    md: 'h-3',
    lg: 'h-4'
  };

  return (
    <div className={`w-full ${className}`}>
      {showLabel && (
        <div className="flex justify-between text-sm text-gray-600 mb-1">
          <span>Progress</span>
          <span>{Math.round(percentage)}%</span>
        </div>
      )}
      <div className={`w-full bg-gray-200 rounded-full ${sizeClasses[size]}`}>
        <div
          className={`${sizeClasses[size]} ${variantClasses[variant]} rounded-full transition-all duration-300 ease-out`}
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  );
};

// Alert Component
export const Alert = ({ 
  variant = 'info', 
  title, 
  children, 
  onClose,
  className = '' 
}) => {
  const variantClasses = {
    success: 'bg-green-50 border-green-200 text-green-800',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-800',
    error: 'bg-red-50 border-red-200 text-red-800',
    info: 'bg-blue-50 border-blue-200 text-blue-800'
  };

  const iconMap = {
    success: '✓',
    warning: '⚠',
    error: '✕',
    info: 'ℹ'
  };

  return (
    <div className={`border rounded-lg p-4 ${variantClasses[variant]} ${className}`}>
      <div className="flex items-start">
        <div className="flex-shrink-0 mr-3">
          <span className="text-lg">{iconMap[variant]}</span>
        </div>
        <div className="flex-1">
          {title && <h4 className="font-medium mb-1">{title}</h4>}
          <div>{children}</div>
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="flex-shrink-0 ml-3 text-lg hover:opacity-70"
          >
            ✕
          </button>
        )}
      </div>
    </div>
  );
};

// Loading Spinner Component
export const LoadingSpinner = ({ 
  size = 'md', 
  variant = 'primary',
  className = '' 
}) => {
  const sizeClasses = {
    sm: 'w-4 h-4',
    md: 'w-6 h-6',
    lg: 'w-8 h-8',
    xl: 'w-12 h-12'
  };

  const variantClasses = {
    primary: 'border-purple-500',
    secondary: 'border-blue-500',
    white: 'border-white'
  };

  return (
    <div className={`inline-block ${className}`}>
      <div
        className={`${sizeClasses[size]} border-2 ${variantClasses[variant]} border-t-transparent rounded-full bp-animate-spin`}
      />
    </div>
  );
};

// Search Input Component
export const SearchInput = ({ 
  placeholder = 'Search...', 
  value, 
  onChange, 
  onClear,
  className = '',
  ...props 
}) => (
  <div className={`relative ${className}`}>
    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
      <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
      </svg>
    </div>
    <input
      type="text"
      className="bp-input pl-10 pr-10"
      placeholder={placeholder}
      value={value}
      onChange={onChange}
      {...props}
    />
    {value && onClear && (
      <button
        onClick={onClear}
        className="absolute inset-y-0 right-0 pr-3 flex items-center"
      >
        <svg className="w-4 h-4 text-gray-400 hover:text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    )}
  </div>
);

// Pagination Component
export const Pagination = ({ 
  currentPage, 
  totalPages, 
  onPageChange,
  showInfo = true,
  totalItems = 0,
  itemsPerPage = 10,
  className = '' 
}) => {
  const startItem = (currentPage - 1) * itemsPerPage + 1;
  const endItem = Math.min(currentPage * itemsPerPage, totalItems);

  const getVisiblePages = () => {
    const delta = 2;
    const range = [];
    const rangeWithDots = [];

    for (let i = Math.max(2, currentPage - delta); 
         i <= Math.min(totalPages - 1, currentPage + delta); 
         i++) {
      range.push(i);
    }

    if (currentPage - delta > 2) {
      rangeWithDots.push(1, '...');
    } else {
      rangeWithDots.push(1);
    }

    rangeWithDots.push(...range);

    if (currentPage + delta < totalPages - 1) {
      rangeWithDots.push('...', totalPages);
    } else {
      rangeWithDots.push(totalPages);
    }

    return rangeWithDots;
  };

  return (
    <div className={`flex items-center justify-between ${className}`}>
      {showInfo && (
        <div className="text-sm text-gray-700">
          Showing {startItem} to {endItem} of {totalItems} entries
        </div>
      )}
      
      <div className="flex items-center space-x-1">
        <button
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage === 1}
          className="bp-btn bp-btn-outline bp-btn-sm"
        >
          Previous
        </button>
        
        {getVisiblePages().map((page, index) => (
          <button
            key={index}
            onClick={() => typeof page === 'number' && onPageChange(page)}
            disabled={page === '...'}
            className={`bp-btn bp-btn-sm ${
              page === currentPage 
                ? 'bp-btn-primary' 
                : page === '...' 
                  ? 'bp-btn-ghost cursor-default' 
                  : 'bp-btn-outline'
            }`}
          >
            {page}
          </button>
        ))}
        
        <button
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage === totalPages}
          className="bp-btn bp-btn-outline bp-btn-sm"
        >
          Next
        </button>
      </div>
    </div>
  );
};

// Data Table Component
export const DataTable = ({ 
  columns, 
  data, 
  sortable = true,
  selectable = false,
  onRowSelect,
  selectedRows = [],
  className = '',
  variant = 'default'
}) => {
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' });

  const handleSort = (key) => {
    if (!sortable) return;
    
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  const sortedData = React.useMemo(() => {
    if (!sortConfig.key) return data;
    
    return [...data].sort((a, b) => {
      const aValue = a[sortConfig.key];
      const bValue = b[sortConfig.key];
      
      if (aValue < bValue) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aValue > bValue) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
  }, [data, sortConfig]);

  const handleSelectAll = (checked) => {
    if (checked) {
      onRowSelect(data.map((_, index) => index));
    } else {
      onRowSelect([]);
    }
  };

  const isAllSelected = selectedRows.length === data.length && data.length > 0;
  const isIndeterminate = selectedRows.length > 0 && selectedRows.length < data.length;

  return (
    <div className={`overflow-x-auto ${className}`}>
      <table className={`bp-table ${variant !== 'default' ? `bp-table-${variant}` : ''}`}>
        <thead>
          <tr>
            {selectable && (
              <th className="w-12">
                <input
                  type="checkbox"
                  checked={isAllSelected}
                  ref={input => {
                    if (input) input.indeterminate = isIndeterminate;
                  }}
                  onChange={(e) => handleSelectAll(e.target.checked)}
                />
              </th>
            )}
            {columns.map((column) => (
              <th
                key={column.key}
                className={sortable && column.sortable !== false ? 'cursor-pointer hover:bg-gray-100' : ''}
                onClick={() => column.sortable !== false && handleSort(column.key)}
              >
                <div className="flex items-center justify-between">
                  {column.title}
                  {sortable && column.sortable !== false && (
                    <span className="ml-2">
                      {sortConfig.key === column.key ? (
                        sortConfig.direction === 'asc' ? '↑' : '↓'
                      ) : '↕'}
                    </span>
                  )}
                </div>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {sortedData.map((row, index) => (
            <tr key={index}>
              {selectable && (
                <td>
                  <input
                    type="checkbox"
                    checked={selectedRows.includes(index)}
                    onChange={(e) => {
                      if (e.target.checked) {
                        onRowSelect([...selectedRows, index]);
                      } else {
                        onRowSelect(selectedRows.filter(i => i !== index));
                      }
                    }}
                  />
                </td>
              )}
              {columns.map((column) => (
                <td key={column.key}>
                  {column.render ? column.render(row[column.key], row, index) : row[column.key]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default {
  Button,
  Card,
  CardBody,
  Input,
  Select,
  Modal,
  Dropdown,
  DropdownItem,
  Tooltip,
  Tabs,
  ProgressBar,
  Alert,
  LoadingSpinner,
  SearchInput,
  Pagination,
  DataTable
};
