import React, { useState } from 'react';
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

function CustomerOpportunities() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  useScrollAnimation();

  const [selectedCategory, setSelectedCategory] = useState('all');

  // Savings opportunities data
  const opportunities = [
    {
      id: 'INV001',
      title: 'Solar Energy Infrastructure',
      category: 'renewable',
      minSavings: 50000,
      expectedReturn: 12.5,
      duration: '24 months',
      riskLevel: 'Medium',
      description: 'Invest in large-scale solar panel installations across rural India',
      raised: 2500000,
      target: 5000000,
      investors: 45,
      image: '/new-logo.png'
    },
    {
      id: 'INV002',
      title: 'Organic Farming Collective',
      category: 'agriculture',
      minSavings: 25000,
      expectedReturn: 15.2,
      duration: '18 months',
      riskLevel: 'Low',
      description: 'Support sustainable organic farming practices and direct-to-consumer sales',
      raised: 1800000,
      target: 3000000,
      investors: 78,
      image: '/new-logo.png'
    },
    {
      id: 'INV003',
      title: 'Green Tech Startup Fund',
      category: 'technology',
      minSavings: 100000,
      expectedReturn: 18.7,
      duration: '36 months',
      riskLevel: 'High',
      description: 'Early-stage savings in innovative green technology startups',
      raised: 4200000,
      target: 8000000,
      investors: 32,
      image: '/new-logo.png'
    },
    {
      id: 'INV004',
      title: 'Waste-to-Energy Plant',
      category: 'renewable',
      minSavings: 75000,
      expectedReturn: 14.3,
      duration: '30 months',
      riskLevel: 'Medium',
      description: 'Convert municipal waste into clean energy for urban communities',
      raised: 3100000,
      target: 6000000,
      investors: 56,
      image: '/new-logo.png'
    },
    {
      id: 'INV005',
      title: 'Sustainable Fashion Brand',
      category: 'consumer',
      minSavings: 30000,
      expectedReturn: 16.8,
      duration: '20 months',
      riskLevel: 'Medium',
      description: 'Eco-friendly clothing brand using recycled materials and ethical practices',
      raised: 950000,
      target: 2000000,
      investors: 89,
      image: '/new-logo.png'
    },
    {
      id: 'INV006',
      title: 'Electric Vehicle Charging Network',
      category: 'technology',
      minSavings: 60000,
      expectedReturn: 13.9,
      duration: '28 months',
      riskLevel: 'Medium',
      description: 'Build comprehensive EV charging infrastructure across major cities',
      raised: 2800000,
      target: 5500000,
      investors: 67,
      image: '/new-logo.png'
    }
  ];

  const categories = [
    { id: 'all', label: 'All Opportunities' },
    { id: 'renewable', label: 'Renewable Energy' },
    { id: 'agriculture', label: 'Sustainable Agriculture' },
    { id: 'technology', label: 'Green Technology' },
    { id: 'consumer', label: 'Sustainable Consumer' }
  ];

  const filteredOpportunities = opportunities.filter(opp => 
    selectedCategory === 'all' || opp.category === selectedCategory
  );

  const getRiskColor = (risk) => {
    switch(risk) {
      case 'Low': return 'text-green-400 bg-green-400/20';
      case 'Medium': return 'text-yellow-400 bg-yellow-400/20';
      case 'High': return 'text-red-400 bg-red-400/20';
      default: return 'text-gray-400 bg-gray-400/20';
    }
  };

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
                  Savings Opportunities
                </h1>
                <p className="text-gray-400">
                  Discover sustainable ventures and savings options
                </p>
              </div>
              <UnifiedButton onClick={() => navigate('/customer/savings')}>
                View My Savings
              </UnifiedButton>
            </div>

            {/* Category Filter */}
            <div className="flex flex-wrap gap-4 mb-8" data-animate>
              {categories.map((category) => (
                <button
                  key={category.id}
                  onClick={() => setSelectedCategory(category.id)}
                  className={`px-4 py-2 rounded-lg font-medium transition-all duration-200 ${
                    selectedCategory === category.id
                      ? 'bg-green-500 text-white'
                      : 'bg-slate-700 text-gray-300 hover:bg-slate-600'
                  }`}
                >
                  {category.label}
                </button>
              ))}
            </div>

            {/* Opportunities Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" data-animate>
              {filteredOpportunities.map((opportunity) => {
                const progressPercentage = (opportunity.raised / opportunity.target) * 100;
                
                return (
                  <UnifiedCard key={opportunity.id} className="overflow-hidden hover:transform hover:scale-105 transition-all duration-300">
                    <div className="relative">
                      <img 
                        src={opportunity.image} 
                        alt={opportunity.title}
                        className="w-full h-48 object-cover"
                      />
                      <div className="absolute top-4 right-4">
                        <span className={`px-2 py-1 rounded-full text-xs font-semibold ${getRiskColor(opportunity.riskLevel)}`}>
                          {opportunity.riskLevel} Risk
                        </span>
                      </div>
                    </div>
                    
                    <div className="p-6">
                      <h3 className="text-xl font-bold text-white mb-2">{opportunity.title}</h3>
                      <p className="text-gray-400 text-sm mb-4 line-clamp-2">{opportunity.description}</p>
                      
                      <div className="space-y-3 mb-4">
                        <div className="flex justify-between items-center">
                          <span className="text-gray-400 text-sm">Expected Return</span>
                          <span className="text-green-400 font-semibold">{opportunity.expectedReturn}%</span>
                        </div>
                        
                        <div className="flex justify-between items-center">
                          <span className="text-gray-400 text-sm">Duration</span>
                          <span className="text-white font-medium">{opportunity.duration}</span>
                        </div>
                        
                        <div className="flex justify-between items-center">
                          <span className="text-gray-400 text-sm">Min Savings</span>
                          <span className="text-white font-medium">₹{opportunity.minSavings.toLocaleString()}</span>
                        </div>
                      </div>

                      {/* Progress Bar */}
                      <div className="mb-4">
                        <div className="flex justify-between items-center mb-2">
                          <span className="text-gray-400 text-sm">Funding Progress</span>
                          <span className="text-white text-sm">{progressPercentage.toFixed(1)}%</span>
                        </div>
                        <div className="w-full bg-slate-700 rounded-full h-2">
                          <div 
                            className="bg-gradient-to-r from-green-400 to-blue-500 h-2 rounded-full transition-all duration-300"
                            style={{ width: `${Math.min(progressPercentage, 100)}%` }}
                          ></div>
                        </div>
                        <div className="flex justify-between items-center mt-2 text-xs text-gray-500">
                          <span>₹{(opportunity.raised / 1000000).toFixed(1)}M raised</span>
                          <span>{opportunity.investors} investors</span>
                        </div>
                      </div>

                      <div className="flex space-x-2">
                        <UnifiedButton 
                          className="flex-1 text-sm py-2"
                          onClick={() => {/* Handle save */}}
                        >
                          Save Now
                        </UnifiedButton>
                        <button className="px-4 py-2 border border-gray-600 text-gray-300 rounded-lg hover:bg-slate-700 transition-colors text-sm">
                          Learn More
                        </button>
                      </div>
                    </div>
                  </UnifiedCard>
                );
              })}
            </div>

            {/* Saving Stats */}
            <div className="mt-12 grid grid-cols-1 md:grid-cols-4 gap-6" data-animate>
              <UnifiedCard className="p-6 text-center">
                <div className="w-12 h-12 bg-blue-500/20 rounded-lg flex items-center justify-center mx-auto mb-4">
                  <svg className="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                  </svg>
                </div>
                <p className="text-2xl font-bold text-white mb-1">{opportunities.length}</p>
                <p className="text-gray-400 text-sm">Active Opportunities</p>
              </UnifiedCard>

              <UnifiedCard className="p-6 text-center">
                <div className="w-12 h-12 bg-green-500/20 rounded-lg flex items-center justify-center mx-auto mb-4">
                  <svg className="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                  </svg>
                </div>
                <p className="text-2xl font-bold text-white mb-1">₹15.4M</p>
                <p className="text-gray-400 text-sm">Total Raised</p>
              </UnifiedCard>

              <UnifiedCard className="p-6 text-center">
                <div className="w-12 h-12 bg-purple-500/20 rounded-lg flex items-center justify-center mx-auto mb-4">
                  <svg className="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
                <p className="text-2xl font-bold text-white mb-1">367</p>
                <p className="text-gray-400 text-sm">Total Investors</p>
              </UnifiedCard>

              <UnifiedCard className="p-6 text-center">
                <div className="w-12 h-12 bg-orange-500/20 rounded-lg flex items-center justify-center mx-auto mb-4">
                  <svg className="w-6 h-6 text-orange-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                  </svg>
                </div>
                <p className="text-2xl font-bold text-white mb-1">15.2%</p>
                <p className="text-gray-400 text-sm">Avg. Return</p>
              </UnifiedCard>
            </div>
          </div>
        </div>
      </UnifiedBackground>
      <Footer />
    </>
  );
}

export default CustomerOpportunities;
