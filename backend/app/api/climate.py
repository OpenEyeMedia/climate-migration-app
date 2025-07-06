from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, List, Optional
from pydantic import BaseModel
from app.services.climate_service import ClimateDataService
import asyncio

router = APIRouter()

class LocationQuery(BaseModel):
    # Support both old format (location string) and new format (full geocoding object)
    location: Optional[str] = None
    name: Optional[str] = None
    country: Optional[str] = None
    admin1: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    population: Optional[int] = None
    timezone: Optional[str] = None

class ComparisonQuery(BaseModel):
    current_location: str
    target_location: str

@router.post("/climate/analyze")
async def analyze_location(query: LocationQuery):
    """Get comprehensive climate analysis for a location"""
    service = ClimateDataService()
    
    try:
        # If we have lat/lon coordinates, use them directly
        if query.latitude is not None and query.longitude is not None:
            print(f"Using coordinates directly: {query.latitude}, {query.longitude}")
            analysis = await service.get_comprehensive_climate_analysis_by_coords(
                query.latitude, 
                query.longitude,
                name=query.name or "Unknown",
                country=query.country or "Unknown",
                admin1=query.admin1 or "Unknown"
            )
        else:
            # Fall back to geocoding by name
            location_name = query.name or query.location
            if not location_name:
                raise HTTPException(
                    status_code=400,
                    detail="Either coordinates (latitude/longitude) or location name must be provided"
                )
            print(f"Using geocoding for location: {location_name}")
            analysis = await service.get_comprehensive_climate_analysis(location_name)
        
        if not analysis:
            location_display = query.name or query.location or "Unknown"
            raise HTTPException(
                status_code=404, 
                detail=f"Could not find climate data for location: {location_display}"
            )
        
        return {
            "success": True,
            "data": analysis
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error analyzing location: {str(e)}"
        )

@router.post("/climate/compare")
async def compare_locations(query: ComparisonQuery):
    """Compare climate data between two locations"""
    service = ClimateDataService()
    
    try:
        # Get analysis for both locations
        current_analysis, target_analysis = await asyncio.gather(
            service.get_comprehensive_climate_analysis(query.current_location),
            service.get_comprehensive_climate_analysis(query.target_location)
        )
        
        if not current_analysis:
            raise HTTPException(
                status_code=404,
                detail=f"Could not find data for current location: {query.current_location}"
            )
            
        if not target_analysis:
            raise HTTPException(
                status_code=404,
                detail=f"Could not find data for target location: {query.target_location}"
            )
        
        # Generate comparison insights
        comparison = {
            "current_location": current_analysis,
            "target_location": target_analysis,
            "comparison_insights": _generate_comparison_insights(current_analysis, target_analysis)
        }
        
        return {
            "success": True,
            "data": comparison
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error comparing locations: {str(e)}"
        )

def _generate_comparison_insights(current: Dict, target: Dict) -> Dict:
    """Generate insights comparing two locations"""
    current_score = current.get("resilience_score", 0)
    target_score = target.get("resilience_score", 0)
    
    current_temp_change = current.get("projections", {}).get("temperature_change_2050", 0)
    target_temp_change = target.get("projections", {}).get("temperature_change_2050", 0)
    
    insights = {
        "resilience_comparison": {
            "winner": "target" if target_score > current_score else "current" if current_score > target_score else "tie",
            "score_difference": target_score - current_score,
            "improvement": target_score > current_score
        },
        "temperature_comparison": {
            "current_change": current_temp_change,
            "target_change": target_temp_change,
            "difference": target_temp_change - current_temp_change,
            "target_cooler": target_temp_change < current_temp_change
        },
        "recommendation": _get_comparison_recommendation(current_score, target_score, current_temp_change, target_temp_change)
    }
    
    return insights

def _get_comparison_recommendation(current_score: int, target_score: int, current_temp: float, target_temp: float) -> str:
    """Get recommendation based on comparison"""
    if target_score > current_score + 10:
        return "Strong recommendation to consider target location - significantly better climate resilience"
    elif target_score > current_score:
        return "Moderate improvement expected by moving to target location"
    elif target_score < current_score - 10:
        return "Current location has significantly better climate outlook"
    else:
        return "Both locations have similar climate resilience profiles"

@router.get("/climate/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "climate-api"}
