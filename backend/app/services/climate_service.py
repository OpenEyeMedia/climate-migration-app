import httpx
import asyncio
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
import json
import redis
from app.core.config import settings

class ClimateDataService:
    def __init__(self):
        self.redis_client = redis.from_url(settings.redis_url)
        self.cache_ttl = 3600 * 24  # 24 hours
        
    async def get_location_coordinates(self, location_name: str) -> Optional[Dict]:
        """Get coordinates for a location using geocoding API"""
        cache_key = f"geocoding:{location_name.lower()}"
        
        # Check cache first
        cached_data = self.redis_client.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        async with httpx.AsyncClient() as client:
            try:
                url = f"{settings.geocoding_api_url}/search"
                params = {
                    "name": location_name,
                    "count": 1,
                    "language": "en",
                    "format": "json"
                }
                
                response = await client.get(url, params=params)
                response.raise_for_status()
                
                data = response.json()
                if data.get("results") and len(data["results"]) > 0:
                    result = data["results"][0]
                    location_data = {
                        "name": result.get("name"),
                        "country": result.get("country"),
                        "latitude": result.get("latitude"),
                        "longitude": result.get("longitude"),
                        "population": result.get("population"),
                        "timezone": result.get("timezone")
                    }
                    
                    # Cache the result
                    self.redis_client.setex(
                        cache_key, 
                        self.cache_ttl * 7,  # Cache geocoding for 7 days
                        json.dumps(location_data)
                    )
                    
                    return location_data
                    
            except Exception as e:
                print(f"Geocoding error for {location_name}: {e}")
                return None
                
        return None
    
    async def get_current_climate_data(self, latitude: float, longitude: float) -> Optional[Dict]:
        """Get current climate data from Open-Meteo"""
        cache_key = f"current_climate:{latitude}:{longitude}"
        
        # Check cache
        cached_data = self.redis_client.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        async with httpx.AsyncClient() as client:
            try:
                url = f"{settings.open_meteo_api_url}/forecast"
                params = {
                    "latitude": latitude,
                    "longitude": longitude,
                    "current": ["temperature_2m", "relative_humidity_2m", "precipitation", "weather_code"],
                    "daily": ["temperature_2m_max", "temperature_2m_min", "precipitation_sum"],
                    "timezone": "auto",
                    "forecast_days": 7
                }
                
                response = await client.get(url, params=params)
                response.raise_for_status()
                
                data = response.json()
                
                # Process current data
                current = data.get("current", {})
                daily = data.get("daily", {})
                
                climate_data = {
                    "current_temperature": current.get("temperature_2m"),
                    "current_humidity": current.get("relative_humidity_2m"),
                    "current_precipitation": current.get("precipitation"),
                    "weather_code": current.get("weather_code"),
                    
                    "weekly_temp_max": daily.get("temperature_2m_max", []),
                    "weekly_temp_min": daily.get("temperature_2m_min", []),
                    "weekly_precipitation": daily.get("precipitation_sum", []),
                    
                    "avg_temp_max": sum(daily.get("temperature_2m_max", [])) / len(daily.get("temperature_2m_max", [])) if daily.get("temperature_2m_max") else None,
                    "avg_temp_min": sum(daily.get("temperature_2m_min", [])) / len(daily.get("temperature_2m_min", [])) if daily.get("temperature_2m_min") else None,
                    "total_precipitation": sum(daily.get("precipitation_sum", [])),
                    
                    "last_updated": datetime.utcnow().isoformat(),
                    "data_source": "open-meteo"
                }
                
                # Cache for 1 hour
                self.redis_client.setex(cache_key, 3600, json.dumps(climate_data))
                
                return climate_data
                
            except Exception as e:
                print(f"Current climate data error for {latitude}, {longitude}: {e}")
                return None
    
    async def get_climate_projections(self, latitude: float, longitude: float) -> Optional[Dict]:
        """Get climate projections from Open-Meteo Climate API"""
        cache_key = f"climate_projections:{latitude}:{longitude}"
        
        # Check cache
        cached_data = self.redis_client.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        async with httpx.AsyncClient() as client:
            try:
                url = f"https://climate-api.open-meteo.com/v1/climate"
                params = {
                    "latitude": latitude,
                    "longitude": longitude,
                    "models": "CMCC_CM2_VHR4",
                    "daily": ["temperature_2m_max", "temperature_2m_min", "precipitation_sum"],
                    "start_date": "2024-01-01",
                    "end_date": "2050-12-31"
                }
                
                response = await client.get(url, params=params)
                response.raise_for_status()
                
                data = response.json()
                daily = data.get("daily", {})
                
                # Calculate climate change projections
                temp_max_data = daily.get("temperature_2m_max", [])
                temp_min_data = daily.get("temperature_2m_min", [])
                precipitation_data = daily.get("precipitation_sum", [])
                
                # Split data into current period (2024-2030) and future period (2045-2050)
                current_period_temp_max = temp_max_data[:365*7] if temp_max_data else []
                future_period_temp_max = temp_max_data[-365*6:] if temp_max_data else []
                
                current_avg_temp = sum(current_period_temp_max) / len(current_period_temp_max) if current_period_temp_max else 0
                future_avg_temp = sum(future_period_temp_max) / len(future_period_temp_max) if future_period_temp_max else 0
                
                projections = {
                    "temperature_change_2050": round(future_avg_temp - current_avg_temp, 2),
                    "current_avg_temp": round(current_avg_temp, 1),
                    "future_avg_temp": round(future_avg_temp, 1),
                    
                    "extreme_heat_days_current": len([t for t in current_period_temp_max if t > 35]) if current_period_temp_max else 0,
                    "extreme_heat_days_future": len([t for t in future_period_temp_max if t > 35]) if future_period_temp_max else 0,
                    
                    "precipitation_change_percent": self._calculate_precipitation_change(precipitation_data),
                    
                    "last_updated": datetime.utcnow().isoformat(),
                    "data_source": "open-meteo-climate",
                    "model": "CMCC_CM2_VHR4"
                }
                
                # Cache for 24 hours (climate projections don't change often)
                self.redis_client.setex(cache_key, self.cache_ttl, json.dumps(projections))
                
                return projections
                
            except Exception as e:
                print(f"Climate projections error for {latitude}, {longitude}: {e}")
                return None
    
    def _calculate_precipitation_change(self, precipitation_data: List[float]) -> float:
        """Calculate percentage change in precipitation"""
        if not precipitation_data or len(precipitation_data) < 365*10:
            return 0.0
            
        # Split into current and future periods
        current_period = precipitation_data[:365*7]
        future_period = precipitation_data[-365*6:]
        
        current_avg = sum(current_period) / len(current_period)
        future_avg = sum(future_period) / len(future_period)
        
        if current_avg == 0:
            return 0.0
            
        change_percent = ((future_avg - current_avg) / current_avg) * 100
        return round(change_percent, 1)
    
    async def calculate_climate_resilience_score(self, climate_data: Dict, projections: Dict) -> int:
        """Calculate a climate resilience score (0-100)"""
        score = 100
        
        # Penalize for temperature increases
        temp_change = projections.get("temperature_change_2050", 0)
        if temp_change > 3:
            score -= 40
        elif temp_change > 2:
            score -= 25
        elif temp_change > 1.5:
            score -= 15
        elif temp_change > 1:
            score -= 10
        
        # Penalize for extreme heat days
        extreme_heat_increase = projections.get("extreme_heat_days_future", 0) - projections.get("extreme_heat_days_current", 0)
        if extreme_heat_increase > 30:
            score -= 20
        elif extreme_heat_increase > 15:
            score -= 10
        elif extreme_heat_increase > 5:
            score -= 5
        
        # Penalize for extreme precipitation changes
        precip_change = abs(projections.get("precipitation_change_percent", 0))
        if precip_change > 30:
            score -= 15
        elif precip_change > 20:
            score -= 10
        elif precip_change > 10:
            score -= 5
        
        return max(0, min(100, score))
    
    async def get_comprehensive_climate_analysis(self, location_name: str) -> Optional[Dict]:
        """Get complete climate analysis for a location"""
        # Step 1: Get coordinates
        location_data = await self.get_location_coordinates(location_name)
        if not location_data:
            return None
        
        latitude = location_data["latitude"]
        longitude = location_data["longitude"]
        
        # Step 2: Get current climate data and projections
        current_data, projections = await asyncio.gather(
            self.get_current_climate_data(latitude, longitude),
            self.get_climate_projections(latitude, longitude)
        )
        
        if not current_data or not projections:
            return None
        
        # Step 3: Calculate resilience score
        resilience_score = await self.calculate_climate_resilience_score(current_data, projections)
        
        # Step 4: Compile comprehensive analysis
        analysis = {
            "location": location_data,
            "current_climate": current_data,
            "projections": projections,
            "resilience_score": resilience_score,
            "risk_assessment": self._generate_risk_assessment(projections, resilience_score),
            "recommendations": self._generate_recommendations(projections, resilience_score),
            "last_updated": datetime.utcnow().isoformat()
        }
        
        return analysis
    
    def _generate_risk_assessment(self, projections: Dict, resilience_score: int) -> Dict:
        """Generate human-readable risk assessment"""
        temp_change = projections.get("temperature_change_2050", 0)
        
        if resilience_score >= 80:
            risk_level = "Low"
            description = "Minimal climate risks expected. Good long-term outlook."
        elif resilience_score >= 60:
            risk_level = "Moderate"
            description = "Some climate challenges expected but manageable with adaptation."
        elif resilience_score >= 40:
            risk_level = "High"
            description = "Significant climate risks. Consider adaptation measures."
        else:
            risk_level = "Very High"
            description = "Severe climate risks. Relocation may be advisable."
        
        return {
            "risk_level": risk_level,
            "description": description,
            "temperature_impact": f"+{temp_change}°C by 2050",
            "key_concerns": self._identify_key_concerns(projections)
        }
    
    def _identify_key_concerns(self, projections: Dict) -> List[str]:
        """Identify main climate concerns"""
        concerns = []
        
        temp_change = projections.get("temperature_change_2050", 0)
        if temp_change > 2:
            concerns.append("Significant temperature increase")
        
        extreme_heat_increase = projections.get("extreme_heat_days_future", 0) - projections.get("extreme_heat_days_current", 0)
        if extreme_heat_increase > 10:
            concerns.append("Increased extreme heat events")
        
        precip_change = projections.get("precipitation_change_percent", 0)
        if precip_change > 20:
            concerns.append("Increased flooding risk")
        elif precip_change < -20:
            concerns.append("Increased drought risk")
        
        if not concerns:
            concerns.append("Stable climate conditions expected")
        
        return concerns
    
    def _generate_recommendations(self, projections: Dict, resilience_score: int) -> List[str]:
        """Generate adaptation recommendations"""
        recommendations = []
        
        if resilience_score < 60:
            recommendations.append("Consider climate adaptation measures")
            recommendations.append("Invest in cooling/heating systems")
        
        temp_change = projections.get("temperature_change_2050", 0)
        if temp_change > 1.5:
            recommendations.append("Prepare for increased energy costs")
        
        precip_change = projections.get("precipitation_change_percent", 0)
        if precip_change > 15:
            recommendations.append("Consider flood insurance and drainage")
        elif precip_change < -15:
            recommendations.append("Plan for water conservation measures")
        
        if resilience_score >= 80:
            recommendations.append("Excellent climate stability - ideal for long-term planning")
        
        return recommendations
