import React from 'react';

// ===== REUSABLE UI COMPONENTS =====

// Button Component
export const Button = ({ 
  variant = 'primary', 
  size = 'md', 
  children, 
  className = '', 
  icon = false,
  ...props 
}) => {
  const baseClass = 'bp-btn';
  const variantClass = `bp-btn-${variant}`;
  const sizeClass = size !== 'md' ? `bp-btn-${size}` : '';
  const iconClass = icon ? 'bp-btn-icon' : '';
  
  return (
    <button 
      className={`${baseClass} ${variantClass} ${sizeClass} ${iconClass} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};

// Card Component
export const Card = ({ 
  variant = 'default', 
  children, 
  className = '', 
  hover = true,
  ...props 
}) => {
  const baseClass = 'bp-card';
  const variantClass = variant !== 'default' ? `bp-card-${variant}` : '';
  const hoverClass = hover ? 'hover-lift' : '';
  
  return (
    <div 
      className={`${baseClass} ${variantClass} ${hoverClass} ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

// Card Sub-components
export const CardHeader = ({ children, className = '', ...props }) => (
  <div className={`bp-card-header ${className}`} {...props}>
    {children}
  </div>
);

export const CardBody = ({ children, className = '', ...props }) => (
  <div className={`bp-card-body ${className}`} {...props}>
    {children}
  </div>
);

export const CardFooter = ({ children, className = '', ...props }) => (
  <div className={`bp-card-footer ${className}`} {...props}>
    {children}
  </div>
);

// Input Component
export const Input = ({ 
  variant = 'default', 
  error = false, 
  className = '', 
  ...props 
}) => {
  const baseClass = 'bp-input';
  const variantClass = variant !== 'default' ? `bp-input-${variant}` : '';
  const errorClass = error ? 'bp-input-error' : '';
  
  return (
    <input 
      className={`${baseClass} ${variantClass} ${errorClass} ${className}`}
      {...props}
    />
  );
};

// Badge Component
export const Badge = ({ 
  variant = 'primary', 
  children, 
  className = '', 
  ...props 
}) => {
  const baseClass = 'bp-badge';
  const variantClass = `bp-badge-${variant}`;
  
  return (
    <span 
      className={`${baseClass} ${variantClass} ${className}`}
      {...props}
    >
      {children}
    </span>
  );
};

// Typography Components
export const Heading = ({ 
  level = 1, 
  children, 
  className = '', 
  gradient = false,
  ...props 
}) => {
  const Component = `h${level}`;
  const baseClass = `bp-heading-${level}`;
  const gradientClass = gradient ? 'bp-gradient-text' : '';
  
  return React.createElement(
    Component,
    {
      className: `${baseClass} ${gradientClass} ${className}`,
      ...props
    },
    children
  );
};

export const Text = ({ 
  variant = 'body', 
  children, 
  className = '', 
  ...props 
}) => {
  const baseClass = variant === 'body' ? 'bp-body' : `bp-${variant}`;
  
  return (
    <p className={`${baseClass} ${className}`} {...props}>
      {children}
    </p>
  );
};

// Container Components
export const Container = ({ 
  fluid = false, 
  children, 
  className = '', 
  ...props 
}) => {
  const baseClass = fluid ? 'bp-container-fluid' : 'bp-container';
  
  return (
    <div className={`${baseClass} ${className}`} {...props}>
      {children}
    </div>
  );
};

export const Section = ({ 
  size = 'md', 
  children, 
  className = '', 
  ...props 
}) => {
  const baseClass = 'bp-section';
  const sizeClass = size !== 'md' ? `bp-section-${size}` : '';
  
  return (
    <section className={`${baseClass} ${sizeClass} ${className}`} {...props}>
      {children}
    </section>
  );
};

// Grid Component
export const Grid = ({ 
  cols = 1, 
  responsive = {}, 
  children, 
  className = '', 
  ...props 
}) => {
  const baseClass = 'bp-grid';
  const colsClass = `bp-grid-cols-${cols}`;
  
  // Generate responsive classes
  const responsiveClasses = Object.entries(responsive)
    .map(([breakpoint, columns]) => `bp-grid-${breakpoint}-cols-${columns}`)
    .join(' ');
  
  return (
    <div 
      className={`${baseClass} ${colsClass} ${responsiveClasses} ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

// Flex Component
export const Flex = ({ 
  direction = 'row', 
  align = 'stretch', 
  justify = 'start', 
  wrap = false,
  children, 
  className = '', 
  ...props 
}) => {
  const baseClass = 'bp-flex';
  const directionClass = direction === 'column' ? 'bp-flex-col' : '';
  const alignClass = align !== 'stretch' ? `bp-items-${align}` : '';
  const justifyClass = justify !== 'start' ? `bp-justify-${justify}` : '';
  const wrapClass = wrap ? 'bp-flex-wrap' : '';
  
  return (
    <div 
      className={`${baseClass} ${directionClass} ${alignClass} ${justifyClass} ${wrapClass} ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

// Table Component
export const Table = ({ 
  variant = 'default', 
  striped = false, 
  children, 
  className = '', 
  ...props 
}) => {
  const baseClass = 'bp-table';
  const variantClass = variant !== 'default' ? `bp-table-${variant}` : '';
  const stripedClass = striped ? 'bp-table-striped' : '';
  
  return (
    <table 
      className={`${baseClass} ${variantClass} ${stripedClass} ${className}`}
      {...props}
    >
      {children}
    </table>
  );
};

// Loading Skeleton Component
export const Skeleton = ({ 
  width = '100%', 
  height = '1rem', 
  className = '', 
  ...props 
}) => (
  <div 
    className={`animate-pulse bg-gray-200 rounded ${className}`}
    style={{ width, height }}
    {...props}
  />
);

// Glass Effect Component
export const GlassCard = ({ 
  children, 
  className = '', 
  blur = 'medium',
  ...props 
}) => {
  const baseClass = 'bp-glass';
  const blurClass = blur !== 'medium' ? `backdrop-blur-${blur}` : '';
  
  return (
    <div 
      className={`${baseClass} ${blurClass} rounded-xl p-6 ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

// Status Indicator Component
export const StatusIndicator = ({ 
  status, 
  children, 
  className = '', 
  ...props 
}) => {
  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'paid':
      case 'completed':
      case 'success':
        return 'success';
      case 'pending':
      case 'processing':
      case 'warning':
        return 'warning';
      case 'inactive':
      case 'failed':
      case 'error':
        return 'error';
      case 'info':
      case 'mail send':
        return 'info';
      default:
        return 'primary';
    }
  };

  return (
    <Badge variant={getStatusColor(status)} className={className} {...props}>
      {children || status}
    </Badge>
  );
};

// Animation Wrapper Component
export const AnimatedDiv = ({ 
  animation = 'fadeIn', 
  delay = 0, 
  children, 
  className = '', 
  ...props 
}) => {
  const animationClass = `bp-animate-${animation}`;
  const style = delay > 0 ? { animationDelay: `${delay}ms` } : {};
  
  return (
    <div 
      className={`${animationClass} ${className}`}
      style={style}
      {...props}
    >
      {children}
    </div>
  );
};

// Icon Component (for consistent icon sizing)
export const Icon = ({ 
  size = 'md', 
  children, 
  className = '', 
  ...props 
}) => {
  const sizeMap = {
    xs: 'w-3 h-3',
    sm: 'w-4 h-4',
    md: 'w-5 h-5',
    lg: 'w-6 h-6',
    xl: 'w-8 h-8'
  };
  
  return (
    <span 
      className={`inline-flex ${sizeMap[size]} ${className}`}
      {...props}
    >
      {children}
    </span>
  );
};

// Export all components as default
export default {
  Button,
  Card,
  CardHeader,
  CardBody,
  CardFooter,
  Input,
  Badge,
  Heading,
  Text,
  Container,
  Section,
  Grid,
  Flex,
  Table,
  Skeleton,
  GlassCard,
  StatusIndicator,
  AnimatedDiv,
  Icon
};
