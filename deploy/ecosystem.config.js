module.exports = {
  apps: [
    // Backend API
    {
      name: 'brightplanet-api',
      script: 'server.js',
      cwd: './backend',
      env: {
        NODE_ENV: 'production',
        PORT: 5000,
        SUPABASE_URL: 'https://ubokvxgxszhpzmjonuss.supabase.co',
        SUPABASE_SERVICE_ROLE_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk1MTgzMSwiZXhwIjoyMDc0NTI3ODMxfQ.S9YcbQqlgXMMFE-5gpd-NfrglVbBscBh72eYgCmVRSY'
      },
      instances: 'max',
      exec_mode: 'cluster',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: 'logs/api-error.log',
      out_file: 'logs/api-out.log',
      time: true
    },
    // Frontend
    {
      name: 'brightplanet-web',
      script: 'npx',
      args: 'serve -s build -l 3000',
      cwd: './frontend',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        REACT_APP_SUPABASE_URL: 'https://ubokvxgxszhpzmjonuss.supabase.co',
        REACT_APP_SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NTE4MzEsImV4cCI6MjA3NDUyNzgzMX0.rkPYllqA2-oxPtWowjwosGiYzgMfwYQFSbCRZ3tTcA4',
        REACT_APP_API_URL: 'http://localhost:5000'
      },
      instances: 1,
      autorestart: true,
      watch: false,
      error_file: 'logs/web-error.log',
      out_file: 'logs/web-out.log',
      time: true
    }
  ]
};
