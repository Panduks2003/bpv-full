import React, { useEffect } from 'react';
import { useAuth } from "../context/AuthContext";
import { useNavigate } from 'react-router-dom';

function CustomerDashboard() {
  const { user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    
    if (user) {
      navigate('/customer/coupons', { replace: true });
    } else {
      navigate('/login', { replace: true });
    }
  }, [navigate, user]);

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-blue-400 border-t-transparent mx-auto mb-4"></div>
        <p className="text-gray-600">Loading customer dashboard...</p>
      </div>
    </div>
  );
}

export default CustomerDashboard;
