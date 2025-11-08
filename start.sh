#!/bin/bash

# Create necessary directories
mkdir -p logs

# Install PM2 globally if not installed
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    npm install -g pm2
fi

# Install dependencies
echo "Installing dependencies..."
cd backend
npm install --production
cd ../frontend
npm install --production

# Build frontend
echo "Building frontend..."
npm run build

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

# Follow logs
pm2 logs --lines 20
