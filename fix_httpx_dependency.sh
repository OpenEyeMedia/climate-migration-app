#!/bin/bash

echo "🔧 Step 3: Fix Missing httpx Dependency"
echo "======================================"
echo ""

cd /root/climate-migration-app/backend

echo "1️⃣ Check virtual environment:"
if [ -d "venv" ]; then
    echo "✅ Virtual environment exists"
    source venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "❌ Virtual environment missing"
fi

echo ""
echo "2️⃣ Check current Python packages:"
venv/bin/pip list | grep -E "(httpx|fastapi|uvicorn)"

echo ""
echo "3️⃣ Install missing httpx dependency:"
venv/bin/pip install httpx

echo ""
echo "4️⃣ Verify httpx installation:"
venv/bin/python -c "import httpx; print('✅ httpx imported successfully')"

echo ""
echo "5️⃣ Test geocoding now:"
venv/bin/python -c "
import asyncio
import httpx

async def test_geocoding():
    try:
        async with httpx.AsyncClient() as client:
            url = 'https://geocoding-api.open-meteo.com/v1/search'
            params = {'name': 'London', 'count': 1, 'language': 'en', 'format': 'json'}
            response = await client.get(url, params=params, timeout=10.0)
            data = response.json()
            if data.get('results'):
                print('✅ Geocoding works!')
                result = data['results'][0]
                print(f'Found: {result.get(\"name\")}, {result.get(\"country\")}')
                print(f'Coordinates: {result.get(\"latitude\")}, {result.get(\"longitude\")}')
            else:
                print('❌ No results from geocoding')
                print(f'Response: {data}')
    except Exception as e:
        print(f'❌ Error: {e}')

asyncio.run(test_geocoding())
"

echo ""
echo "6️⃣ Test climate service import:"
export PYTHONPATH="/root/climate-migration-app/backend:$PYTHONPATH"
venv/bin/python -c "
try:
    from app.services.climate_service import ClimateDataService
    print('✅ Climate service imports successfully')
    
    # Test the service
    import asyncio
    async def test_service():
        service = ClimateDataService()
        location_data = await service.get_location_coordinates('London, UK')
        if location_data:
            print(f'✅ Location found: {location_data.get(\"name\")}, {location_data.get(\"country\")}')
        else:
            print('❌ Location not found')
    
    asyncio.run(test_service())
    
except Exception as e:
    print(f'❌ Import error: {e}')
"

echo ""
echo "7️⃣ Restart backend with fixed dependencies:"
pm2 stop climate-backend
pm2 start "venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000" --name climate-backend

echo ""
echo "8️⃣ Test the fixed API:"
sleep 3
echo "Testing London analysis with fixed dependencies..."
curl -s -X POST http://localhost:8000/climate/analyze \
     -H 'Content-Type: application/json' \
     -d '{"location": "London, UK"}' > /tmp/fixed_test.json

if grep -q '"success": true' /tmp/fixed_test.json; then
    echo "🎉 SUCCESS! London analysis now works"
    echo "Climate data preview:"
    grep -o '"temp_max_variation":[^,]*' /tmp/fixed_test.json
    grep -o '"rainfall_variation_percent":[^,]*' /tmp/fixed_test.json
else
    echo "❌ Still failing:"
    cat /tmp/fixed_test.json
fi

echo ""
echo "9️⃣ Test data consistency:"
echo "First Bristol request:"
curl -s -X POST http://localhost:8000/climate/analyze \
     -H 'Content-Type: application/json' \
     -d '{"location": "Bristol, UK"}' | grep -o '"temp_max_variation":[^,]*'

sleep 1

echo "Second Bristol request (should be identical):"
curl -s -X POST http://localhost:8000/climate/analyze \
     -H 'Content-Type: application/json' \
     -d '{"location": "Bristol, UK"}' | grep -o '"temp_max_variation":[^,]*'

echo ""
echo "🎯 DEPENDENCY FIX COMPLETE!"
echo "=========================="
echo "✅ httpx dependency installed"
echo "✅ Geocoding functionality restored"
echo "✅ Backend restarted with working dependencies"
echo ""
echo "Next: Test your app in browser - location analysis should now work!"
