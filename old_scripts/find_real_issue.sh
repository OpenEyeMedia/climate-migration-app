#!/bin/bash

echo "🔍 Step 4: Find the REAL Issue in Climate Service"
echo "==============================================="
echo ""

cd /root/climate-migration-app/backend

echo "📋 Let's see the EXACT current climate service code:"
echo "=================================================="
cat app/services/climate_service.py

echo ""
echo ""
echo "📋 Let's trace the issue step by step:"
echo "====================================="

echo "1️⃣ Test get_location_coordinates directly:"
venv/bin/python -c "
import sys, asyncio
sys.path.append('/root/climate-migration-app/backend')

async def test_coords():
    try:
        from app.services.climate_service import ClimateDataService
        service = ClimateDataService()
        
        print('Testing get_location_coordinates...')
        result = await service.get_location_coordinates('London, UK')
        print(f'Result: {result}')
        
        if result:
            print(f'✅ Coordinates found: {result.get(\"name\")}, {result.get(\"country\")}')
            print(f'Lat/Lng: {result.get(\"latitude\")}, {result.get(\"longitude\")}')
        else:
            print('❌ get_location_coordinates returned None')
            
    except Exception as e:
        print(f'❌ Error: {e}')
        import traceback
        traceback.print_exc()

asyncio.run(test_coords())
"

echo ""
echo "2️⃣ Test get_comprehensive_climate_analysis step by step:"
venv/bin/python -c "
import sys, asyncio
sys.path.append('/root/climate-migration-app/backend')

async def test_analysis():
    try:
        from app.services.climate_service import ClimateDataService
        service = ClimateDataService()
        
        print('Testing get_comprehensive_climate_analysis...')
        result = await service.get_comprehensive_climate_analysis('London, UK')
        print(f'Analysis result: {result}')
        
    except Exception as e:
        print(f'❌ Error in analysis: {e}')
        import traceback
        traceback.print_exc()

asyncio.run(test_analysis())
"

echo ""
echo "📋 DIAGNOSIS SUMMARY:"
echo "===================="
echo "This will show us exactly where the disconnect is happening."
