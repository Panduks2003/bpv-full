import React, { useState, useEffect, useRef } from "react";
import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../../common/context/AuthContext";


function AdminNavbar() {
  const location = useLocation();
  const { user, logout } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [isVisible, setIsVisible] = useState(false);
  const navbarRef = useRef(null);

  // Entry animation - immediate for better UX
  useEffect(() => {
    setIsVisible(true);
  }, []);

  // Admin navigation items
  const navItems = [
    { path: "/admin", label: "Home" },
    { path: "/admin/promoters", label: "Promoters" },
    { path: "/admin/customers", label: "Customers" },
    { path: "/admin/pins", label: "Pin Management" },
    { path: "/admin/commissions", label: "Commissions" },
    { path: "/admin/withdrawals", label: "Withdrawals" }
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
      {/* Admin Navbar */}
      <nav 
        ref={navbarRef}
        className={`fixed top-6 left-6 right-6 z-50 transition-all duration-700 ease-out ${
          isVisible ? 'translate-y-0 opacity-100' : '-translate-y-full opacity-0'
        }`}
      >
        <div className="relative">
          <div className="relative bg-gradient-to-r from-slate-900/70 via-orange-900/60 to-slate-900/70 backdrop-blur-3xl border border-orange-400/30 rounded-3xl shadow-[0_20px_60px_rgba(0,0,0,0.6)]">
            <div className="max-w-7xl mx-auto px-8 py-4">
              <div className="flex justify-between items-center">
                
                {/* Logo Section */}
                <div className="relative">
                  <div className="relative px-4 py-2">
                    <img 
                      src="/new-logo.png" 
                      alt="BrightPlanet Ventures - Admin" 
                      className="h-12 w-auto filter drop-shadow-lg"
                    />
                    <span className="absolute -top-1 -right-1 bg-gradient-to-r from-orange-600 to-red-500 text-white text-xs px-2 py-1 rounded-full font-bold shadow-lg">
                      ADMIN
                    </span>
                  </div>
                </div>

                {/* Desktop Navigation - Center */}
                <div className="hidden lg:flex items-center space-x-1 flex-1 justify-center">
                  {navItems.map((item, index) => (
                    <Link
                      key={item.path}
                      to={item.path}
                      className={`
                        px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200 border backdrop-blur-sm whitespace-nowrap
                        ${(location.pathname === item.path || (item.path === '/admin' && (location.pathname === '/admin/dashboard' || location.pathname === '/admin')))
                          ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-red-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                          : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:shadow-md hover:text-orange-100'
                        }
                      `}
                    >
                      {item.label}
                    </Link>
                  ))}
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
                  {navItems.map((item, index) => (
                    <Link
                      key={item.path}
                      onClick={handleNavItemClick}
                      to={item.path}
                      className={`
                          block px-4 py-3 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm
                          ${(location.pathname === item.path || (item.path === '/admin' && (location.pathname === '/admin/dashboard' || location.pathname === '/admin')))
                            ? 'text-orange-100 bg-gradient-to-r from-orange-500/40 to-red-500/30 border-orange-400/60 shadow-lg shadow-orange-500/30' 
                            : 'text-white/90 border-transparent hover:bg-slate-700/50 hover:border-orange-400/50 hover:text-orange-100'
                          }
                        `}
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      {item.label}
                    </Link>
                  ))}
                  
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

export default AdminNavbar;
