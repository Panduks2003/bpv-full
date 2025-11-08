import React from 'react';

// Brand colors from design system
const BRAND_COLORS = {
  primary: '#F7931E',      // Sunset Orange
  secondary: '#FDC830',    // Golden Yellow
  accent: '#004AAD',       // Deep Blue
  shimmer: 'rgba(247, 147, 30, 0.1)', // Orange shimmer
  background: 'rgba(255, 255, 255, 0.05)', // Glass background
  border: 'rgba(255, 255, 255, 0.1)'
};

// Base shimmer animation keyframes
const shimmerStyles = `
  @keyframes bp-skeleton-shimmer {
    0% {
      background-position: -200px 0;
    }
    100% {
      background-position: calc(200px + 100%) 0;
    }
  }
  
  .bp-skeleton-shimmer {
    background: linear-gradient(
      90deg,
      ${BRAND_COLORS.background} 25%,
      ${BRAND_COLORS.shimmer} 50%,
      ${BRAND_COLORS.background} 75%
    );
    background-size: 200px 100%;
    animation: bp-skeleton-shimmer 1.5s infinite linear;
  }
`;

// Inject shimmer styles into document head
if (typeof document !== 'undefined' && !document.getElementById('bp-skeleton-styles')) {
  const style = document.createElement('style');
  style.id = 'bp-skeleton-styles';
  style.textContent = shimmerStyles;
  document.head.appendChild(style);
}

// Base Skeleton Component
export const SkeletonBase = ({ 
  width = '100%', 
  height = '1rem', 
  className = '', 
  rounded = 'rounded-lg',
  animate = true 
}) => (
  <div
    className={`${rounded} border border-white/10 ${animate ? 'bp-skeleton-shimmer' : ''} ${className}`}
    style={{
      width,
      height,
      background: animate ? undefined : BRAND_COLORS.background
    }}
  />
);

// Dashboard Card Skeleton
export const SkeletonCard = ({ className = '' }) => (
  <div className={`bg-white/5 backdrop-blur-sm border border-slate-200/10 rounded-xl p-4 h-full ${className}`}>
    <div className="flex items-center justify-between mb-3">
      <SkeletonBase width="3rem" height="3rem" rounded="rounded-xl" />
      <SkeletonBase width="3rem" height="2rem" />
    </div>
    <div className="space-y-2">
      <SkeletonBase width="70%" height="1rem" />
      <SkeletonBase width="90%" height="0.75rem" />
    </div>
  </div>
);

// Table Skeleton
export const SkeletonTable = ({ rows = 5, columns = 4, className = '' }) => (
  <div className={`bg-white/5 backdrop-blur-sm border border-slate-200/10 rounded-xl overflow-hidden ${className}`}>
    {/* Table Header */}
    <div className="bg-white/5 p-4 border-b border-white/10">
      <div className="grid gap-4" style={{ gridTemplateColumns: `repeat(${columns}, 1fr)` }}>
        {Array.from({ length: columns }).map((_, i) => (
          <SkeletonBase key={i} width="80%" height="1rem" />
        ))}
      </div>
    </div>
    
    {/* Table Rows */}
    <div className="divide-y divide-white/10">
      {Array.from({ length: rows }).map((_, rowIndex) => (
        <div key={rowIndex} className="p-4">
          <div className="grid gap-4" style={{ gridTemplateColumns: `repeat(${columns}, 1fr)` }}>
            {Array.from({ length: columns }).map((_, colIndex) => (
              <SkeletonBase 
                key={colIndex} 
                width={colIndex === 0 ? '90%' : '70%'} 
                height="1rem" 
              />
            ))}
          </div>
        </div>
      ))}
    </div>
  </div>
);

// Form Skeleton
export const SkeletonForm = ({ fields = 4, className = '' }) => (
  <div className={`bg-white/5 backdrop-blur-sm border border-slate-200/10 rounded-xl p-6 ${className}`}>
    <div className="space-y-6">
      {Array.from({ length: fields }).map((_, i) => (
        <div key={i} className="space-y-2">
          <SkeletonBase width="25%" height="1rem" />
          <SkeletonBase width="100%" height="2.5rem" rounded="rounded-lg" />
        </div>
      ))}
      <div className="flex justify-end space-x-3 pt-4">
        <SkeletonBase width="5rem" height="2.5rem" rounded="rounded-lg" />
        <SkeletonBase width="6rem" height="2.5rem" rounded="rounded-lg" />
      </div>
    </div>
  </div>
);

// Stats Cards Skeleton (for dashboard overview)
export const SkeletonStats = ({ count = 2, className = '' }) => (
  <div className={`grid grid-cols-1 md:grid-cols-2 gap-4 ${className}`}>
    {Array.from({ length: count }).map((_, i) => (
      <SkeletonCard key={i} />
    ))}
  </div>
);

// Management Grid Skeleton (for dashboard management tools)
export const SkeletonManagementGrid = ({ count = 4, className = '' }) => (
  <div className={`grid grid-cols-2 lg:grid-cols-4 gap-4 ${className}`}>
    {Array.from({ length: count }).map((_, i) => (
      <div key={i} className="bg-white/5 backdrop-blur-sm border border-slate-200/10 rounded-xl p-5 h-full">
        <div className="text-center space-y-4">
          <SkeletonBase width="3.5rem" height="3.5rem" rounded="rounded-xl" className="mx-auto" />
          <div className="space-y-2">
            <SkeletonBase width="70%" height="1rem" className="mx-auto" />
            <SkeletonBase width="90%" height="0.75rem" className="mx-auto" />
          </div>
        </div>
      </div>
    ))}
  </div>
);

// List Item Skeleton (for promoters/customers lists)
export const SkeletonListItem = ({ className = '' }) => (
  <div className={`bg-white/5 backdrop-blur-sm border border-slate-200/10 rounded-xl p-4 ${className}`}>
    <div className="flex items-center space-x-4">
      <SkeletonBase width="3rem" height="3rem" rounded="rounded-full" />
      <div className="flex-1 space-y-2">
        <SkeletonBase width="60%" height="1rem" />
        <SkeletonBase width="40%" height="0.75rem" />
      </div>
      <div className="flex space-x-2">
        <SkeletonBase width="2rem" height="2rem" rounded="rounded-lg" />
        <SkeletonBase width="2rem" height="2rem" rounded="rounded-lg" />
      </div>
    </div>
  </div>
);

// Page Header Skeleton
export const SkeletonPageHeader = ({ className = '' }) => (
  <div className={`text-center mb-6 ${className}`}>
    <SkeletonBase width="4rem" height="4rem" rounded="rounded-2xl" className="mx-auto mb-4" />
    <SkeletonBase width="15rem" height="2rem" className="mx-auto mb-2" />
    <SkeletonBase width="20rem" height="1rem" className="mx-auto" />
  </div>
);

// Search and Filters Skeleton
export const SkeletonSearchFilters = ({ className = '' }) => (
  <div className={`flex flex-col md:flex-row gap-4 mb-6 ${className}`}>
    <div className="flex-1">
      <SkeletonBase width="100%" height="2.5rem" rounded="rounded-lg" />
    </div>
    <div className="flex gap-2">
      <SkeletonBase width="8rem" height="2.5rem" rounded="rounded-lg" />
      <SkeletonBase width="6rem" height="2.5rem" rounded="rounded-lg" />
    </div>
  </div>
);

// Modal Skeleton
export const SkeletonModal = ({ className = '' }) => (
  <div className={`bg-white/10 backdrop-blur-sm border border-slate-200/20 rounded-2xl p-6 max-w-md mx-auto ${className}`}>
    <div className="space-y-4">
      <SkeletonBase width="60%" height="1.5rem" />
      <SkeletonBase width="100%" height="4rem" />
      <div className="flex justify-end space-x-3">
        <SkeletonBase width="5rem" height="2.5rem" rounded="rounded-lg" />
        <SkeletonBase width="6rem" height="2.5rem" rounded="rounded-lg" />
      </div>
    </div>
  </div>
);

// Withdrawal Request Card Skeleton
export const SkeletonWithdrawalCard = ({ className = '' }) => (
  <div className={`bg-white/5 backdrop-blur-sm border border-slate-200/10 rounded-xl p-6 ${className}`}>
    <div className="flex justify-between items-start mb-4">
      <div className="space-y-2">
        <SkeletonBase width="8rem" height="1rem" />
        <SkeletonBase width="6rem" height="0.75rem" />
      </div>
      <SkeletonBase width="4rem" height="1.5rem" rounded="rounded-full" />
    </div>
    <div className="space-y-3">
      <div className="flex justify-between">
        <SkeletonBase width="4rem" height="0.75rem" />
        <SkeletonBase width="6rem" height="0.75rem" />
      </div>
      <div className="flex justify-between">
        <SkeletonBase width="5rem" height="0.75rem" />
        <SkeletonBase width="7rem" height="0.75rem" />
      </div>
    </div>
    <div className="flex justify-end space-x-2 mt-4 pt-4 border-t border-white/10">
      <SkeletonBase width="4rem" height="2rem" rounded="rounded-lg" />
      <SkeletonBase width="4rem" height="2rem" rounded="rounded-lg" />
    </div>
  </div>
);

// Full Page Loading Skeleton
export const SkeletonFullPage = ({ type = 'dashboard' }) => {
  switch (type) {
    case 'dashboard':
      return (
        <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
          <div className="max-w-7xl mx-auto px-6 py-6">
            <SkeletonPageHeader />
            <div className="space-y-6">
              <div>
                <SkeletonBase width="10rem" height="1.5rem" className="mb-4" />
                <SkeletonStats />
              </div>
              <div>
                <SkeletonBase width="12rem" height="1.5rem" className="mb-4" />
                <SkeletonManagementGrid />
              </div>
            </div>
          </div>
        </div>
      );
    
    case 'table':
      return (
        <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
          <div className="max-w-7xl mx-auto px-6 py-6">
            <SkeletonPageHeader />
            <SkeletonSearchFilters />
            <SkeletonTable rows={8} columns={5} />
          </div>
        </div>
      );
    
    case 'cards':
      return (
        <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
          <div className="max-w-7xl mx-auto px-6 py-6">
            <SkeletonPageHeader />
            <SkeletonSearchFilters />
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {Array.from({ length: 6 }).map((_, i) => (
                <SkeletonWithdrawalCard key={i} />
              ))}
            </div>
          </div>
        </div>
      );
    
    default:
      return <SkeletonFullPage type="dashboard" />;
  }
};

// Export all components
export default {
  SkeletonBase,
  SkeletonCard,
  SkeletonTable,
  SkeletonForm,
  SkeletonStats,
  SkeletonManagementGrid,
  SkeletonListItem,
  SkeletonPageHeader,
  SkeletonSearchFilters,
  SkeletonModal,
  SkeletonWithdrawalCard,
  SkeletonFullPage
};
