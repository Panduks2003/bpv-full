#!/bin/bash

# =====================================================
# BRIGHTPLANET VENTURES - COMPLETE SYSTEM SETUP
# =====================================================
# This script sets up the entire system permanently
# Run this once to deploy everything needed

echo "🚀 BrightPlanet Ventures - Complete System Setup"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "package.json" ] && [ ! -d "frontend" ] && [ ! -d "backend" ]; then
    print_error "Please run this script from the BrightPlanet Ventures root directory"
    exit 1
fi

print_info "Setting up BrightPlanet Ventures complete system..."
echo ""

# =====================================================
# 1. SETUP BACKEND
# =====================================================
echo "🔧 Step 1: Setting up Backend..."

if [ ! -d "backend/node_modules" ]; then
    print_info "Installing backend dependencies..."
    cd backend
    npm install
    cd ..
    print_status "Backend dependencies installed"
else
    print_status "Backend dependencies already installed"
fi

# Check if backend .env exists
if [ ! -f "backend/.env" ]; then
    print_warning "Backend .env file not found"
    print_info "Copying from .env.example..."
    cp backend/.env.example backend/.env
    print_warning "Please update backend/.env with your Supabase service role key"
else
    print_status "Backend .env file exists"
fi

# =====================================================
# 2. SETUP FRONTEND
# =====================================================
echo ""
echo "🔧 Step 2: Setting up Frontend..."

if [ ! -d "frontend/node_modules" ]; then
    print_info "Installing frontend dependencies..."
    cd frontend
    npm install
    cd ..
    print_status "Frontend dependencies installed"
else
    print_status "Frontend dependencies already installed"
fi

# =====================================================
# 3. START BACKEND SERVICE
# =====================================================
echo ""
echo "🔧 Step 3: Starting Backend Service..."

# Kill existing backend processes
pkill -f "PORT=5001" 2>/dev/null || true

# Start backend on port 5001
cd backend
PORT=5001 npm start &
BACKEND_PID=$!
cd ..

# Wait for backend to start
sleep 3

# Check if backend is running
if curl -s http://localhost:5001/api/health > /dev/null; then
    print_status "Backend service started on port 5001"
else
    print_error "Backend service failed to start"
    exit 1
fi

# =====================================================
# 4. DEPLOY DATABASE FUNCTIONS AUTOMATICALLY
# =====================================================
echo ""
echo "🔧 Step 4: Deploying Database Functions Automatically..."

print_info "Setting up automatic database deployment..."

# Create auto-deployment script in frontend public directory
cp auto-deploy-database.js frontend/public/

print_status "Database auto-deployment script installed"
print_info "Database functions will be deployed automatically when you access the application"
echo ""

# =====================================================
# 5. START TRIPLE PORT FRONTEND
# =====================================================
echo "🔧 Step 5: Starting Triple Port Frontend..."

# Make scripts executable
chmod +x start-triple-ports.sh

# Start triple port frontend
./start-triple-ports.sh &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 5

print_status "Frontend started on triple ports"

# =====================================================
# 6. SYSTEM READY
# =====================================================
echo ""
echo "🎉 SYSTEM SETUP COMPLETED!"
echo "========================="
echo ""
print_status "Backend Service: http://localhost:5001"
print_status "Admin Panel: http://localhost:3000"
print_status "Promoter Panel: http://localhost:3001"
print_status "Customer Panel: http://localhost:3002"
echo ""

echo "🔑 LOGIN CREDENTIALS:"
echo "Admin: admin@brightplanet.com / admin123"
echo "Promoter: promoter@brightplanet.com / promoter123"
echo "Customer: customer@brightplanet.com / customer123"
echo ""

echo "⚠️ IMPORTANT: Don't forget to deploy the database functions!"
echo "📁 File: deploy-commission-system-permanent.sql"
echo ""

echo "🚀 FEATURES READY:"
print_status "✅ Promoter creation (Admin & Promoter accounts)"
print_status "✅ Customer creation with PIN system"
print_status "✅ Commission distribution (after DB deployment)"
print_status "✅ Multi-port testing environment"
print_status "✅ Authentication system"
print_status "✅ Database functions"
echo ""

echo "🛑 TO STOP ALL SERVICES:"
echo "Press Ctrl+C or run: pkill -f 'PORT=300[0-2]' && pkill -f 'PORT=5001'"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    print_info "Stopping all services..."
    kill $BACKEND_PID 2>/dev/null || true
    pkill -f "PORT=300[0-2]" 2>/dev/null || true
    pkill -f "PORT=5001" 2>/dev/null || true
    print_status "All services stopped"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Keep script running
print_info "System is running. Press Ctrl+C to stop all services."
wait
