#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Creating BrightPlanet Ventures Deployment Package...${NC}\n"

# =====================================
# 1. Build Frontend
# =====================================
echo -e "${GREEN}1. Building Frontend...${NC}"
cd frontend
npm install
npm run build

# =====================================
# 2. Prepare Backend
# =====================================
echo -e "\n${GREEN}2. Setting up Backend...${NC}"
cd ../backend
npm install --production

# =====================================
# 3. Create Deployment Package
# =====================================
echo -e "\n${GREEN}3. Creating Deployment Package...${NC}"
cd ..
DEPLOY_DIR="deploy/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DEPLOY_DIR"

# Copy frontend build
cp -r frontend/build "$DEPLOY_DIR/frontend"

# Copy backend
mkdir -p "$DEPLOY_DIR/backend"
cp -r backend/* "$DEPLOY_DIR/backend/"

# Copy environment files if they exist
cp .env "$DEPLOY_DIR/" 2>/dev/null || echo "No root .env file found"
cp frontend/.env "$DEPLOY_DIR/frontend/" 2>/dev/null || echo "No frontend .env file found"
cp backend/.env "$DEPLOY_DIR/backend/" 2>/dev/null || echo "No backend .env file found"

# Create start script
cat > "$DEPLOY_DIR/start.sh" << 'EOL'
#!/bin/bash

# Create logs directory
mkdir -p logs

# Install PM2 if not installed
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    npm install -g pm2
fi

# Install dependencies
echo "Installing dependencies..."
cd backend
npm install --production

# Start services using PM2
echo "Starting services..."
cd ..
pm2 delete all 2>/dev/null
pm2 start ecosystem.config.js

# Save PM2 process list
echo "Saving PM2 configuration..."
pm2 save

# Set up PM2 to start on system boot
pm2 startup 2>/dev/null || echo "PM2 startup already configured"

# Display status
echo ""
echo "=================================="
echo "🚀 BrightPlanet Ventures is running!"
echo ""
echo "Frontend: http://localhost:3000"
echo "Backend API: http://localhost:5000"
echo ""
echo "PM2 Status:"
pm2 status

echo ""
echo "To monitor logs:"
echo "  pm2 logs"
echo ""
echo "To stop services:"
echo "  pm2 stop all"
echo ""
echo "=================================="
EOL

# Create PM2 ecosystem file
cat > "$DEPLOY_DIR/ecosystem.config.js" << 'EOL'
module.exports = {
  apps: [
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
EOL

# Make scripts executable
chmod +x "$DEPLOY_DIR/start.sh"

# Create a symlink to the latest deployment
ln -sfn "$DEPLOY_DIR" "deploy/current"

echo -e "\n${GREEN}✅ Deployment package created at: $DEPLOY_DIR${NC}"
echo -e "\n${GREEN}📦 Deployment package includes:${NC}"
echo "- Frontend build"
echo "- Backend server"
echo "- Environment files"
echo "- Start script (start.sh)"
echo "- PM2 ecosystem config (ecosystem.config.js)"

echo -e "\n${GREEN}🚀 To deploy:${NC}"
echo "1. Copy the deployment folder to your server:"
echo "   scp -r $DEPLOY_DIR user@your-server:/opt/brightplanet"
echo "2. On the server, run:"
echo "   cd $DEPLOY_DIR && ./start.sh"
echo -e "\n${GREEN}🌐 Your app will be available at: http://your-server-ip:3000${NC}"
