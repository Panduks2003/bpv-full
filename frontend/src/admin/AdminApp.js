/**
 * AdminApp - Wrapper component for Admin Dashboard with unified toast system
 * 
 * This component wraps all admin routes with the ToastProvider to ensure
 * consistent notification behavior across the entire admin interface.
 */

import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ToastProvider } from './services/toastService';
import AdminDashboard from './pages/AdminDashboard';
import AdminPromoters from './pages/AdminPromoters';
import AdminCustomers from './pages/AdminCustomers';
import AdminPins from './pages/AdminPins';
import AdminWithdrawals from './pages/AdminWithdrawals';
import AffiliateCommissions from './pages/AffiliateCommissions';

// Toast configuration for admin interface
const ADMIN_TOAST_CONFIG = {
  duration: 4000,
  position: 'top-right',
  maxToasts: 3,
  showCloseButton: true,
  pauseOnHover: true
};

function AdminApp() {
  return (
    <ToastProvider config={ADMIN_TOAST_CONFIG}>
      <Routes>
        <Route path="/" element={<AdminDashboard />} />
        <Route path="/dashboard" element={<AdminDashboard />} />
        <Route path="/promoters" element={<AdminPromoters />} />
        <Route path="/customers" element={<AdminCustomers />} />
        <Route path="/pins" element={<AdminPins />} />
        <Route path="/affiliate-commissions" element={<AffiliateCommissions />} />
        <Route path="/withdrawals" element={<AdminWithdrawals />} />
        {/* Redirect any unknown admin routes to dashboard */}
        <Route path="*" element={<Navigate to="/admin/dashboard" replace />} />
      </Routes>
    </ToastProvider>
  );
}

export default AdminApp;
