import React, { useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import TrustedCommunities from "../components/TrustedCommunities";
import PurposeBuiltSection from "../components/PurposeBuiltSection";
import { 
  UnifiedBackground, 
  SharedStyles, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  useInteractiveParticles,
  gradients,
  animations
} from "../components/SharedTheme";

function Home() {
  const heroRef = useRef(null);
  const globeRef = useRef(null);
  const particleCanvasRef = useRef(null);
  
  // Use unified theme hooks
  useScrollAnimation();
  const mousePosition = useInteractiveParticles(particleCanvasRef);

  useEffect(() => {
    const root = heroRef.current;
    if (!root) return;

    // Enhanced mouse parallax / tilt for globe
    const handleMove = (e) => {
      const section = root.querySelector("section[data-hero]");
      if (!section) return;
      const rect = section.getBoundingClientRect();
      const px = (e.clientX - rect.left) / rect.width - 0.5;
      const py = (e.clientY - rect.top) / rect.height - 0.5;
      const mx = px * 40;
      const my = py * 40;
      section.style.setProperty("--mx", `${mx}`);
      section.style.setProperty("--my", `${my}`);
      const rx = px * 8;
      const ry = -py * 8;
      section.style.setProperty("--rx", `${rx}deg`);
      section.style.setProperty("--ry", `${ry}deg`);
    };
    const handleLeave = () => {
      const section = root.querySelector("section[data-hero]");
      if (!section) return;
      section.style.setProperty("--mx", `0`);
      section.style.setProperty("--my", `0`);
      section.style.setProperty("--rx", `0deg`);
      section.style.setProperty("--ry", `0deg`);
    };

    const sectionEl = root.querySelector("section[data-hero]");
    if (sectionEl) {
      sectionEl.addEventListener("mousemove", handleMove);
      sectionEl.addEventListener("mouseleave", handleLeave);
    }

    return () => {
      if (sectionEl) {
        sectionEl.removeEventListener("mousemove", handleMove);
        sectionEl.removeEventListener("mouseleave", handleLeave);
      }
    };
  }, []);

  return (
    <>
      <SharedStyles />
      <div className="relative min-h-screen bg-gradient-to-br from-slate-50 via-orange-50/30 to-yellow-50/20 overflow-hidden">
        {/* Enhanced Background Elements */}
        <div className="absolute inset-0 -z-10">
          {/* Floating Orbs */}
          <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-to-r from-orange-500/15 to-yellow-500/15 rounded-full blur-3xl animate-float" />
          <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-gradient-to-r from-yellow-500/15 to-orange-400/15 rounded-full blur-3xl animate-float" style={{ animationDelay: '2s' }} />
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-gradient-to-r from-blue-600/10 to-slate-600/10 rounded-full blur-3xl animate-float" style={{ animationDelay: '4s' }} />
          
          {/* Grid Pattern */}
          <div className="absolute inset-0 opacity-5">
            <div className="w-full h-full" style={{
              backgroundImage: `
                linear-gradient(rgba(59,130,246,0.1) 1px, transparent 1px),
                linear-gradient(90deg, rgba(59,130,246,0.1) 1px, transparent 1px)
              `,
              backgroundSize: '50px 50px'
            }} />
          </div>
          
          {/* Floating Particles */}
          <div className="absolute top-1/2 left-1/2 w-2 h-2 bg-orange-500 rounded-full animate-ping" />
          <div className="absolute top-1/3 right-1/4 w-1.5 h-1.5 bg-yellow-500 rounded-full animate-ping" style={{ animationDelay: '1s' }} />
          <div className="absolute bottom-1/3 left-1/4 w-1 h-1 bg-orange-400 rounded-full animate-ping" style={{ animationDelay: '2s' }} />
          <div className="absolute top-2/3 right-1/3 w-1.5 h-1.5 bg-yellow-400 rounded-full animate-ping" style={{ animationDelay: '3s' }} />
        </div>

        {/* Interactive Particle Canvas */}
        <canvas
          ref={particleCanvasRef}
          className="absolute inset-0 pointer-events-none z-0"
        />
        
        <div ref={heroRef}>
          {/* 1. Enhanced Hero Section with Unified Theme */}
          <section
            data-hero
            className="relative isolate overflow-hidden bg-gradient-to-br from-white via-orange-50/30 to-yellow-50/20"
            style={{ minHeight: "calc(100vh - 64px)" }}
          >
            {/* Hero-specific background overlay */}
            <div className="absolute inset-0 bg-gradient-to-t from-slate-100/20 via-transparent to-white/10" />
            <div className="absolute inset-0 bg-gradient-to-r from-orange-600/5 via-transparent to-yellow-500/5" />
            {/* Content */}
            <div className="relative px-4 pt-16 pb-20 sm:pt-24 sm:pb-28">
              <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-6 lg:gap-10 items-center">
                {/* Left: Enhanced Copy */}
                <div className="lg:col-span-6">
                  <UnifiedCard 
                    variant="glass" 
                    className="inline-flex items-center gap-2 px-4 py-2 mb-6 hover-scale stagger-1 bg-white/95 border border-orange-300 shadow-md"
                    animation="fade-in"
                    delay={0.2}
                  >
                    <span className="h-2 w-2 rounded-full bg-gradient-to-r from-orange-500 to-yellow-500 animate-pulse" />
                    <span className="text-xs font-medium text-slate-900">Trusted Business Platform • Proven Results</span>
                  </UnifiedCard>
                  
                  <h1 className="mt-6 text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-extrabold leading-tight tracking-tight scroll-animate animate-slide-up stagger-2">
                    <span className="text-slate-900">
                      Connect with trusted businesses across 
                    </span>
                    <span className="bg-clip-text text-transparent bg-gradient-to-r from-orange-600 to-yellow-600 animate-gradient-x">
                      multiple industries
                    </span>
                  </h1>
                  
                  <p className="mt-4 sm:mt-6 text-slate-900 text-sm sm:text-base lg:text-lg max-w-xl scroll-animate animate-slide-up stagger-3 bg-white/95 rounded-lg p-3 sm:p-4 lg:p-5 border border-slate-200 shadow-md leading-relaxed">
                    Access quality products and services from verified businesses in electronics, furniture, home appliances, fashion, and more. Join thousands of satisfied customers and business partners.
                  </p>
                  
                  <div className="mt-6 sm:mt-8 lg:mt-10 flex flex-col sm:flex-row gap-3 sm:gap-4 scroll-animate animate-slide-up stagger-4">
                    <UnifiedButton variant="primary" size="lg" className="hover-lift w-full sm:flex-1 min-h-[48px] text-base sm:text-lg">
                      <Link to="/contact" className="flex items-center justify-center gap-2 w-full">
                        <span>Contact Us</span>
                      </Link>
                    </UnifiedButton>
                    <UnifiedButton variant="ghost" size="lg" className="hover-lift w-full sm:flex-1 min-h-[48px] text-base sm:text-lg !bg-black !text-white hover:!bg-gray-800 !border-2 !border-black">
                      <Link to="/login" className="flex items-center justify-center gap-2 !text-white w-full">
                        <span>Login</span>
                      </Link>
                    </UnifiedButton>
                  </div>
                  
                  {/* Enhanced floating KPI pill */}
                  <UnifiedCard 
                    variant="glass"
                    className="mt-8 inline-flex items-center gap-3 hover-lift scroll-animate animate-bounce-in stagger-5 bg-white/95 border border-orange-200 shadow-lg"
                  >
                    <span className="inline-flex -space-x-2">
                      <span className="h-8 w-8 rounded-full bg-gradient-to-r from-orange-500 to-yellow-500 ring-2 ring-white/60 animate-pulse" />
                      <span className="h-8 w-8 rounded-full bg-gradient-to-r from-yellow-500 to-orange-500 ring-2 ring-white/60 animate-pulse" style={{ animationDelay: '0.5s' }} />
                      <span className="h-8 w-8 rounded-full bg-gradient-to-r from-blue-500 to-blue-600 ring-2 ring-white/60 animate-pulse" style={{ animationDelay: '1s' }} />
                    </span>
                    <span className="text-sm text-slate-900 font-medium">Serving 50+ customers • 10+ business partners</span>
                  </UnifiedCard>
                </div>

                {/* Right: Enhanced Products Showcase */}
                <div className="lg:col-span-6 relative">
                  {/* Main Products Container - Responsive */}
                  <div className="relative h-full min-h-[350px] sm:min-h-[450px] lg:min-h-[550px] xl:min-h-[600px] bg-gradient-to-br from-white via-orange-50/30 to-yellow-50/20 rounded-lg sm:rounded-xl lg:rounded-2xl xl:rounded-3xl p-3 sm:p-4 md:p-6 lg:p-8 overflow-hidden scroll-animate animate-scale-in stagger-6 shadow-2xl border-2 border-black">
                    {/* Animated Background Elements */}
                    <div className="absolute inset-0 overflow-hidden">
                      <div className="absolute top-10 right-10 w-32 h-32 bg-gradient-to-r from-blue-400/8 via-purple-400/8 to-teal-400/8 rounded-full blur-2xl animate-pulse" />
                      <div className="absolute bottom-20 left-10 w-40 h-40 bg-gradient-to-r from-green-400/8 via-orange-400/8 to-pink-400/8 rounded-full blur-3xl animate-pulse" style={{ animationDelay: '1s' }} />
                      <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-24 h-24 bg-gradient-to-r from-indigo-300/6 via-amber-300/6 to-red-300/6 rounded-full blur-2xl animate-pulse" style={{ animationDelay: '2s' }} />
                    </div>

                    {/* Header Section */}
                    <div className="relative z-10 text-center mb-6 sm:mb-8">
                      <div className="inline-flex items-center gap-2 px-3 py-2 sm:px-4 bg-white/95 rounded-full border border-orange-300/50 mb-3 sm:mb-4 shadow-sm">
                        <span className="w-2 h-2 bg-gradient-to-r from-orange-500 to-yellow-500 rounded-full animate-pulse" />
                        <span className="text-slate-900 text-xs sm:text-sm font-semibold">Diverse Business Categories</span>
                      </div>
                      <h3 className="text-lg sm:text-xl md:text-2xl font-bold text-slate-900 mb-2">Serving Multiple Industries</h3>
                      <p className="text-slate-900 text-xs sm:text-sm px-2">Comprehensive solutions across diverse business sectors</p>
                    </div>

                    {/* Enhanced Products Grid - Responsive */}
                    <div className="relative z-10 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-1.5 sm:gap-2 md:gap-3 mb-3 sm:mb-4 lg:mb-6">
                      {/* All Products in One Grid - 2 columns on mobile, 5 columns on larger screens */}
                      {[
                        { name: "LED TV", icon: "📺", color: "from-blue-500 to-blue-700", bgColor: "bg-gradient-to-br from-blue-50 to-blue-100" },
                        { name: "REFRIGERATOR", icon: "🧊", color: "from-cyan-500 to-cyan-700", bgColor: "bg-gradient-to-br from-cyan-50 to-cyan-100" },
                        { name: "WASHING MACHINE", icon: "🌀", color: "from-purple-500 to-purple-700", bgColor: "bg-gradient-to-br from-purple-50 to-purple-100" },
                        { name: "COMBO SET", icon: "📦", color: "from-orange-500 to-orange-700", bgColor: "bg-gradient-to-br from-orange-50 to-orange-100" },
                        { name: "KITCHEN APPLIANCES", icon: "🍳", color: "from-red-500 to-red-700", bgColor: "bg-gradient-to-br from-red-50 to-red-100" },
                        { name: "DINING TABLE", icon: "🍽️", color: "from-amber-500 to-amber-700", bgColor: "bg-gradient-to-br from-amber-50 to-amber-100" },
                        { name: "WARDROBE", icon: "👔", color: "from-indigo-500 to-indigo-700", bgColor: "bg-gradient-to-br from-indigo-50 to-indigo-100" },
                        { name: "COT", icon: "🛏️", color: "from-green-500 to-green-700", bgColor: "bg-gradient-to-br from-green-50 to-green-100" },
                        { name: "SOFA SET", icon: "🛋️", color: "from-pink-500 to-pink-700", bgColor: "bg-gradient-to-br from-pink-50 to-pink-100" },
                        { name: "TV CABINET", icon: "📺", color: "from-slate-500 to-slate-700", bgColor: "bg-gradient-to-br from-slate-50 to-slate-100" }
                      ].map((product, idx) => (
                        <div key={product.name} className="group relative" style={{ animationDelay: `${idx * 0.1}s` }}>
                          <div className="bg-white/95 rounded-md sm:rounded-lg lg:rounded-xl p-1.5 sm:p-2 lg:p-3 text-center shadow-lg hover:shadow-2xl transition-all duration-300 hover:-translate-y-0.5 sm:hover:-translate-y-1 lg:hover:-translate-y-2 hover:scale-105 border border-slate-200/60">
                            <div className={`${product.bgColor} rounded-sm sm:rounded-md lg:rounded-lg mb-1 sm:mb-2 h-8 sm:h-10 md:h-12 lg:h-14 xl:h-16 flex items-center justify-center relative overflow-hidden group-hover:scale-110 transition-transform duration-300`}>
                              <div className="text-xs sm:text-sm md:text-base lg:text-lg xl:text-xl">{product.icon}</div>
                              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -skew-x-12 translate-x-[-100%] group-hover:translate-x-[200%] transition-transform duration-700" />
                            </div>
                            <p className="text-[7px] sm:text-[8px] md:text-[9px] lg:text-[10px] xl:text-xs font-bold text-slate-900 leading-tight px-0.5 sm:px-1 break-words">{product.name}</p>
                            <div className="mt-1 h-0.5 sm:h-1 bg-gradient-to-r from-transparent via-orange-400 to-transparent rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                          </div>
                        </div>
                      ))}
                    </div>

                    {/* Bottom Stats Section - Responsive */}
                    <div className="relative z-10 mt-3 sm:mt-4 md:mt-6 lg:mt-8 grid grid-cols-2 sm:grid-cols-4 gap-1 sm:gap-2 lg:gap-3">
                      <div className="text-center bg-gradient-to-br from-orange-50 to-orange-100/50 rounded-md sm:rounded-lg lg:rounded-xl p-2 sm:p-2.5 lg:p-3 border border-orange-200/60 shadow-sm">
                        <div className="text-sm sm:text-base md:text-lg lg:text-xl font-bold text-orange-700">50+</div>
                        <div className="text-[8px] sm:text-[9px] md:text-[10px] lg:text-xs text-orange-600 font-medium">Customers</div>
                      </div>
                      <div className="text-center bg-gradient-to-br from-green-50 to-green-100/50 rounded-md sm:rounded-lg lg:rounded-xl p-2 sm:p-2.5 lg:p-3 border border-green-200/60 shadow-sm">
                        <div className="text-sm sm:text-base md:text-lg lg:text-xl font-bold text-green-700">10+</div>
                        <div className="text-[8px] sm:text-[9px] md:text-[10px] lg:text-xs text-green-600 font-medium">Partners</div>
                      </div>
                      <div className="text-center bg-gradient-to-br from-purple-50 to-purple-100/50 rounded-md sm:rounded-lg lg:rounded-xl p-2 sm:p-2.5 lg:p-3 border border-purple-200/60 shadow-sm">
                        <div className="text-sm sm:text-base md:text-lg lg:text-xl font-bold text-purple-700">8</div>
                        <div className="text-[8px] sm:text-[9px] md:text-[10px] lg:text-xs text-purple-600 font-medium">Categories</div>
                      </div>
                      <div className="text-center bg-gradient-to-br from-blue-50 to-blue-100/50 rounded-md sm:rounded-lg lg:rounded-xl p-2 sm:p-2.5 lg:p-3 border border-blue-200/60 shadow-sm">
                        <div className="text-sm sm:text-base md:text-lg lg:text-xl font-bold text-blue-700">24/7</div>
                        <div className="text-[8px] sm:text-[9px] md:text-[10px] lg:text-xs text-blue-600 font-medium">Support</div>
                      </div>
                    </div>

                    {/* Floating Action Button - Responsive */}
                    <div className="absolute bottom-2 right-2 sm:bottom-3 sm:right-3 md:bottom-4 md:right-4 lg:bottom-6 lg:right-6">
                      <UnifiedButton 
                        variant="primary" 
                        className="rounded-full w-8 h-8 sm:w-9 sm:h-9 md:w-10 md:h-10 lg:w-12 lg:h-12 flex items-center justify-center shadow-2xl hover:shadow-orange-500/25 hover:scale-110 transition-all duration-300 bg-gradient-to-r from-orange-500 to-yellow-500 border-2 border-white/60"
                      >
                        <span className="text-xs sm:text-sm md:text-base lg:text-lg">→</span>
                      </UnifiedButton>
                    </div>

                    {/* Decorative Elements */}
                    <div className="absolute top-4 left-4 w-8 h-8 border-2 border-orange-300/50 rounded-full animate-spin" style={{ animationDuration: '8s' }} />
                    <div className="absolute bottom-4 left-4 w-6 h-6 border-2 border-yellow-400/50 rounded-full animate-bounce" />
                    <div className="absolute top-1/3 right-4 w-4 h-4 bg-gradient-to-r from-orange-400 to-yellow-400 rounded-full animate-pulse" />
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* 2. Enhanced Trusted Communities Section */}
          <TrustedCommunities />

          {/* 3. Enhanced Purpose Built Section */}
          <PurposeBuiltSection />

          {/* 4. Enhanced How It Works Section */}
          <section className="relative px-4 py-16 sm:py-20 lg:py-24 overflow-hidden bg-gradient-to-br from-white via-slate-50 to-orange-50/30">
            {/* Light background overlay */}
            <div className="absolute inset-0 bg-gradient-to-t from-slate-100/30 via-transparent to-white/20" />
            <div className="absolute inset-0 bg-gradient-to-r from-orange-600/5 via-transparent to-yellow-500/5" />
            <div className="max-w-7xl mx-auto relative">
              {/* Enhanced Header */}
              <div className="text-center mb-12 sm:mb-14 lg:mb-16 scroll-animate animate-fade-in">
                <UnifiedCard variant="glass" className="inline-flex items-center gap-2 px-5 py-3 mb-6 hover-scale bg-white/95 border border-orange-300 shadow-md">
                  <span className="w-3 h-3 rounded-full bg-gradient-to-r from-orange-500 to-yellow-500 animate-pulse" />
                  <span className="text-sm font-semibold text-slate-900">Simple 4-step process</span>
                </UnifiedCard>
                <h2 className="text-3xl sm:text-4xl md:text-5xl font-extrabold tracking-tight text-slate-900">
                  How It Works
                </h2>
                <p className="mt-4 text-slate-900 max-w-2xl mx-auto text-base sm:text-lg bg-white/95 rounded-lg p-3 sm:p-4 border border-slate-200 shadow-md leading-relaxed">
                  Get started in minutes and connect with quality businesses across multiple industries.
                </p>
              </div>

              {/* Enhanced Steps */}
              <ol className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 sm:gap-8">
                {[
                  {
                    step: "01",
                    title: "Browse Categories",
                    desc: "Explore our curated selection of electronics, furniture, home appliances, fashion, and more from verified businesses.",
                    gradient: gradients.cool,
                  },
                  {
                    step: "02",
                    title: "Create Account",
                    desc: "Sign up as a customer to shop or as a business partner to offer your products and services.",
                    gradient: gradients.secondary,
                  },
                  {
                    step: "03",
                    title: "Connect & Purchase",
                    desc: "Browse products, compare options, and make secure purchases from trusted business partners.",
                    gradient: gradients.warm,
                  },
                  {
                    step: "04",
                    title: "Enjoy Support",
                    desc: "Get 24/7 customer support, warranty protection, and access to our growing business network.",
                    gradient: gradients.accent,
                  },
                ].map((s, idx) => (
                  <li key={s.step} className="group relative scroll-animate animate-slide-up" style={{ animationDelay: `${idx * 0.1}s` }}>
                    <UnifiedCard variant="glass" className="relative p-6 sm:p-8 pt-10 sm:pt-12 h-full hover-lift card-tilt bg-white/95 border border-slate-200 shadow-lg">
                      {/* Enhanced Badge */}
                      <div className={`absolute top-3 sm:top-4 left-6 sm:left-8 h-10 w-10 sm:h-12 sm:w-12 rounded-xl sm:rounded-2xl bg-gradient-to-br ${s.gradient} text-white grid place-items-center font-bold shadow-lg group-hover:scale-110 transition-transform duration-300 text-sm sm:text-base`}>
                        {s.step}
                      </div>
                      <h3 className="mt-3 sm:mt-4 text-lg sm:text-xl font-bold text-slate-900 group-hover:text-orange-600 transition-colors">{s.title}</h3>
                      <p className="mt-2 sm:mt-3 text-sm text-slate-900 leading-relaxed bg-white/90 rounded-lg p-2.5 sm:p-3 border border-slate-200/50">{s.desc}</p>
                    </UnifiedCard>
                  </li>
                ))}
              </ol>

              {/* Enhanced CTAs */}
              <div className="mt-12 sm:mt-14 lg:mt-16 flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 scroll-animate animate-fade-in">
                <UnifiedButton variant="ghost" size="lg" className="hover-lift w-full sm:w-auto min-h-[48px] !bg-black !text-white hover:!bg-gray-800 !border-2 !border-black">
                  <Link to="/about" className="!text-white">About Us</Link>
                </UnifiedButton>
                <UnifiedButton variant="primary" size="lg" className="hover-lift w-full sm:w-auto min-h-[48px]">
                  <Link to="/contact">Contact Us</Link>
                </UnifiedButton>
              </div>
            </div>
          </section>
        </div>
      </div>
    </>
  );
}

export default Home; 
