/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}"
  ],
  theme: {
    extend: {
      animation: {
        'gradient-x': 'gradient-x 3s ease infinite',
        'gradient-y': 'gradient-y 3s ease infinite',
        'gradient-xy': 'gradient-xy 3s ease infinite',
        'float': 'float 6s ease-in-out infinite',
        'glow': 'glow 2s ease-in-out infinite alternate',
        'shimmer': 'shimmer 2s linear infinite',
        'bounce-subtle': 'bounce-subtle 2s ease-in-out infinite',
        'pulse-glow': 'pulse-glow 2s ease-in-out infinite',
        'spin-slow': 'spin 20s linear infinite',
        'spin-reverse': 'spin 20s linear infinite reverse',
        'wiggle': 'wiggle 1s ease-in-out infinite',
        'fade-in-up': 'fade-in-up 0.6s ease-out',
        'fade-in-down': 'fade-in-down 0.6s ease-out',
        'scale-in': 'scale-in 0.6s ease-out',
        'fadeIn': 'fadeIn 0.5s ease-out',
      },
      keyframes: {
        'gradient-x': {
          '0%, 100%': {
            'background-size': '200% 200%',
            'background-position': 'left center'
          },
          '50%': {
            'background-size': '200% 200%',
            'background-position': 'right center'
          }
        },
        'gradient-y': {
          '0%, 100%': {
            'background-size': '200% 200%',
            'background-position': 'center top'
          },
          '50%': {
            'background-size': '200% 200%',
            'background-position': 'center bottom'
          }
        },
        'gradient-xy': {
          '0%, 100%': {
            'background-size': '400% 400%',
            'background-position': 'left center'
          },
          '50%': {
            'background-size': '400% 400%',
            'background-position': 'right center'
          }
        },
        'float': {
          '0%, 100%': {
            transform: 'translateY(0px)'
          },
          '50%': {
            transform: 'translateY(-20px)'
          }
        },
        'glow': {
          '0%, 100%': {
            'box-shadow': '0 0 20px rgba(59, 130, 246, 0.3)'
          },
          '50%': {
            'box-shadow': '0 0 40px rgba(59, 130, 246, 0.6)'
          }
        },
        'shimmer': {
          '0%': {
            'background-position': '-200% 0'
          },
          '100%': {
            'background-position': '200% 0'
          }
        },
        'bounce-subtle': {
          '0%, 100%': {
            transform: 'translateY(0)'
          },
          '50%': {
            transform: 'translateY(-5px)'
          }
        },
        'pulse-glow': {
          '0%, 100%': {
            opacity: '0.5',
            transform: 'scale(1)'
          },
          '50%': {
            opacity: '1',
            transform: 'scale(1.05)'
          }
        },
        'wiggle': {
          '0%, 100%': {
            transform: 'rotate(-3deg)'
          },
          '50%': {
            transform: 'rotate(3deg)'
          }
        },
        'fade-in-up': {
          '0%': {
            opacity: '0',
            transform: 'translateY(30px)'
          },
          '100%': {
            opacity: '1',
            transform: 'translateY(0)'
          }
        },
        'fade-in-down': {
          '0%': {
            opacity: '0',
            transform: 'translateY(-30px)'
          },
          '100%': {
            opacity: '1',
            transform: 'translateY(0)'
          }
        },
        'scale-in': {
          '0%': {
            opacity: '0',
            transform: 'scale(0.9)'
          },
          '100%': {
            opacity: '1',
            transform: 'scale(1)'
          }
        },
        'fadeIn': {
          '0%': {
            opacity: '0'
          },
          '100%': {
            opacity: '1'
          }
        }
      },
      colors: {
        brand: {
          50: '#FEF9E7',   // Lightest gold
          100: '#FDF2D3',  // Very light gold
          200: '#F9E79F',  // Light champagne
          300: '#F4E4BC',  // Champagne
          400: '#F1C40F',  // Bright gold
          500: '#D4AF37',  // Primary gold (main brand)
          600: '#B8860B',  // Dark goldenrod
          700: '#996515',  // Darker gold
          800: '#7A4F0A',  // Deep gold
          900: '#5D3A08',  // Darkest gold
        },
        accent: {
          bronze: '#CD7F32',
          copper: '#B87333',
          amber: '#FFBF00',
        },
        navy: {
          50: '#F0F4F8',
          500: '#1E3A8A',
          900: '#0F172A',
        },
        neon: {
          'pink': '#ff0080',
          'purple': '#8000ff',
          'blue': '#0080ff',
          'cyan': '#00ffff',
          'green': '#00ff80',
          'yellow': '#ffff00',
          'orange': '#ff8000',
          'red': '#ff0000'
        }
      },
      backdropBlur: {
        'xs': '2px',
      }
    },
  },
  plugins: [],
}

