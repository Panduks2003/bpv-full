import React, { useEffect } from 'react';
import { useAuth } from "../context/AuthContext";
import { useNavigate } from 'react-router-dom';

function PromoterDashboard() {
  const { user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    // Redirect to the actual promoter home page
    navigate('/promoter/home', { replace: true });
  }, [navigate]);

  return null; // This component just redirects
}

export default PromoterDashboard;
