import React from "react";
import { Link, useLocation } from "react-router-dom";

function SimpleNavbar() {
  const location = useLocation();

  const navItems = [
    { path: "/", label: "Home" },
    { path: "/about", label: "About" },
    { path: "/ventures", label: "Ventures" },
    { path: "/contact", label: "Contact" },
    { path: "/login", label: "Login" }
  ];

  return (
    <>
      {/* Simple Test Navbar */}
      <nav 
        data-testid="simple-navbar"
        className="fixed top-0 left-0 right-0 z-50 bg-blue-600 text-white shadow-lg"
        style={{ minHeight: '60px' }}
      >
        <div className="max-w-7xl mx-auto px-4 py-3">
          <div className="flex justify-between items-center">
            
            {/* Logo */}
            <div>
              <Link to="/" className="text-xl font-bold">
                BrightPlanet Ventures
              </Link>
            </div>

            {/* Navigation Links */}
            <div className="hidden md:flex space-x-4">
              {navItems.map((item) => (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`px-3 py-2 rounded transition-colors ${
                    location.pathname === item.path 
                      ? 'bg-blue-700 text-white' 
                      : 'hover:bg-blue-500'
                  }`}
                >
                  {item.label}
                </Link>
              ))}
            </div>

            {/* Mobile Menu Button */}
            <div className="md:hidden">
              <button className="text-white">☰</button>
            </div>
          </div>
        </div>
      </nav>

      {/* Spacer */}
      <div className="h-16" />
    </>
  );
}

export default SimpleNavbar;
