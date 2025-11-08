import React, { useState, useEffect } from 'react';
import { useAuth } from '../../common/context/AuthContext';
import { supabase } from "../../common/services/supabaseClient"
import CustomerNavbar from '../components/CustomerNavbar';
import { UnifiedBackground } from "../../common/components/SharedTheme";
import { Gift, Clock, Copy, Tag } from 'lucide-react';

function CustomerCoupons() {
  const { user } = useAuth();
  const [copiedCode, setCopiedCode] = useState(null);
  const [coupons, setCoupons] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Load coupons from Supabase
  useEffect(() => {
    loadCoupons();
  }, []);

  const loadCoupons = async () => {
    try {
      setLoading(true);
      // For now, use a simple static set of coupons
      // In a real implementation, this would come from Supabase
      const staticCoupons = [
        {
          id: 1,
          code: 'WELCOME20',
          title: '20% Off First Purchase',
          description: 'Get 20% discount on your first investment with BrightPlanet Ventures',
          discount: '20%',
          minAmount: 1000,
          expiryDate: '2024-12-31',
          category: 'Welcome Offer',
          isActive: true
        },
        {
          id: 2,
          code: 'REFER25',
          title: '25% Referral Bonus',
          description: 'Get 25% bonus when you refer a friend',
          discount: '25%',
          minAmount: 500,
          expiryDate: '2024-12-31',
          category: 'Referral',
          isActive: true
        },
        {
          id: 3,
          code: 'SAVE500',
          title: '₹500 Off on ₹3000+',
          description: 'Save ₹500 on savings above ₹3000',
          discount: '₹500',
          minAmount: 3000,
          expiryDate: '2024-11-30',
          category: 'Special Offer',
          isActive: true
        }
      ];
      
      setCoupons(staticCoupons);
      setError(null);
    } catch (err) {
      console.error('Error loading coupons:', err);
      setError('Failed to load coupons');
    } finally {
      setLoading(false);
    }
  };



  const handleCopyCode = (code) => {
    navigator.clipboard.writeText(code);
    setCopiedCode(code);
    setTimeout(() => setCopiedCode(null), 2000);
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-IN', {
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  };

  if (loading) {
    return (
      <UnifiedBackground>
        <CustomerNavbar />
        <div className="container mx-auto px-4 py-8">
          <div className="text-center">
            <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-orange-400 mx-auto"></div>
            <p className="text-white mt-4">Loading coupons...</p>
          </div>
        </div>
      </UnifiedBackground>
    );
  }

  if (error) {
    return (
      <UnifiedBackground>
        <CustomerNavbar />
        <div className="container mx-auto px-4 py-8">
          <div className="text-center">
            <p className="text-red-400 text-lg">{error}</p>
            <button 
              onClick={loadCoupons}
              className="mt-4 bg-orange-600 hover:bg-orange-700 text-white px-6 py-2 rounded-lg transition-colors duration-200"
            >
              Retry
            </button>
          </div>
        </div>
      </UnifiedBackground>
    );
  }

  return (
    <UnifiedBackground>
      <CustomerNavbar />
      
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-white flex items-center justify-center gap-3 mb-4">
            <Gift className="text-yellow-400" size={40} />
            Available Coupons
          </h1>
          <p className="text-blue-200 text-lg">
            Save more on your savings with exclusive offers
          </p>
        </div>

        {/* Stats Card */}
        <div className="mb-8">
          <div className="bg-gradient-to-r from-green-600/20 to-green-500/20 backdrop-blur-sm border border-green-400/30 rounded-xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-green-200 text-sm">Available Coupons</p>
                <p className="text-2xl font-bold text-white">{coupons.length}</p>
              </div>
              <Tag className="text-green-400" size={32} />
            </div>
          </div>
        </div>

        {/* Coupons Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {coupons.map((coupon) => (
            <div key={coupon.id} className="bg-gradient-to-br from-slate-800/80 to-slate-700/80 backdrop-blur-sm border border-slate-600/50 rounded-xl p-6 hover:border-green-400/50 transition-all duration-300 hover:shadow-lg hover:shadow-green-500/20">
              <div className="mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="bg-green-500/20 text-green-300 px-3 py-1 rounded-full text-sm font-medium">
                    {coupon.category}
                  </span>
                  <span className="text-2xl font-bold text-green-400">
                    {coupon.discount}
                  </span>
                </div>
                
                <h3 className="text-xl font-bold text-white mb-2">{coupon.title}</h3>
                <p className="text-slate-300 text-sm mb-4">{coupon.description}</p>
                
                <div className="space-y-2 text-sm text-slate-400">
                  <div className="flex items-center gap-2">
                    <Clock size={16} />
                    <span>Expires: {formatDate(coupon.expiryDate)}</span>
                  </div>
                  <div>
                    <span>Min. Amount: ₹{coupon.minAmount.toLocaleString()}</span>
                  </div>
                </div>
              </div>
              
              <div className="border-t border-slate-600/50 pt-4">
                <div className="flex items-center justify-between">
                  <div className="bg-slate-700/50 px-3 py-2 rounded-lg">
                    <span className="text-white font-mono font-bold">{coupon.code}</span>
                  </div>
                  <button
                    onClick={() => handleCopyCode(coupon.code)}
                    className="flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg transition-colors duration-200"
                  >
                    <Copy size={16} />
                    {copiedCode === coupon.code ? 'Copied!' : 'Copy'}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

      </div>
    </UnifiedBackground>
  );
}

export default CustomerCoupons;
