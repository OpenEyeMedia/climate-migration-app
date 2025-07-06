#!/usr/bin/env python3
"""
Local test script to verify climate analysis consistency
"""
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

import asyncio
from app.services.climate_service import ClimateDataService

async def test_consistency():
    print("🧪 Testing Climate Data Consistency...")
    print("=" * 50)
    
    service = ClimateDataService()
    location = "Perpignan, France"
    
    print(f"📍 Testing: {location}")
    print("🔄 Running 3 consecutive analyses...")
    
    results = []
    
    for i in range(3):
        print(f"\n🔍 Test #{i+1}:")
        try:
            analysis = await service.get_comprehensive_climate_analysis(location)
            
            if analysis:
                current_temp = analysis.get('current_climate', {}).get('current_temperature')
                resilience = analysis.get('resilience_score')
                temp_change = analysis.get('projections', {}).get('temperature_change_2050')
                
                result = {
                    'current_temp': current_temp,
                    'resilience': resilience,
                    'temp_change': temp_change,
                    'data_source': analysis.get('current_climate', {}).get('data_source')
                }
                
                results.append(result)
                
                print(f"  ✅ Current Temp: {current_temp}°C")
                print(f"  ✅ Resilience: {resilience}")
                print(f"  ✅ 2050 Change: +{temp_change}°C")
                print(f"  ✅ Data Source: {result['data_source']}")
                
            else:
                print("  ❌ No analysis returned")
                
        except Exception as e:
            print(f"  ❌ Error: {e}")
    
    print("\n" + "=" * 50)
    print("📊 CONSISTENCY ANALYSIS:")
    
    if len(results) == 3:
        # Check if all results are identical
        if (results[0]['current_temp'] == results[1]['current_temp'] == results[2]['current_temp'] and
            results[0]['resilience'] == results[1]['resilience'] == results[2]['resilience']):
            print("✅ SUCCESS: All results are IDENTICAL!")
            print("✅ Data consistency issue FIXED!")
        else:
            print("❌ ISSUE: Results are still different:")
            for i, result in enumerate(results):
                print(f"   Test {i+1}: Temp={result['current_temp']}, Resilience={result['resilience']}")
        
        # Check data sources
        data_sources = [r['data_source'] for r in results]
        if all(source == 'open-meteo' for source in data_sources):
            print("✅ Using real Open-Meteo API data")
        elif all(source == 'fallback-realistic' for source in data_sources):
            print("⚠️  Using fallback data (API might be down)")
        else:
            print("❌ Mixed data sources - inconsistent!")
    else:
        print("❌ Not all tests completed successfully")

if __name__ == "__main__":
    asyncio.run(test_consistency())
