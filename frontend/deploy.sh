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

# Stop existing PM2 process
echo "🛑 Stopping existing application..."
pm2 stop climate-app 2>/dev/null || true

# Kill any processes using port 3000
echo "🧹 Cleaning up port 3000..."
sudo fuser -k 3000/tcp 2>/dev/null || true

# Wait a moment for processes to stop
sleep 2

# Start the application with PM2
echo "🔄 Starting application..."
pm2 start "npm start" --name climate-app

# Save PM2 configuration
pm2 save

# Check PM2 status
pm2 status

echo "✅ Deployment completed successfully!"
echo "🌍 Your app is live at: https://climate-migration-app.openeyemedia.net"

# Show recent logs
echo "📋 Recent application logs:"
pm2 logs climate-app --lines 5
