import React from "react";
import { Link } from "react-router-dom";

function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="bg-gradient-to-br from-slate-800 via-slate-900 to-gray-900 text-white relative">
      {/* Professional background overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-slate-900/30 via-transparent to-slate-800/20" />
      <div className="absolute inset-0 bg-gradient-to-r from-slate-700/10 via-transparent to-slate-600/10" />
      {/* Main Footer Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 relative">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Company Info */}
          <div className="lg:col-span-1">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 flex items-center justify-center mr-3">
                <img 
                  src="/new-logo.png" 
                  alt="BrightPlanet Ventures" 
                  className="h-8 w-auto"
                />
              </div>
              <h3 className="text-xl font-bold bg-gradient-to-r from-orange-400 to-yellow-500 bg-clip-text text-transparent">
                BRIGHTPLANET VENTURES
              </h3>
            </div>
            <p className="text-slate-300 text-sm leading-relaxed mb-4">
              Building sustainable ventures that create opportunity and impact. 
              We connect innovative entrepreneurs with strategic investors and partners.
            </p>
            <div className="flex space-x-4">
              <a href="https://linkedin.com" target="_blank" rel="noopener noreferrer" 
                 className="w-10 h-10 bg-orange-500 hover:bg-orange-600 rounded-full flex items-center justify-center transition-colors duration-200">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.047-1.852-3.047-1.853 0-2.136 1.445-2.136 2.939v5.677H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                </svg>
              </a>
              <a href="https://twitter.com" target="_blank" rel="noopener noreferrer" 
                 className="w-10 h-10 bg-yellow-400 hover:bg-yellow-500 rounded-full flex items-center justify-center transition-colors duration-200">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
                </svg>
              </a>
              <a href="https://instagram.com" target="_blank" rel="noopener noreferrer" 
                 className="w-10 h-10 bg-gradient-to-r from-orange-400 to-yellow-400 hover:from-orange-500 hover:to-yellow-500 rounded-full flex items-center justify-center transition-colors duration-200">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12.017 0C5.396 0 .029 5.367.029 11.987c0 6.62 5.367 11.987 11.988 11.987 6.62 0 11.987-5.367 11.987-11.987C24.014 5.367 18.637.001 12.017.001zM8.449 16.988c-1.297 0-2.448-.49-3.323-1.297C4.198 14.895 3.708 13.744 3.708 12.447s.49-2.448 1.418-3.323c.875-.807 2.026-1.297 3.323-1.297s2.448.49 3.323 1.297c.928.875 1.418 2.026 1.418 3.323s-.49 2.448-1.418 3.323c-.875.807-2.026 1.297-3.323 1.297zm7.718-1.297c-.875.807-2.026 1.297-3.323 1.297s-2.448-.49-3.323-1.297c-.928-.875-1.418-2.026-1.418-3.323s.49-2.448 1.418-3.323c.875-.807 2.026-1.297 3.323-1.297s2.448.49 3.323 1.297c.928.875 1.418 2.026 1.418 3.323s-.49 2.448-1.418 3.323z"/>
                </svg>
              </a>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="text-lg font-semibold mb-4 text-slate-200">Company</h4>
            <ul className="space-y-3">
              <li>
                <Link to="/about" className="text-slate-300 hover:text-orange-400 transition-colors duration-200 flex items-center">
                  <span className="w-2 h-2 bg-orange-400 rounded-full mr-3"></span>
                  About Us
                </Link>
              </li>
              <li>
                <Link to="/ventures" className="text-slate-300 hover:text-orange-400 transition-colors duration-200 flex items-center">
                  <span className="w-2 h-2 bg-orange-400 rounded-full mr-3"></span>
                  Our Ventures
                </Link>
              </li>
              <li>
                <Link to="/events" className="text-slate-300 hover:text-orange-400 transition-colors duration-200 flex items-center">
                  <span className="w-2 h-2 bg-orange-400 rounded-full mr-3"></span>
                  Events
                </Link>
              </li>
              <li>
                <Link to="/contact" className="text-slate-300 hover:text-orange-400 transition-colors duration-200 flex items-center">
                  <span className="w-2 h-2 bg-orange-400 rounded-full mr-3"></span>
                  Contact
                </Link>
              </li>
            </ul>
          </div>

          {/* Get Involved */}
          <div>
            <h4 className="text-lg font-semibold mb-4 text-slate-200">Get Involved</h4>
            <ul className="space-y-3">
              <li>
                <Link to="/login" className="text-slate-300 hover:text-orange-400 transition-colors duration-200 flex items-center">
                  <span className="w-2 h-2 bg-orange-400 rounded-full mr-3"></span>
                  Login
                </Link>
              </li>
              <li>
                <Link to="/login" className="text-slate-300 hover:text-orange-400 transition-colors duration-200 flex items-center">
                  <span className="w-2 h-2 bg-orange-400 rounded-full mr-3"></span>
                  Join as Promoter
                </Link>
              </li>
              <li>
                <Link to="/login" className="text-slate-300 hover:text-orange-400 transition-colors duration-200 flex items-center">
                  <span className="w-2 h-2 bg-orange-400 rounded-full mr-3"></span>
                  Join as Customer
                </Link>
              </li>
            </ul>
          </div>

          {/* Contact Info */}
          <div>
            <h4 className="text-lg font-semibold mb-4 text-slate-200">Contact Info</h4>
            <div className="space-y-2 text-sm text-slate-300">
              <div className="flex items-center">
                <svg className="w-4 h-4 mr-2 text-orange-400" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z"/>
                  <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z"/>
                </svg>
                info@brightplanetventures.com
              </div>
              <div className="flex items-center">
                <svg className="w-4 h-4 mr-2 text-orange-400" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z"/>
                </svg>
+91 7353297211
              </div>
              <div className="flex items-center">
                <svg className="w-4 h-4 mr-2 text-orange-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clipRule="evenodd"/>
                </svg>
Gokak, Karnataka, India
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Bar */}
      <div className="border-t border-slate-600/50 relative">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex flex-col md:flex-row items-center justify-between">
            <div className="text-slate-300 text-sm mb-4 md:mb-0">
              <p>© {year} BrightPlanet Ventures. All rights reserved.</p>
              <p className="text-xs mt-1">Empowering sustainable growth and innovation</p>
            </div>
            <div className="flex space-x-6 text-sm">
              <Link to="/privacy" className="text-slate-300 hover:text-orange-400 transition-colors duration-200">
                Privacy Policy
              </Link>
              <Link to="/terms" className="text-slate-300 hover:text-orange-400 transition-colors duration-200">
                Terms of Service
              </Link>
              <Link to="/sitemap" className="text-slate-300 hover:text-orange-400 transition-colors duration-200">
                Sitemap
              </Link>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}

export default Footer;


