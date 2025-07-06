#!/bin/bash

echo "🚀 Deploying Enhanced Climate App with Location Autocomplete"
echo "============================================================"
echo ""
echo "🎯 NEW FEATURES:"
echo "✅ Location autocomplete with Open-Meteo Geocoding API"
echo "✅ Real-time location search as you type"
echo "✅ Only shows cities with available climate data"
echo "✅ Smart fallbacks: 'Data available' vs 'Data unavailable'"
echo "✅ Enhanced climate analysis with real APIs"
echo "✅ Proper error handling and loading states"
echo ""

cd /root/climate-migration-app

echo "1️⃣ Backing up current services..."
cp backend/app/services/climate_service.py backend/app/services/climate_service_old.py

echo ""
echo "2️⃣ Installing enhanced climate service..."
cp backend/app/services/climate_service_enhanced.py backend/app/services/climate_service.py

echo ""
echo "3️⃣ Restarting backend with enhanced APIs..."
pm2 stop climate-backend
pm2 start "venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend

echo ""
echo "4️⃣ Building enhanced frontend..."
cd frontend
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Frontend build failed! Check for errors above."
    exit 1
fi

echo ""
echo "5️⃣ Restarting frontend..."
pm2 stop climate-frontend
pm2 start "npm start -- -p 3001" --name climate-frontend

echo ""
echo "6️⃣ Testing enhanced APIs..."
sleep 5

echo "Testing location search API..."
curl -s "http://localhost:8000/locations/search?q=London&limit=3" | grep -q '"success": true' && echo "✅ Location search works!" || echo "❌ Location search failed"

echo "Testing climate analysis API..."
curl -s -X POST http://localhost:8000/climate/analyze \
     -H 'Content-Type: application/json' \
     -d '{"location": "London, United Kingdom"}' | grep -q '"success": true' && echo "✅ Climate analysis works!" || echo "❌ Climate analysis failed"

echo ""
echo "7️⃣ Checking PM2 status..."
pm2 status

echo ""
echo "🎉 ENHANCED DEPLOYMENT COMPLETE!"
echo ""
echo "🌟 NEW USER EXPERIENCE:"
echo "   1. User types 'Lond...' → sees 'London, United Kingdom' in dropdown"
echo "   2. Selects from verified locations with climate data"
echo "   3. Gets real climate analysis with data availability indicators"
echo "   4. Sees 'Data available' or 'Data unavailable' for each metric"
echo ""
echo "📊 REAL DATA INTEGRATION:"
echo "   • Open-Meteo Geocoding: Location search and coordinates"
echo "   • Open-Meteo Current Weather: Real current conditions"
echo "   • Open-Meteo Archive: Historical climate comparisons"
echo "   • Smart Fallbacks: Geographic estimates when APIs unavailable"
echo ""
echo "🌐 Test your enhanced app at:"
echo "   https://climate-migration-app.openeyemedia.net"
echo ""
echo "🧪 TRY THESE FEATURES:"
echo "   • Type 'Lond' and see London suggestions"
echo "   • Try 'Perp' for Perpignan options"
echo "   • Select verified cities with real climate data"
echo "   • Compare data quality: 'Real' vs 'Estimated'"
echo ""
echo "📋 Monitor performance:"
echo "   pm2 logs climate-backend --lines 10"
echo "   pm2 logs climate-frontend --lines 5"
