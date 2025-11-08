import React, { useState } from "react";
import { 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../components/SharedTheme";
import { validateForm, sanitizeInput } from "../utils/security";

function Contact() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    subject: '',
    message: ''
  });
  const [formErrors, setFormErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  
  useScrollAnimation();

  // Security validation rules
  const validationRules = {
    name: { required: true },
    email: { required: true, type: 'email' },
    phone: { required: false, type: 'phone' },
    subject: { required: false },
    message: { required: true }
  };

  // Handle form submission with security validation
  const handleSubmit = async (e) => {
    e.preventDefault();
    setFormErrors({});
    
    // Comprehensive security validation
    const validation = validateForm(formData, validationRules);
    
    if (!validation.isValid) {
      setFormErrors(validation.errors);
      return;
    }
    
    // Sanitize all inputs before submission
    const sanitizedData = {};
    for (const [key, value] of Object.entries(formData)) {
      sanitizedData[key] = typeof value === 'string' ? sanitizeInput(value) : value;
    }
    
    setIsSubmitting(true);
    // Simulate API call with sanitized data
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsSubmitting(false);
    setSubmitSuccess(true);
    setFormData({ name: '', email: '', phone: '', subject: '', message: '' });
    setTimeout(() => setSubmitSuccess(false), 5000);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    
    // Clear error when user starts typing
    if (formErrors[name]) {
      setFormErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  return (
    <>
      <SharedStyles />
      <div className="min-h-screen bg-white">
        
        {/* Hero Section - Matching Other Pages */}
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

          {/* Main Background Overlays */}
          <div className="absolute inset-0 bg-gradient-to-t from-slate-900/30 via-transparent to-slate-900/10" />
          <div className="absolute inset-0 bg-gradient-to-r from-orange-600/8 via-transparent to-yellow-500/8" />

          <div className="relative flex items-center justify-center min-h-[60vh] px-4 sm:px-6 lg:px-8">
            <div className="text-center max-w-5xl mx-auto">
              <div className="inline-flex items-center gap-2 px-6 py-3 bg-white/95 rounded-full mb-8 border border-orange-200 hover:border-orange-300 transition-all duration-300 hover:scale-105 group shadow-md">
                <span className="w-3 h-3 rounded-full bg-gradient-to-r from-orange-400 to-yellow-400 animate-pulse group-hover:animate-spin" />
                <span className="text-sm font-medium text-slate-800 group-hover:text-slate-900 transition-colors">Get In Touch</span>
              </div>
              
              <h1 className="text-4xl sm:text-6xl lg:text-7xl font-extrabold mb-12 leading-tight">
                <span className="text-slate-900">Contact </span>
                <span className="bg-gradient-to-r from-orange-600 via-yellow-600 to-orange-500 bg-clip-text text-transparent">
                  Us
                </span>
              </h1>
              
              <div className="relative max-w-4xl mx-auto">
                <p className="text-xl sm:text-2xl text-slate-800 leading-relaxed bg-white/95 rounded-2xl p-8 shadow-lg font-medium border border-slate-200">
                  Ready to transform your business? Let's connect and explore how we can help you achieve your goals in{' '}
                  <strong className="text-orange-600">Belagavi</strong>
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="max-w-7xl mx-auto px-4 py-12 sm:py-16 sm:px-6 lg:px-8">
          
          {/* Contact Content */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 sm:gap-10 lg:gap-16">
            
            {/* Contact Form */}
            <div>
              <div className="mb-6 sm:mb-8">
                <h2 className="text-2xl sm:text-3xl font-bold text-slate-900 mb-3 sm:mb-4">Send us a Message</h2>
                <p className="text-base sm:text-lg text-slate-600">Fill out the form below and we'll get back to you within 24 hours.</p>
              </div>

              {submitSuccess && (
                <div className="mb-6 p-4 bg-green-50 border border-green-200 rounded-xl">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                      <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    <div>
                      <p className="text-green-800 font-semibold">Message sent successfully!</p>
                      <p className="text-green-700 text-sm">We'll get back to you within 24 hours.</p>
                    </div>
                  </div>
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4 sm:space-y-5 lg:space-y-6">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
                  <div>
                    <label className="block text-sm font-medium text-slate-900 mb-2">Name *</label>
                    <input
                      type="text"
                      name="name"
                      value={formData.name}
                      onChange={handleInputChange}
                      className="w-full px-3 sm:px-4 py-2.5 sm:py-3 bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-500 focus:outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 transition-all duration-300 text-sm sm:text-base"
                      placeholder="Your full name"
                    />
                    {formErrors.name && (
                      <p className="mt-1 text-sm text-red-600">{formErrors.name}</p>
                    )}
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-slate-900 mb-2">Email *</label>
                    <input
                      type="email"
                      name="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      className="w-full px-3 sm:px-4 py-2.5 sm:py-3 bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-500 focus:outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 transition-all duration-300 text-sm sm:text-base"
                      placeholder="your.email@example.com"
                    />
                    {formErrors.email && (
                      <p className="mt-1 text-sm text-red-600">{formErrors.email}</p>
                    )}
                  </div>
                </div>
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
                  <div>
                    <label className="block text-sm font-medium text-slate-900 mb-2">Phone</label>
                    <input
                      type="tel"
                      name="phone"
                      value={formData.phone}
                      onChange={handleInputChange}
                      className="w-full px-3 sm:px-4 py-2.5 sm:py-3 bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-500 focus:outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 transition-all duration-300 text-sm sm:text-base"
                      placeholder="+91 98765 43210"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-slate-900 mb-2">Subject</label>
                    <select
                      name="subject"
                      value={formData.subject}
                      onChange={handleInputChange}
                      className="w-full px-3 sm:px-4 py-2.5 sm:py-3 bg-white border border-slate-300 rounded-lg text-slate-900 focus:outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 transition-all duration-300 text-sm sm:text-base"
                    >
                      <option value="">Select a subject</option>
                      <option value="general">General Inquiry</option>
                      <option value="services">Services</option>
                      <option value="partnership">Partnership</option>
                      <option value="support">Support</option>
                      <option value="other">Other</option>
                    </select>
                  </div>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-slate-900 mb-2">Message *</label>
                  <textarea
                    name="message"
                    value={formData.message}
                    onChange={handleInputChange}
                    rows={5}
                    className="w-full px-3 sm:px-4 py-2.5 sm:py-3 bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-500 focus:outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 transition-all duration-300 resize-none text-sm sm:text-base"
                    placeholder="Tell us how we can help you..."
                  />
                  {formErrors.message && (
                    <p className="mt-1 text-sm text-red-600">{formErrors.message}</p>
                  )}
                </div>
                
                <UnifiedButton
                  type="submit"
                  disabled={isSubmitting}
                  variant="primary"
                  className="w-full py-3 sm:py-4 text-base sm:text-lg font-semibold min-h-[48px]"
                >
                  {isSubmitting ? (
                    <div className="flex items-center justify-center gap-2">
                      <svg className="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      <span>Sending Message...</span>
                    </div>
                  ) : (
                    <div className="flex items-center justify-center gap-2">
                      <span>Send Message</span>
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                      </svg>
                    </div>
                  )}
                </UnifiedButton>
              </form>
            </div>

            {/* Contact Information */}
            <div className="space-y-6 sm:space-y-8 mt-8 lg:mt-0">
              <div>
                <h2 className="text-2xl sm:text-3xl font-bold text-slate-900 mb-3 sm:mb-4">Get in Touch</h2>
                <p className="text-base sm:text-lg text-slate-600 mb-6 sm:mb-8">
                  We're here to help and answer any questions you might have. We look forward to hearing from you.
                </p>
              </div>

              {/* Contact Cards */}
              <div className="space-y-4 sm:space-y-5 lg:space-y-6">
                {/* Phone */}
                <div className="flex items-start gap-3 sm:gap-4 p-4 sm:p-5 lg:p-6 bg-slate-50 rounded-lg sm:rounded-xl border border-slate-200 hover:border-slate-300 transition-colors">
                  <div className="w-10 h-10 sm:w-12 sm:h-12 bg-green-100 rounded-lg sm:rounded-xl flex items-center justify-center flex-shrink-0">
                    <svg className="w-5 h-5 sm:w-6 sm:h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="text-base sm:text-lg font-semibold text-slate-900 mb-1">Call Us</h3>
                    <p className="text-green-600 font-semibold text-base sm:text-lg">+91 7353297211</p>
                    <p className="text-slate-600 text-xs sm:text-sm">Monday - Friday, 9:00 AM - 6:00 PM</p>
                  </div>
                </div>

                {/* Email */}
                <div className="flex items-start gap-3 sm:gap-4 p-4 sm:p-5 lg:p-6 bg-slate-50 rounded-lg sm:rounded-xl border border-slate-200 hover:border-slate-300 transition-colors">
                  <div className="w-10 h-10 sm:w-12 sm:h-12 bg-blue-100 rounded-lg sm:rounded-xl flex items-center justify-center flex-shrink-0">
                    <svg className="w-5 h-5 sm:w-6 sm:h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="text-base sm:text-lg font-semibold text-slate-900 mb-1">Email Us</h3>
                    <p className="text-blue-600 font-semibold text-sm sm:text-base break-all">hello@brightplanetventures.com</p>
                    <p className="text-slate-600 text-xs sm:text-sm">We'll respond within 24 hours</p>
                  </div>
                </div>

                {/* Location */}
                <div className="flex items-start gap-3 sm:gap-4 p-4 sm:p-5 lg:p-6 bg-slate-50 rounded-lg sm:rounded-xl border border-slate-200 hover:border-slate-300 transition-colors">
                  <div className="w-10 h-10 sm:w-12 sm:h-12 bg-orange-100 rounded-lg sm:rounded-xl flex items-center justify-center flex-shrink-0">
                    <svg className="w-5 h-5 sm:w-6 sm:h-6 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="text-base sm:text-lg font-semibold text-slate-900 mb-1">Visit Us</h3>
                    <p className="text-orange-600 font-semibold text-sm sm:text-base">Gokak, Karnataka, India</p>
                    <p className="text-slate-600 text-xs sm:text-sm">Our office location</p>
                  </div>
                </div>

              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

export default Contact;
