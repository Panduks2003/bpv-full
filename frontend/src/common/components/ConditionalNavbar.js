import React from 'react';
import { useAuth } from '../context/AuthContext';
import PublicNavbar from './Navbar';
import SimpleNavbar from './SimpleNavbar';
import AdminNavbar from '../../admin/components/AdminNavbar';
import PromoterNavbar from '../../promoter/components/PromoterNavbar';
import CustomerNavbar from '../../customer/components/CustomerNavbar';
import { useLocation } from 'react-router-dom';
function ConditionalNavbar() {
  const { user, loading } = useAuth(); // Use simple auth for testing

  // Show public navbar while loading
  if (loading) {
    return <div data-testid="conditional-navbar" data-state="loading"><PublicNavbar /></div>;
  }

  // If user is not authenticated, show public navbar
  if (!user) {
    return <div data-testid="conditional-navbar" data-state="public"><PublicNavbar /></div>;
  }

  // Render navbar based on user role
  switch (user.role) {
    case 'admin':
      return <div data-testid="conditional-navbar" data-state="admin"><AdminNavbar /></div>;
    case 'promoter':
      return <div data-testid="conditional-navbar" data-state="promoter"><PromoterNavbar /></div>;
    case 'customer':
      return <div data-testid="conditional-navbar" data-state="customer"><CustomerNavbar /></div>;
    default:
      return <div data-testid="conditional-navbar" data-state="default"><PublicNavbar /></div>;
  }
}

export default ConditionalNavbar;
