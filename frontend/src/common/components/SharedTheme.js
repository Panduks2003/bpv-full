import React, { useEffect, useRef, useState } from 'react';

// Standardized Typography Scale
export const typography = {
  // Font Sizes (rem values for scalability)
  sizes: {
    xs: '0.75rem',    // 12px
    sm: '0.875rem',   // 14px
    base: '1rem',     // 16px
    lg: '1.125rem',   // 18px
    xl: '1.25rem',    // 20px
    '2xl': '1.5rem',  // 24px
    '3xl': '1.875rem', // 30px
    '4xl': '2.25rem', // 36px
    '5xl': '3rem',    // 48px
    '6xl': '3.75rem', // 60px
    '7xl': '4.5rem',  // 72px
    '8xl': '6rem',    // 96px
    '9xl': '8rem',    // 128px
  },
  // Font Weights
  weights: {
    thin: '100',
    extralight: '200',
    light: '300',
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
    extrabold: '800',
    black: '900',
  },
  // Line Heights
  lineHeights: {
    none: '1',
    tight: '1.25',
    snug: '1.375',
    normal: '1.5',
    relaxed: '1.625',
    loose: '2',
  },
  // Letter Spacing
  letterSpacing: {
    tighter: '-0.05em',
    tight: '-0.025em',
    normal: '0em',
    wide: '0.025em',
    wider: '0.05em',
    widest: '0.1em',
  }
};

// Standardized Spacing Scale (based on 4px grid)
export const spacing = {
  px: '1px',
  0: '0px',
  0.5: '0.125rem', // 2px
  1: '0.25rem',    // 4px
  1.5: '0.375rem', // 6px
  2: '0.5rem',     // 8px
  2.5: '0.625rem', // 10px
  3: '0.75rem',    // 12px
  3.5: '0.875rem', // 14px
  4: '1rem',       // 16px
  5: '1.25rem',    // 20px
  6: '1.5rem',     // 24px
  7: '1.75rem',    // 28px
  8: '2rem',       // 32px
  9: '2.25rem',    // 36px
  10: '2.5rem',    // 40px
  11: '2.75rem',   // 44px
  12: '3rem',      // 48px
  14: '3.5rem',    // 56px
  16: '4rem',      // 64px
  20: '5rem',      // 80px
  24: '6rem',      // 96px
  28: '7rem',      // 112px
  32: '8rem',      // 128px
  36: '9rem',      // 144px
  40: '10rem',     // 160px
  44: '11rem',     // 176px
  48: '12rem',     // 192px
  52: '13rem',     // 208px
  56: '14rem',     // 224px
  60: '15rem',     // 240px
  64: '16rem',     // 256px
  72: '18rem',     // 288px
  80: '20rem',     // 320px
  96: '24rem',     // 384px
};

// Enhanced Color Palette - Harmonized with Logo Colors & Accessibility Focused
export const themeColors = {
  // Primary Brand Colors - Sunset Orange (from logo)
  primary: {
    50: '#FFF8F1',
    100: '#FEECDC',
    200: '#FCD9BD',
    300: '#FDBA74',
    400: '#FB923C',
    500: '#F97316', // Main brand orange - higher contrast
    600: '#EA580C',
    700: '#C2410C',
    800: '#9A3412',
    900: '#7C2D12',
  },
  // Secondary Colors - Golden Yellow (from logo)
  secondary: {
    50: '#FFFBEB',
    100: '#FEF3C7',
    200: '#FDE68A',
    300: '#FCD34D',
    400: '#FBBF24',
    500: '#F59E0B', // Enhanced golden yellow - better contrast
    600: '#D97706',
    700: '#B45309',
    800: '#92400E',
    900: '#78350F',
  },
  // Accent Colors - Professional Blue & Teal (complementary to orange/yellow)
  accent: {
    50: '#EFF6FF',
    100: '#DBEAFE',
    200: '#BFDBFE',
    300: '#93C5FD',
    400: '#60A5FA',
    500: '#3B82F6', // Professional blue - good contrast
    600: '#2563EB',
    700: '#1D4ED8',
    800: '#1E40AF',
    900: '#1E3A8A',
  },
  // Success/Green - Harmonized with brand
  success: {
    50: '#F0FDF4',
    100: '#DCFCE7',
    200: '#BBF7D0',
    300: '#86EFAC',
    400: '#4ADE80',
    500: '#22C55E', // Vibrant green - excellent contrast
    600: '#16A34A',
    700: '#15803D',
    800: '#166534',
    900: '#14532D',
  },
  // Neutral Colors - Enhanced for better readability
  neutral: {
    50: '#FAFAFA',
    100: '#F5F5F5',
    200: '#E5E5E5',
    300: '#D4D4D4',
    400: '#A3A3A3',
    500: '#737373', // Better mid-tone contrast
    600: '#525252',
    700: '#404040',
    800: '#262626',
    900: '#171717', // True dark for high contrast
  },
  // Semantic Colors - High contrast for accessibility
  error: {
    50: '#FEF2F2',
    100: '#FEE2E2',
    200: '#FECACA',
    300: '#FCA5A5',
    400: '#F87171',
    500: '#EF4444', // High contrast red
    600: '#DC2626',
    700: '#B91C1C',
    800: '#991B1B',
    900: '#7F1D1D',
  },
  warning: {
    50: '#FFFBEB',
    100: '#FEF3C7',
    200: '#FDE68A',
    300: '#FCD34D',
    400: '#FBBF24',
    500: '#F59E0B', // Matches secondary for consistency
    600: '#D97706',
    700: '#B45309',
    800: '#92400E',
    900: '#78350F',
  }
};

// Enhanced Gradient Combinations - Improved Accessibility & Brand Harmony
export const gradients = {
  // Primary brand gradients - higher contrast
  primary: 'from-orange-500 via-orange-600 to-orange-700',
  secondary: 'from-yellow-500 via-amber-500 to-orange-500',
  accent: 'from-blue-600 via-blue-700 to-blue-800',
  success: 'from-green-500 via-green-600 to-emerald-600',
  
  // Warm brand combinations
  warm: 'from-orange-600 via-orange-500 to-yellow-500',
  warmLight: 'from-orange-400 via-orange-300 to-yellow-300',
  
  // Cool professional combinations
  cool: 'from-blue-700 via-blue-800 to-slate-800',
  coolLight: 'from-blue-500 via-blue-600 to-blue-700',
  
  // Background gradients - enhanced contrast
  background: 'from-slate-900 via-slate-800 to-slate-900',
  backgroundWarm: 'from-orange-900 via-slate-900 to-blue-900',
  backgroundLight: 'from-slate-50 via-orange-50 to-yellow-50',
  
  // Glass morphism - improved visibility
  glass: 'from-white/20 to-white/10',
  glassHover: 'from-white/30 to-white/20',
  glassStrong: 'from-white/40 to-white/25',
  glassDark: 'from-black/20 to-black/10',
  
  // Semantic gradients
  error: 'from-red-500 via-red-600 to-red-700',
  warning: 'from-yellow-500 via-amber-500 to-orange-500',
  info: 'from-blue-500 via-blue-600 to-indigo-600'
};

// Unified Animation Classes
export const animations = {
  fadeIn: 'animate-fade-in',
  slideUp: 'animate-slide-up',
  slideDown: 'animate-slide-down',
  slideLeft: 'animate-slide-left',
  slideRight: 'animate-slide-right',
  scaleIn: 'animate-scale-in',
  bounceIn: 'animate-bounce-in',
  float: 'animate-float',
  pulse: 'animate-pulse-glow',
  shimmer: 'animate-shimmer',
  gradient: 'animate-gradient-x',
  spin: 'animate-spin-slow',
  tilt: 'animate-tilt',
  glow: 'animate-glow'
};

// Unified CSS Animations and Styles
export const SharedStyles = () => (
  <style>{`
    /* Core Animations */
    @keyframes fade-in {
      from { opacity: 0; transform: translateY(20px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    @keyframes slide-up {
      from { opacity: 0; transform: translateY(40px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    @keyframes slide-down {
      from { opacity: 0; transform: translateY(-40px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    @keyframes slide-left {
      from { opacity: 0; transform: translateX(-40px); }
      to { opacity: 1; transform: translateX(0); }
    }
    
    @keyframes slide-right {
      from { opacity: 0; transform: translateX(40px); }
      to { opacity: 1; transform: translateX(0); }
    }
    
    @keyframes scale-in {
      from { opacity: 0; transform: scale(0.8); }
      to { opacity: 1; transform: scale(1); }
    }
    
    @keyframes bounce-in {
      0% { opacity: 0; transform: scale(0.3) rotate(-10deg); }
      50% { opacity: 1; transform: scale(1.05) rotate(2deg); }
      70% { transform: scale(0.9) rotate(-1deg); }
      100% { opacity: 1; transform: scale(1) rotate(0deg); }
    }
    
    @keyframes float {
      0%, 100% { transform: translateY(0px) rotate(0deg); }
      50% { transform: translateY(-20px) rotate(180deg); }
    }
    
    @keyframes pulse-glow {
      0%, 100% { box-shadow: 0 0 20px rgba(59, 130, 246, 0.5); }
      50% { box-shadow: 0 0 40px rgba(59, 130, 246, 0.8), 0 0 60px rgba(147, 51, 234, 0.3); }
    }
    
    @keyframes shimmer {
      0% { background-position: -200% center; }
      100% { background-position: 200% center; }
    }
    
    @keyframes gradient-x {
      0%, 100% { background-size: 200% 200%; background-position: left center; }
      50% { background-size: 200% 200%; background-position: right center; }
    }
    
    @keyframes spin-slow {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }
    
    @keyframes tilt {
      0%, 100% { transform: rotate(0deg); }
      25% { transform: rotate(1deg); }
      75% { transform: rotate(-1deg); }
    }
    
    @keyframes glow {
      0%, 100% { text-shadow: 0 0 10px currentColor; }
      50% { text-shadow: 0 0 20px currentColor, 0 0 30px currentColor; }
    }
    
    @keyframes morph {
      0%, 100% { border-radius: 60% 40% 30% 70% / 60% 30% 70% 40%; }
      50% { border-radius: 30% 60% 70% 40% / 50% 60% 30% 60%; }
    }
    
    /* Animation Classes */
    .animate-fade-in { animation: fade-in 0.8s ease-out forwards; }
    .animate-slide-up { animation: slide-up 0.8s ease-out forwards; }
    .animate-slide-down { animation: slide-down 0.8s ease-out forwards; }
    .animate-slide-left { animation: slide-left 0.8s ease-out forwards; }
    .animate-slide-right { animation: slide-right 0.8s ease-out forwards; }
    .animate-scale-in { animation: scale-in 0.6s ease-out forwards; }
    .animate-bounce-in { animation: bounce-in 0.8s ease-out forwards; }
    .animate-float { animation: float 6s ease-in-out infinite; }
    .animate-pulse-glow { animation: pulse-glow 2s ease-in-out infinite; }
    .animate-shimmer { 
      background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
      background-size: 200% 100%;
      animation: shimmer 2s infinite;
    }
    .animate-gradient-x { animation: gradient-x 3s ease infinite; }
    .animate-spin-slow { animation: spin-slow 8s linear infinite; }
    .animate-tilt { animation: tilt 2s ease-in-out infinite; }
    .animate-glow { animation: glow 2s ease-in-out infinite; }
    .animate-morph { animation: morph 8s ease-in-out infinite; }
    
    /* Hover Effects */
    .hover-lift {
      transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    }
    
    .hover-lift:hover {
      transform: translateY(-8px) scale(1.02);
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
    }
    
    .hover-glow {
      position: relative;
      overflow: hidden;
      transition: all 0.3s ease;
    }
    
    .hover-glow::before {
      content: '';
      position: absolute;
      top: 0;
      left: -100%;
      width: 100%;
      height: 100%;
      background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.1), transparent);
      transition: left 0.6s ease;
    }
    
    .hover-glow:hover::before {
      left: 100%;
    }
    
    .hover-scale {
      transition: transform 0.3s ease;
    }
    
    .hover-scale:hover {
      transform: scale(1.05);
    }
    
    .hover-rotate {
      transition: transform 0.3s ease;
    }
    
    .hover-rotate:hover {
      transform: rotate(5deg);
    }
    
    .card-tilt {
      transition: transform 0.3s ease;
    }
    
    .card-tilt:hover {
      transform: perspective(1000px) rotateX(5deg) rotateY(-5deg);
    }
    
    .magnetic-hover {
      transition: transform 0.3s ease;
    }
    
    /* Enhanced Glass Morphism Effects - Better Accessibility */
    .glass-card {
      background: rgba(255, 255, 255, 0.25);
      backdrop-filter: blur(20px);
      border: 1px solid rgba(255, 255, 255, 0.4);
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
    }
    
    .glass-card-hover {
      background: rgba(255, 255, 255, 0.35);
      backdrop-filter: blur(25px);
      border: 1px solid rgba(255, 255, 255, 0.5);
      box-shadow: 0 12px 40px rgba(0, 0, 0, 0.5);
    }
    
    .glass-card-dark {
      background: rgba(0, 0, 0, 0.25);
      backdrop-filter: blur(20px);
      border: 1px solid rgba(255, 255, 255, 0.2);
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
    }
    
    .glass-card-strong {
      background: rgba(255, 255, 255, 0.4);
      backdrop-filter: blur(30px);
      border: 1px solid rgba(255, 255, 255, 0.6);
      box-shadow: 0 16px 48px rgba(0, 0, 0, 0.3);
    }
    
    /* Particle Effects */
    .particle-glow {
      filter: drop-shadow(0 0 10px currentColor);
    }
    
    /* Enhanced Text Effects - Better Accessibility */
    .text-glow {
      text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
    }
    
    .text-glow:hover {
      text-shadow: 0 0 20px currentColor, 0 0 40px currentColor, 0 2px 4px rgba(0, 0, 0, 0.5);
      transition: text-shadow 0.3s ease;
    }
    
    .text-gradient {
      background: linear-gradient(135deg, #F97316 0%, #F59E0B 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    
    .text-gradient-cool {
      background: linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    
    .text-shadow-strong {
      text-shadow: 0 4px 8px rgba(0, 0, 0, 0.7), 0 2px 4px rgba(0, 0, 0, 0.5);
    }
    
    .text-shadow-medium {
      text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5), 0 1px 2px rgba(0, 0, 0, 0.3);
    }
    
    .text-shadow-light {
      text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
    }
    
    /* High Contrast Text Utilities */
    .text-high-contrast {
      color: #FFFFFF;
      text-shadow: 0 2px 4px rgba(0, 0, 0, 0.8);
    }
    
    .text-high-contrast-dark {
      color: #171717;
      text-shadow: 0 1px 2px rgba(255, 255, 255, 0.8);
    }
    
    .text-readable-light {
      color: #F5F5F5;
      text-shadow: 0 1px 3px rgba(0, 0, 0, 0.8);
    }
    
    .text-readable-dark {
      color: #262626;
      text-shadow: 0 1px 2px rgba(255, 255, 255, 0.5);
    }
    
    /* Scroll Animations */
    .scroll-animate {
      opacity: 0;
      transform: translateY(30px);
      transition: all 0.8s ease-out;
    }
    
    .scroll-animate.animate-in {
      opacity: 1;
      transform: translateY(0);
    }
    
    /* Custom Scrollbar */
    ::-webkit-scrollbar {
      width: 8px;
    }
    
    ::-webkit-scrollbar-track {
      background: rgba(15, 23, 42, 0.3);
    }
    
    ::-webkit-scrollbar-thumb {
      background: linear-gradient(to bottom, #F7931E, #FDC830);
      border-radius: 4px;
    }
    
    ::-webkit-scrollbar-thumb:hover {
      background: linear-gradient(to bottom, #EA580C, #D97706);
    }
    
    /* Stagger Animation Delays */
    .stagger-1 { animation-delay: 0.1s; }
    .stagger-2 { animation-delay: 0.2s; }
    .stagger-3 { animation-delay: 0.3s; }
    .stagger-4 { animation-delay: 0.4s; }
    .stagger-5 { animation-delay: 0.5s; }
    .stagger-6 { animation-delay: 0.6s; }
    .stagger-7 { animation-delay: 0.7s; }
    .stagger-8 { animation-delay: 0.8s; }
    
    /* Responsive Typography Utilities */
    .text-responsive-xs { font-size: clamp(0.75rem, 2vw, 0.875rem); }
    .text-responsive-sm { font-size: clamp(0.875rem, 2.5vw, 1rem); }
    .text-responsive-base { font-size: clamp(1rem, 3vw, 1.125rem); }
    .text-responsive-lg { font-size: clamp(1.125rem, 3.5vw, 1.25rem); }
    .text-responsive-xl { font-size: clamp(1.25rem, 4vw, 1.5rem); }
    .text-responsive-2xl { font-size: clamp(1.5rem, 5vw, 1.875rem); }
    .text-responsive-3xl { font-size: clamp(1.875rem, 6vw, 2.25rem); }
    .text-responsive-4xl { font-size: clamp(2.25rem, 7vw, 3rem); }
    .text-responsive-5xl { font-size: clamp(3rem, 8vw, 3.75rem); }
    .text-responsive-6xl { font-size: clamp(3.75rem, 10vw, 4.5rem); }
    
    /* Mobile-First Responsive Spacing */
    .spacing-responsive-sm { padding: clamp(1rem, 4vw, 1.5rem); }
    .spacing-responsive-md { padding: clamp(1.5rem, 5vw, 2rem); }
    .spacing-responsive-lg { padding: clamp(2rem, 6vw, 3rem); }
    .spacing-responsive-xl { padding: clamp(3rem, 8vw, 4rem); }
    
    /* Enhanced Focus States for Accessibility */
    .focus-ring {
      transition: all 0.2s ease-in-out;
    }
    
    .focus-ring:focus {
      outline: 2px solid #F97316;
      outline-offset: 2px;
      box-shadow: 0 0 0 4px rgba(249, 115, 22, 0.2);
    }
    
    .focus-ring:focus-visible {
      outline: 2px solid #F97316;
      outline-offset: 2px;
      box-shadow: 0 0 0 4px rgba(249, 115, 22, 0.2);
    }
    
    /* High Contrast Mode Support */
    @media (prefers-contrast: high) {
      .text-readable-light { color: #FFFFFF; text-shadow: 0 2px 4px rgba(0, 0, 0, 1); }
      .text-readable-dark { color: #000000; text-shadow: none; }
      .glass-card { background: rgba(255, 255, 255, 0.95); border: 2px solid rgba(0, 0, 0, 0.8); }
      .glass-card-dark { background: rgba(0, 0, 0, 0.95); border: 2px solid rgba(255, 255, 255, 0.8); }
    }
    
    /* Reduced Motion Support */
    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
      }
      
      .animate-float, .animate-pulse-glow, .animate-shimmer, 
      .animate-gradient-x, .animate-spin-slow, .animate-tilt, 
      .animate-glow, .animate-morph {
        animation: none !important;
      }
    }
    
    /* Print Styles */
    @media print {
      .no-print { display: none !important; }
      .print-only { display: block !important; }
      
      * {
        background: white !important;
        color: black !important;
        box-shadow: none !important;
        text-shadow: none !important;
      }
      
      .glass-card, .glass-card-hover, .glass-card-dark, .glass-card-strong {
        background: white !important;
        border: 1px solid black !important;
        backdrop-filter: none !important;
      }
    }
  `}</style>
);

// Unified Background Component
export const UnifiedBackground = ({ variant = 'default', children }) => {
  const backgroundVariants = {
    default: gradients.background,
    alt: gradients.backgroundAlt,
    dark: 'from-gray-900 via-black to-gray-800',
    cosmic: 'from-orange-900 via-yellow-900 to-blue-900'
  };

  return (
    <div className={`relative min-h-screen bg-gradient-to-br ${backgroundVariants[variant]} overflow-hidden`}>
      {/* Animated Background Elements */}
      <div className="absolute inset-0 -z-10">
        {/* Floating Orbs */}
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-to-r from-orange-500/20 to-yellow-500/20 rounded-full blur-3xl animate-float" />
        <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-gradient-to-r from-yellow-500/20 to-orange-400/20 rounded-full blur-3xl animate-float" style={{ animationDelay: '2s' }} />
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-gradient-to-r from-blue-800/20 to-blue-600/20 rounded-full blur-3xl animate-float" style={{ animationDelay: '4s' }} />
        
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
        <div className="absolute top-1/2 left-1/2 w-2 h-2 bg-orange-400 rounded-full animate-ping" />
        <div className="absolute top-1/3 right-1/4 w-1.5 h-1.5 bg-yellow-400 rounded-full animate-ping" style={{ animationDelay: '1s' }} />
        <div className="absolute bottom-1/3 left-1/4 w-1 h-1 bg-emerald-400 rounded-full animate-ping" style={{ animationDelay: '2s' }} />
        <div className="absolute top-2/3 right-1/3 w-1.5 h-1.5 bg-blue-600 rounded-full animate-ping" style={{ animationDelay: '3s' }} />
      </div>
      
      {children}
    </div>
  );
};

// Interactive Particle System Hook
export const useInteractiveParticles = (canvasRef, particleCount = 50) => {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e) => {
      setMousePosition({
        x: (e.clientX / window.innerWidth) * 100,
        y: (e.clientY / window.innerHeight) * 100
      });
    };
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const resizeCanvas = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    resizeCanvas();

    const particles = [];

    class InteractiveParticle {
      constructor() {
        this.x = Math.random() * canvas.width;
        this.y = Math.random() * canvas.height;
        this.size = Math.random() * 3 + 1;
        this.speedX = (Math.random() - 0.5) * 2;
        this.speedY = (Math.random() - 0.5) * 2;
        this.opacity = Math.random() * 0.5 + 0.2;
        this.hue = Math.random() * 60 + 200;
        this.life = Math.random() * 100 + 100;
        this.maxLife = this.life;
      }

      update() {
        this.x += this.speedX;
        this.y += this.speedY;
        this.life--;

        // Mouse interaction
        const mouseX = (mousePosition.x / 100) * canvas.width;
        const mouseY = (mousePosition.y / 100) * canvas.height;
        const dx = mouseX - this.x;
        const dy = mouseY - this.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        if (distance < 100) {
          const force = (100 - distance) / 100;
          this.x -= (dx / distance) * force * 2;
          this.y -= (dy / distance) * force * 2;
          this.opacity = Math.min(1, this.opacity + force * 0.02);
        }

        // Boundaries
        if (this.x < 0 || this.x > canvas.width) this.speedX *= -1;
        if (this.y < 0 || this.y > canvas.height) this.speedY *= -1;

        // Respawn
        if (this.life <= 0) {
          this.x = Math.random() * canvas.width;
          this.y = Math.random() * canvas.height;
          this.life = this.maxLife;
        }
      }

      draw() {
        ctx.save();
        ctx.globalAlpha = this.opacity * (this.life / this.maxLife);
        ctx.fillStyle = `hsl(${this.hue}, 70%, 60%)`;
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      }
    }

    for (let i = 0; i < particleCount; i++) {
      particles.push(new InteractiveParticle());
    }

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      particles.forEach(particle => {
        particle.update();
        particle.draw();
      });
      requestAnimationFrame(animate);
    };

    animate();
    window.addEventListener('resize', resizeCanvas);
    return () => window.removeEventListener('resize', resizeCanvas);
  }, [mousePosition, particleCount]);

  return mousePosition;
};

// Scroll Animation Hook
export const useScrollAnimation = () => {
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('animate-in');
          }
        });
      },
      { threshold: 0.1, rootMargin: '0px 0px -50px 0px' }
    );

    const elements = document.querySelectorAll('.scroll-animate');
    elements.forEach((el) => observer.observe(el));

    return () => observer.disconnect();
  }, []);
};

// Enhanced Unified Card Component - Better Accessibility
export const UnifiedCard = ({ 
  children, 
  className = '', 
  variant = 'glassDark',
  hover = true,
  animation = 'fade-in',
  delay = 0,
  textContrast = 'dark'
}) => {
  const variants = {
    glass: 'bg-white/90 backdrop-blur-md border border-slate-200/50 shadow-lg text-slate-900',
    glassStrong: 'bg-white/95 backdrop-blur-lg border border-slate-200/60 shadow-xl text-slate-900',
    glassDark: 'bg-slate-800/95 backdrop-blur-md border border-slate-600/50 shadow-lg text-white',
    solid: 'bg-white/90 border border-slate-200/50 shadow-md text-slate-900',
    solidDark: 'bg-slate-800/95 border border-slate-600/50 shadow-md text-white',
    gradient: `bg-gradient-to-br from-white/90 to-white/80 border border-slate-200/50 shadow-lg text-slate-900`,
    gradientStrong: `bg-gradient-to-br from-white/95 to-white/85 border border-slate-200/60 shadow-xl text-slate-900`,
  };

  const textContrastClass = textContrast === 'light' ? 'text-white' : 'text-slate-900';
  const hoverClass = hover ? 'hover-lift hover-glow' : '';
  const animationClass = `animate-${animation}`;
  const delayStyle = delay ? { animationDelay: `${delay}s` } : {};

  return (
    <div 
      className={`${variants[variant]} ${hoverClass} ${animationClass} rounded-2xl p-6 ${className}`}
      style={delayStyle}
    >
      {children}
    </div>
  );
};

// Enhanced Unified Button Component - Better Accessibility
export const UnifiedButton = ({ 
  children, 
  variant = 'primary', 
  size = 'md',
  className = '',
  disabled = false,
  ...props 
}) => {
  const variants = {
    primary: `bg-gradient-to-r ${gradients.primary} text-high-contrast shadow-lg hover:shadow-xl hover:shadow-orange-500/30 border border-white/30 focus:ring-4 focus:ring-orange-500/50`,
    secondary: `bg-gradient-to-r ${gradients.secondary} text-high-contrast shadow-lg hover:shadow-xl hover:shadow-yellow-500/30 border border-white/30 focus:ring-4 focus:ring-yellow-500/50`,
    accent: `bg-gradient-to-r ${gradients.accent} text-high-contrast shadow-lg hover:shadow-xl hover:shadow-blue-500/30 border border-white/30 focus:ring-4 focus:ring-blue-500/50`,
    success: `bg-gradient-to-r ${gradients.success} text-high-contrast shadow-lg hover:shadow-xl hover:shadow-green-500/30 border border-white/30 focus:ring-4 focus:ring-green-500/50`,
    ghost: 'bg-white/15 backdrop-blur-md border-2 border-white/40 text-readable-light hover:bg-white/25 hover:border-white/60 focus:ring-4 focus:ring-white/30',
    glass: 'glass-card text-readable-light hover:glass-card-hover focus:ring-4 focus:ring-white/30',
    outline: 'bg-transparent border-2 border-orange-500 text-orange-500 hover:bg-orange-500 hover:text-white focus:ring-4 focus:ring-orange-500/50'
  };

  const sizes = {
    sm: 'px-4 py-2 text-sm',
    md: 'px-6 py-3 text-base',
    lg: 'px-8 py-4 text-lg',
    xl: 'px-10 py-5 text-xl'
  };

  const disabledClass = disabled ? 'opacity-50 cursor-not-allowed' : 'hover:scale-105 hover:-translate-y-1 active:scale-95';

  return (
    <button 
      className={`${variants[variant]} ${sizes[size]} ${disabledClass} rounded-xl font-semibold transition-all duration-300 focus:outline-none ${className}`}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
};

// Typography Component for consistent text styling
export const Typography = ({ 
  variant = 'body', 
  size = 'base',
  weight = 'normal',
  color = 'slate-900',
  className = '',
  children,
  ...props 
}) => {
  const variants = {
    h1: 'text-4xl md:text-5xl lg:text-6xl font-extrabold leading-tight tracking-tight',
    h2: 'text-3xl md:text-4xl lg:text-5xl font-bold leading-tight tracking-tight',
    h3: 'text-2xl md:text-3xl font-bold leading-snug',
    h4: 'text-xl md:text-2xl font-semibold leading-snug',
    h5: 'text-lg md:text-xl font-semibold leading-normal',
    h6: 'text-base md:text-lg font-semibold leading-normal',
    body: 'text-base leading-relaxed',
    bodyLarge: 'text-lg leading-relaxed',
    bodySmall: 'text-sm leading-normal',
    caption: 'text-xs leading-normal',
    overline: 'text-xs uppercase tracking-wider font-medium',
    button: 'text-sm font-semibold leading-none',
    label: 'text-sm font-medium leading-normal',
  };

  const Component = variant.startsWith('h') ? variant : 'p';
  
  return React.createElement(
    Component,
    {
      className: `${variants[variant]} text-${color} ${className}`,
      ...props
    },
    children
  );
};

// Input Component for consistent form styling
export const UnifiedInput = ({
  type = 'text',
  variant = 'default',
  size = 'md',
  error = false,
  className = '',
  ...props
}) => {
  const variants = {
    default: 'bg-white border-slate-300 text-slate-900 placeholder-slate-500',
    filled: 'bg-slate-50 border-slate-200 text-slate-900 placeholder-slate-500',
    outlined: 'bg-transparent border-slate-400 text-slate-900 placeholder-slate-500',
  };

  const sizes = {
    sm: 'px-3 py-2 text-sm',
    md: 'px-4 py-3 text-base',
    lg: 'px-4 py-4 text-lg',
  };

  const errorClass = error ? 'border-red-500 focus:border-red-500 focus:ring-red-500/20' : 'focus:border-orange-500 focus:ring-orange-500/20';

  return (
    <input
      type={type}
      className={`${variants[variant]} ${sizes[size]} ${errorClass} border rounded-xl focus:outline-none focus:ring-2 transition-all duration-300 hover:border-slate-400 shadow-sm ${className}`}
      {...props}
    />
  );
};

// Container Component for consistent layout
export const Container = ({ 
  size = 'default',
  className = '',
  children,
  ...props 
}) => {
  const sizes = {
    sm: 'max-w-3xl',
    default: 'max-w-6xl',
    lg: 'max-w-7xl',
    xl: 'max-w-screen-2xl',
    full: 'max-w-full',
  };

  return (
    <div 
      className={`${sizes[size]} mx-auto px-4 sm:px-6 lg:px-8 ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};

// Responsive Breakpoints
export const breakpoints = {
  xs: '475px',
  sm: '640px',
  md: '768px',
  lg: '1024px',
  xl: '1280px',
  '2xl': '1536px',
};

// Responsive Utilities
export const responsive = {
  // Mobile-first responsive text sizes
  text: {
    xs: 'text-xs sm:text-sm',
    sm: 'text-sm sm:text-base',
    base: 'text-sm sm:text-base lg:text-lg',
    lg: 'text-base sm:text-lg lg:text-xl',
    xl: 'text-lg sm:text-xl lg:text-2xl',
    '2xl': 'text-xl sm:text-2xl lg:text-3xl',
    '3xl': 'text-2xl sm:text-3xl lg:text-4xl',
    '4xl': 'text-3xl sm:text-4xl lg:text-5xl',
    '5xl': 'text-4xl sm:text-5xl lg:text-6xl',
  },
  
  // Responsive spacing
  spacing: {
    xs: 'p-2 sm:p-3',
    sm: 'p-3 sm:p-4',
    md: 'p-4 sm:p-6',
    lg: 'p-6 sm:p-8',
    xl: 'p-8 sm:p-12',
  },
  
  // Responsive gaps
  gap: {
    xs: 'gap-1 sm:gap-2',
    sm: 'gap-2 sm:gap-3',
    md: 'gap-3 sm:gap-4',
    lg: 'gap-4 sm:gap-6',
    xl: 'gap-6 sm:gap-8',
  },
  
  // Responsive margins
  margin: {
    xs: 'm-2 sm:m-3',
    sm: 'm-3 sm:m-4',
    md: 'm-4 sm:m-6',
    lg: 'm-6 sm:m-8',
    xl: 'm-8 sm:m-12',
  },
  
  // Responsive grid columns
  grid: {
    auto: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3',
    cards: 'grid-cols-1 md:grid-cols-2 xl:grid-cols-3',
    features: 'grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5',
    stats: 'grid-cols-2 sm:grid-cols-4',
    form: 'grid-cols-1 sm:grid-cols-2',
  },
  
  // Responsive flex directions
  flex: {
    stack: 'flex-col sm:flex-row',
    reverse: 'flex-col-reverse sm:flex-row',
  },
};

// CSS-in-JS responsive styles
export const responsiveStyles = `
  /* Mobile-first responsive utilities */
  .responsive-text {
    @apply text-sm;
  }
  
  @media (min-width: 640px) {
    .responsive-text {
      @apply text-base;
    }
  }
  
  @media (min-width: 1024px) {
    .responsive-text {
      @apply text-lg;
    }
  }
  
  /* Responsive containers */
  .responsive-container {
    @apply px-4;
  }
  
  @media (min-width: 640px) {
    .responsive-container {
      @apply px-6;
    }
  }
  
  @media (min-width: 1024px) {
    .responsive-container {
      @apply px-8;
    }
  }
  
  /* Responsive cards */
  .responsive-card {
    @apply p-4 rounded-lg;
  }
  
  @media (min-width: 640px) {
    .responsive-card {
      @apply p-6 rounded-xl;
    }
  }
  
  @media (min-width: 1024px) {
    .responsive-card {
      @apply p-8 rounded-2xl;
    }
  }
`;

export default {
  typography,
  spacing,
  themeColors,
  gradients,
  animations,
  breakpoints,
  responsive,
  SharedStyles,
  UnifiedBackground,
  useInteractiveParticles,
  useScrollAnimation,
  UnifiedCard,
  UnifiedButton,
  Typography,
  UnifiedInput,
  Container
};
