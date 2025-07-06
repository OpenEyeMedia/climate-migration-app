#!/bin/bash

echo "🚀 Starting deployment of Climate Migration App..."

# Navigate to project directory
cd /root/climate-migration-app

# Pull latest changes from GitHub
echo "📥 Pulling latest changes from GitHub..."
git pull origin main

# Check if pull was successful
if [ $? -ne 0 ]; then
    echo "❌ Git pull failed! Deployment aborted."
    exit 1
fi

# Navigate to frontend
cd frontend

# Install any new dependencies
echo "📦 Installing dependencies..."
npm install

# Build the application
echo "🔨 Building application..."
npm run build

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Build failed! Deployment aborted."
    exit 1
fi

# Restart the application with PM2
echo "🔄 Restarting application..."
pm2 restart climate-app 2>/dev/null || pm2 start "npm start" --name climate-app

# Check PM2 status
pm2 status

echo "✅ Deployment completed successfully!"
echo "🌍 Your app is live at: https://climate-migration-app.openeyemedia.net"

# Optional: Show recent logs
echo "📋 Recent application logs:"
pm2 logs climate-app --lines 10
