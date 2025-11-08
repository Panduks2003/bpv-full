#!/bin/bash

# BrightPlanet Ventures - Quick Deploy Script
# Customized for your VPS: 72.61.169.111

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 BrightPlanet Ventures - Quick Deploy"
echo "======================================="
echo ""

# VPS Details
VPS_IP="72.61.169.111"
VPS_USER="root"
VPS_PATH="/var/www/brightplanet-backend"

echo -e "${YELLOW}Your VPS Details:${NC}"
echo "IP: $VPS_IP"
echo "User: $VPS_USER"
echo "Path: $VPS_PATH"
echo ""

# Menu
echo "What would you like to do?"
echo "1) Build Frontend"
echo "2) Build Backend Package"
echo "3) Upload Backend to VPS"
echo "4) Complete Deployment (All Steps)"
echo "5) Test Backend Connection"
echo "6) Exit"
echo ""
read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}Building Frontend...${NC}"
        cd frontend
        
        # Update .env with VPS IP
        echo "REACT_APP_API_URL=http://$VPS_IP:5000/api" >> .env
        
        npm run build
        
        if [ -d "build" ]; then
            echo -e "${GREEN}✅ Frontend built successfully!${NC}"
            echo ""
            echo "Next steps:"
            echo "1. Login to Hostinger File Manager"
            echo "2. Navigate to public_html/"
            echo "3. Upload all files from frontend/build/"
        else
            echo -e "${RED}❌ Build failed!${NC}"
            exit 1
        fi
        ;;
        
    2)
        echo ""
        echo -e "${YELLOW}Preparing Backend Package...${NC}"
        cd backend
        
        if [ ! -f ".env" ]; then
            cp .env.example .env
            echo -e "${GREEN}Created .env file${NC}"
        fi
        
        npm install --production
        
        echo -e "${GREEN}✅ Backend package ready!${NC}"
        echo ""
        echo "Files ready to upload:"
        echo "- server.js"
        echo "- package.json"
        echo "- .env"
        echo "- ecosystem.config.js"
        echo "- node_modules/"
        ;;
        
    3)
        echo ""
        echo -e "${YELLOW}Uploading Backend to VPS...${NC}"
        echo "VPS IP: $VPS_IP"
        echo ""
        
        cd backend
        
        echo "Creating directory on VPS..."
        ssh $VPS_USER@$VPS_IP "mkdir -p $VPS_PATH"
        
        echo "Uploading files..."
        scp -r server.js package.json .env ecosystem.config.js $VPS_USER@$VPS_IP:$VPS_PATH/
        
        echo ""
        echo -e "${GREEN}✅ Files uploaded!${NC}"
        echo ""
        echo "Next steps (run on VPS):"
        echo "ssh $VPS_USER@$VPS_IP"
        echo "cd $VPS_PATH"
        echo "npm install --production"
        echo "pm2 start ecosystem.config.js"
        ;;
        
    4)
        echo ""
        echo -e "${YELLOW}Starting Complete Deployment...${NC}"
        echo ""
        
        # Build Frontend
        echo "Step 1/4: Building Frontend..."
        cd frontend
        echo "REACT_APP_API_URL=http://$VPS_IP:5000/api" >> .env
        npm run build
        cd ..
        
        if [ ! -d "frontend/build" ]; then
            echo -e "${RED}❌ Frontend build failed!${NC}"
            exit 1
        fi
        echo -e "${GREEN}✅ Frontend built${NC}"
        
        # Prepare Backend
        echo ""
        echo "Step 2/4: Preparing Backend..."
        cd backend
        if [ ! -f ".env" ]; then
            cp .env.example .env
        fi
        npm install --production
        cd ..
        echo -e "${GREEN}✅ Backend prepared${NC}"
        
        # Upload Backend
        echo ""
        echo "Step 3/4: Uploading Backend to VPS..."
        ssh $VPS_USER@$VPS_IP "mkdir -p $VPS_PATH"
        scp -r backend/server.js backend/package.json backend/.env backend/ecosystem.config.js $VPS_USER@$VPS_IP:$VPS_PATH/
        echo -e "${GREEN}✅ Backend uploaded${NC}"
        
        # Instructions
        echo ""
        echo "Step 4/4: Final Steps"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "BACKEND (Complete on VPS):"
        echo "  ssh $VPS_USER@$VPS_IP"
        echo "  cd $VPS_PATH"
        echo "  npm install --production"
        echo "  pm2 start ecosystem.config.js"
        echo "  pm2 save"
        echo "  pm2 startup"
        echo ""
        echo "FRONTEND (Upload to Hostinger):"
        echo "  1. Login to Hostinger File Manager"
        echo "  2. Go to public_html/"
        echo "  3. Upload all files from: frontend/build/"
        echo ""
        echo -e "${GREEN}✅ Deployment package ready!${NC}"
        ;;
        
    5)
        echo ""
        echo -e "${YELLOW}Testing Backend Connection...${NC}"
        echo ""
        
        echo "Testing SSH connection..."
        if ssh -o ConnectTimeout=5 $VPS_USER@$VPS_IP "echo 'SSH connection successful'"; then
            echo -e "${GREEN}✅ SSH connection working${NC}"
        else
            echo -e "${RED}❌ SSH connection failed${NC}"
            exit 1
        fi
        
        echo ""
        echo "Testing API health endpoint..."
        if curl -s http://$VPS_IP:5000/api/health | grep -q "ok"; then
            echo -e "${GREEN}✅ Backend API is running${NC}"
            curl http://$VPS_IP:5000/api/health
        else
            echo -e "${YELLOW}⚠️  Backend API not responding (may not be started yet)${NC}"
        fi
        ;;
        
    6)
        echo ""
        echo "Exiting..."
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Task completed!${NC}"
echo ""
