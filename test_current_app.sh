#!/bin/bash

echo "🧪 Step 1: Testing Current Climate Migration App"
echo "==============================================="
echo ""
echo "Let's verify what's currently working on your server..."
echo ""

cd /root/climate-migration-app

echo "📋 1. Check current PM2 processes:"
pm2 status

echo ""
echo "📋 2. Test backend health:"
curl -s http://localhost:8000/ | head -3

echo ""
echo "📋 3. Test basic climate analysis:"
echo "Testing London analysis..."
curl -s -X POST http://localhost:8000/climate/analyze \
     -H 'Content-Type: application/json' \
     -d '{"location": "London, UK"}' > /tmp/london_test.json

if grep -q '"success": true' /tmp/london_test.json; then
    echo "✅ London analysis works"
    echo "Sample data:"
    cat /tmp/london_test.json | jq -r '.data.climate_variations.month_name // "No month data"'
    cat /tmp/london_test.json | jq -r '.data.climate_variations.temp_max_variation // "No temp data"'
else
    echo "❌ London analysis failed"
    echo "Response:"
    cat /tmp/london_test.json
fi

echo ""
echo "📋 4. Test data consistency (run same query twice):"
echo "First request:"
curl -s -X POST http://localhost:8000/climate/analyze \
     -H 'Content-Type: application/json' \
     -d '{"location": "Bristol, UK"}' | jq -r '.data.climate_variations.temp_max_variation // "No data"'

sleep 2

echo "Second request (should be identical):"
curl -s -X POST http://localhost:8000/climate/analyze \
     -H 'Content-Type: application/json' \
     -d '{"location": "Bristol, UK"}' | jq -r '.data.climate_variations.temp_max_variation // "No data"'

echo ""
echo "📋 5. Check frontend accessibility:"
curl -s http://localhost:3001/ | grep -q "Climate Migration" && echo "✅ Frontend responding" || echo "❌ Frontend not responding"

echo ""
echo "📋 6. Test different locations:"
for city in "Perpignan, France" "Berlin, Germany" "Madrid, Spain"; do
    echo "Testing: $city"
    curl -s -X POST http://localhost:8000/climate/analyze \
         -H 'Content-Type: application/json' \
         -d "{\"location\": \"$city\"}" | jq -r '.success // false'
done

echo ""
echo "📋 7. Check current climate service file:"
if [ -f "backend/app/services/climate_service.py" ]; then
    echo "✅ Climate service exists"
    echo "Service type:"
    head -10 backend/app/services/climate_service.py | grep -E "(class|def|import)" | head -3
else
    echo "❌ Climate service missing"
fi

echo ""
echo "📋 8. Check current app structure:"
echo "Backend structure:"
ls -la backend/app/services/
echo ""
echo "Frontend structure:"
ls -la frontend/src/components/

echo ""
echo "📋 9. Check logs for errors:"
echo "Recent backend logs:"
pm2 logs climate-backend --lines 3 --nostream

echo ""
echo "Recent frontend logs:"
pm2 logs climate-frontend --lines 3 --nostream

echo ""
echo "🎯 CURRENT STATUS SUMMARY:"
echo "========================="
echo "✅ What's working:"
echo "❌ What's broken:"
echo "⚠️  What needs attention:"
echo ""
echo "Please review the output above and tell me:"
echo "1. Are both frontend and backend responding?"
echo "2. Is the climate analysis returning data?"
echo "3. Are you getting consistent results for the same city?"
echo "4. Any errors in the logs?"
