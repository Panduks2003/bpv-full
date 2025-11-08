#!/bin/bash
# BrightPlanet Ventures - System Status Check

echo "🔍 BrightPlanet Ventures System Status"
echo "======================================"

# Check backend
if curl -s http://localhost:5001/api/health > /dev/null 2>&1; then
    echo "✅ Backend Service: Running (Port 5001)"
else
    echo "❌ Backend Service: Not Running"
fi

# Check frontend ports
for port in 3000 3001 3002; do
    if curl -s http://localhost:$port > /dev/null 2>&1; then
        case $port in
            3000) echo "✅ Admin Panel: Running (Port $port)" ;;
            3001) echo "✅ Promoter Panel: Running (Port $port)" ;;
            3002) echo "✅ Customer Panel: Running (Port $port)" ;;
        esac
    else
        case $port in
            3000) echo "❌ Admin Panel: Not Running" ;;
            3001) echo "❌ Promoter Panel: Not Running" ;;
            3002) echo "❌ Customer Panel: Not Running" ;;
        esac
    fi
done

echo ""
echo "🚀 To start the system: ./start-brightplanet.sh"
echo "🛑 To stop the system: pkill -f 'PORT=300[0-2]' && pkill -f 'PORT=5001'"
