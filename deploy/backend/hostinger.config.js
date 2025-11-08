/**
 * Hostinger Node.js configuration
 * This file contains settings specific to Hostinger deployment
 */

module.exports = {
  // Hostinger typically assigns a specific port for Node.js applications
  port: process.env.PORT || 8080,
  
  // Set production mode
  nodeEnv: 'production',
  
  // Hostinger-specific paths
  paths: {
    // Public directory for static files
    public: '../public_html',
    
    // Logs directory
    logs: './logs',
  },
  
  // CORS settings for Hostinger
  cors: {
    // Allow requests from your domain
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  },
  
  // Database connection - using Supabase
  // Note: Keep using Supabase even on Hostinger
  database: {
    supabaseUrl: process.env.SUPABASE_URL,
    supabaseKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  }
};