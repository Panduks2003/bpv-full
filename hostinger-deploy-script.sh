#!/bin/bash

# BrightPlanet Ventures - Hostinger Deployment Script
# This script helps automate the deployment process

set -e  # Exit on error

echo "🚀 BrightPlanet Ventures - Hostinger Deployment Helper"
echo "======================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
BACKEND_DIR="$PROJECT_ROOT/backend"
DEPLOY_DIR="$PROJECT_ROOT/hostinger-deploy"

echo "Project Root: $PROJECT_ROOT"
echo ""

# Menu
echo "Select deployment task:"
echo "1) Build Frontend Only"
echo "2) Prepare Backend Package"
echo "3) Build Both (Frontend + Backend)"
echo "4) Create Complete Deployment Package"
echo "5) Test Backend Locally"
echo "6) Exit"
echo ""
read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo ""
        print_info "Building Frontend..."
        cd "$FRONTEND_DIR"
        
        # Check if node_modules exists
        if [ ! -d "node_modules" ]; then
            print_info "Installing frontend dependencies..."
            npm install
        fi
        
        # Build
        print_info "Running production build..."
        npm run build
        
        if [ -d "build" ]; then
            print_success "Frontend built successfully!"
            print_info "Build location: $FRONTEND_DIR/build"
            print_info "Build size: $(du -sh build | cut -f1)"
            echo ""
            print_info "Next steps:"
            echo "  1. Upload contents of 'build/' folder to Hostinger public_html"
            echo "  2. Ensure .htaccess is configured for React Router"
        else
            print_error "Build failed! Check for errors above."
            exit 1
        fi
        ;;
        
    2)
        echo ""
        print_info "Preparing Backend Package..."
        cd "$BACKEND_DIR"
        
        # Check if .env exists
        if [ ! -f ".env" ]; then
            print_error ".env file not found!"
            print_info "Creating .env from .env.example..."
            cp .env.example .env
            print_info "Please edit backend/.env with your production values"
            exit 1
        fi
        
        # Install production dependencies
        print_info "Installing production dependencies..."
        npm install --production
        
        print_success "Backend package prepared!"
        print_info "Backend location: $BACKEND_DIR"
        echo ""
        print_info "Files to upload to VPS:"
        echo "  - server.js"
        echo "  - package.json"
        echo "  - .env"
        echo "  - node_modules/ (or run 'npm install' on VPS)"
        ;;
        
    3)
        echo ""
        print_info "Building Frontend and Backend..."
        
        # Build Frontend
        print_info "Step 1/2: Building Frontend..."
        cd "$FRONTEND_DIR"
        if [ ! -d "node_modules" ]; then
            npm install
        fi
        npm run build
        
        if [ ! -d "build" ]; then
            print_error "Frontend build failed!"
            exit 1
        fi
        print_success "Frontend built!"
        
        # Prepare Backend
        print_info "Step 2/2: Preparing Backend..."
        cd "$BACKEND_DIR"
        if [ ! -f ".env" ]; then
            cp .env.example .env
            print_info "Created .env - please configure it"
        fi
        npm install --production
        print_success "Backend prepared!"
        
        print_success "Both Frontend and Backend ready for deployment!"
        ;;
        
    4)
        echo ""
        print_info "Creating Complete Deployment Package..."
        
        # Create deployment directory
        rm -rf "$DEPLOY_DIR"
        mkdir -p "$DEPLOY_DIR/frontend"
        mkdir -p "$DEPLOY_DIR/backend"
        
        # Build Frontend
        print_info "Building Frontend..."
        cd "$FRONTEND_DIR"
        if [ ! -d "node_modules" ]; then
            npm install
        fi
        npm run build
        
        if [ ! -d "build" ]; then
            print_error "Frontend build failed!"
            exit 1
        fi
        
        # Copy frontend build
        print_info "Copying frontend files..."
        cp -r build/* "$DEPLOY_DIR/frontend/"
        
        # Copy .htaccess
        cat > "$DEPLOY_DIR/frontend/.htaccess" << 'EOF'
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteCond %{REQUEST_FILENAME} !-l
  RewriteRule . /index.html [L]
</IfModule>
EOF
        
        # Copy backend files
        print_info "Copying backend files..."
        cd "$BACKEND_DIR"
        cp server.js "$DEPLOY_DIR/backend/"
        cp package.json "$DEPLOY_DIR/backend/"
        
        if [ -f ".env" ]; then
            cp .env "$DEPLOY_DIR/backend/"
        else
            cp .env.example "$DEPLOY_DIR/backend/.env"
            print_info "Created .env from example - please configure it"
        fi
        
        # Create deployment instructions
        cat > "$DEPLOY_DIR/README.md" << 'EOF'
# BrightPlanet Ventures - Deployment Package

## Frontend Deployment (Cloud Hosting)
1. Upload all files from `frontend/` to your Hostinger `public_html/` directory
2. Ensure `.htaccess` is present for React Router support

## Backend Deployment (VPS)
1. Upload all files from `backend/` to your VPS (e.g., `/var/www/brightplanet-backend/`)
2. SSH into VPS
3. Run: `npm install --production`
4. Configure `.env` file with production values
5. Start with PM2: `pm2 start server.js --name brightplanet-backend`
6. Save PM2 config: `pm2 save`
7. Setup startup: `pm2 startup`

## Important Notes
- Update `.env` files with production URLs
- Configure firewall on VPS (ports 22, 80, 443, 5000)
- Setup SSL certificates
- Test all endpoints after deployment

For detailed instructions, see HOSTINGER-DEPLOYMENT-COMPLETE-GUIDE.md
EOF
        
        # Create ecosystem file for PM2
        cat > "$DEPLOY_DIR/backend/ecosystem.config.js" << 'EOF'
module.exports = {
  apps: [{
    name: 'brightplanet-backend',
    script: './server.js',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: './logs/error.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF
        
        # Create archive
        print_info "Creating deployment archive..."
        cd "$PROJECT_ROOT"
        tar -czf hostinger-deploy.tar.gz hostinger-deploy/
        
        print_success "Deployment package created!"
        echo ""
        print_info "Package location: $DEPLOY_DIR"
        print_info "Archive: $PROJECT_ROOT/hostinger-deploy.tar.gz"
        echo ""
        print_info "Package contents:"
        echo "  📁 frontend/ - Upload to Cloud Hosting public_html"
        echo "  📁 backend/ - Upload to VPS"
        echo "  📄 README.md - Deployment instructions"
        echo ""
        print_info "Package size: $(du -sh hostinger-deploy | cut -f1)"
        print_info "Archive size: $(du -sh hostinger-deploy.tar.gz | cut -f1)"
        ;;
        
    5)
        echo ""
        print_info "Testing Backend Locally..."
        cd "$BACKEND_DIR"
        
        if [ ! -f ".env" ]; then
            print_error ".env file not found!"
            print_info "Creating from .env.example..."
            cp .env.example .env
        fi
        
        if [ ! -d "node_modules" ]; then
            print_info "Installing dependencies..."
            npm install
        fi
        
        print_info "Starting backend server..."
        print_info "Press Ctrl+C to stop"
        echo ""
        node server.js
        ;;
        
    6)
        echo ""
        print_info "Exiting..."
        exit 0
        ;;
        
    *)
        print_error "Invalid choice!"
        exit 1
        ;;
esac

echo ""
print_success "Task completed!"
echo ""
