// PM2 Configuration for Production
module.exports = {
  apps: [{
    name: 'brightplanet-backend',
    script: './backend/server.js',
    instances: 1,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    watch: false,
    max_memory_restart: '500M',
    env_production: {
      NODE_ENV: 'production'
    }
  }]
};
