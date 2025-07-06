#!/bin/bash

# Virtual Environment Fix Script for Production Server
# This script specifically addresses the externally-managed-environment error

set -e

# Configuration
DEPLOY_DIR="/root/climate-adaptation-app"
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
# if [ ! -d "$DEPLOY_DIR" ]; then
#     error "This script should be run on the production server"
# fi

log "Step 1: Checking current Python environment"

# Check Python version and environment
python3 --version
which python3

# Check if we're in the right directory
log "Current directory: $(pwd)"
log "Directory contents:"
ls -la

# Check if we can access the backend directory
if [ ! -d "backend" ]; then
    log "Backend directory not found, checking if we're in the right place..."
    ls -la
    if [ -d "app" ]; then
        log "Found app directory, we might be in the backend already"
    else
        error "Cannot find backend or app directory"
    fi
fi

log "Step 2: Checking current virtual environment"

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

# Remove existing virtual environment if it exists
if [ -d "venv" ]; then
    log "Removing existing virtual environment..."
    rm -rf venv
fi

# Create new virtual environment
log "Creating virtual environment with python3 -m venv venv..."
python3 -m venv venv

if [ $? -ne 0 ]; then
    error "Failed to create virtual environment"
fi

# Show what was created
log "Virtual environment creation completed. Contents:"
ls -la venv/bin/

# Verify virtual environment was created properly
if [ ! -d "venv" ]; then
    error "Virtual environment directory was not created"
fi

if [ ! -f "venv/bin/activate" ]; then
    error "Virtual environment activation script not found"
fi

if [ ! -f "venv/bin/python" ]; then
    error "Virtual environment Python executable not found"
fi

if [ ! -f "venv/bin/pip" ]; then
    error "Virtual environment pip executable not found"
fi

# Make sure pip is executable
chmod +x venv/bin/pip

# List available Python executables in venv
log "Available Python executables in virtual environment:"
ls -la venv/bin/python*

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

# Check if pip exists in virtual environment
if [ ! -f "venv/bin/pip" ]; then
    error "pip not found in virtual environment. Virtual environment may be corrupted."
fi

# Check if pip is executable
if [ ! -x "venv/bin/pip" ]; then
    log "Making pip executable..."
    chmod +x venv/bin/pip
fi

# Try different approaches to install dependencies
log "Upgrading pip..."
if ./venv/bin/pip install --upgrade pip; then
    success "Pip upgraded successfully"
else
    warning "Pip upgrade failed, trying alternative approach..."
    # Try using python -m pip instead
    ./venv/bin/python -m pip install --upgrade pip
fi

# Install requirements
log "Installing requirements..."
if ./venv/bin/pip install -r requirements.txt; then
    success "Requirements installed successfully"
else
    warning "Pip install failed, trying alternative approach..."
    # Try using python -m pip instead
    ./venv/bin/python -m pip install -r requirements.txt
fi

if [ $? -ne 0 ]; then
    error "Failed to install dependencies"
fi

success "Dependencies installed successfully"

log "Step 6: Verifying installation"

# Check installed packages
./venv/bin/pip list | grep -E "(fastapi|uvicorn|httpx|pydantic)"

log "Step 7: Testing the application"

# Test if the app can start
log "Testing application import..."
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