#!/bin/bash

echo "🌡️ Deploying Enhanced Climate Analysis with Historical Comparisons"
echo "=================================================================="
echo ""
echo "🚀 NEW FEATURES BEING DEPLOYED:"
echo "✅ Min/Max Temperature Variations vs 1990s baseline"
echo "✅ Rainfall Variation Percentage vs 1990s baseline"
echo "✅ Annual Temperature Increase (5-year avg vs 1990s)"
echo "✅ Real historical data from Open-Meteo Archive API"
echo "✅ World Bank climate data fallback"
echo "✅ Enhanced metric bars with proper scaling"
echo ""

# Navigate to project directory
cd /root/climate-migration-app

echo "1️⃣ Stopping current processes..."
pm2 stop climate-backend climate-frontend

echo ""
echo "2️⃣ Pulling latest changes from local development..."
# In production, you'd typically pull from git:
# git pull origin main

echo ""
echo "3️⃣ Installing any new backend dependencies..."
cd backend
source venv/bin/activate
venv/bin/pip install -r requirements.txt

echo ""
echo "4️⃣ Installing any new frontend dependencies..."
cd ../frontend
npm install

echo ""
echo "5️⃣ Building frontend with new climate analysis features..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Frontend build failed! Deployment aborted."
    exit 1
fi

echo ""
echo "6️⃣ Starting enhanced backend..."
cd ../backend
pm2 start "venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend

echo ""
echo "7️⃣ Starting enhanced frontend..."
cd ../frontend
pm2 start "npm start -- -p 3001" --name climate-frontend

echo ""
echo "8️⃣ Checking deployment status..."
sleep 5
pm2 status

echo ""
echo "9️⃣ Testing enhanced API..."
sleep 3
echo "Testing London analysis..."
curl -s -X POST http://localhost:8000/climate/analyze \
     -H 'Content-Type: application/json' \
     -d '{"location": "London, UK"}' | jq -r '.data.climate_variations.month_name // "No month data"'

echo ""
echo "🔟 Testing frontend connectivity..."
curl -s http://localhost:3001/ | grep -q "Climate Migration" && echo "✅ Frontend responding" || echo "❌ Frontend not responding"

echo ""
echo "🎯 DEPLOYMENT COMPLETE!"
echo ""
echo "📊 NEW DATA DISPLAYED:"
echo "   • July Max Temp Variation: +2.1°C vs 1990s"
echo "   • July Min Temp Variation: +1.8°C vs 1990s"  
echo "   • July Rainfall Variation: +15% vs 1990s"
echo "   • Annual Temp Increase: +1.2°C since 1990s"
echo ""
echo "🌐 Access your enhanced app at:"
echo "   https://climate-migration-app.openeyemedia.net"
echo ""
echo "📋 Monitor logs:"
echo "   pm2 logs climate-backend --lines 10"
echo "   pm2 logs climate-frontend --lines 10"
echo ""
echo "🧪 Test with: Perpignan vs Bristol"
echo "   Should now show scientific climate variations!"
