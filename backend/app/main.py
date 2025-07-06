from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import httpx
import asyncio
from typing import Dict, Optional
import os
import redis
from datetime import datetime
import json
from app.core.config import settings

app = FastAPI(
    title="Climate Migration API",
    description="Real-time climate data analysis for migration decisions",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
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
    """Basic health check"""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.get("/health/comprehensive")
async def comprehensive_health():
    """Comprehensive health check for all services"""
    health_status = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "checks": {},
        "version": "1.0.0"
    }
    
    # Check Redis
    try:
        from app.core.config import settings
        r = redis.from_url(settings.redis_url)
        r.ping()
        health_status["checks"]["redis"] = {
            "status": "healthy",
            "message": "Redis connection successful"
        }
    except Exception as e:
        health_status["checks"]["redis"] = {
            "status": "degraded",
            "message": f"Redis unavailable: {str(e)}"
        }
        health_status["status"] = "degraded"
    
    # Check external APIs
    try:
        async with httpx.AsyncClient() as client:
            # Test Open-Meteo Geocoding API
            response = await client.get(
                "https://geocoding-api.open-meteo.com/v1/search?name=London&count=1",
                timeout=5.0
            )
            response.raise_for_status()
            health_status["checks"]["openmeteo_geocoding"] = {
                "status": "healthy",
                "message": "Open-Meteo Geocoding API responding"
            }
    except Exception as e:
        health_status["checks"]["openmeteo_geocoding"] = {
            "status": "unhealthy",
            "message": f"Open-Meteo Geocoding API error: {str(e)}"
        }
        health_status["status"] = "degraded"
    
    # Check climate API
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://api.open-meteo.com/v1/forecast?latitude=51.5074&longitude=-0.1278&current=temperature_2m",
                timeout=5.0
            )
            response.raise_for_status()
            health_status["checks"]["openmeteo_climate"] = {
                "status": "healthy",
                "message": "Open-Meteo Climate API responding"
            }
    except Exception as e:
        health_status["checks"]["openmeteo_climate"] = {
            "status": "unhealthy",
            "message": f"Open-Meteo Climate API error: {str(e)}"
        }
        health_status["status"] = "degraded"
    
    # Check internal services
    try:
        from app.services.climate_service import ClimateDataService
        service = ClimateDataService()
        health_status["checks"]["climate_service"] = {
            "status": "healthy",
            "message": "Climate service initialized successfully"
        }
    except Exception as e:
        health_status["checks"]["climate_service"] = {
            "status": "unhealthy",
            "message": f"Climate service error: {str(e)}"
        }
        health_status["status"] = "degraded"
    
    return health_status

@app.get("/health/live")
async def liveness_check():
    """Simple liveness check for Kubernetes"""
    return {"status": "alive", "timestamp": datetime.utcnow().isoformat()}

@app.get("/health/ready")
async def readiness_check():
    """Readiness check for Kubernetes"""
    try:
        # Quick Redis check
        from app.core.config import settings
        r = redis.from_url(settings.redis_url)
        r.ping()
        return {"status": "ready", "timestamp": datetime.utcnow().isoformat()}
    except Exception:
        return {"status": "not ready", "timestamp": datetime.utcnow().isoformat()}

@app.get("/test")
async def test():
    return {"message": "API is working!", "endpoint": "test"}

# Simple climate data endpoint
@app.get("/climate/test/{city}")
async def test_climate(city: str):
    """Test endpoint to fetch real climate data"""
    try:
        async with httpx.AsyncClient() as client:
            # Simple geocoding request
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

@app.get("/locations/search")
async def search_locations(q: str, limit: int = 10):
    """Search for locations using Open-Meteo Geocoding API"""
    try:
        from app.services.climate_service import ClimateDataService
        
        service = ClimateDataService()
        locations = await service.search_locations(q, limit)
        
        return {
            "success": True,
            "locations": locations,
            "query": q
        }
        
    except Exception as e:
        print(f"Location search error: {e}")
        return {
            "success": False,
            "error": str(e),
            "locations": []
        }

@app.post("/climate/analyze")
async def analyze_location(request: dict):
    """Get comprehensive climate analysis using real data"""
    location = request.get("location", "")
    
    print(f"Received request for location: {location}")
    
    if not location:
        return {"success": False, "error": "Location parameter required"}
    
    try:
        # Import the climate service here to avoid circular imports
        from app.services.climate_service import ClimateDataService
        
        service = ClimateDataService()
        print(f"Created ClimateDataService, analyzing {location}...")
        
        analysis = await service.get_comprehensive_climate_analysis(location)
        
        if not analysis:
            print(f"No analysis returned for {location}")
            return {
                "success": False,
                "error": f"Could not find climate data for location: {location}"
            }
        
        print(f"Analysis completed for {location}")
        print(f"Current temp: {analysis.get('current_climate', {}).get('current_temperature')}")
        print(f"Resilience: {analysis.get('resilience_score')}")
        
        return {
            "success": True,
            "data": analysis
        }
        
    except Exception as e:
        print(f"Error analyzing {location}: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": f"Error analyzing location: {str(e)}"
        }
