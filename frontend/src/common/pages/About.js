import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../components/SharedTheme";

function AboutClean() {
  useScrollAnimation();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('about');

  const tabs = [
    { id: 'about', label: 'About Us' },
    { id: 'mission', label: 'Mission' },
    { id: 'vision', label: 'Vision' },
    { id: 'values', label: 'Values' }
  ];
  return (
    <>
      <SharedStyles />
      <div className="min-h-screen bg-white">
        
        {/* Hero Section - Matching Ventures/Contact Style */}
        <div className="relative min-h-[60vh] bg-gradient-to-br from-slate-50 via-orange-50/30 to-yellow-50/20 overflow-hidden">
          {/* Background Elements */}
          <div className="absolute inset-0 -z-10">
            {/* Floating Orbs */}
            <div className="absolute top-1/4 right-1/5 w-84 h-84 bg-gradient-to-r from-orange-500/20 to-yellow-500/20 rounded-full blur-3xl animate-float" />
            <div className="absolute bottom-1/4 left-1/4 w-76 h-76 bg-gradient-to-r from-yellow-500/20 to-orange-400/20 rounded-full blur-3xl animate-float" style={{ animationDelay: '3s' }} />
            <div className="absolute top-3/5 right-2/5 w-68 h-68 bg-gradient-to-r from-orange-800/15 to-yellow-600/15 rounded-full blur-3xl animate-float" style={{ animationDelay: '6s' }} />
            
            {/* Grid Pattern */}
            <div className="absolute inset-0 opacity-10">
              <div className="w-full h-full" style={{
                backgroundImage: `
                  linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px),
                  linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)
                `,
                backgroundSize: '50px 50px'
              }} />
            </div>
            
            {/* Floating Particles */}
            <div className="absolute top-1/5 left-4/5 w-1.5 h-1.5 bg-orange-300 rounded-full animate-ping" />
            <div className="absolute top-4/5 right-1/6 w-2 h-2 bg-yellow-300 rounded-full animate-ping" style={{ animationDelay: '2.5s' }} />
            <div className="absolute bottom-1/6 left-2/5 w-1 h-1 bg-orange-400 rounded-full animate-ping" style={{ animationDelay: '5s' }} />
            <div className="absolute top-2/5 left-1/6 w-1.5 h-1.5 bg-yellow-400 rounded-full animate-ping" style={{ animationDelay: '7.5s' }} />
          </div>

          {/* Main BackgroundOverlays */}
          <div className="absolute inset-0 bg-gradient-to-t from-slate-900/30 via-transparent to-slate-900/10" />
          <div className="absolute inset-0 bg-gradient-to-r from-orange-600/8 via-transparent to-yellow-500/8" />

          <div className="relative flex items-center justify-center min-h-[60vh] px-4 sm:px-6 lg:px-8">
            <div className="text-center max-w-5xl mx-auto">
              <div className="inline-flex items-center gap-2 px-4 sm:px-6 py-2 sm:py-3 bg-white/95 rounded-full mb-6 sm:mb-8 border border-orange-200 hover:border-orange-300 transition-all duration-300 hover:scale-105 group shadow-md">
                <span className="w-3 h-3 rounded-full bg-gradient-to-r from-orange-400 to-yellow-400 animate-pulse group-hover:animate-spin" />
                <span className="text-xs sm:text-sm font-medium text-slate-800 group-hover:text-slate-900 transition-colors">About Our Company</span>
              </div>
              
              <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-extrabold mb-8 sm:mb-12 leading-tight">
                <span className="text-slate-900">About </span>
                <span className="bg-gradient-to-r from-orange-600 via-yellow-600 to-orange-500 bg-clip-text text-transparent">
                  BrightPlanet
                </span>
                <span className="text-slate-900"> Ventures</span>
              </h1>
              
              <div className="relative max-w-4xl mx-auto">
                <p className="text-base sm:text-lg md:text-xl lg:text-2xl text-slate-800 leading-relaxed bg-white/95 rounded-xl sm:rounded-2xl p-4 sm:p-6 lg:p-8 shadow-lg font-medium border border-slate-200">
                  Transforming lives through <strong className="text-orange-600">innovative solutions</strong> and{' '}
                  <strong className="text-yellow-600">exceptional service</strong> in <strong className="text-orange-600">Belagavi</strong>
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="max-w-7xl mx-auto px-4 py-12 sm:py-16 sm:px-6 lg:px-8">
          
          {/* Navigation Tabs */}
          <div className="flex justify-center mb-12 sm:mb-16">
            <div className="inline-flex bg-slate-100 rounded-lg p-1 w-full max-w-2xl overflow-x-auto">
              {tabs.map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex-1 sm:flex-none px-3 sm:px-4 lg:px-6 py-2 sm:py-3 rounded-md font-medium transition-all duration-200 text-xs sm:text-sm lg:text-base whitespace-nowrap text-center ${
                    activeTab === tab.id
                      ? 'bg-white text-slate-900 shadow-sm'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          {/* Content Sections */}
          {activeTab === 'about' && (
            <div className="max-w-4xl mx-auto">
              {/* Company Overview */}
              <section className="text-center">
                <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-slate-900 mb-6 sm:mb-8">
                  Who We Are
                </h2>
                <div className="prose prose-xl max-w-none">
                  <p className="text-base sm:text-lg lg:text-xl text-slate-700 leading-relaxed mb-4 sm:mb-6">
                    <strong className="text-orange-600">Brightplanet Ventures Pvt Ltd</strong> is a dynamic multi-service company 
                    based in <strong className="text-orange-600">Belagavi</strong>, dedicated to simplifying everyday life by providing a comprehensive 
                    range of products and services under one trusted brand.
                  </p>
                  <p className="text-base sm:text-lg lg:text-xl text-slate-700 leading-relaxed">
                    We bridge the gap between innovation and accessibility, making modern solutions 
                    available to individuals, families, and businesses throughout our community.
                  </p>
                </div>
              </section>
            </div>
          )}

          {activeTab === 'mission' && (
            <div className="max-w-4xl mx-auto text-center">
              <div className="w-16 h-16 sm:w-20 sm:h-20 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-6 sm:mb-8">
                <svg className="w-8 h-8 sm:w-10 sm:h-10 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-slate-900 mb-6 sm:mb-8">Our Mission</h2>
              <div className="prose prose-xl max-w-none">
                <p className="text-base sm:text-lg lg:text-xl text-slate-700 leading-relaxed mb-4 sm:mb-6">
                  At Brightplanet Ventures Pvt Ltd, our mission is to <strong className="text-orange-600">simplify life</strong> 
                  for our customers by offering diverse, high-quality services and products through a single trusted platform.
                </p>
                <p className="text-base sm:text-lg lg:text-xl text-slate-700 leading-relaxed mb-4 sm:mb-6">
                  We are committed to <strong className="text-orange-600">excellence and affordability</strong>, ensuring that 
                  every individual in Belagavi can access modern solutions for their household, lifestyle, and business needs.
                </p>
                <p className="text-base sm:text-lg lg:text-xl text-slate-700 leading-relaxed">
                  By fostering innovation, building strong customer relationships, and creating opportunities for local communities, 
                  we strive to drive sustainable growth while making Brightplanet Ventures a symbol of 
                  <strong className="text-orange-600"> trust, convenience, and progress</strong>.
                </p>
              </div>
            </div>
          )}

          {activeTab === 'vision' && (
            <div className="max-w-4xl mx-auto text-center">
              <div className="w-16 h-16 sm:w-20 sm:h-20 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-6 sm:mb-8">
                <svg className="w-8 h-8 sm:w-10 sm:h-10 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
              </div>
              <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-slate-900 mb-6 sm:mb-8">Our Vision</h2>
              <div className="prose prose-xl max-w-none">
                <p className="text-base sm:text-lg lg:text-xl text-slate-700 leading-relaxed mb-4 sm:mb-6">
                  To become <strong className="text-blue-600">Belagavi's most trusted and innovative</strong> multi-service company, 
                  recognized for delivering convenience, reliability, and value.
                </p>
                <p className="text-base sm:text-lg lg:text-xl text-slate-700 leading-relaxed mb-4 sm:mb-6">
                  We aspire to be a <strong className="text-blue-600">one-stop destination</strong> that empowers communities, 
                  creates opportunities, and contributes to the overall growth of Belagavi through innovation, trust, and sustainable practices.
                </p>
                <p className="text-base sm:text-lg lg:text-xl text-slate-700 leading-relaxed">
                  Our vision extends beyond business success to <strong className="text-blue-600">community transformation</strong>, 
                  where every service we provide contributes to building a more connected, efficient, and prosperous society.
                </p>
              </div>
            </div>
          )}

          {activeTab === 'values' && (
            <div className="max-w-5xl mx-auto">
              <div className="text-center mb-8 sm:mb-12">
                <div className="w-16 h-16 sm:w-20 sm:h-20 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-6 sm:mb-8">
                  <svg className="w-8 h-8 sm:w-10 sm:h-10 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                  </svg>
                </div>
                <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-slate-900 mb-3 sm:mb-4">Our Core Values</h2>
                <p className="text-base sm:text-lg lg:text-xl text-slate-600">The principles that guide everything we do</p>
              </div>
              
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6 lg:gap-8">
                {[
                  {
                    title: "Customer First",
                    description: "Prioritizing customer needs with quality and convenience.",
                    color: "border-red-200 bg-red-50"
                  },
                  {
                    title: "Trust & Transparency",
                    description: "Building lasting relationships through honesty and reliability.",
                    color: "border-blue-200 bg-blue-50"
                  },
                  {
                    title: "Community Growth",
                    description: "Supporting local development and creating opportunities.",
                    color: "border-yellow-200 bg-yellow-50"
                  },
                  {
                    title: "Affordability & Accessibility",
                    description: "Ensuring everyone can access quality services.",
                    color: "border-purple-200 bg-purple-50"
                  },
                  {
                    title: "Integrity & Responsibility",
                    description: "Acting with accountability towards customers, employees, and society.",
                    color: "border-indigo-200 bg-indigo-50"
                  },
                  {
                    title: "Sustainability",
                    description: "Promoting eco-friendly and responsible growth.",
                    color: "border-emerald-200 bg-emerald-50"
                  }
                ].map((value, index) => (
                  <div key={index} className={`w-full p-4 sm:p-5 lg:p-6 rounded-lg sm:rounded-xl border-2 ${value.color} hover:shadow-lg transition-all duration-300 hover:-translate-y-1`}>
                    <div className="text-center mb-4">
                      <div className="w-10 h-10 sm:w-12 sm:h-12 bg-slate-900 text-white rounded-full flex items-center justify-center text-base sm:text-lg font-bold mx-auto mb-2 sm:mb-3">
                        {index + 1}
                      </div>
                      <h3 className="text-base sm:text-lg lg:text-xl font-semibold text-slate-900 mb-2 sm:mb-3">{value.title}</h3>
                    </div>
                    <p className="text-xs sm:text-sm lg:text-base text-slate-700 text-center leading-relaxed">{value.description}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Call to Action */}
          <section className="mt-16 sm:mt-20 text-center">
            <div className="bg-slate-50 rounded-lg sm:rounded-xl lg:rounded-2xl p-6 sm:p-8 lg:p-12">
              <h2 className="text-2xl sm:text-3xl font-bold text-slate-900 mb-4 sm:mb-6">
                Ready to Experience Excellence?
              </h2>
              <p className="text-base sm:text-lg lg:text-xl text-slate-600 mb-6 sm:mb-8 max-w-2xl mx-auto">
                Join thousands of satisfied customers who trust BrightPlanet Ventures 
                for their everyday needs in Belagavi.
              </p>
              <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center items-center">
                <UnifiedButton 
                  variant="primary" 
                  className="w-full sm:w-auto px-6 sm:px-8 py-3 sm:py-3.5 text-sm sm:text-base min-h-[44px] sm:min-h-[48px]"
                  onClick={() => navigate('/contact')}
                >
                  Contact Us Today
                </UnifiedButton>
                <UnifiedButton 
                  variant="secondary" 
                  className="w-full sm:w-auto px-6 sm:px-8 py-3 sm:py-3.5 text-sm sm:text-base min-h-[44px] sm:min-h-[48px]"
                  onClick={() => navigate('/ventures')}
                >
                  Explore Services
                </UnifiedButton>
              </div>
            </div>
          </section>
        </div>
      </div>
    </>
  );
}

export default AboutClean;
