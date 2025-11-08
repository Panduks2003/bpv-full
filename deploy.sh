#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting BrightPlanet Ventures Deployment...${NC}
"

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

# Start backend
cd backend
npm install --production
node server.js &

# Serve frontend
cd ../frontend
npx serve -s . -l 3000
EOL

chmod +x "$DEPLOY_DIR/start.sh"

# Create PM2 ecosystem file
cat > "$DEPLOY_DIR/ecosystem.config.js" << 'EOL'
module.exports = {
  apps: [
    {
      name: 'brightplanet-backend',
      script: './backend/server.js',
      env: {
        NODE_ENV: 'production',
        PORT: 5000
      },
      instances: 'max',
      exec_mode: 'cluster',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G'
    },
    {
      name: 'brightplanet-frontend',
      script: 'npx',
      args: 'serve -s frontend -l 3000',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      instances: 1,
      autorestart: true,
      watch: false
    }
  ]
};
EOL

echo -e "\n${GREEN}✅ Deployment package created at: $DEPLOY_DIR${NC}"
echo -e "\n${GREEN}📦 Deployment package includes:${NC}"
echo "- Frontend build"
echo "- Backend server"
echo "- Environment files"
echo "- Start script (start.sh)"
echo "- PM2 ecosystem config (ecosystem.config.js)"

echo -e "\n${GREEN}🚀 To deploy:${NC}"
echo "1. Copy $DEPLOY_DIR to your server"
echo "2. On the server, run: cd $DEPLOY_DIR && ./start.sh"
echo "   Or with PM2: pm2 start ecosystem.config.js"
echo -e "\n${GREEN}🌐 Your app will be available at: http://your-server-ip:3000${NC}"
