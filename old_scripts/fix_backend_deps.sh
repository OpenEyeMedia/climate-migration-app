#!/bin/bash

echo "🔧 Fixing Backend Dependencies and Starting Services"
echo "===================================================="

# Navigate to project root
cd /root/climate-migration-app

echo "1️⃣ Cleaning up old processes..."
pm2 stop all
pm2 delete all

echo ""
echo "2️⃣ Installing backend dependencies..."
cd backend

# Try different Python installation methods
echo "   📦 Installing with pip..."
pip install -r requirements.txt

echo "   📦 Installing uvicorn specifically..."
pip install "uvicorn[standard]==0.24.0"

echo "   📦 Installing fastapi specifically..."
pip install "fastapi==0.104.1"

echo ""
echo "3️⃣ Testing Python imports..."
python -c "import uvicorn; print('✅ uvicorn imported successfully')"
python -c "import fastapi; print('✅ fastapi imported successfully')"
python -c "from app.main import app; print('✅ app imported successfully')"

echo ""
echo "4️⃣ Starting backend with Python module syntax..."
pm2 start "python -m uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend

echo ""
echo "5️⃣ Starting frontend..."
cd ../frontend
pm2 start "npm start -- -p 3001" --name climate-frontend

echo ""
echo "6️⃣ Checking status..."
sleep 3
pm2 status

echo ""
echo "7️⃣ Testing backend..."
sleep 2
curl -s http://localhost:8000/ || echo "❌ Backend not responding"

echo ""
echo "8️⃣ Checking logs..."
pm2 logs climate-backend --lines 3

echo ""
echo "✅ If backend is still failing, run:"
echo "   cd /root/climate-migration-app/backend"
echo "   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
echo "   (to test manually)"
