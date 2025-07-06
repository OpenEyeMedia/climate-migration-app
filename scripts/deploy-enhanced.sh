#!/bin/bash

# Enhanced Deployment Script for Climate Adaptation App
# This script provides better error handling, health checks, and rollback capabilities

set -e  # Exit on any error

# Configuration
REPO_URL="https://github.com/yourusername/climate-adaptation-app.git"
DEPLOY_DIR="/root/climate-migration-app"
BACKUP_DIR="/root/backups"
LOG_FILE="/var/log/climate-app-deploy.log"

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
    local max_attempts=30
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
    
    error "$service_name failed health check after $max_attempts attempts"
}

# Backup current deployment
backup_current() {
    log "Creating backup of current deployment"
    local backup_name="backup-$(date +'%Y%m%d-%H%M%S')"
    
    if [ -d "$DEPLOY_DIR" ]; then
        cp -r "$DEPLOY_DIR" "$BACKUP_DIR/$backup_name"
        success "Backup created: $BACKUP_DIR/$backup_name"
        echo "$backup_name" > "$DEPLOY_DIR/.current_backup"
    else
        warning "No existing deployment to backup"
    fi
}

# Rollback function
rollback() {
    local backup_name=$(cat "$DEPLOY_DIR/.current_backup" 2>/dev/null || echo "")
    
    if [ -n "$backup_name" ] && [ -d "$BACKUP_DIR/$backup_name" ]; then
        log "Rolling back to backup: $backup_name"
        
        # Stop current services
        pm2 stop climate-backend climate-frontend 2>/dev/null || true
        
        # Restore from backup
        rm -rf "$DEPLOY_DIR"
        cp -r "$BACKUP_DIR/$backup_name" "$DEPLOY_DIR"
        
        # Restart services
        cd "$DEPLOY_DIR/backend"
        pm2 start "venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend
        
        cd "$DEPLOY_DIR/frontend"
        pm2 start "npm start -- -p 3001" --name climate-frontend
        
        success "Rollback completed"
    else
        error "No backup available for rollback"
    fi
}

# Main deployment function
deploy() {
    log "Starting enhanced deployment"
    
    # Create backup
    backup_current
    
    # Navigate to deployment directory
    cd "$DEPLOY_DIR" || error "Deployment directory not found"
    
    # Pull latest changes
    log "Pulling latest changes from GitHub"
    git fetch origin
    git reset --hard origin/main
    
    if [ $? -ne 0 ]; then
        error "Git pull failed"
    fi
    
    # Install backend dependencies
    log "Installing backend dependencies"
    cd backend
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
    
    # Stop existing services
    log "Stopping existing services"
    pm2 stop climate-backend climate-frontend 2>/dev/null || true
    
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
    health_check "Backend" "http://localhost:8000/health"
    health_check "Frontend" "http://localhost:3001"
    
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
    "rollback")
        rollback
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
    *)
        echo "Usage: $0 {deploy|rollback|health|status|logs}"
        echo "  deploy   - Deploy latest changes"
        echo "  rollback - Rollback to previous version"
        echo "  health   - Check service health"
        echo "  status   - Show service status"
        echo "  logs     - Show recent logs"
        exit 1
        ;;
esac 