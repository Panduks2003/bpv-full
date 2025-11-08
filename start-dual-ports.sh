#!/bin/bash

# BrightPlanet Ventures - Dual Port Startup Script
# This script starts the React app on two different ports for testing
# Admin and Promoter interfaces simultaneously

echo "🚀 Starting BrightPlanet Ventures on dual ports..."
echo ""
echo "📊 Admin Panel:    http://localhost:3000"
echo "👤 Promoter Panel: http://localhost:3001"
echo ""
echo "💡 Usage Tips:"
echo "   • Admin Panel:    Login as admin to manage the platform"
echo "   • Promoter Panel: Login as promoter to manage customers and commissions"
echo ""
echo "Press Ctrl+C to stop both servers"
echo "================================================"

# Navigate to frontend directory
cd frontend

# Start both servers in background
echo "🔧 Starting Admin server on port 3000..."
PORT=3000 npm start &
ADMIN_PID=$!

echo "🔧 Starting Promoter server on port 3001..."
PORT=3001 npm start &
PROMOTER_PID=$!

# Function to cleanup processes on exit
cleanup() {
    echo ""
    echo "🛑 Stopping servers..."
    kill $ADMIN_PID 2>/dev/null
    kill $PROMOTER_PID 2>/dev/null
    echo "✅ Both servers stopped"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Wait for both processes
wait $ADMIN_PID $PROMOTER_PID
