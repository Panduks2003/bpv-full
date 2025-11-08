import React, { useState, useEffect } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import { useNavigate } from 'react-router-dom';
import CustomerNavbar from '../components/CustomerNavbar';
import Footer from '../../common/components/Footer';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { db } from "../../common/services/supabaseClient"

function CustomerSavings() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  useScrollAnimation();

  // State for customer data
  const [customerData, setCustomerData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadCustomerData();
  }, [user]);

  const loadCustomerData = async () => {
    if (!user) return;
    
    try {
      setLoading(true);
      const { data, error } = await db.customers.getById(user.id);
      if (error) {
        console.error('Error loading customer data:', error);
      } else {
        setCustomerData(data);
      }
    } catch (error) {
      console.error('Error loading customer data:', error);
    } finally {
      setLoading(false);
    }
  };
  
  // Generate sample investments for the customer (will be replaced with real data)
  const customerPurchases = [
    {
      id: 'INV001',
      customerId: customerData?.id || user?.id,
      amount: 50000,
      returns: 6250,
      status: 'active',
      date: '2024-01-15'
    },
    {
      id: 'INV002', 
      customerId: customerData?.id || user?.id,
      amount: 25000,
      returns: 3800,
      status: 'active',
      date: '2024-02-10'
    },
    {
      id: 'INV003',
      customerId: customerData?.id || user?.id, 
      amount: 75000,
      returns: 10500,
      status: 'completed',
      date: '2023-12-05'
    }
  ];
  
  // Calculate portfolio stats
  const totalSaved = customerPurchases.reduce((sum, p) => sum + p.amount, 0);
  const totalReturns = customerPurchases.reduce((sum, p) => sum + (p.returns || 0), 0);
  const totalGrowth = totalSaved > 0 ? ((totalReturns / totalSaved) * 100) : 0;

  const [selectedFilter, setSelectedFilter] = useState('all');

  const filteredPurchases = customerPurchases.filter(purchase => {
    if (selectedFilter === 'all') return true;
    if (selectedFilter === 'active') return purchase.status === 'active';
    if (selectedFilter === 'completed') return purchase.status === 'completed';
    return true;
  });

  return (
    <>
      <SharedStyles />
      <CustomerNavbar />
      <UnifiedBackground>
        <div className="min-h-screen p-8">
          <div className="max-w-7xl mx-auto">
            <div className="flex justify-between items-center mb-8" data-animate>
              <div>
                <h1 className="text-4xl font-bold text-white mb-2">
                  My Savings
                </h1>
                <p className="text-gray-400">
                  Track and manage your savings portfolio
                </p>
              </div>
              <UnifiedButton onClick={() => navigate('/customer/opportunities')}>
                Explore Opportunities
              </UnifiedButton>
            </div>

            {/* Portfolio Overview Cards */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8" data-animate>
              <UnifiedCard className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">Total Saved</p>
                    <p className="text-2xl font-bold text-white">₹{totalSaved.toLocaleString()}</p>
                  </div>
                  <div className="w-12 h-12 bg-blue-500/20 rounded-lg flex items-center justify-center">
                    <svg className="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                    </svg>
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">Current Returns</p>
                    <p className="text-2xl font-bold text-green-400">₹{totalReturns.toLocaleString()}</p>
                  </div>
                  <div className="w-12 h-12 bg-green-500/20 rounded-lg flex items-center justify-center">
                    <svg className="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                    </svg>
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">Growth Rate</p>
                    <p className={`text-2xl font-bold ${totalGrowth >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                      {totalGrowth >= 0 ? '+' : ''}{totalGrowth.toFixed(1)}%
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-purple-500/20 rounded-lg flex items-center justify-center">
                    <svg className="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">Active Savings</p>
                    <p className="text-2xl font-bold text-white">{customerPurchases.length}</p>
                  </div>
                  <div className="w-12 h-12 bg-orange-500/20 rounded-lg flex items-center justify-center">
                    <svg className="w-6 h-6 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                    </svg>
                  </div>
                </div>
              </UnifiedCard>
            </div>

            {/* Filter Buttons */}
            <div className="flex space-x-4 mb-6" data-animate>
              <button
                onClick={() => setSelectedFilter('all')}
                className={`px-4 py-2 rounded-lg font-medium transition-all duration-200 ${
                  selectedFilter === 'all' 
                    ? 'bg-green-500 text-white' 
                    : 'bg-slate-700 text-gray-300 hover:bg-slate-600'
                }`}
              >
                All Savings
              </button>
              <button
                onClick={() => setSelectedFilter('active')}
                className={`px-4 py-2 rounded-lg font-medium transition-all duration-200 ${
                  selectedFilter === 'active' 
                    ? 'bg-green-500 text-white' 
                    : 'bg-slate-700 text-gray-300 hover:bg-slate-600'
                }`}
              >
                Active
              </button>
              <button
                onClick={() => setSelectedFilter('completed')}
                className={`px-4 py-2 rounded-lg font-medium transition-all duration-200 ${
                  selectedFilter === 'completed' 
                    ? 'bg-green-500 text-white' 
                    : 'bg-slate-700 text-gray-300 hover:bg-slate-600'
                }`}
              >
                Completed
              </button>
            </div>

            {/* Savings Table */}
            <UnifiedCard className="overflow-hidden" data-animate>
              <div className="p-6 border-b border-gray-700">
                <h2 className="text-xl font-semibold text-white">Savings History</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-slate-800">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Savings ID
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Amount
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Returns
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Status
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Date
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Growth
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-700">
                    {filteredPurchases.map((purchase) => {
                      const growth = purchase.amount > 0 ? (((purchase.returns || 0) / purchase.amount) * 100) : 0;
                      return (
                        <tr key={purchase.id} className="hover:bg-slate-800/50">
                          <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-white">
                            {purchase.id}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                            ₹{purchase.amount.toLocaleString()}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-green-400">
                            ₹{(purchase.returns || 0).toLocaleString()}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                              purchase.status === 'active' 
                                ? 'bg-green-100 text-green-800' 
                                : purchase.status === 'completed'
                                ? 'bg-blue-100 text-blue-800'
                                : 'bg-gray-100 text-gray-800'
                            }`}>
                              {purchase.status}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                            {purchase.date}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm">
                            <span className={`font-medium ${growth >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                              {growth >= 0 ? '+' : ''}{growth.toFixed(1)}%
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </UnifiedCard>
          </div>
        </div>
      </UnifiedBackground>
      <Footer />
    </>
  );
}

export default CustomerSavings;
