import React, { useState, useEffect, useMemo, useRef } from 'react';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../components/SharedTheme";

// Venture data with comprehensive information
const venturesData = [
  {
    id: 1,
    name: "Electronics Hub",
    category: "Technology",
    description: "Premium electronics and smart devices with cutting-edge technology solutions for modern living.",
    longDescription: "Our Electronics Hub offers the latest in consumer electronics, from smartphones and laptops to smart home devices and IoT solutions. We partner with leading brands to bring you premium quality products with comprehensive warranty and expert support.",
    icon: "⚡",
    color: "#8b5cf6",
    gradient: "from-purple-600 to-blue-600",
    stats: {
      customers: "15+",
      revenue: "₹2.5Cr",
      growth: "+25%",
      satisfaction: "98%",
      marketShare: "15%"
    },
    features: ["Premium Brands", "Expert Support", "Extended Warranty", "Latest Tech"],
    certifications: ["ISO 9001", "CE Certified"],
    image: "/api/placeholder/400/300",
    gallery: ["/api/placeholder/300/200", "/api/placeholder/300/200", "/api/placeholder/300/200"]
  },
  {
    id: 2,
    name: "Furniture Studio",
    category: "Lifestyle",
    description: "Custom furniture and interior design solutions crafted with premium materials and modern aesthetics.",
    longDescription: "Transform your living spaces with our curated collection of premium furniture. From custom designs to ready-made pieces, we offer quality craftsmanship with sustainable materials and modern aesthetics that reflect your personal style.",
    icon: "🏡",
    color: "#10b981",
    gradient: "from-emerald-600 to-teal-600",
    stats: {
      customers: "12+",
      revenue: "₹1.8Cr",
      growth: "+18%",
      satisfaction: "96%",
      marketShare: "22%"
    },
    features: ["Custom Design", "Quality Materials", "Free Assembly", "Lifetime Support"],
    certifications: ["FSC Certified", "Green Guard"],
    image: "/api/placeholder/400/300",
    gallery: ["/api/placeholder/300/200", "/api/placeholder/300/200", "/api/placeholder/300/200"]
  },
  {
    id: 3,
    name: "Home Appliances",
    category: "Home Tech",
    description: "Energy-efficient home appliances with smart controls and sustainable technology solutions.",
    longDescription: "Upgrade your home with our range of energy-efficient appliances featuring smart controls and IoT connectivity. From kitchen essentials to laundry solutions, our products combine functionality with sustainability.",
    icon: "🔧",
    color: "#f97316",
    gradient: "from-orange-600 to-red-500",
    stats: {
      customers: "8+",
      revenue: "₹2.1Cr",
      growth: "+22%",
      satisfaction: "94%",
      marketShare: "18%"
    },
    features: ["Energy Star", "Smart Controls", "Installation", "Maintenance"],
    certifications: ["Energy Star", "BEE 5 Star"],
    image: "/api/placeholder/400/300",
    gallery: ["/api/placeholder/300/200", "/api/placeholder/300/200", "/api/placeholder/300/200"]
  },
  {
    id: 4,
    name: "Fashion Forward",
    category: "Fashion",
    description: "Trendy fashion collections with sustainable materials and contemporary designs for all occasions.",
    longDescription: "Discover your unique style with our diverse collection of contemporary fashion. From casual wear to formal attire, we offer sustainable fashion choices that make a statement while respecting the environment.",
    icon: "✨",
    color: "#eab308",
    gradient: "from-yellow-600 to-orange-500",
    stats: {
      customers: "20+",
      revenue: "₹3.2Cr",
      growth: "+30%",
      satisfaction: "92%",
      marketShare: "12%"
    },
    features: ["Latest Trends", "Sustainable Materials", "Size Guide", "Easy Returns"],
    certifications: ["GOTS Certified", "Fair Trade"],
    image: "/api/placeholder/400/300",
    gallery: ["/api/placeholder/300/200", "/api/placeholder/300/200", "/api/placeholder/300/200"]
  },
  {
    id: 5,
    name: "Fresh Mart",
    category: "Essential",
    description: "Premium groceries and fresh produce delivered with convenience and quality assurance.",
    longDescription: "Experience the convenience of premium grocery shopping with our Fresh Mart. We source the finest produce directly from farms and offer a comprehensive range of organic and conventional products delivered fresh to your doorstep.",
    icon: "🌱",
    color: "#22c55e",
    gradient: "from-green-600 to-emerald-500",
    stats: {
      customers: "25+",
      revenue: "₹4.5Cr",
      growth: "+35%",
      satisfaction: "97%",
      marketShare: "25%"
    },
    features: ["Fresh Produce", "Fast Delivery", "Organic Options", "Best Prices"],
    certifications: ["Organic Certified", "FSSAI Licensed"],
    image: "/api/placeholder/400/300",
    gallery: ["/api/placeholder/300/200", "/api/placeholder/300/200", "/api/placeholder/300/200"]
  },
  {
    id: 6,
    name: "Adventure Tours",
    category: "Travel",
    description: "Curated travel experiences and adventure packages with expert guides and premium services.",
    longDescription: "Embark on unforgettable journeys with our curated travel experiences. From adventure tours to luxury getaways, we create personalized itineraries that showcase the best destinations with expert local guides and premium accommodations.",
    icon: "🌍",
    color: "#3b82f6",
    gradient: "from-blue-600 to-indigo-500",
    stats: {
      customers: "5+",
      revenue: "₹1.5Cr",
      growth: "+28%",
      satisfaction: "95%",
      marketShare: "8%"
    },
    features: ["Custom Itineraries", "Expert Guides", "24/7 Support", "Best Deals"],
    certifications: ["IATA Certified", "Ministry of Tourism"],
    image: "/api/placeholder/400/300",
    gallery: ["/api/placeholder/300/200", "/api/placeholder/300/200", "/api/placeholder/300/200"]
  },
  {
    id: 7,
    name: "Prime Properties",
    category: "Real Estate",
    description: "Premium real estate development with sustainable construction and modern amenities.",
    longDescription: "Build your dream home with our premium real estate developments. We focus on sustainable construction practices, modern amenities, and strategic locations to create communities that enhance quality of life while ensuring excellent investment returns.",
    icon: "🏢",
    color: "#6366f1",
    gradient: "from-indigo-600 to-purple-500",
    stats: {
      customers: "3+",
      revenue: "₹8.7Cr",
      growth: "+15%",
      satisfaction: "99%",
      marketShare: "5%"
    },
    features: ["Quality Construction", "Green Building", "Prime Locations", "Transparent Process"],
    certifications: ["RERA Registered", "Green Building Certified"],
    image: "/api/placeholder/400/300",
    gallery: ["/api/placeholder/300/200", "/api/placeholder/300/200", "/api/placeholder/300/200"]
  }
];

// Animated Counter Component
const AnimatedCounter = ({ end, duration = 2000, suffix = "" }) => {
  const [count, setCount] = useState(0);
  const [isVisible, setIsVisible] = useState(false);
  const ref = useRef();

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !isVisible) {
          setIsVisible(true);
        }
      },
      { threshold: 0.1 }
    );

    if (ref.current) {
      observer.observe(ref.current);
    }

    return () => observer.disconnect();
  }, [isVisible]);

  useEffect(() => {
    if (!isVisible) return;

    let startTime;
    const endValue = parseInt(end.replace(/[^\d]/g, ''));
    
    const animate = (timestamp) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      
      setCount(Math.floor(progress * endValue));
      
      if (progress < 1) {
        requestAnimationFrame(animate);
      }
    };
    
    requestAnimationFrame(animate);
  }, [isVisible, end, duration]);

  return (
    <span ref={ref}>
      {count}{suffix}
    </span>
  );
};

// Professional Venture Card Component
const VentureCard = ({ venture, onClick, isSelected }) => {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div 
      className={`group cursor-pointer transition-all duration-500 hover:scale-[1.02] bg-white/95 border border-slate-200 rounded-2xl shadow-xl hover:shadow-2xl ${
        isSelected ? 'ring-2 ring-orange-500/50 scale-[1.02]' : ''
      }`}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onClick={() => onClick(venture)}
    >
      {/* Subtle Colored Accent */}
      <div 
        className="absolute inset-0 opacity-[0.15] rounded-2xl"
        style={{
          background: `linear-gradient(135deg, ${venture.color}20, transparent 60%)`
        }}
      />
      
      {/* Content */}
      <div className="relative p-3 sm:p-4 lg:p-6 xl:p-8 h-full flex flex-col">
        {/* Professional Header */}
        <div className="flex items-start justify-between mb-3 sm:mb-4 lg:mb-6">
          <div 
            className="w-8 h-8 sm:w-10 sm:h-10 lg:w-12 lg:h-12 xl:w-14 xl:h-14 rounded-lg sm:rounded-xl lg:rounded-2xl flex items-center justify-center text-sm sm:text-base lg:text-lg xl:text-xl shadow-lg"
            style={{ 
              backgroundColor: `${venture.color}15`, 
              border: `1px solid ${venture.color}30`,
              boxShadow: `0 4px 20px ${venture.color}20`
            }}
          >
            {venture.icon}
          </div>
          <div className="text-right">
            <div 
              className="text-[10px] sm:text-xs px-1.5 sm:px-2 lg:px-3 py-0.5 sm:py-1 lg:py-1.5 rounded-md sm:rounded-lg lg:rounded-xl font-semibold tracking-wide"
              style={{ 
                backgroundColor: `${venture.color}10`,
                color: venture.color,
                border: `1px solid ${venture.color}20`
              }}
            >
              {venture.category}
            </div>
            <div className="text-[10px] sm:text-xs text-emerald-400 font-bold mt-1 sm:mt-2 bg-emerald-400/10 px-1 sm:px-1.5 lg:px-2 py-0.5 sm:py-1 rounded-md sm:rounded-lg">
              {venture.stats.growth}
            </div>
          </div>
        </div>

        {/* Title and Description */}
        <div className="flex-1 mb-3 sm:mb-4 lg:mb-6">
          <h3 className="text-base sm:text-lg lg:text-xl font-bold text-slate-900 mb-1.5 sm:mb-2 lg:mb-3 leading-tight">{venture.name}</h3>
          <p className="text-slate-700 text-[10px] sm:text-xs lg:text-sm leading-relaxed font-light">{venture.description}</p>
        </div>

        {/* Professional Stats Grid */}
        <div className="grid grid-cols-2 gap-2 sm:gap-3 lg:gap-4 mb-3 sm:mb-4 lg:mb-6">
          <div className="bg-white/90 border border-slate-200 rounded-lg sm:rounded-xl p-2 sm:p-3 lg:p-4 text-center shadow-sm">
            <div className="font-bold text-sm sm:text-base lg:text-lg mb-1" style={{ color: venture.color }}>
              {venture.stats.customers}
            </div>
            <div className="text-[9px] sm:text-[10px] lg:text-xs text-slate-600 font-medium">Customers</div>
          </div>
          <div className="bg-white/90 border border-slate-200 rounded-lg sm:rounded-xl p-2 sm:p-3 lg:p-4 text-center shadow-sm">
            <div className="font-bold text-sm sm:text-base lg:text-lg mb-1" style={{ color: venture.color }}>
              {venture.stats.revenue}
            </div>
            <div className="text-[9px] sm:text-[10px] lg:text-xs text-slate-600 font-medium">Revenue</div>
          </div>
        </div>

        {/* Professional Features */}
        <div className="flex flex-wrap gap-1 sm:gap-1.5 lg:gap-2 mb-3 sm:mb-4 lg:mb-6">
          {venture.features.slice(0, 2).map((feature, idx) => (
            <span 
              key={idx}
              className="text-[9px] sm:text-[10px] lg:text-xs px-1.5 sm:px-2 lg:px-3 py-0.5 sm:py-1 lg:py-1.5 rounded-md sm:rounded-lg bg-white/80 text-slate-700 border border-slate-200 font-medium"
            >
              {feature}
            </span>
          ))}
        </div>

        {/* Professional Action Indicator */}
        <div className={`transition-all duration-300 ${isHovered ? 'opacity-100 translate-y-0' : 'opacity-70 translate-y-1'}`}>
          <div className="flex items-center justify-between p-1.5 sm:p-2 lg:p-3 bg-white/80 rounded-md sm:rounded-lg lg:rounded-xl border border-slate-200">
            <span className="text-xs sm:text-sm font-medium text-slate-900">View Details</span>
            <div className="w-6 h-6 sm:w-8 sm:h-8 bg-gradient-to-r from-orange-500/20 to-yellow-500/20 rounded-lg flex items-center justify-center">
              <svg className="w-3 h-3 sm:w-4 sm:h-4 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// Venture Detail Modal
const VentureDetailModal = ({ venture, isOpen, onClose }) => {
  if (!isOpen || !venture) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/70 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal */}
      <div className="relative bg-white/95 border border-slate-200 rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto shadow-2xl mx-4">
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 z-10 w-10 h-10 bg-black/50 hover:bg-black/70 rounded-full flex items-center justify-center text-white transition-colors"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <div className="p-8">
          {/* Header */}
          <div className="flex items-start gap-6 mb-8">
            <div 
              className="w-20 h-20 rounded-2xl flex items-center justify-center text-4xl"
              style={{ backgroundColor: `${venture.color}20`, border: `2px solid ${venture.color}40` }}
            >
              {venture.icon}
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-4 mb-2">
                <h2 className="text-3xl font-bold text-slate-900">{venture.name}</h2>
                <span 
                  className="px-3 py-1 rounded-full text-sm font-semibold"
                  style={{ 
                    backgroundColor: `${venture.color}20`,
                    color: venture.color,
                    border: `1px solid ${venture.color}40`
                  }}
                >
                  {venture.category}
                </span>
              </div>
              <p className="text-slate-700 text-lg leading-relaxed">{venture.longDescription}</p>
            </div>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 sm:gap-4 mb-6 sm:mb-8">
            <div className="bg-white/95 border border-slate-200 rounded-xl p-4 text-center shadow-sm">
              <div className="text-2xl font-bold mb-1" style={{ color: venture.color }}>
                {venture.stats.customers}
              </div>
              <div className="text-slate-600 text-sm">Customers</div>
            </div>
            <div className="bg-white/95 border border-slate-200 rounded-xl p-4 text-center shadow-sm">
              <div className="text-2xl font-bold mb-1" style={{ color: venture.color }}>
                {venture.stats.revenue}
              </div>
              <div className="text-slate-600 text-sm">Revenue</div>
            </div>
            <div className="bg-white/95 border border-slate-200 rounded-xl p-4 text-center shadow-sm">
              <div className="text-2xl font-bold mb-1" style={{ color: venture.color }}>
                {venture.stats.growth}
              </div>
              <div className="text-slate-600 text-sm">Growth</div>
            </div>
            <div className="bg-white/95 border border-slate-200 rounded-xl p-4 text-center shadow-sm">
              <div className="text-2xl font-bold mb-1" style={{ color: venture.color }}>
                {venture.stats.satisfaction}
              </div>
              <div className="text-slate-600 text-sm">Satisfaction</div>
            </div>
            <div className="bg-white/95 border border-slate-200 rounded-xl p-4 text-center shadow-sm">
              <div className="text-2xl font-bold mb-1" style={{ color: venture.color }}>
                {venture.stats.marketShare}
              </div>
              <div className="text-slate-600 text-sm">Market Share</div>
            </div>
          </div>

          {/* Features and Certifications */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-8">
            <div>
              <h3 className="text-xl font-bold text-slate-900 mb-4">Key Features</h3>
              <div className="space-y-3">
                {venture.features.map((feature, idx) => (
                  <div key={idx} className="flex items-center gap-3">
                    <div 
                      className="w-2 h-2 rounded-full"
                      style={{ backgroundColor: venture.color }}
                    />
                    <span className="text-slate-700">{feature}</span>
                  </div>
                ))}
              </div>
            </div>
            <div>
              <h3 className="text-xl font-bold text-slate-900 mb-4">Certifications</h3>
              <div className="space-y-3">
                {venture.certifications.map((cert, idx) => (
                  <div key={idx} className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-green-500/20 rounded-lg flex items-center justify-center">
                      <svg className="w-4 h-4 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    <span className="text-slate-700">{cert}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const Ventures = () => {
  const [selectedVenture, setSelectedVenture] = useState(null);
  const [filter, setFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  
  useScrollAnimation();

  // Filter ventures based on category and search
  const filteredVentures = useMemo(() => {
    return venturesData.filter(venture => {
      const matchesFilter = filter === 'all' || venture.category.toLowerCase() === filter.toLowerCase();
      const matchesSearch = venture.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           venture.description.toLowerCase().includes(searchTerm.toLowerCase());
      return matchesFilter && matchesSearch;
    });
  }, [filter, searchTerm]);

  // Calculate total stats
  const totalStats = useMemo(() => {
    return {
      customers: 50,
      promoters: 49,
      support: '24x7',
      ventures: venturesData.length
    };
  }, []);

  const handleVentureClick = (venture) => {
    setSelectedVenture(venture);
    setIsModalOpen(true);
  };

  const categories = ['all', 'technology', 'lifestyle', 'home tech', 'fashion', 'essential', 'travel', 'real estate'];

  return (
    <>
      <SharedStyles />
      <div className="relative min-h-screen bg-white overflow-hidden">
        {/* Enhanced Background Elements */}
        <div className="absolute inset-0 -z-10">
          {/* Floating Orbs */}
          <div className="absolute top-1/5 right-1/4 w-96 h-96 bg-gradient-to-r from-orange-500/18 to-yellow-500/18 rounded-full blur-3xl animate-float" />
          <div className="absolute bottom-1/3 left-1/5 w-88 h-88 bg-gradient-to-r from-yellow-500/18 to-orange-400/18 rounded-full blur-3xl animate-float" style={{ animationDelay: '2.5s' }} />
          <div className="absolute top-1/2 right-1/2 w-72 h-72 bg-gradient-to-r from-orange-800/15 to-yellow-600/15 rounded-full blur-3xl animate-float" style={{ animationDelay: '5s' }} />
          
          {/* Grid Pattern */}
          <div className="absolute inset-0 opacity-12">
            <div className="w-full h-full" style={{
              backgroundImage: `
                linear-gradient(rgba(255,255,255,0.12) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255,255,255,0.12) 1px, transparent 1px)
              `,
              backgroundSize: '45px 45px'
            }} />
          </div>
          
          {/* Floating Particles */}
          <div className="absolute top-1/6 left-2/3 w-2 h-2 bg-orange-400 rounded-full animate-ping" />
          <div className="absolute top-2/3 right-1/6 w-1.5 h-1.5 bg-yellow-400 rounded-full animate-ping" style={{ animationDelay: '1.5s' }} />
          <div className="absolute bottom-1/5 left-1/2 w-1 h-1 bg-orange-300 rounded-full animate-ping" style={{ animationDelay: '3s' }} />
          <div className="absolute top-4/5 right-2/5 w-1.5 h-1.5 bg-yellow-300 rounded-full animate-ping" style={{ animationDelay: '4.5s' }} />
        </div>

        {/* Main Background Overlays - Reduced opacity for better readability */}
        <div className="absolute inset-0 bg-gradient-to-t from-slate-900/20 via-transparent to-slate-900/10" />
        <div className="absolute inset-0 bg-gradient-to-r from-orange-600/5 via-transparent to-yellow-500/5" />

        {/* Hero Section */}
        <section data-animate className="relative px-4 sm:px-6 pt-8 sm:pt-12 pb-8 sm:pb-12">
          <div className="max-w-6xl mx-auto">
            {/* Header with Title and Description */}
            <div className="text-center mb-8 sm:mb-10 lg:mb-12">
              <div className="inline-flex items-center gap-2 px-3 sm:px-4 lg:px-6 py-1.5 sm:py-2 mb-4 sm:mb-6 rounded-full bg-white/95 backdrop-blur border border-orange-200 shadow-md">
                <div className="w-2 h-2 bg-gradient-to-r from-orange-400 to-yellow-400 rounded-full animate-pulse"></div>
                <span className="text-slate-900 text-[10px] sm:text-xs lg:text-sm font-medium tracking-wide">BRIGHTPLANET VENTURES ECOSYSTEM</span>
              </div>
              
              <h1 className="text-xl sm:text-2xl md:text-3xl lg:text-4xl xl:text-5xl font-black mb-3 sm:mb-4 leading-tight">
                <span className="bg-gradient-to-r from-slate-900 via-orange-700 to-yellow-700 bg-clip-text text-transparent block drop-shadow-2xl">
                  VenturePortfolio
                </span>
              </h1>
              
              <p className="text-xs sm:text-sm lg:text-base text-slate-900 max-w-4xl mx-auto leading-relaxed mb-6 sm:mb-8 font-medium bg-white/95 backdrop-blur-sm rounded-lg p-3 sm:p-4 lg:p-5 shadow-md border border-slate-200">
                Discover our comprehensive ecosystem of <span className="text-orange-600 font-semibold">{totalStats.ventures} innovative ventures</span> serving <span className="text-yellow-600 font-semibold"><AnimatedCounter end={`${totalStats.customers}`} suffix="+" /> customers</span> across diverse industries with excellence and innovation.
              </p>
            </div>

            {/* Search Bar */}
            <div className="flex justify-center mb-6 sm:mb-8 lg:mb-10">
              <div className="relative w-full max-w-sm sm:max-w-md px-2">
                <input
                  type="text"
                  placeholder="Search ventures..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full bg-white/95 border border-slate-300 rounded-lg px-3 sm:px-4 py-2.5 sm:py-3 pl-8 sm:pl-9 lg:pl-10 text-slate-900 placeholder-slate-500 focus:outline-none focus:border-orange-500 focus:bg-white focus:ring-2 focus:ring-orange-500/50 backdrop-blur-lg transition-all duration-300 text-xs sm:text-sm shadow-md"
                />
                <svg className="absolute left-2 sm:left-2.5 lg:left-3 top-1/2 transform -translate-y-1/2 w-3 h-3 sm:w-3.5 sm:h-3.5 lg:w-4 lg:h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
            </div>
            
            {/* Category Filters */}
            <div className="flex flex-wrap justify-center gap-1 sm:gap-1.5 lg:gap-2 max-w-4xl mx-auto px-2">
              {categories.map((category) => (
                <button
                  key={category}
                  onClick={() => setFilter(category)}
                  className={`px-2 sm:px-2.5 lg:px-3 py-1 sm:py-1.5 text-[10px] sm:text-xs font-semibold rounded-md sm:rounded-lg transition-all duration-300 hover:scale-105 focus:outline-none focus:ring-2 focus:ring-orange-500/50 whitespace-nowrap ${
                    filter === category 
                      ? 'bg-gradient-to-r from-orange-500 to-yellow-500 text-white shadow-lg hover:shadow-xl hover:shadow-orange-500/25 border border-white/30' 
                      : 'bg-white/90 backdrop-blur-md border border-slate-200 text-slate-900 hover:bg-white hover:border-orange-300 hover:text-orange-700 shadow-sm'
                  }`}
                >
                  {category === 'all' ? 'All' : category.charAt(0).toUpperCase() + category.slice(1)}
                </button>
              ))}
            </div>
          </div>
        </section>

        {/* Ventures Grid */}
        <section data-animate className="relative px-4 sm:px-6 pb-12 sm:pb-16 lg:pb-24">
          <div className="max-w-6xl mx-auto">
            {/* Section Header */}
            <div className="text-center mb-6 sm:mb-8 lg:mb-12">
              <h2 className="text-xl sm:text-2xl lg:text-3xl font-bold text-slate-900 mb-3 sm:mb-4">Our Business Ventures</h2>
              <div className="w-24 h-1 bg-gradient-to-r from-orange-500 to-yellow-500 mx-auto rounded-full"></div>
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5 lg:gap-6 xl:gap-8">
              {filteredVentures.map((venture) => (
                <VentureCard
                  key={venture.id}
                  venture={venture}
                  onClick={handleVentureClick}
                  isSelected={selectedVenture?.id === venture.id}
                />
              ))}
            </div>

            {filteredVentures.length === 0 && (
              <div className="text-center py-20">
                <div className="text-6xl mb-4">🔍</div>
                <h3 className="text-2xl font-bold text-slate-600 mb-2">No ventures found</h3>
                <p className="text-slate-500">Try adjusting your search or filter criteria</p>
              </div>
            )}
          </div>
        </section>

        {/* Venture Detail Modal */}
        <VentureDetailModal
          venture={selectedVenture}
          isOpen={isModalOpen}
          onClose={() => {
            setIsModalOpen(false);
            setSelectedVenture(null);
          }}
        />
      </div>
    </>
  );
};

export default Ventures;
