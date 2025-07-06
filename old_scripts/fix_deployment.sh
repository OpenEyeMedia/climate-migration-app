#!/bin/bash

echo "🔧 Fixing Climate Migration App Deployment Issues"
echo "================================================="
echo ""
echo "🔍 Issues Found:"
echo "❌ Backend (FastAPI/Python) is not running"
echo "❌ Only frontend (Next.js) is running"
echo "❌ Port 3000 conflict" 
echo "❌ nginx blocking API requests"
echo ""
echo "🛠️ SOLUTION: Split Frontend and Backend Processes"
echo ""

# Navigate to project directory
cd /root/climate-migration-app

echo "1️⃣ Stopping current broken process..."
pm2 stop climate-app
pm2 delete climate-app

echo ""
echo "2️⃣ Starting Backend (FastAPI on port 8000)..."
cd backend
pm2 start "uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend

echo ""
echo "3️⃣ Starting Frontend (Next.js on port 3001)..."
cd ../frontend
pm2 start "npm start -- -p 3001" --name climate-frontend

echo ""
echo "4️⃣ Checking process status..."
pm2 status

echo ""
echo "5️⃣ Testing backend directly..."
sleep 3
curl -s http://localhost:8000/ | head -3

echo ""
echo "6️⃣ Testing backend API..."
curl -s -X POST http://localhost:8000/climate/analyze \
     -H 'Content-Type: application/json' \
     -d '{"location": "London"}' | head -5

echo ""
echo "🎯 Next Steps:"
echo "✅ Backend should be running on: http://localhost:8000"
echo "✅ Frontend should be running on: http://localhost:3001" 
echo "✅ Update nginx to proxy /api requests to localhost:8000"
echo "✅ Update nginx to proxy / requests to localhost:3001"
echo ""
echo "📋 Check logs:"
echo "pm2 logs climate-backend --lines 10"
echo "pm2 logs climate-frontend --lines 10"
