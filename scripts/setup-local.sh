#!/bin/bash

# Local Development Setup Script for Climate Adaptation App
# This script sets up the local development environment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Setting up Climate Adaptation App Local Development Environment${NC}"
echo "=================================================================="

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo -e "${YELLOW}❌ Please run this script from the project root directory${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Setting up Backend Environment${NC}"
cd backend

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment and install dependencies
echo "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env << EOF
# Backend Configuration
PORT=8000
REDIS_URL=redis://localhost:6379
NODE_ENV=development
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# API endpoints
GEOCODING_API_URL=https://geocoding-api.open-meteo.com/v1
WEATHER_API_URL=https://api.open-meteo.com/v1
CLIMATE_API_URL=https://climate-api.open-meteo.com/v1
ARCHIVE_API_URL=https://archive-api.open-meteo.com/v1

# Rate limiting
MAX_REQUESTS_PER_MINUTE=100
MAX_REQUESTS_PER_HOUR=1000
EOF
    echo -e "${GREEN}✅ Created .env file${NC}"
fi

cd ..

echo -e "${BLUE}📋 Step 2: Setting up Frontend Environment${NC}"
cd frontend

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
npm install

# Create .env.local file if it doesn't exist
if [ ! -f ".env.local" ]; then
    echo "Creating .env.local file..."
    cat > .env.local << EOF
# Frontend Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_ENVIRONMENT=development
EOF
    echo -e "${GREEN}✅ Created .env.local file${NC}"
fi

cd ..

echo -e "${BLUE}📋 Step 3: Setting up Development Scripts${NC}"

# Create development scripts
cat > scripts/dev-backend.sh << 'EOF'
#!/bin/bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
EOF

cat > scripts/dev-frontend.sh << 'EOF'
#!/bin/bash
cd frontend
npm run dev
EOF

cat > scripts/dev.sh << 'EOF'
#!/bin/bash
# Start both backend and frontend in parallel
echo "Starting development servers..."
echo "Backend: http://localhost:8000"
echo "Frontend: http://localhost:3000"
echo "API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop all servers"

# Start backend in background
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# Start frontend in background
cd ../frontend
npm run dev &
FRONTEND_PID=$!

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID
EOF

# Make scripts executable
chmod +x scripts/dev-backend.sh
chmod +x scripts/dev-frontend.sh
chmod +x scripts/dev.sh

echo -e "${GREEN}✅ Created development scripts${NC}"

echo -e "${BLUE}📋 Step 4: Testing Setup${NC}"

# Test backend
echo "Testing backend setup..."
cd backend
source venv/bin/activate
python -c "import fastapi; print('✅ FastAPI imported successfully')" || echo "❌ FastAPI import failed"
python -c "import httpx; print('✅ httpx imported successfully')" || echo "❌ httpx import failed"
cd ..

# Test frontend
echo "Testing frontend setup..."
cd frontend
npm run build --silent && echo "✅ Frontend build successful" || echo "❌ Frontend build failed"
cd ..

echo -e "${GREEN}🎉 Local development environment setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Available Commands:${NC}"
echo "  ./scripts/dev.sh          - Start both backend and frontend"
echo "  ./scripts/dev-backend.sh  - Start backend only"
echo "  ./scripts/dev-frontend.sh - Start frontend only"
echo ""
echo -e "${BLUE}🌐 Access Points:${NC}"
echo "  Frontend: http://localhost:3000"
echo "  Backend:  http://localhost:8000"
echo "  API Docs: http://localhost:8000/docs"
echo "  Health:   http://localhost:8000/health"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "  1. Run: ./scripts/dev.sh"
echo "  2. Open http://localhost:3000 in your browser"
echo "  3. Test the climate analysis with 'London, UK'"
echo ""
echo -e "${GREEN}✅ Setup complete! Happy coding! 🚀${NC}" 