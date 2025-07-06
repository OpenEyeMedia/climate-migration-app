#!/usr/bin/env python3

import asyncio
import sys
import os

# Add the backend directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

from app.services.climate_service import ClimateDataService

async def test_fallback():
    service = ClimateDataService()
    
    print("Testing fallback logic...")
    
    # Test with "London, UK"
    result = await service.get_location_coordinates("London, UK")
    print(f"Result for 'London, UK': {result}")
    
    # Test with "London"
    result2 = await service.get_location_coordinates("London")
    print(f"Result for 'London': {result2}")

if __name__ == "__main__":
    asyncio.run(test_fallback()) 