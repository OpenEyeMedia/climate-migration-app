#!/usr/bin/env python3
"""
Debug script to test the climate API and see what's happening
"""
import asyncio
import httpx
import json

async def test_climate_api():
    print("🔍 Testing Climate Migration API...")
    
    # Test the live API endpoint
    api_url = "https://climate-migration-app.openeyemedia.net/api"
    
    # Test data for Perpignan, France
    location = "Perpignan, France"
    
    print(f"\n📍 Testing location: {location}")
    print("=" * 50)
    
    for i in range(3):
        print(f"\n🔄 Request #{i+1}:")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{api_url}/climate/analyze",
                    headers={'Content-Type': 'application/json'},
                    json={"location": location}
                )
                
                if response.status_code == 200:
                    data = response.json()
                    print(f"✅ Status: {response.status_code}")
                    
                    if data.get("success") and data.get("data"):
                        analysis = data["data"]
                        current_climate = analysis.get("current_climate", {})
                        projections = analysis.get("projections", {})
                        
                        print(f"🌡️  Current Temp: {current_climate.get('current_temperature')}")
                        print(f"🔮 Future Change: {projections.get('temperature_change_2050')}")
                        print(f"🛡️  Resilience: {analysis.get('resilience_score')}")
                        print(f"📊 Data Source: {current_climate.get('data_source')}")
                        print(f"⏰ Last Updated: {current_climate.get('last_updated')}")
                    else:
                        print(f"❌ API Error: {data}")
                else:
                    print(f"❌ HTTP Error: {response.status_code}")
                    print(f"Response: {response.text}")
                    
            except Exception as e:
                print(f"❌ Request failed: {e}")
        
        if i < 2:
            print("⏳ Waiting 2 seconds before next request...")
            await asyncio.sleep(2)
    
    print("\n" + "=" * 50)
    print("🎯 If data is different each time, the issue is:")
    print("   1. API calls are failing and falling back to random data")
    print("   2. Caching is not working")
    print("   3. Open-Meteo API is returning different data")

if __name__ == "__main__":
    asyncio.run(test_climate_api())
