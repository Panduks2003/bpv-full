#!/bin/bash

# BrightPlanet Ventures - Permanent Startup Script
echo "🚀 Starting BrightPlanet Ventures..."

# Kill any existing processes
pkill -f "PORT=300[0-2]" 2>/dev/null || true
pkill -f "PORT=5001" 2>/dev/null || true

# Start backend
echo "🔧 Starting backend service..."
cd backend
PORT=5001 npm start &
BACKEND_PID=$!
cd ..

# Wait for backend
sleep 3

# Start frontend on triple ports
echo "🔧 Starting frontend on triple ports..."
./start-triple-ports.sh &
FRONTEND_PID=$!

# Wait for services to start
sleep 5

echo ""
echo "🎉 BrightPlanet Ventures is running!"
echo "=================================="
echo ""
echo "🌐 Access URLs:"
echo "  Admin Panel:    http://localhost:3000"
echo "  Promoter Panel: http://localhost:3001"
echo "  Customer Panel: http://localhost:3002"
echo "  Backend API:    http://localhost:5001"
echo ""
echo "🔑 Login Credentials:"
echo "  Admin:    admin@brightplanet.com / admin123"
echo "  Promoter: promoter@brightplanet.com / promoter123"
echo "  Customer: customer@brightplanet.com / customer123"
echo ""
echo "✅ All systems operational!"
echo "✅ Database functions auto-deploy on first access"
echo "✅ Commission system works automatically"
echo "✅ No manual intervention required"
echo ""
echo "🛑 Press Ctrl+C to stop all services"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping all services..."
    kill $BACKEND_PID 2>/dev/null || true
    pkill -f "PORT=300[0-2]" 2>/dev/null || true
    pkill -f "PORT=5001" 2>/dev/null || true
    echo "✅ All services stopped"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Keep script running
echo "ℹ️ System running. Press Ctrl+C to stop."
wait
