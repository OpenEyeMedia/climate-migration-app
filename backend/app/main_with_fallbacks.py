"""
Backup main.py with better error handling
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import httpx
import asyncio
from typing import Dict, Optional
import os
import traceback

app = FastAPI(
    title="Climate Migration API",
    description="Real-time climate data analysis for migration decisions",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://climate-migration-app.openeyemedia.net", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "Climate Migration API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs"
    }

@app.get("/health")
async def health():
    return {"status": "healthy", "timestamp": "2025-07-05"}

@app.get("/test")
async def test():
    return {"message": "API is working!", "endpoint": "test"}

@app.post("/climate/analyze")
async def analyze_location_with_fallback(request: dict):
    """Get comprehensive climate analysis with multiple fallbacks"""
    location = request.get("location", "")
    
    print(f"🔍 Received request for location: {location}")
    
    if not location:
        return {"success": False, "error": "Location parameter required"}
    
    # Try Method 1: Full climate service
    try:
        print("🚀 Attempting full climate service...")
        from app.services.climate_service import ClimateDataService
        
        service = ClimateDataService()
        analysis = await service.get_comprehensive_climate_analysis(location)
        
        if analysis:
            print(f"✅ Full climate service successful for {location}")
            return {"success": True, "data": analysis}
        else:
            print("⚠️  Full climate service returned None")
            
    except Exception as e:
        print(f"❌ Full climate service failed: {str(e)}")
        print("📋 Full traceback:")
        traceback.print_exc()
    
    # Try Method 2: Simple climate service
    try:
        print("🔄 Attempting simple climate service...")
        from app.services.simple_climate_service import SimpleClimateService
        
        simple_service = SimpleClimateService()
        analysis = await simple_service.get_simple_analysis(location)
        
        if analysis:
            print(f"✅ Simple climate service successful for {location}")
            return {"success": True, "data": analysis}
        else:
            print("⚠️  Simple climate service returned None")
            
    except Exception as e:
        print(f"❌ Simple climate service failed: {str(e)}")
        traceback.print_exc()
    
    # Method 3: Hardcoded fallback
    print("🆘 Using hardcoded fallback...")
    try:
        hardcoded_analysis = {
            "location": {
                "name": location.split(",")[0].strip(),
                "country": "Unknown",
                "latitude": 50.0,
                "longitude": 2.0,
                "population": 100000
            },
            "current_climate": {
                "current_temperature": 15.0,
                "current_humidity": 65,
                "avg_temp_max": 20.0,
                "avg_temp_min": 10.0,
                "total_precipitation": 80
            },
            "projections": {
                "temperature_change_2050": 1.8,
                "current_avg_temp": 15.0,
                "future_avg_temp": 16.8,
                "extreme_heat_days_current": 5,
                "extreme_heat_days_future": 12,
                "precipitation_change_percent": 8.5
            },
            "resilience_score": 75,
            "risk_assessment": {
                "risk_level": "Moderate",
                "description": "Climate analysis temporarily unavailable - using fallback data.",
                "temperature_impact": "+1.8°C by 2050",
                "key_concerns": ["Rising temperatures"]
            },
            "recommendations": [
                "Monitor local climate adaptation plans",
                "Consider energy-efficient systems"
            ],
            "last_updated": "2025-07-05T12:00:00Z",
            "data_source": "hardcoded-fallback"
        }
        
        print(f"✅ Hardcoded fallback successful for {location}")
        return {"success": True, "data": hardcoded_analysis}
        
    except Exception as e:
        print(f"❌ Even hardcoded fallback failed: {str(e)}")
        traceback.print_exc()
    
    # Final fallback
    return {
        "success": False,
        "error": f"All analysis methods failed for location: {location}",
        "debug_info": "Check backend logs for detailed error information"
    }

# Keep the existing endpoints
@app.get("/climate/test/{city}")
async def test_climate(city: str):
    """Test endpoint to fetch real climate data"""
    try:
        async with httpx.AsyncClient() as client:
            geocoding_url = "https://geocoding-api.open-meteo.com/v1/search"
            params = {
                "name": city,
                "count": 1,
                "language": "en",
                "format": "json"
            }
            
            response = await client.get(geocoding_url, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            if data.get("results") and len(data["results"]) > 0:
                location = data["results"][0]
                return {
                    "success": True,
                    "city": city,
                    "location_data": {
                        "name": location.get("name"),
                        "country": location.get("country"),
                        "latitude": location.get("latitude"),
                        "longitude": location.get("longitude"),
                        "population": location.get("population"),
                        "timezone": location.get("timezone")
                    }
                }
            else:
                return {
                    "success": False,
                    "message": f"No location found for: {city}"
                }
                
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": f"Error fetching data for: {city}"
        }
