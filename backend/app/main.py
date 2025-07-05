from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import httpx
import asyncio
from typing import Dict, Optional

app = FastAPI(
    title="Climate Migration API",
    description="Real-time climate data analysis for migration decisions",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for testing
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

@app.post("/climate/analyze")
async def analyze_simple(request: dict):
    """Simple climate analysis endpoint"""
    location = request.get("location", "")
    
    if not location:
        return {"error": "Location parameter required"}
    
    # For now, return mock data with real structure
    return {
        "success": True,
        "location": location,
        "analysis": {
            "current_temperature": 22.5,
            "climate_resilience_score": 78,
            "temperature_change_2050": 1.8,
            "risk_level": "Moderate",
            "recommendations": [
                "Monitor climate trends",
                "Consider adaptation measures"
            ]
        }
    }
