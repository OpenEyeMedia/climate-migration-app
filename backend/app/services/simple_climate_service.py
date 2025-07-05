"""
Simplified climate service for debugging
"""
from typing import Dict, Optional
from datetime import datetime

class SimpleClimateService:
    """Simplified version that always works for debugging"""
    
    async def get_simple_analysis(self, location_name: str) -> Optional[Dict]:
        """Get simple but realistic climate analysis"""
        print(f"SimpleClimateService: Analyzing {location_name}")
        
        # Simple location-based temperature estimation
        if "UK" in location_name or "United Kingdom" in location_name:
            base_temp = 12.0
            country = "United Kingdom"
        elif "France" in location_name:
            base_temp = 16.0
            country = "France"
        elif "Spain" in location_name:
            base_temp = 20.0
            country = "Spain"
        elif "Germany" in location_name:
            base_temp = 14.0
            country = "Germany"
        else:
            base_temp = 15.0
            country = "Unknown"
        
        # Extract city name (simple)
        city_name = location_name.split(",")[0].strip()
        
        analysis = {
            "location": {
                "name": city_name,
                "country": country,
                "latitude": 50.0,  # Approximate
                "longitude": 2.0,  # Approximate
                "population": 100000
            },
            "current_climate": {
                "current_temperature": round(base_temp + 1.5, 1),
                "current_humidity": 65,
                "avg_temp_max": round(base_temp + 6, 1),
                "avg_temp_min": round(base_temp - 2, 1),
                "total_precipitation": 80
            },
            "projections": {
                "temperature_change_2050": 1.8,
                "current_avg_temp": base_temp,
                "future_avg_temp": round(base_temp + 1.8, 1),
                "extreme_heat_days_current": 5,
                "extreme_heat_days_future": 12,
                "precipitation_change_percent": 8.5
            },
            "resilience_score": 75,
            "risk_assessment": {
                "risk_level": "Moderate",
                "description": "Some climate challenges expected but manageable with adaptation.",
                "temperature_impact": "+1.8°C by 2050",
                "key_concerns": ["Rising temperatures", "Changing precipitation patterns"]
            },
            "recommendations": [
                "Monitor local climate adaptation plans",
                "Consider energy-efficient cooling systems",
                "Stay informed about extreme weather preparedness"
            ],
            "last_updated": datetime.utcnow().isoformat(),
            "data_source": "simplified-fallback"
        }
        
        print(f"SimpleClimateService: Analysis completed for {location_name}")
        return analysis
