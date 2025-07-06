#!/bin/bash

echo "🐍 Setting up Python Virtual Environment for Climate Backend"
echo "============================================================"

cd /root/climate-migration-app/backend

echo "1️⃣ Installing Python virtual environment tools..."
apt update
apt install -y python3-full python3-venv python3-pip

echo ""
echo "2️⃣ Creating virtual environment..."
python3 -m venv venv

echo ""
echo "3️⃣ Activating virtual environment..."
source venv/bin/activate

echo ""
echo "4️⃣ Upgrading pip in virtual environment..."
venv/bin/pip install --upgrade pip

echo ""
echo "5️⃣ Installing backend dependencies..."
venv/bin/pip install -r requirements.txt

echo ""
echo "6️⃣ Verifying installations..."
venv/bin/python -c "import uvicorn; print('✅ uvicorn installed')"
venv/bin/python -c "import fastapi; print('✅ fastapi installed')"

echo ""
echo "7️⃣ Testing backend startup..."
echo "Starting backend for 5 seconds to test..."
timeout 5s venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 || echo "✅ Backend startup test completed"

echo ""
echo "8️⃣ Stopping any existing PM2 processes..."
pm2 stop all
pm2 delete all

echo ""
echo "9️⃣ Starting backend with virtual environment..."
pm2 start "venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend

echo ""
echo "🔟 Starting frontend..."
cd ../frontend
pm2 start "npm start -- -p 3001" --name climate-frontend

echo ""
echo "📊 Checking PM2 status..."
sleep 3
pm2 status

echo ""
echo "🧪 Testing backend API..."
sleep 2
curl -s http://localhost:8000/ | head -3

echo ""
echo "✅ Setup complete!"
echo ""
echo "🔍 To check logs:"
echo "   pm2 logs climate-backend --lines 10"
echo "   pm2 logs climate-frontend --lines 10"
echo ""
echo "🔧 To manually run backend:"
echo "   cd /root/climate-migration-app/backend"
echo "   source venv/bin/activate"
echo "   uvicorn app.main:app --host 0.0.0.0 --port 8000"
