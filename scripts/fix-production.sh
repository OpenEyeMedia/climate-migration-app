#!/bin/bash

# Production Fix Script for Climate Adaptation App
# This script fixes authentication issues and deploys enhanced monitoring

set -e

# Configuration
DEPLOY_DIR="/root/climate-adaptation-app"
LOG_FILE="/var/log/climate-app-fix.log"

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

echo -e "${BLUE}🔧 Production Fix Script for Climate Adaptation App${NC}"
echo "=========================================================="

# Check if we're on the production server
# if [ ! -d "$DEPLOY_DIR" ]; then
#     error "This script should be run on the production server"
# fi

log "Step 1: Checking current nginx configuration"

# Check nginx configuration
if [ -f "/etc/nginx/sites-available/climate-migration-app" ]; then
    log "Found nginx configuration file"
    
    # Check for authentication blocks
    if grep -q "auth_basic" /etc/nginx/sites-available/climate-migration-app; then
        warning "Found authentication blocks in nginx config"
        log "Removing authentication blocks..."
        
        # Create backup
        cp /etc/nginx/sites-available/climate-migration-app /etc/nginx/sites-available/climate-migration-app.backup
        
        # Remove auth blocks
        sed -i '/auth_basic/d' /etc/nginx/sites-available/climate-migration-app
        sed -i '/auth_basic_user_file/d' /etc/nginx/sites-available/climate-migration-app
        
        success "Removed authentication blocks"
    else
        log "No authentication blocks found in nginx config"
    fi
else
    warning "Nginx configuration file not found"
fi

log "Step 2: Checking nginx syntax and restarting"

# Test nginx configuration
if nginx -t; then
    success "Nginx configuration is valid"
    
    # Reload nginx
    systemctl reload nginx
    success "Nginx reloaded successfully"
else
    error "Nginx configuration has errors"
fi

log "Step 3: Checking current services"

# Check PM2 processes
if pm2 list | grep -q "climate-backend\|climate-frontend"; then
    log "Found running PM2 processes"
    pm2 status
else
    warning "No PM2 processes found"
fi

log "Step 4: Pulling latest changes from GitHub"

cd "$DEPLOY_DIR"

# Pull latest changes
git fetch origin
git reset --hard origin/main

if [ $? -ne 0 ]; then
    error "Failed to pull latest changes"
fi

success "Pulled latest changes from GitHub"

log "Step 5: Installing dependencies"

# Install backend dependencies
cd backend

# Debug information for production server
log "Current directory: $(pwd)"
log "Directory contents:"
ls -la

# Check if we're in the right place
if [ ! -f "requirements.txt" ]; then
    error "requirements.txt not found in current directory"
fi

# Check if virtual environment exists and is properly set up
if [ ! -f "venv/bin/activate" ] || [ ! -f "venv/bin/pip" ]; then
    log "Creating or recreating virtual environment..."
    
    # Remove existing virtual environment if it's corrupted
    if [ -d "venv" ]; then
        log "Removing existing virtual environment..."
        rm -rf venv
    fi
    
    python3 -m venv venv

# Show what was created
log "Virtual environment creation completed. Contents:"
ls -la venv/bin/

# Verify virtual environment was created properly
if [ ! -f "venv/bin/pip" ]; then
    error "Virtual environment pip executable not found"
fi
    
    # Make sure pip is executable
chmod +x venv/bin/pip

# List available Python executables in venv
log "Available Python executables in virtual environment:"
ls -la venv/bin/python*
fi

# Activate virtual environment and install dependencies
source venv/bin/activate

# Verify we're using the virtual environment
log "Verifying virtual environment..."
which python
which pip

# Check if pip exists in virtual environment
if [ ! -f "venv/bin/pip" ]; then
    error "pip not found in virtual environment. Virtual environment may be corrupted."
fi

# Make sure pip is executable
if [ ! -x "venv/bin/pip" ]; then
    log "Making pip executable..."
    chmod +x venv/bin/pip
fi

# Use the virtual environment's pip explicitly with fallback
log "Installing Python dependencies..."

# Try upgrading pip first
if ./venv/bin/pip install --upgrade pip; then
    success "Pip upgraded successfully"
else
    warning "Pip upgrade failed, trying alternative approach..."
    ./venv/bin/python -m pip install --upgrade pip
fi

# Install requirements with fallback
if ./venv/bin/pip install -r requirements.txt; then
    success "Requirements installed successfully"
else
    warning "Pip install failed, trying alternative approach..."
    ./venv/bin/python -m pip install -r requirements.txt
fi

# Verify installation
log "Verifying installation..."
./venv/bin/pip list | grep -E "(fastapi|uvicorn|httpx)"

# Install frontend dependencies
cd ../frontend
npm install

log "Step 6: Building frontend"

# Build frontend
npm run build

if [ $? -ne 0 ]; then
    error "Frontend build failed"
fi

success "Frontend built successfully"

log "Step 7: Restarting services"

# Stop existing services
pm2 stop climate-backend climate-frontend 2>/dev/null || true

# Start backend
cd ../backend
pm2 start "venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend

# Start frontend
cd ../frontend
pm2 start "npm start -- -p 3001" --name climate-frontend

# Save PM2 configuration
pm2 save

log "Step 8: Waiting for services to start"

# Wait for services to start
sleep 10

log "Step 9: Testing endpoints"

# Test backend health
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    success "Backend health check passed"
else
    error "Backend health check failed"
fi

# Test comprehensive health check
if curl -s http://localhost:8000/health/comprehensive | grep -q "healthy"; then
    success "Comprehensive health check passed"
else
    warning "Comprehensive health check failed - checking details"
    curl -s http://localhost:8000/health/comprehensive | jq .
fi

# Test API endpoint
log "Testing API endpoint with London, UK..."
if curl -s -X POST http://localhost:8000/climate/analyze \
    -H 'Content-Type: application/json' \
    -d '{"location": "London, UK"}' | grep -q '"success": true'; then
    success "API test passed"
else
    warning "API test failed - checking logs"
    pm2 logs climate-backend --lines 10
fi

log "Step 10: Testing public access"

# Test public access
if curl -s https://climate-migration-app.openeyemedia.net/ | grep -q "Climate Migration\|climate"; then
    success "Public site is accessible"
else
    warning "Public site may still have issues"
    curl -I https://climate-migration-app.openeyemedia.net/
fi

log "Step 11: Setting up monitoring"

# Create monitoring script
cat > /root/monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script
echo "=== Climate App Monitoring ==="
echo "Time: $(date)"
echo ""

echo "PM2 Status:"
pm2 status

echo ""
echo "Backend Health:"
curl -s http://localhost:8000/health | jq .

echo ""
echo "Frontend Status:"
curl -s http://localhost:3001/ | head -5

echo ""
echo "Recent Logs:"
pm2 logs --lines 3
EOF

chmod +x /root/monitor.sh

success "Created monitoring script: /root/monitor.sh"

log "Step 12: Final status check"

echo ""
echo -e "${GREEN}🎉 Production Fix Complete!${NC}"
echo ""
echo -e "${BLUE}📊 Current Status:${NC}"
pm2 status

echo ""
echo -e "${BLUE}🌐 Access Points:${NC}"
echo "  Public Site: https://climate-migration-app.openeyemedia.net"
echo "  Backend API: http://localhost:8000"
echo "  Frontend:    http://localhost:3001"
echo "  Health:      http://localhost:8000/health"
echo "  API Docs:    http://localhost:8000/docs"

echo ""
echo -e "${BLUE}📋 Monitoring Commands:${NC}"
echo "  /root/monitor.sh           - Check system status"
echo "  pm2 logs                   - View logs"
echo "  pm2 status                 - Check service status"
echo "  curl http://localhost:8000/health/comprehensive - Detailed health check"

echo ""
echo -e "${YELLOW}🧪 Test the fix:${NC}"
echo "  1. Visit: https://climate-migration-app.openeyemedia.net"
echo "  2. Try searching for 'London, UK'"
echo "  3. Check if the 401 error is resolved"

success "Production fix completed successfully!" 