#!/usr/bin/env python3
"""
Minimal test to isolate backend issues
"""
import sys
import os

print("🔍 Testing Backend Components...")
print("=" * 40)

# Test 1: Python imports
print("1. Testing Python imports:")
try:
    import httpx
    print("   ✅ httpx imported")
except ImportError as e:
    print(f"   ❌ httpx import failed: {e}")

try:
    import redis
    print("   ✅ redis imported")
except ImportError as e:
    print(f"   ❌ redis import failed: {e}")

try:
    import asyncio
    print("   ✅ asyncio imported")
except ImportError as e:
    print(f"   ❌ asyncio import failed: {e}")

# Test 2: FastAPI import
print("\n2. Testing FastAPI:")
try:
    from fastapi import FastAPI
    print("   ✅ FastAPI imported")
except ImportError as e:
    print(f"   ❌ FastAPI import failed: {e}")

# Test 3: App imports
print("\n3. Testing app imports:")
try:
    # Add the backend directory to Python path
    backend_path = os.path.join(os.path.dirname(__file__), 'backend')
    if backend_path not in sys.path:
        sys.path.insert(0, backend_path)
    
    from app.core.config import settings
    print("   ✅ Config imported")
    print(f"   📡 API URL: {settings.open_meteo_api_url}")
except ImportError as e:
    print(f"   ❌ Config import failed: {e}")

try:
    from app.services.climate_service import ClimateDataService
    print("   ✅ ClimateDataService imported")
except ImportError as e:
    print(f"   ❌ ClimateDataService import failed: {e}")

# Test 4: Simple API test
print("\n4. Testing API connectivity:")
try:
    import asyncio
    import httpx

    async def test_api():
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get("https://geocoding-api.open-meteo.com/v1/search?name=London&count=1")
                if response.status_code == 200:
                    data = response.json()
                    if data.get("results"):
                        print("   ✅ Open-Meteo API accessible")
                        return True
                print("   ⚠️  Open-Meteo API returned no results")
                return False
            except Exception as e:
                print(f"   ❌ Open-Meteo API failed: {e}")
                return False

    # Run the async test
    api_works = asyncio.run(test_api())
    
except Exception as e:
    print(f"   ❌ API test failed: {e}")

print("\n" + "=" * 40)
print("🎯 Diagnosis:")
print("If all imports work but API fails:")
print("   → Backend should use fallback data")
print("   → Check pm2 logs for specific errors")
print("\nIf imports fail:")
print("   → Run: pip install -r backend/requirements.txt")
print("   → Restart: pm2 restart climate-app")
