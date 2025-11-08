import React, { useState, useEffect, useRef } from "react";
import { Link, useLocation } from "react-router-dom";

function PublicNavbar() {
  const location = useLocation();
  const [isOpen, setIsOpen] = useState(false);
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
  const [activeIndex, setActiveIndex] = useState(-1);
  const [isVisible, setIsVisible] = useState(false);
  const navbarRef = useRef(null);
  const particleCanvasRef = useRef(null);



  // Entry animation - make it immediate for debugging
  useEffect(() => {
    setIsVisible(true); // Remove delay for now
  }, []);

  // Mouse tracking for parallax effect
  useEffect(() => {
    const handleMouseMove = (e) => {
      setMousePosition({ x: e.clientX, y: e.clientY });
    };
    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  // Enhanced particle animation with geometric shapes
  useEffect(() => {
    const canvas = particleCanvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    canvas.width = window.innerWidth;
    canvas.height = 100;

    const particles = [];
    const geometricShapes = [];
    const particleCount = 30;
    const shapeCount = 8;

    class Particle {
      constructor() {
        this.x = Math.random() * canvas.width;
        this.y = Math.random() * canvas.height;
        this.size = Math.random() * 3 + 1;
        this.speedX = Math.random() * 2 - 1;
        this.speedY = Math.random() * 2 - 1;
        this.opacity = Math.random() * 0.6 + 0.2;
        this.color = `hsl(${Math.random() * 60 + 240}, 70%, 60%)`;
        this.rotation = 0;
        this.rotationSpeed = (Math.random() - 0.5) * 0.1;
      }

      update() {
        this.x += this.speedX;
        this.y += this.speedY;
        this.rotation += this.rotationSpeed;

        if (this.x > canvas.width) this.x = 0;
        if (this.x < 0) this.x = canvas.width;
        if (this.y > canvas.height) this.y = 0;
        if (this.y < 0) this.y = canvas.height;
      }

      draw() {
        ctx.save();
        ctx.translate(this.x, this.y);
        ctx.rotate(this.rotation);
        ctx.globalAlpha = this.opacity;
        ctx.fillStyle = this.color;
        
        // Draw star shape
        ctx.beginPath();
        for (let i = 0; i < 5; i++) {
          const angle = (i * 2 * Math.PI) / 5;
          const x = Math.cos(angle) * this.size;
          const y = Math.sin(angle) * this.size;
          if (i === 0) ctx.moveTo(x, y);
          else ctx.lineTo(x, y);
        }
        ctx.closePath();
        ctx.fill();
        ctx.restore();
      }
    }

    class GeometricShape {
      constructor() {
        this.x = Math.random() * canvas.width;
        this.y = Math.random() * canvas.height;
        this.size = Math.random() * 20 + 10;
        this.type = Math.floor(Math.random() * 3); // 0: triangle, 1: square, 2: circle
        this.rotation = Math.random() * Math.PI * 2;
        this.rotationSpeed = (Math.random() - 0.5) * 0.02;
        this.opacity = Math.random() * 0.3 + 0.1;
        this.color = `hsl(${Math.random() * 60 + 200}, 80%, 70%)`;
      }

      update() {
        this.rotation += this.rotationSpeed;
      }

      draw() {
        ctx.save();
        ctx.translate(this.x, this.y);
        ctx.rotate(this.rotation);
        ctx.globalAlpha = this.opacity;
        ctx.strokeStyle = this.color;
        ctx.lineWidth = 2;

        switch (this.type) {
          case 0: // Triangle
            ctx.beginPath();
            ctx.moveTo(0, -this.size);
            ctx.lineTo(-this.size * 0.866, this.size * 0.5);
            ctx.lineTo(this.size * 0.866, this.size * 0.5);
            ctx.closePath();
            ctx.stroke();
            break;
          case 1: // Square
            ctx.strokeRect(-this.size, -this.size, this.size * 2, this.size * 2);
            break;
          case 2: // Circle
            ctx.beginPath();
            ctx.arc(0, 0, this.size, 0, Math.PI * 2);
            ctx.stroke();
            break;
          default:
            // Default case for any unexpected values
            break;
        }
        ctx.restore();
      }
    }

    for (let i = 0; i < particleCount; i++) {
      particles.push(new Particle());
    }

    for (let i = 0; i < shapeCount; i++) {
      geometricShapes.push(new GeometricShape());
    }

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      geometricShapes.forEach(shape => {
        shape.update();
        shape.draw();
      });

      particles.forEach(particle => {
        particle.update();
        particle.draw();
      });

      requestAnimationFrame(animate);
    };

    animate();

    const handleResize = () => {
      canvas.width = window.innerWidth;
      canvas.height = 100;
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Simple navigation items
  const navItems = [
    { path: "/", label: "Home" },
    { path: "/about", label: "About" },
    { path: "/ventures", label: "Ventures" },
    { path: "/contact", label: "Contact" },
    { path: "/login", label: "Login" }
  ];

  const handleNavItemClick = () => {
    setIsOpen(false);
  };

  return (
    <>
      
      {/* Main Navbar */}
      <nav 
        ref={navbarRef}
        data-testid="public-navbar"
        className="fixed top-4 left-4 right-4 z-50 opacity-100 translate-y-0"
        style={{ minHeight: '60px' }}
      >
        {/* Modern Floating Container */}
        <div className="relative">
          {/* Main Navbar Container with enhanced glassmorphism */}
          <div className="relative bg-gradient-to-r from-slate-600/70 via-orange-600/60 to-slate-600/70 backdrop-blur-2xl border border-orange-300/40 rounded-2xl shadow-[0_8px_32px_rgba(0,0,0,0.2)] transition-all duration-500 hover:shadow-[0_12px_40px_rgba(247,147,30,0.3)] hover:border-orange-300/60 hover:bg-gradient-to-r hover:from-slate-500/75 hover:via-orange-500/65 hover:to-slate-500/75">
            <div className="max-w-7xl mx-auto px-8 py-4">
              <div className="flex justify-between items-center">
                
                {/* Enhanced Logo Section */}
                <div className="relative">
                  <Link 
                    to="/"
                    className="relative px-4 py-2 block group transition-all duration-300 hover:scale-105"
                    title="BrightPlanet Ventures - Home"
                  >
                    <img 
                      src="/new-logo.png" 
                      alt="BrightPlanet Ventures" 
                      className="h-12 w-auto filter drop-shadow-lg group-hover:drop-shadow-xl transition-all duration-300"
                    />
                    <div className="absolute inset-0 bg-gradient-to-r from-orange-500/0 to-yellow-500/0 group-hover:from-orange-500/10 group-hover:to-yellow-500/10 rounded-lg transition-all duration-300"></div>
                  </Link>
                </div>

                {/* Enhanced Mobile Menu Button */}
                <button 
                  aria-label="Toggle menu" 
                  className="md:hidden relative z-50 p-3 rounded-xl bg-slate-500/60 backdrop-blur-md border border-orange-300/40 transition-all duration-300 hover:bg-slate-400/70 hover:border-orange-300/60 hover:shadow-lg"
                  onClick={() => setIsOpen((v) => !v)}
                >
                  <div className={`w-6 h-0.5 bg-white transition-all duration-300 ${isOpen ? 'rotate-45 translate-y-1.5' : ''}`} />
                  <div className={`w-6 h-0.5 bg-white my-1.5 transition-all duration-300 ${isOpen ? 'opacity-0' : ''}`} />
                  <div className={`w-6 h-0.5 bg-white transition-all duration-300 ${isOpen ? '-rotate-45 -translate-y-1.5' : ''}`} />
                </button>

                {/* Enhanced Desktop Navigation */}
                <div className="hidden md:flex space-x-1">
                  {navItems.map((item, index) => (
                    <div key={item.path} className="relative">
                      <Link
                        to={item.path}
                        className={`
                          px-4 py-2 rounded-lg font-medium transition-all duration-200 border backdrop-blur-sm
                          ${location.pathname === item.path 
                            ? 'text-orange-100 bg-gradient-to-r from-orange-400/35 to-yellow-400/25 border-orange-300/50 shadow-lg shadow-orange-400/25' 
                            : 'text-white/95 border-transparent hover:bg-slate-500/40 hover:border-orange-300/40 hover:shadow-md hover:text-orange-100'
                          }
                        `}
                      >
                        <span>{item.label}</span>
                      </Link>
                    </div>
                  ))}
                </div>
              </div>

              {/* Enhanced Mobile Menu */}
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
                            ? 'text-orange-100 bg-gradient-to-r from-orange-400/35 to-yellow-400/25 border-orange-300/50 shadow-lg shadow-orange-400/25' 
                            : 'text-white/95 border-transparent hover:bg-slate-500/40 hover:border-orange-300/40 hover:text-orange-100'
                          }
                        `}
                      style={{ animationDelay: `${index * 50}ms` }}
                    >
                      <span>{item.label}</span>
                    </Link>
                  ))}
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

export default PublicNavbar; 