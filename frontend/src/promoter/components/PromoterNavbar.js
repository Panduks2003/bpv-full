import React, { useState, useEffect, useRef } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../../common/context/AuthContext";
import { ChevronDown } from "lucide-react";

function PromoterNavbar() {
  const location = useLocation();
  const { user, logout } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [isVisible, setIsVisible] = useState(false);
  const [activeDropdown, setActiveDropdown] = useState(null);
  const [hoverTimeout, setHoverTimeout] = useState(null);
  const navbarRef = useRef(null);

  // Entry animation
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(true);
    }, 100);
    return () => clearTimeout(timer);
  }, []);

  // Promoter navigation items with unified pin management
  const navItems = [
    { path: "/promoter/promoters", label: "Promoters" },
    { path: "/promoter/customers", label: "Customers" },
    { path: "/promoter/pins", label: "Pin Management" },
    { path: "/promoter/commissions", label: "Commissions" },
    { path: "/promoter/withdrawals", label: "Withdrawals" }
  ];

  const handleNavItemClick = () => {
    setIsOpen(false);
    setActiveDropdown(null);
  };

  const handleLogout = () => {
    logout();
    setIsOpen(false);
    setActiveDropdown(null);
  };

  const toggleDropdown = (itemId) => {
    setActiveDropdown(activeDropdown === itemId ? null : itemId);
  };

  const handleMouseEnter = (sectionId) => {
    if (hoverTimeout) {
      clearTimeout(hoverTimeout);
    }
    setActiveDropdown(sectionId);
  };

  const handleMouseLeave = () => {
    const timeout = setTimeout(() => {
      setActiveDropdown(null);
    }, 150); // Small delay to prevent flickering
    setHoverTimeout(timeout);
  };

  const isActiveSection = (items) => {
    return items && items.some(item => location.pathname === item.path);
  };

  const isActiveDirectLink = (path) => {
    return location.pathname === path;
  };

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (navbarRef.current && !navbarRef.current.contains(event.target)) {
        setActiveDropdown(null);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  // Cleanup timeout on unmount
  useEffect(() => {
    return () => {
      if (hoverTimeout) {
        clearTimeout(hoverTimeout);
      }
    };
  }, [hoverTimeout]);

  return (
    <>
      {/* Promoter Navbar */}
      <nav 
        ref={navbarRef}
        className={`fixed top-6 left-6 right-6 z-50 transition-all duration-700 ease-out ${
          isVisible ? 'translate-y-0 opacity-100' : '-translate-y-full opacity-0'
        }`}
      >
        <div className="relative">
          <div className="relative bg-gradient-to-r from-slate-900/70 via-orange-900/60 to-slate-900/70 backdrop-blur-3xl border border-orange-400/30 rounded-3xl shadow-[0_20px_60px_rgba(0,0,0,0.6)] transition-all duration-500 hover:shadow-[0_25px_80px_rgba(247,147,30,0.5)] hover:border-orange-400/50 hover:bg-gradient-to-r hover:from-slate-800/75 hover:via-orange-800/65 hover:to-slate-800/75 hover:scale-[1.02]">
            <div className="max-w-7xl mx-auto px-8 py-4">
              <div className="flex justify-between items-center">
                
                {/* Logo Section */}
                <div className="relative">
                  <div className="relative px-4 py-2">
                    <img 
                      src="/new-logo.png" 
                      alt="BrightPlanet Ventures - Promoter" 
                      className="h-12 w-auto filter drop-shadow-lg"
                    />
                    <span className="absolute -top-1 -right-1 bg-gradient-to-r from-orange-600 to-red-500 text-white text-xs px-2 py-1 rounded-full font-bold shadow-lg">
                      PROMOTER
                    </span>
                  </div>
                </div>

                {/* Desktop Navigation - Center */}
                <div className="hidden lg:flex items-center space-x-1 flex-1 justify-center">
                  {/* Home Link */}
                  <Link
                    to="/promoter"
                    className={`
                      px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200 border backdrop-blur-sm whitespace-nowrap
                      ${(location.pathname === "/promoter" || location.pathname === "/promoter/home" || location.pathname === "/promoter/dashboard")
                        ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-red-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                        : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:shadow-md hover:text-orange-100'
                      }
                    `}
                  >
                    Home
                  </Link>

                  {navItems.map((item, index) => {
                    // Check if it's a direct link or a dropdown section
                    if (item.path) {
                      // Direct link (like "My Customers")
                      return (
                        <Link
                          key={item.path}
                          to={item.path}
                          onClick={handleNavItemClick}
                          className={`
                            flex items-center px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200 border backdrop-blur-sm whitespace-nowrap
                            ${isActiveDirectLink(item.path)
                              ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-red-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                              : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:shadow-md hover:text-orange-100'
                            }
                          `}
                        >
                          {item.label}
                        </Link>
                      );
                    } else {
                      // Dropdown section
                      return (
                        <div 
                          key={item.id} 
                          className="relative"
                          onMouseEnter={() => handleMouseEnter(item.id)}
                          onMouseLeave={handleMouseLeave}
                        >
                          <button
                            onClick={() => toggleDropdown(item.id)}
                            className={`
                              flex items-center px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200 border backdrop-blur-sm whitespace-nowrap
                              ${isActiveSection(item.items) || activeDropdown === item.id
                                ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-red-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                                : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:shadow-md hover:text-orange-100'
                              }
                            `}
                          >
                            <span>{item.label}</span>
                            <ChevronDown className={`ml-1 h-4 w-4 transition-transform duration-200 ${
                              activeDropdown === item.id ? 'rotate-180' : ''
                            }`} />
                          </button>
                          
                          {/* Dropdown Menu */}
                          {activeDropdown === item.id && (
                            <div 
                              className="absolute top-full left-0 mt-1 w-56 bg-slate-800/95 backdrop-blur-xl border border-orange-400/50 rounded-lg shadow-xl z-[60] animate-in slide-in-from-top-2 duration-200"
                            >
                              <div className="py-2">
                                {item.items.map((subItem) => (
                                  <Link
                                    key={subItem.path}
                                    to={subItem.path}
                                    onClick={handleNavItemClick}
                                    className={`
                                      block px-4 py-2 text-sm transition-all duration-200
                                      ${location.pathname === subItem.path
                                        ? 'text-orange-100 bg-gradient-to-r from-orange-500/30 to-red-500/20 border-l-2 border-orange-400'
                                        : 'text-white/90 hover:bg-slate-700/50 hover:text-orange-100'
                                      }
                                    `}
                                  >
                                    {subItem.label}
                                  </Link>
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    }
                  })}
                </div>

                {/* Logout Button & Mobile Menu Button - Right */}
                <div className="flex items-center space-x-4">
                  {/* Logout Button */}
                  <button
                    onClick={handleLogout}
                    className="hidden lg:block px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200 border backdrop-blur-sm text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:shadow-md hover:text-orange-100"
                  >
                    Logout
                  </button>
                  
                  <button 
                    aria-label="Toggle menu" 
                    className="lg:hidden relative z-50 p-3 rounded-xl bg-slate-700/70 backdrop-blur-md border border-orange-400/50 transition-all duration-300 hover:bg-slate-600/80 hover:border-orange-400/70 hover:shadow-lg"
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
                <div className="lg:hidden mt-4 space-y-2 border-t border-white/20 pt-4 animate-in slide-in-from-top duration-300">
                  {/* Home Link */}
                  <Link
                    to="/promoter"
                    onClick={handleNavItemClick}
                    className={`
                      block px-4 py-3 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm
                      ${(location.pathname === "/promoter" || location.pathname === "/promoter/home" || location.pathname === "/promoter/dashboard")
                        ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-red-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                        : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:text-orange-100'
                      }
                    `}
                  >
                    Home
                  </Link>
                  
                  {navItems.map((item, sectionIndex) => {
                    // Check if it's a direct link or a dropdown section
                    if (item.path) {
                      // Direct link (like "My Customers")
                      return (
                        <Link
                          key={item.path}
                          to={item.path}
                          onClick={handleNavItemClick}
                          className={`
                            block px-4 py-3 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm
                            ${isActiveDirectLink(item.path)
                              ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-red-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                              : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:text-orange-100'
                            }
                          `}
                          style={{ animationDelay: `${(sectionIndex + 1) * 50}ms` }}
                        >
                          {item.label}
                        </Link>
                      );
                    } else {
                      // Dropdown section
                      return (
                        <div key={item.id} className="space-y-1">
                          <button
                            onClick={() => toggleDropdown(item.id)}
                            className={`
                              flex items-center justify-between w-full px-4 py-3 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm
                              ${isActiveSection(item.items) || activeDropdown === item.id
                                ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-red-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                                : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:text-orange-100'
                              }
                            `}
                            style={{ animationDelay: `${(sectionIndex + 1) * 50}ms` }}
                          >
                            <div className="flex items-center">
                              <span>{item.label}</span>
                            </div>
                            <ChevronDown className={`h-4 w-4 transition-transform duration-200 ${
                              activeDropdown === item.id ? 'rotate-180' : ''
                            }`} />
                          </button>
                          
                          {/* Mobile Dropdown Items */}
                          {activeDropdown === item.id && (
                            <div className="ml-4 space-y-1 animate-in slide-in-from-top duration-200">
                              {item.items.map((subItem, itemIndex) => (
                                <Link
                                  key={subItem.path}
                                  onClick={handleNavItemClick}
                                  to={subItem.path}
                                  className={`
                                    block px-4 py-2 rounded-lg text-sm transition-all duration-200 border backdrop-blur-sm
                                    ${location.pathname === subItem.path 
                                      ? 'text-orange-100 bg-gradient-to-r from-orange-500/20 to-red-500/10 border-orange-400/40 border-l-2' 
                                      : 'text-white/80 border-transparent hover:bg-slate-700/30 hover:border-orange-400/40 hover:text-orange-100'
                                    }
                                  `}
                                  style={{ animationDelay: `${((sectionIndex + 1) * item.items.length + itemIndex) * 30}ms` }}
                                >
                                  {subItem.label}
                                </Link>
                              ))}
                            </div>
                          )}
                        </div>
                      );
                    }
                  })}
                  
                  <button
                    onClick={handleLogout}
                    className="block w-full text-left px-4 py-3 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:text-orange-100 mt-4"
                  >
                    Logout
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </nav>

    </>
  );
}

export default PromoterNavbar;
