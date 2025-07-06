#!/bin/bash

# Test runner for Climate Adaptation App
# Runs all tests for both backend and frontend

echo "🧪 Running Climate Adaptation App Tests"
echo "====================================="

# Backend tests
echo -e "\n📋 Running backend tests..."
cd backend
source venv/bin/activate
pytest -v --cov=app --cov-report=term-missing
BACKEND_EXIT=$?

# Frontend tests
echo -e "\n📋 Running frontend tests..."
cd ../frontend
npm test
FRONTEND_EXIT=$?

# Summary
echo -e "\n📊 Test Summary:"
if [ $BACKEND_EXIT -eq 0 ]; then
    echo "✅ Backend tests passed"
else
    echo "❌ Backend tests failed"
fi

if [ $FRONTEND_EXIT -eq 0 ]; then
    echo "✅ Frontend tests passed"
else
    echo "❌ Frontend tests failed"
fi

# Exit with error if any tests failed
if [ $BACKEND_EXIT -ne 0 ] || [ $FRONTEND_EXIT -ne 0 ]; then
    exit 1
fi

echo -e "\n✅ All tests passed!"
