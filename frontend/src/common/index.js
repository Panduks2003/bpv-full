// Common module exports

// Pages
export { default as Home } from './pages/Home';
export { default as About } from './pages/About';
export { default as Login } from './pages/Login';
export { default as Contact } from './pages/Contact';
export { default as Ventures } from './pages/Ventures';
export { default as CustomerDashboard } from './pages/CustomerDashboard';
export { default as PromoterDashboard } from './pages/PromoterDashboard';

// Components
export { default as Footer } from './components/Footer';
export { default as Navbar } from './components/Navbar';
export { default as ConditionalNavbar } from './components/ConditionalNavbar';
export { default as SimpleNavbar } from './components/SimpleNavbar';
export { default as HomePage } from './components/HomePage';
export { default as LoginPage } from './components/LoginPage';
export { default as PaymentManager } from './components/PaymentManager';
export { default as PurposeBuiltSection } from './components/PurposeBuiltSection';
export { default as SecurityAlert } from './components/SecurityAlert';
export { default as SharedTheme } from './components/SharedTheme';
export { default as SuccessModal } from './components/SuccessModal';
export { default as TrustedCommunities } from './components/TrustedCommunities';
export { default as UnifiedCustomerForm } from './components/UnifiedCustomerForm';

// Context
export { AuthProvider } from './context/AuthContext';
export { ScalabilityProvider } from './context/ScalabilityContext';

// Services
export * from './services/authService';
export { default as supabaseClient } from './services/supabaseClient';
export { UnifiedToastProvider, useUnifiedToast } from './services/unifiedToastService';

// Hooks
export { default as useOptimizedQuery } from './hooks/useOptimizedQuery';
export { default as useSecureQuery } from './hooks/useSecureQuery';

// Utils
export { default as ScrollToTop } from './utils/ScrollToTop';
export * from './utils/constants';
export * from './utils/formatters';
export * from './utils/helpers';
export * from './utils/logger';
export * from './utils/security';
