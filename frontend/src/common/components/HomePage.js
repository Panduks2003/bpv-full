import { Link } from 'react-router-dom'
import { ArrowRight, Leaf, Users, TrendingUp, Globe } from 'lucide-react'

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-orange-50 to-yellow-50">
      {/* Navigation */}
      <nav className="bg-white/95 backdrop-blur-md shadow-lg border-b border-orange-200/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <div className="flex-shrink-0 flex items-center">
                <Leaf className="h-8 w-8 text-orange-600" />
                <span className="ml-2 text-xl font-bold text-slate-900">BrightPlanet Ventures</span>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <Link to="/login" className="text-slate-700 hover:text-orange-600 px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-orange-500/50">
                Login
              </Link>
              <Link to="/register" className="bg-gradient-to-r from-orange-600 to-orange-700 hover:from-orange-700 hover:to-orange-800 text-white px-4 py-2 rounded-md text-sm font-medium shadow-md hover:shadow-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-orange-500/50">
                Get Started
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative overflow-hidden bg-gradient-to-br from-white via-orange-50/30 to-yellow-50/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
          <div className="text-center mb-16">
            <h1 className="text-4xl md:text-6xl font-bold text-slate-900 mb-6 leading-tight">
              Serving Multiple
              <span className="block bg-gradient-to-r from-orange-600 to-yellow-600 bg-clip-text text-transparent">
                Industries
              </span>
            </h1>
            <p className="text-xl text-slate-700 mb-8 leading-relaxed max-w-3xl mx-auto">
              Comprehensive solutions across diverse business sectors
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link 
                to="/promoter/dashboard" 
                className="inline-flex items-center justify-center bg-gradient-to-r from-orange-600 to-orange-700 hover:from-orange-700 hover:to-orange-800 text-white font-semibold text-lg px-8 py-3 rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 focus:outline-none focus:ring-4 focus:ring-orange-500/50"
              >
                Promoter Dashboard
                <ArrowRight className="ml-2 h-5 w-5" />
              </Link>
              <Link 
                to="/customer" 
                className="inline-flex items-center justify-center bg-white border-2 border-orange-600 text-orange-700 hover:bg-orange-600 hover:text-white font-semibold text-lg px-8 py-3 rounded-xl shadow-md hover:shadow-lg transition-all duration-200 focus:outline-none focus:ring-4 focus:ring-orange-500/50"
              >
                Customer Portal
              </Link>
            </div>
          </div>

          {/* Products Grid */}
            <div className="bg-gradient-to-br from-slate-800 via-slate-700 to-slate-900 rounded-2xl p-8 shadow-2xl border border-slate-600/50">
              <div className="grid grid-cols-5 gap-4">
                {/* Row 1 */}
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="w-12 h-8 bg-black rounded"></div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">LED TV</p>
                </div>
                
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="w-8 h-12 bg-red-600 rounded"></div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">REFRIGERATOR</p>
                </div>
                
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="w-10 h-10 bg-gray-300 rounded-full"></div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">WASHING MACHINE</p>
                </div>
                
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="grid grid-cols-2 gap-1">
                      <div className="w-3 h-3 bg-blue-500 rounded"></div>
                      <div className="w-3 h-3 bg-red-500 rounded"></div>
                      <div className="w-3 h-3 bg-green-500 rounded"></div>
                      <div className="w-3 h-3 bg-yellow-500 rounded"></div>
                    </div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">COMBO SET</p>
                </div>
                
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="grid grid-cols-2 gap-1">
                      <div className="w-2 h-4 bg-gray-600 rounded"></div>
                      <div className="w-2 h-4 bg-gray-400 rounded"></div>
                      <div className="w-2 h-4 bg-gray-500 rounded"></div>
                      <div className="w-2 h-4 bg-gray-700 rounded"></div>
                    </div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">KITCHEN APPLIANCES</p>
                </div>

                {/* Row 2 */}
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="w-12 h-8 bg-amber-700 rounded"></div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">DINING TABLE</p>
                </div>
                
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="w-8 h-12 bg-amber-800 rounded"></div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">WARDROBE</p>
                </div>
                
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="w-12 h-6 bg-amber-600 rounded"></div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">COT</p>
                </div>
                
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="w-10 h-6 bg-red-400 rounded"></div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">SOFA SET</p>
                </div>
                
                <div className="bg-white rounded-lg p-3 text-center shadow-lg hover:shadow-xl transition-shadow">
                  <div className="bg-gray-100 rounded-lg mb-2 h-16 flex items-center justify-center">
                    <div className="w-10 h-8 bg-gray-800 rounded"></div>
                  </div>
                  <p className="text-xs font-semibold text-gray-800">TV CABINET</p>
                </div>

              </div>
            </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 bg-gradient-to-br from-white via-slate-50 to-orange-50/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-slate-900 mb-4">Our Mission</h2>
            <p className="text-lg text-slate-700 max-w-2xl mx-auto leading-relaxed">
              Leading catalyst for sustainable innovation, linking business success with environmental stewardship
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="text-center p-6 bg-white/80 backdrop-blur-sm rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 border border-orange-200/50">
              <div className="bg-gradient-to-br from-orange-100 to-orange-200 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 shadow-md">
                <Leaf className="h-8 w-8 text-orange-700" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-2">Sustainability Focus</h3>
              <p className="text-slate-700 leading-relaxed">
                Renewable energy, sustainable agriculture, circular economy, and green fintech solutions
              </p>
            </div>

            <div className="text-center p-6 bg-white/80 backdrop-blur-sm rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 border border-blue-200/50">
              <div className="bg-gradient-to-br from-blue-100 to-blue-200 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 shadow-md">
                <Users className="h-8 w-8 text-blue-700" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-2">Global Network</h3>
              <p className="text-slate-700 leading-relaxed">
                50+ portfolio companies and a network of sustainability experts and entrepreneurs
              </p>
            </div>

            <div className="text-center p-6 bg-white/80 backdrop-blur-sm rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 border border-yellow-200/50">
              <div className="bg-gradient-to-br from-yellow-100 to-yellow-200 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 shadow-md">
                <TrendingUp className="h-8 w-8 text-yellow-700" />
              </div>
              <h3 className="text-xl font-semibold text-slate-900 mb-2">Proven Results</h3>
              <p className="text-slate-700 leading-relaxed">
                $200M+ in savings with 15+ years of combined experience in sustainable innovation
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-gradient-to-r from-orange-600 via-orange-700 to-yellow-600 py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl font-bold text-white mb-4 text-shadow-medium">Ready to Make an Impact?</h2>
          <p className="text-xl text-orange-100 mb-8 max-w-2xl mx-auto leading-relaxed">
            Join our platform and be part of the sustainable revolution that's changing the world
          </p>
          <Link 
            to="/register" 
            className="bg-white text-orange-700 hover:bg-orange-50 hover:text-orange-800 px-8 py-3 rounded-xl text-lg font-semibold inline-flex items-center shadow-lg hover:shadow-xl transition-all duration-200 focus:outline-none focus:ring-4 focus:ring-white/50"
          >
            Start Your Journey
            <ArrowRight className="ml-2 h-5 w-5" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center mb-4">
                <Leaf className="h-6 w-6 text-orange-400" />
                <span className="ml-2 text-lg font-bold text-white">BrightPlanet Ventures</span>
              </div>
              <p className="text-slate-300 leading-relaxed">
                Accelerating sustainable economy transition through innovative ventures.
              </p>
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-4 text-white">Services</h3>
              <ul className="space-y-2 text-slate-300">
                <li className="hover:text-orange-400 transition-colors cursor-pointer">Venture Capital</li>
                <li className="hover:text-orange-400 transition-colors cursor-pointer">Innovation Labs</li>
                <li className="hover:text-orange-400 transition-colors cursor-pointer">Advisory Services</li>
                <li className="hover:text-orange-400 transition-colors cursor-pointer">Global Network</li>
              </ul>
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-4 text-white">Focus Areas</h3>
              <ul className="space-y-2 text-slate-300">
                <li className="hover:text-orange-400 transition-colors cursor-pointer">Renewable Energy</li>
                <li className="hover:text-orange-400 transition-colors cursor-pointer">Sustainable Agriculture</li>
                <li className="hover:text-orange-400 transition-colors cursor-pointer">Circular Economy</li>
                <li className="hover:text-orange-400 transition-colors cursor-pointer">Green Fintech</li>
              </ul>
            </div>
            <div>
              <h3 className="text-lg font-semibold mb-4 text-white">Contact</h3>
              <p className="text-slate-300 leading-relaxed">
                Founded in 2020 by sustainability experts and entrepreneurs
              </p>
            </div>
          </div>
          <div className="border-t border-slate-700 mt-8 pt-8 text-center text-slate-400">
            <p>&copy; 2024 BrightPlanet Ventures. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}
