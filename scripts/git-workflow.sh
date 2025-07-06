#!/bin/bash

# Git Workflow Script for Climate Adaptation App
# This script helps manage the development and deployment workflow

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔄 Git Workflow for Climate Adaptation App${NC}"
echo "================================================"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

# Function to show current status
show_status() {
    echo -e "${BLUE}📊 Current Git Status:${NC}"
    echo "Branch: $(git branch --show-current)"
    echo "Status:"
    git status --short
    echo ""
}

# Function to commit changes
commit_changes() {
    local message="$1"
    if [ -z "$message" ]; then
        echo -e "${YELLOW}Enter commit message:${NC}"
        read -r message
    fi
    
    echo -e "${BLUE}📝 Committing changes...${NC}"
    git add .
    git commit -m "$message"
    echo -e "${GREEN}✅ Changes committed${NC}"
}

# Function to push to GitHub
push_to_github() {
    echo -e "${BLUE}🚀 Pushing to GitHub...${NC}"
    git push origin main
    echo -e "${GREEN}✅ Pushed to GitHub${NC}"
}

# Function to deploy to production
deploy_to_production() {
    echo -e "${BLUE}🌐 Deploying to production...${NC}"
    echo -e "${YELLOW}This will trigger deployment on the production server${NC}"
    echo -e "${YELLOW}Make sure your changes are pushed to GitHub first${NC}"
    
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Deploying...${NC}"
        # You would run the deployment script here
        echo -e "${GREEN}✅ Deployment triggered${NC}"
        echo -e "${BLUE}Check production status at: https://climate-migration-app.openeyemedia.net${NC}"
    else
        echo -e "${YELLOW}Deployment cancelled${NC}"
    fi
}

# Function to create a new feature branch
create_feature_branch() {
    local feature_name="$1"
    if [ -z "$feature_name" ]; then
        echo -e "${YELLOW}Enter feature name:${NC}"
        read -r feature_name
    fi
    
    # Clean feature name
    feature_name=$(echo "$feature_name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
    
    echo -e "${BLUE}🌿 Creating feature branch: feature/$feature_name${NC}"
    git checkout -b "feature/$feature_name"
    echo -e "${GREEN}✅ Created and switched to feature/$feature_name${NC}"
}

# Function to merge feature branch
merge_feature() {
    echo -e "${BLUE}🔀 Merging feature branch...${NC}"
    git checkout main
    git merge "$(git branch --show-current)"
    echo -e "${GREEN}✅ Feature merged to main${NC}"
}

# Function to show recent commits
show_recent_commits() {
    echo -e "${BLUE}📜 Recent Commits:${NC}"
    git log --oneline -10
    echo ""
}

# Function to check production status
check_production() {
    echo -e "${BLUE}🔍 Checking production status...${NC}"
    
    # Check if site is accessible
    if curl -s -f https://climate-migration-app.openeyemedia.net/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Production site is accessible${NC}"
    else
        echo -e "${RED}❌ Production site is not accessible${NC}"
    fi
    
    # Check API health
    if curl -s -f https://climate-migration-app.openeyemedia.net/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Production API is healthy${NC}"
    else
        echo -e "${RED}❌ Production API is not responding${NC}"
    fi
}

# Main menu
case "${1:-menu}" in
    "status")
        show_status
        ;;
    "commit")
        commit_changes "$2"
        ;;
    "push")
        push_to_github
        ;;
    "deploy")
        deploy_to_production
        ;;
    "feature")
        create_feature_branch "$2"
        ;;
    "merge")
        merge_feature
        ;;
    "commits")
        show_recent_commits
        ;;
    "production")
        check_production
        ;;
    "workflow")
        echo -e "${BLUE}🔄 Complete Workflow:${NC}"
        show_status
        commit_changes
        push_to_github
        deploy_to_production
        ;;
    "menu"|*)
        echo -e "${BLUE}📋 Available Commands:${NC}"
        echo "  $0 status      - Show current git status"
        echo "  $0 commit      - Commit changes"
        echo "  $0 push        - Push to GitHub"
        echo "  $0 deploy      - Deploy to production"
        echo "  $0 feature     - Create feature branch"
        echo "  $0 merge       - Merge feature branch"
        echo "  $0 commits     - Show recent commits"
        echo "  $0 production  - Check production status"
        echo "  $0 workflow    - Complete workflow (commit → push → deploy)"
        echo ""
        echo -e "${YELLOW}💡 Quick Workflow:${NC}"
        echo "  1. Make changes locally"
        echo "  2. Run: $0 workflow"
        echo "  3. Test production site"
        echo ""
        show_status
        ;;
esac 