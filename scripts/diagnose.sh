#!/bin/bash

# Diagnostic script to identify virtual environment issues

echo "Virtual Environment Diagnostic Script"
echo "===================================="
echo ""

echo "1. Current directory:"
pwd
echo ""

echo "2. Python version:"
python3 --version
echo ""

echo "3. Python location:"
which python3
echo ""

echo "4. Directory contents:"
ls -la
echo ""

echo "5. Backend directory contents:"
if [ -d "backend" ]; then
    ls -la backend/
else
    echo "Backend directory not found"
fi
echo ""

echo "6. Virtual environment status:"
if [ -d "backend/venv" ]; then
    echo "Virtual environment exists"
    ls -la backend/venv/bin/
else
    echo "No virtual environment found"
fi
echo ""

echo "7. Testing virtual environment creation:"
cd backend
python3 -m venv test_venv
echo "Test virtual environment created"
ls -la test_venv/bin/
rm -rf test_venv
echo "Test virtual environment removed"
cd ..
echo ""

echo "8. PM2 status:"
pm2 status
echo ""

echo "9. System information:"
uname -a
echo ""

echo "10. Available Python executables:"
which python
which python3
ls -la /usr/bin/python*
echo ""

echo "Diagnostic complete!" 