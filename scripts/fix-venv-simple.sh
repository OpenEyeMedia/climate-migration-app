#!/bin/bash

# Simplified Virtual Environment Fix Script
# This script addresses the externally-managed-environment error

set -e

# Configuration
DEPLOY_DIR="/root/climate-adaptation-app"
LOG_FILE="/var/log/climate-app-venv-simple.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

echo -e "${BLUE}🐍 Simplified Virtual Environment Fix Script${NC}"
echo "=================================================="

log "Step 1: Checking current environment"

# Check Python version
python3 --version
which python3

log "Step 2: Navigating to backend directory"

# Navigate to backend directory
if [ -d "backend" ]; then
    cd backend
    log "Changed to backend directory"
elif [ -d "app" ]; then
    log "Already in backend directory"
else
    cd "$DEPLOY_DIR/backend"
    log "Changed to backend directory via DEPLOY_DIR"
fi

log "Current directory: $(pwd)"
ls -la

log "Step 3: Removing existing virtual environment"

# Remove existing virtual environment
if [ -d "venv" ]; then
    log "Removing existing virtual environment..."
    rm -rf venv
fi

log "Step 4: Creating new virtual environment"

# Create new virtual environment
log "Creating virtual environment..."
python3 -m venv venv

if [ $? -ne 0 ]; then
    error "Failed to create virtual environment"
fi

log "Virtual environment created successfully"

log "Step 5: Verifying virtual environment"

# Check what was created
ls -la venv/bin/

# Verify key files exist
if [ ! -f "venv/bin/python" ]; then
    error "Python executable not found in virtual environment"
fi

if [ ! -f "venv/bin/pip" ]; then
    error "Pip executable not found in virtual environment"
fi

# Make sure pip is executable
chmod +x venv/bin/pip

success "Virtual environment verified successfully"

log "Step 6: Installing dependencies"

# Install dependencies using the virtual environment's pip
log "Installing requirements..."
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

if [ $? -ne 0 ]; then
    error "Failed to install dependencies"
fi

success "Dependencies installed successfully"

log "Step 7: Testing the application"

# Test if the app can start
log "Testing application import..."
./venv/bin/python -c "
import sys
sys.path.append('.')
from app.main import app
print('✅ Application imports successfully')
" || warning "Application import test failed"

log "Step 8: Updating PM2 configuration"

# Stop existing backend if running
pm2 stop climate-backend 2>/dev/null || true

# Start with new virtual environment
pm2 start "venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend

# Save PM2 configuration
pm2 save

log "Step 9: Testing the service"

# Wait for service to start
sleep 5

# Test health endpoint
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    success "Backend is running and healthy"
else
    warning "Backend health check failed - checking logs"
    pm2 logs climate-backend --lines 5
fi

echo ""
echo -e "${GREEN}🎉 Simplified Virtual Environment Fix Complete!${NC}"
echo ""
echo -e "${BLUE}📊 Status:${NC}"
pm2 status climate-backend

echo ""
echo -e "${BLUE}🔧 Commands:${NC}"
echo "  pm2 logs climate-backend    - View backend logs"
echo "  pm2 restart climate-backend - Restart backend"
echo "  curl http://localhost:8000/health - Test health endpoint"

success "Simplified virtual environment fix completed successfully!" 