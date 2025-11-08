#!/bin/bash

# =====================================================
# BRIGHTPLANET VENTURES - HOSTINGER DEPLOYMENT SCRIPT
# =====================================================

echo "🚀 Starting deployment process..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Build Frontend
echo -e "${YELLOW}📦 Step 1: Building frontend...${NC}"
cd frontend
npm install
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend build successful${NC}"
else
    echo -e "${RED}❌ Frontend build failed${NC}"
    exit 1
fi

# Step 2: Install Backend Dependencies
echo -e "${YELLOW}📦 Step 2: Installing backend dependencies...${NC}"
cd ../backend
npm install --production

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend dependencies installed${NC}"
else
    echo -e "${RED}❌ Backend installation failed${NC}"
    exit 1
fi

# Step 3: Create logs directory
echo -e "${YELLOW}📁 Step 3: Creating logs directory...${NC}"
cd ..
mkdir -p logs

# Step 4: Display next steps
echo ""
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
echo "1. Upload the following to your Hostinger server:"
echo "   - frontend/build/ folder → Upload to public_html/"
echo "   - backend/ folder → Upload to your server root"
echo "   - ecosystem.config.js → Upload to server root"
echo "   - .htaccess → Upload to public_html/"
echo ""
echo "2. On Hostinger server, run:"
echo "   cd /path/to/your/app"
echo "   npm install -g pm2"
echo "   pm2 start ecosystem.config.js --env production"
echo "   pm2 save"
echo "   pm2 startup"
echo ""
echo "3. Set environment variables in Hostinger hPanel"
echo ""
echo -e "${GREEN}🎉 Ready for deployment!${NC}"
