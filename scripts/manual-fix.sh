#!/bin/bash

# Manual Fix Script - Run commands step by step
# This script provides individual commands to fix the virtual environment issue

echo "Manual Fix Script for Virtual Environment Issues"
echo "================================================"
echo ""
echo "Run these commands one by one:"
echo ""

echo "1. Navigate to backend directory:"
echo "   cd /root/climate-adaptation-app/backend"
echo ""

echo "2. Remove existing virtual environment:"
echo "   rm -rf venv"
echo ""

echo "3. Create new virtual environment:"
echo "   python3 -m venv venv"
echo ""

echo "4. Make pip executable:"
echo "   chmod +x venv/bin/pip"
echo ""

echo "5. Install dependencies:"
echo "   ./venv/bin/pip install --upgrade pip"
echo "   ./venv/bin/pip install -r requirements.txt"
echo ""

echo "6. Test the application:"
echo "   ./venv/bin/python -c \"import sys; sys.path.append('.'); from app.main import app; print('✅ Application imports successfully')\""
echo ""

echo "7. Restart PM2 service:"
echo "   pm2 stop climate-backend"
echo "   pm2 start \"venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000\" --name climate-backend"
echo "   pm2 save"
echo ""

echo "8. Test the service:"
echo "   curl http://localhost:8000/health"
echo ""

echo "9. Test geocoding:"
echo "   ./scripts/test-geocoding.sh"
echo ""

echo "10. Test full analysis:"
echo "    curl -X POST http://localhost:8000/climate/analyze -H 'Content-Type: application/json' -d '{\"location\": \"London, UK\"}'"
echo ""

echo "Run these commands one by one to fix the virtual environment issue." 