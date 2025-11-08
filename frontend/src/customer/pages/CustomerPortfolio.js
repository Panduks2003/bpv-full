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

function CustomerPortfolio() {
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
  
  // Generate sample portfolio for the customer (will be replaced with real data)
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
  
  // Calculate portfolio metrics
  const totalInvested = customerPurchases.reduce((sum, p) => sum + p.amount, 0);
  const totalReturns = customerPurchases.reduce((sum, p) => sum + (p.returns || 0), 0);
  const totalValue = totalInvested + totalReturns;
  const totalGrowth = totalInvested > 0 ? ((totalReturns / totalInvested) * 100) : 0;

  // Portfolio allocation by category
  const portfolioAllocation = [
    { category: 'Renewable Energy', amount: totalInvested * 0.4, percentage: 40, color: 'bg-green-500' },
    { category: 'Sustainable Agriculture', amount: totalInvested * 0.25, percentage: 25, color: 'bg-blue-500' },
    { category: 'Green Technology', amount: totalInvested * 0.2, percentage: 20, color: 'bg-purple-500' },
    { category: 'Sustainable Consumer', amount: totalInvested * 0.15, percentage: 15, color: 'bg-orange-500' }
  ];

  // Performance data (mock monthly data)
  const performanceData = [
    { month: 'Jan', value: totalInvested * 0.8 },
    { month: 'Feb', value: totalInvested * 0.85 },
    { month: 'Mar', value: totalInvested * 0.9 },
    { month: 'Apr', value: totalInvested * 0.95 },
    { month: 'May', value: totalInvested * 1.02 },
    { month: 'Jun', value: totalValue }
  ];

  const [selectedTimeframe, setSelectedTimeframe] = useState('6M');

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
                  Portfolio Overview
                </h1>
                <p className="text-gray-400">
                  View your complete saving portfolio performance
                </p>
              </div>
              <div className="flex space-x-3">
                <UnifiedButton onClick={() => navigate('/customer/opportunities')}>
                  Explore Opportunities
                </UnifiedButton>
                <UnifiedButton onClick={() => navigate('/customer/savings')}>
                  View Savings
                </UnifiedButton>
              </div>
            </div>

            {/* Portfolio Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8" data-animate>
              <UnifiedCard className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">Total Portfolio Value</p>
                    <p className="text-3xl font-bold text-white">₹{totalValue.toLocaleString()}</p>
                    <p className={`text-sm ${totalGrowth >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                      {totalGrowth >= 0 ? '+' : ''}{totalGrowth.toFixed(1)}% overall
                    </p>
                  </div>
                  <div className="w-12 h-12 bg-green-500/20 rounded-lg flex items-center justify-center">
                    <svg className="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                    </svg>
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">Total Invested</p>
                    <p className="text-2xl font-bold text-white">₹{totalInvested.toLocaleString()}</p>
                    <p className="text-sm text-gray-400">{customerPurchases.length} savings</p>
                  </div>
                  <div className="w-12 h-12 bg-blue-500/20 rounded-lg flex items-center justify-center">
                    <svg className="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                    </svg>
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">Total Returns</p>
                    <p className="text-2xl font-bold text-green-400">₹{totalReturns.toLocaleString()}</p>
                    <p className="text-sm text-green-400">+{totalGrowth.toFixed(1)}% growth</p>
                  </div>
                  <div className="w-12 h-12 bg-purple-500/20 rounded-lg flex items-center justify-center">
                    <svg className="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                    </svg>
                  </div>
                </div>
              </UnifiedCard>

              <UnifiedCard className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-gray-400 text-sm">Monthly Return</p>
                    <p className="text-2xl font-bold text-orange-400">₹{Math.round(totalReturns / 6).toLocaleString()}</p>
                    <p className="text-sm text-gray-400">Average per month</p>
                  </div>
                  <div className="w-12 h-12 bg-orange-500/20 rounded-lg flex items-center justify-center">
                    <svg className="w-6 h-6 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  </div>
                </div>
              </UnifiedCard>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
              {/* Portfolio Allocation */}
              <UnifiedCard className="p-6" data-animate>
                <h2 className="text-xl font-semibold text-white mb-6">Portfolio Allocation</h2>
                <div className="space-y-4">
                  {portfolioAllocation.map((item, index) => (
                    <div key={index} className="space-y-2">
                      <div className="flex justify-between items-center">
                        <span className="text-gray-300 text-sm">{item.category}</span>
                        <span className="text-white font-medium">{item.percentage}%</span>
                      </div>
                      <div className="w-full bg-slate-700 rounded-full h-2">
                        <div 
                          className={`${item.color} h-2 rounded-full transition-all duration-500`}
                          style={{ width: `${item.percentage}%` }}
                        ></div>
                      </div>
                      <div className="flex justify-between items-center text-xs text-gray-500">
                        <span>₹{item.amount.toLocaleString()}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </UnifiedCard>

              {/* Performance Chart */}
              <UnifiedCard className="p-6" data-animate>
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-xl font-semibold text-white">Performance</h2>
                  <div className="flex space-x-2">
                    {['1M', '3M', '6M', '1Y'].map((period) => (
                      <button
                        key={period}
                        onClick={() => setSelectedTimeframe(period)}
                        className={`px-3 py-1 rounded text-sm transition-colors ${
                          selectedTimeframe === period
                            ? 'bg-green-500 text-white'
                            : 'bg-slate-700 text-gray-300 hover:bg-slate-600'
                        }`}
                      >
                        {period}
                      </button>
                    ))}
                  </div>
                </div>
                
                <div className="h-64 flex items-end space-x-2">
                  {performanceData.map((data, index) => {
                    const height = (data.value / Math.max(...performanceData.map(d => d.value))) * 100;
                    return (
                      <div key={index} className="flex-1 flex flex-col items-center">
                        <div 
                          className="w-full bg-gradient-to-t from-green-500 to-green-400 rounded-t transition-all duration-500 hover:from-green-400 hover:to-green-300"
                          style={{ height: `${height}%` }}
                        ></div>
                        <span className="text-xs text-gray-400 mt-2">{data.month}</span>
                      </div>
                    );
                  })}
                </div>
              </UnifiedCard>
            </div>

            {/* Recent Savings */}
            <UnifiedCard className="overflow-hidden" data-animate>
              <div className="p-6 border-b border-gray-700">
                <div className="flex justify-between items-center">
                  <h2 className="text-xl font-semibold text-white">Recent Savings</h2>
                  <UnifiedButton onClick={() => navigate('/customer/investments')}>
                    View All
                  </UnifiedButton>
                </div>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-slate-800">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Saving
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Amount
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Returns
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Performance
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Status
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-700">
                    {customerPurchases.slice(0, 5).map((purchase) => {
                      const growth = purchase.amount > 0 ? (((purchase.returns || 0) / purchase.amount) * 100) : 0;
                      return (
                        <tr key={purchase.id} className="hover:bg-slate-800/50">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm font-medium text-white">{purchase.id}</div>
                            <div className="text-sm text-gray-400">{purchase.date}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                            ₹{purchase.amount.toLocaleString()}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-green-400">
                            ₹{(purchase.returns || 0).toLocaleString()}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm">
                            <span className={`font-medium ${growth >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                              {growth >= 0 ? '+' : ''}{growth.toFixed(1)}%
                            </span>
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

export default CustomerPortfolio;
