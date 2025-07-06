#!/bin/bash

echo "🔍 Step 2: Diagnose Location Lookup Issue"
echo "========================================"
echo ""

cd /root/climate-migration-app/backend

echo "📋 Current climate service analysis:"
echo "File size: $(wc -l app/services/climate_service.py)"
echo ""
echo "📋 Key methods in current service:"
grep -n "def " app/services/climate_service.py

echo ""
echo "📋 Location search methods:"
grep -n -A 5 "location" app/services/climate_service.py

echo ""
echo "📋 Check if geocoding is working:"
echo "Testing direct geocoding call..."
python3 -c "
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
                print('✅ Open-Meteo geocoding works')
                print(f'Found: {data[\"results\"][0].get(\"name\")}, {data[\"results\"][0].get(\"country\")}')
            else:
                print('❌ No results from Open-Meteo geocoding')
    except Exception as e:
        print(f'❌ Geocoding error: {e}')

asyncio.run(test_geocoding())
"

echo ""
echo "📋 Test the find_location method in current service:"
python3 -c "
import sys
sys.path.append('/root/climate-migration-app/backend')

try:
    from app.services.climate_service import ClimateDataService
    service = ClimateDataService()
    
    # Test if it has find_location method
    if hasattr(service, 'find_location'):
        result = service.find_location('London, UK')
        print(f'✅ find_location method exists, result: {result}')
    else:
        print('❌ find_location method missing')
        
    # Test available methods
    methods = [method for method in dir(service) if not method.startswith('_')]
    print(f'Available methods: {methods}')
    
except Exception as e:
    print(f'❌ Error importing climate service: {e}')
"

echo ""
echo "📋 Compare with backup service:"
echo "Backup service methods:"
grep -c "def " app/services/climate_service_backup.py
echo "Current service methods:"
grep -c "def " app/services/climate_service.py

echo ""
echo "🎯 DIAGNOSIS COMPLETE"
echo "===================="
echo "Based on the results above, the issue is likely:"
echo "1. Missing geocoding functionality in current service"
echo "2. Simplified service doesn't have proper location lookup"
echo "3. Need to restore working geocoding from backup"
