import React, { useState, useEffect, useRef } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../../common/context/AuthContext";

function CustomerNavbar() {
  const location = useLocation();
  const { user, logout } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [isVisible, setIsVisible] = useState(false);
  const navbarRef = useRef(null);

  // Entry animation
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(true);
    }, 100);
    return () => clearTimeout(timer);
  }, []);

  // Customer navigation items
  const navItems = [
    { path: "/customer/coupons", label: "Coupons" },
    { path: "/customer/profile", label: "Profile" }
  ];

  const handleNavItemClick = () => {
    setIsOpen(false);
  };

  const handleLogout = () => {
    logout();
    setIsOpen(false);
  };

  return (
    <>
      {/* Customer Navbar */}
      <nav 
        ref={navbarRef}
        className={`fixed top-4 left-4 right-4 z-50 transition-all duration-700 ease-out ${
          isVisible ? 'translate-y-0 opacity-100' : '-translate-y-full opacity-0'
        }`}
      >
        <div className="relative">
          <div className="relative bg-gradient-to-r from-slate-900/90 via-orange-900/80 to-slate-900/90 backdrop-blur-2xl border border-orange-400/50 rounded-2xl shadow-[0_8px_32px_rgba(0,0,0,0.4)] transition-all duration-500 hover:shadow-[0_12px_40px_rgba(247,147,30,0.4)] hover:border-orange-400/70 hover:bg-gradient-to-r hover:from-slate-800/95 hover:via-orange-800/85 hover:to-slate-800/95">
            <div className="max-w-7xl mx-auto px-8 py-4">
              <div className="flex justify-between items-center">
                
                {/* Logo Section - Left */}
                <div className="relative">
                  <div className="relative px-4 py-2">
                    <img 
                      src="/new-logo.png" 
                      alt="BrightPlanet Ventures - Customer" 
                      className="h-12 w-auto filter drop-shadow-lg"
                    />
                    <span className="absolute -top-1 -right-1 bg-gradient-to-r from-orange-500 to-yellow-500 text-white text-xs px-2 py-1 rounded-full font-bold shadow-lg">
                      CUSTOMER
                    </span>
                  </div>
                </div>

                {/* Desktop Navigation - Center */}
                <div className="hidden md:flex items-center space-x-1">
                  {navItems.map((item, index) => (
                    <div key={item.path} className="relative">
                      <Link
                        to={item.path}
                        className={`
                          px-4 py-2 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm
                          ${location.pathname === item.path 
                            ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-yellow-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                            : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:shadow-md hover:text-orange-100'
                          }
                        `}
                      >
                        <span>{item.label}</span>
                      </Link>
                    </div>
                  ))}
                </div>

                {/* Logout Button - Right */}
                <div className="flex items-center space-x-4">
                  <button
                    onClick={handleLogout}
                    className="hidden md:block px-4 py-2 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:shadow-md hover:text-orange-100"
                  >
                    Logout
                  </button>
                  
                  <button 
                    aria-label="Toggle menu" 
                    className="md:hidden relative z-50 p-3 rounded-xl bg-slate-700/70 backdrop-blur-md border border-orange-400/50 transition-all duration-300 hover:bg-slate-600/80 hover:border-orange-400/70 hover:shadow-lg"
                    onClick={() => setIsOpen((v) => !v)}
                  >
                    <div className={`w-6 h-0.5 bg-white transition-all duration-300 ${isOpen ? 'rotate-45 translate-y-1.5' : ''}`} />
                    <div className={`w-6 h-0.5 bg-white my-1.5 transition-all duration-300 ${isOpen ? 'opacity-0' : ''}`} />
                    <div className={`w-6 h-0.5 bg-white transition-all duration-300 ${isOpen ? '-rotate-45 -translate-y-1.5' : ''}`} />
                  </button>
                </div>
              </div>

              {/* Mobile Menu */}
              {isOpen && (
                <div className="md:hidden mt-4 space-y-2 border-t border-white/20 pt-4 animate-in slide-in-from-top duration-300">
                  {navItems.map((item, index) => (
                    <Link
                      key={item.path}
                      onClick={handleNavItemClick}
                      to={item.path}
                      className={`
                          block px-4 py-3 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm
                          ${location.pathname === item.path 
                            ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-yellow-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                            : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:text-orange-100'
                          }
                        `}
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <span>{item.label}</span>
                    </Link>
                  ))}
                  
                  <button
                    onClick={handleLogout}
                    className="block w-full text-left px-4 py-3 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:text-orange-100"
                  >
                    Logout
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </nav>

      {/* Spacer for fixed navbar */}
      <div className="h-20" />
    </>
  );
}

export default CustomerNavbar;
