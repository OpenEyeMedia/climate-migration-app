#!/bin/bash

# Simple Deployment Script for Climate Adaptation App
# This script works without root permissions

set -e  # Exit on any error

# Configuration
LOG_FILE="./deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Health check function
health_check() {
    local service_name=$1
    local url=$2
    local max_attempts=10
    local attempt=1
    
    log "Checking health of $service_name at $url"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            success "$service_name is healthy"
            return 0
        else
            warning "Attempt $attempt/$max_attempts: $service_name not responding"
            sleep 2
            ((attempt++))
        fi
    done
    
    warning "$service_name failed health check after $max_attempts attempts"
    return 1
}

# Main deployment function
deploy() {
    log "Starting simple deployment"
    
    # Navigate to backend directory
    cd backend || error "Backend directory not found"
    
    # Install backend dependencies
    log "Installing backend dependencies"
    source venv/bin/activate
    pip install -r requirements.txt
    
    # Install frontend dependencies
    log "Installing frontend dependencies"
    cd ../frontend
    npm install
    
    # Build frontend
    log "Building frontend application"
    npm run build
    
    if [ $? -ne 0 ]; then
        error "Frontend build failed"
    fi
    
    # Stop existing services if running
    log "Stopping existing services"
    pm2 stop climate-backend climate-frontend 2>/dev/null || true
    pm2 delete climate-backend climate-frontend 2>/dev/null || true
    
    # Start backend
    log "Starting backend service"
    cd ../backend
    pm2 start "venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend
    
    # Start frontend
    log "Starting frontend service"
    cd ../frontend
    pm2 start "npm start -- -p 3001" --name climate-frontend
    
    # Wait for services to start
    sleep 5
    
    # Health checks
    health_check "Backend" "http://localhost:8000/health" || warning "Backend health check failed"
    health_check "Frontend" "http://localhost:3001" || warning "Frontend health check failed"
    
    # Test API endpoints
    log "Testing API endpoints"
    if curl -s -X POST http://localhost:8000/climate/analyze \
        -H 'Content-Type: application/json' \
        -d '{"location": "London, UK"}' | grep -q '"success": true'; then
        success "API test passed"
    else
        warning "API test failed - checking logs"
        pm2 logs climate-backend --lines 5
    fi
    
    # Save PM2 configuration
    pm2 save
    
    success "Deployment completed successfully"
    
    # Show status
    log "Current service status:"
    pm2 status
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "health")
        health_check "Backend" "http://localhost:8000/health"
        health_check "Frontend" "http://localhost:3001"
        ;;
    "status")
        pm2 status
        ;;
    "logs")
        pm2 logs --lines 20
        ;;
    "stop")
        pm2 stop climate-backend climate-frontend
        pm2 delete climate-backend climate-frontend
        success "Services stopped"
        ;;
    "start")
        cd backend
        pm2 start "venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend
        cd ../frontend
        pm2 start "npm start -- -p 3001" --name climate-frontend
        success "Services started"
        ;;
    *)
        echo "Usage: $0 {deploy|health|status|logs|stop|start}"
        echo "  deploy   - Deploy the application"
        echo "  health   - Check service health"
        echo "  status   - Show service status"
        echo "  logs     - Show recent logs"
        echo "  stop     - Stop all services"
        echo "  start    - Start all services"
        exit 1
        ;;
esac 