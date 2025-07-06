#!/bin/bash

# Setup script for Climate Adaptation App
# This script sets up both backend and frontend environments

echo "🌍 Climate Adaptation App Setup"
echo "=============================="

# Check prerequisites
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        exit 1
    else
        echo "✅ $1 is installed"
    fi
}

echo "Checking prerequisites..."
check_command python3
check_command node
check_command npm
check_command git

# Setup backend
echo -e "\n📦 Setting up backend..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Copy env file if doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "⚠️  Please edit backend/.env with your configuration"
fi

# Setup frontend
echo -e "\n📦 Setting up frontend..."
cd ../frontend
npm install

# Copy env file if doesn't exist
if [ ! -f .env.local ]; then
    cp .env.example .env.local
    echo "⚠️  Please edit frontend/.env.local with your configuration"
fi

echo -e "\n✅ Setup complete!"
echo "To start the development servers:"
echo "  Backend: cd backend && source venv/bin/activate && uvicorn app.main:app --reload"
echo "  Frontend: cd frontend && npm run dev"
echo ""
echo "Or use Docker: docker-compose up"
