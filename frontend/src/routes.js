import React, { Suspense, lazy } from "react";
import { Routes, Route } from "react-router-dom";
import ProtectedRoute from "./common/components/ProtectedRoute";
import { ToastProvider } from "./admin/services/toastService";
import { 
  Home, 
  About, 
  Login, 
  Ventures, 
  Contact,
  CustomerDashboard,
  PromoterDashboard
} from "./common";

// Toast configuration for admin interface
const ADMIN_TOAST_CONFIG = {
  duration: 4000,
  position: 'top-right',
  maxToasts: 3,
  showCloseButton: true,
  pauseOnHover: true
};

// Loading component for better UX
const LoadingSpinner = () => (
  <div className="min-h-screen flex items-center justify-center bg-gray-900">
    <div className="text-center">
      <div className="animate-spin rounded-full h-16 w-16 border-4 border-purple-400/30 border-t-purple-400 mx-auto mb-4"></div>
      <p className="text-xl text-gray-300">Loading...</p>
      <p className="text-sm text-gray-500 mt-2">Please wait while we load the application</p>
    </div>
  </div>
);

// Lazy load admin components
const AdminDashboard = lazy(() => import("./admin/pages/AdminDashboard"));
const AdminPromoters = lazy(() => import("./admin/pages/AdminPromoters"));
const AdminCustomers = lazy(() => import("./admin/pages/AdminCustomers"));
const AdminPins = lazy(() => import("./admin/pages/AdminPins"));
const AdminWithdrawals = lazy(() => import("./admin/pages/AdminWithdrawals"));
const AffiliateCommissions = lazy(() => import("./admin/pages/AffiliateCommissions"));

// Lazy load promoter components
const PromoterHome = lazy(() => import("./promoter/pages/PromoterHome"));
const PromoterCustomers = lazy(() => import("./promoter/pages/PromoterCustomers"));
const MyPromoters = lazy(() => import("./promoter/pages/MyPromoters"));
// Fixed JSX structure - using original components
const PinManagement = lazy(() => import("./promoter/pages/PinManagement"));
const CommissionHistory = lazy(() => import("./promoter/pages/CommissionHistory"));
const WithdrawalRequest = lazy(() => import("./promoter/pages/WithdrawalRequest"));

// Lazy load customer components
const CustomerSavings = lazy(() => import("./customer/pages/CustomerInvestments"));
const CustomerOpportunities = lazy(() => import("./customer/pages/CustomerOpportunities"));
const CustomerProfile = lazy(() => import("./customer/pages/CustomerProfile"));
const CustomerPortfolio = lazy(() => import("./customer/pages/CustomerPortfolio"));
const CustomerCoupons = lazy(() => import("./customer/pages/CustomerCoupons"));

const AppRoutes = () => {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        {/* Public Routes */}
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="/ventures" element={<Ventures />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="/login" element={<Login />} />

        {/* Admin Routes */}
        <Route
          path="/admin"
          element={
            <ProtectedRoute allowedRoles={["admin"]}>
              <ToastProvider config={ADMIN_TOAST_CONFIG}>
                <AdminDashboard />
              </ToastProvider>
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/dashboard"
          element={
            <ProtectedRoute allowedRoles={["admin"]}>
              <ToastProvider config={ADMIN_TOAST_CONFIG}>
                <AdminDashboard />
              </ToastProvider>
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/promoters"
          element={
            <ProtectedRoute allowedRoles={["admin"]}>
              <ToastProvider config={ADMIN_TOAST_CONFIG}>
                <AdminPromoters />
              </ToastProvider>
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/customers"
          element={
            <ProtectedRoute allowedRoles={["admin"]}>
              <ToastProvider config={ADMIN_TOAST_CONFIG}>
                <AdminCustomers />
              </ToastProvider>
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/pins"
          element={
            <ProtectedRoute allowedRoles={["admin"]}>
              <ToastProvider config={ADMIN_TOAST_CONFIG}>
                <AdminPins />
              </ToastProvider>
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/withdrawals"
          element={
            <ProtectedRoute allowedRoles={["admin"]}>
              <ToastProvider config={ADMIN_TOAST_CONFIG}>
                <AdminWithdrawals />
              </ToastProvider>
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/commissions"
          element={
            <ProtectedRoute allowedRoles={["admin"]}>
              <ToastProvider config={ADMIN_TOAST_CONFIG}>
                <AffiliateCommissions />
              </ToastProvider>
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin/affiliate-commissions"
          element={
            <ProtectedRoute allowedRoles={["admin"]}>
              <ToastProvider config={ADMIN_TOAST_CONFIG}>
                <AffiliateCommissions />
              </ToastProvider>
            </ProtectedRoute>
          }
        />

        {/* Promoter Routes */}
        <Route
          path="/promoter"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <PromoterDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/dashboard"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <PromoterDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/home"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <PromoterHome />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/customers"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <PromoterCustomers />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/my-customers"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <PromoterCustomers />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/promoters"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <MyPromoters />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/my-promoters"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <MyPromoters />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/pins"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <PinManagement />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/pin-management"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <PinManagement />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/commissions"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <CommissionHistory />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/commission-history"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <CommissionHistory />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/withdrawals"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <WithdrawalRequest />
            </ProtectedRoute>
          }
        />
        <Route
          path="/promoter/withdrawal-request"
          element={
            <ProtectedRoute allowedRoles={["promoter"]}>
              <WithdrawalRequest />
            </ProtectedRoute>
          }
        />

        {/* Customer Routes */}
        <Route
          path="/customer"
          element={
            <ProtectedRoute allowedRoles={["customer"]}>
              <CustomerDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/customer/savings"
          element={
            <ProtectedRoute allowedRoles={["customer"]}>
              <CustomerSavings />
            </ProtectedRoute>
          }
        />
        <Route
          path="/customer/opportunities"
          element={
            <ProtectedRoute allowedRoles={["customer"]}>
              <CustomerOpportunities />
            </ProtectedRoute>
          }
        />
        <Route
          path="/customer/profile"
          element={
            <ProtectedRoute allowedRoles={["customer"]}>
              <CustomerProfile />
            </ProtectedRoute>
          }
        />
        <Route
          path="/customer/portfolio"
          element={
            <ProtectedRoute allowedRoles={["customer"]}>
              <CustomerPortfolio />
            </ProtectedRoute>
          }
        />
        <Route
          path="/customer/coupons"
          element={
            <ProtectedRoute allowedRoles={["customer"]}>
              <CustomerCoupons />
            </ProtectedRoute>
          }
        />
      </Routes>
    </Suspense>
  );
};

export default AppRoutes;
