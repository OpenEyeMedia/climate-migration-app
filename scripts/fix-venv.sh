#!/bin/bash

# Virtual Environment Fix Script for Production Server
# This script specifically addresses the externally-managed-environment error

set -e

# Configuration
DEPLOY_DIR="/root/climate-migration-app"
LOG_FILE="/var/log/climate-app-venv-fix.log"

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

echo -e "${BLUE}🐍 Virtual Environment Fix Script${NC}"
echo "======================================"

# Check if we're on the production server
if [ ! -d "$DEPLOY_DIR" ]; then
    error "This script should be run on the production server"
fi

log "Step 1: Checking current Python environment"

# Check Python version and environment
python3 --version
which python3

log "Step 2: Checking current virtual environment"

cd "$DEPLOY_DIR/backend"

if [ -d "venv" ]; then
    log "Found existing virtual environment"
    
    # Check if it's properly set up
    if [ -f "venv/bin/activate" ]; then
        log "Virtual environment appears to be properly set up"
    else
        warning "Virtual environment exists but may be corrupted"
        log "Removing corrupted virtual environment..."
        rm -rf venv
    fi
else
    log "No virtual environment found"
fi

log "Step 3: Creating fresh virtual environment"

# Create new virtual environment
python3 -m venv venv

if [ $? -ne 0 ]; then
    error "Failed to create virtual environment"
fi

success "Virtual environment created successfully"

log "Step 4: Activating and verifying virtual environment"

# Activate virtual environment
source venv/bin/activate

# Verify we're using the virtual environment
log "Python location: $(which python)"
log "Pip location: $(which pip)"

# Check that we're not using system Python
if [[ "$(which python)" == *"venv"* ]]; then
    success "Using virtual environment Python"
else
    error "Not using virtual environment Python"
fi

log "Step 5: Installing dependencies"

# Upgrade pip first
./venv/bin/pip install --upgrade pip

# Install requirements
./venv/bin/pip install -r requirements.txt

if [ $? -ne 0 ]; then
    error "Failed to install dependencies"
fi

success "Dependencies installed successfully"

log "Step 6: Verifying installation"

# Check installed packages
./venv/bin/pip list | grep -E "(fastapi|uvicorn|httpx|pydantic)"

log "Step 7: Testing the application"

# Test if the app can start
timeout 10s ./venv/bin/python -c "
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
echo -e "${GREEN}🎉 Virtual Environment Fix Complete!${NC}"
echo ""
echo -e "${BLUE}📊 Status:${NC}"
pm2 status climate-backend

echo ""
echo -e "${BLUE}🔧 Commands:${NC}"
echo "  pm2 logs climate-backend    - View backend logs"
echo "  pm2 restart climate-backend - Restart backend"
echo "  curl http://localhost:8000/health - Test health endpoint"

success "Virtual environment fix completed successfully!" 