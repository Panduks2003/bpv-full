#!/bin/bash

# BrightPlanet Ventures - Triple Port Startup Script
# This script starts the React app on three different ports for simultaneous testing
# of Admin, Promoter, and Customer interfaces

echo "🚀 Starting BrightPlanet Ventures on triple ports..."
echo ""
echo "📊 Admin Panel:    http://localhost:3000"
echo "👤 Promoter Panel: http://localhost:3001" 
echo "🛒 Customer Panel: http://localhost:3002"
echo ""
echo "💡 Usage Tips:"
echo "   • Admin Panel:    Login as admin to manage the platform"
echo "   • Promoter Panel: Login as promoter to manage customers and commissions"
echo "   • Customer Panel: Login as customer to view investments and opportunities"
echo ""
echo "Press Ctrl+C to stop all servers"
echo "================================================================"

# Navigate to frontend directory
cd frontend

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "⚠️  node_modules not found. Installing dependencies..."
    npm install
    echo "✅ Dependencies installed"
    echo ""
fi

# Start all three servers in background
echo "🔧 Starting Admin server on port 3000..."
PORT=3000 npm start &
ADMIN_PID=$!
sleep 2

echo "🔧 Starting Promoter server on port 3001..."
PORT=3001 npm start &
PROMOTER_PID=$!
sleep 2

echo "🔧 Starting Customer server on port 3002..."
PORT=3002 npm start &
CUSTOMER_PID=$!
sleep 2

echo ""
echo "✅ All servers started successfully!"
echo ""
echo "🌐 Access URLs:"
echo "   Admin:    http://localhost:3000/admin"
echo "   Promoter: http://localhost:3001/promoter" 
echo "   Customer: http://localhost:3002/customer"
echo ""
echo "📝 Note: Each server runs the same React app but you can navigate to different"
echo "         role-specific routes on each port for testing multiple user types."
echo ""

# Function to cleanup processes on exit
cleanup() {
    echo ""
    echo "🛑 Stopping all servers..."
    kill $ADMIN_PID 2>/dev/null
    kill $PROMOTER_PID 2>/dev/null  
    kill $CUSTOMER_PID 2>/dev/null
    echo "✅ All servers stopped"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Wait for all processes
wait $ADMIN_PID $PROMOTER_PID $CUSTOMER_PID
