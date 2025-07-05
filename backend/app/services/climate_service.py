import httpx
import asyncio
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
import json
import redis
import calendar
import math
from app.core.config import settings

class ClimateDataService:
    def __init__(self):
        # Try to initialize Redis, but fall back to no caching if it fails
        try:
            self.redis_client = redis.from_url(settings.redis_url)
            self.use_cache = True
        except Exception as e:
            print(f"Redis not available, running without cache: {e}")
            self.redis_client = None
            self.use_cache = False
        self.cache_ttl = 3600 * 24  # 24 hours
        
    async def get_location_coordinates(self, location_name: str) -> Optional[Dict]:
        """Get coordinates for a location using geocoding API"""
        cache_key = f"geocoding:{location_name.lower()}"
        
        # Check cache first (if available)
        if self.use_cache and self.redis_client:
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
                    
                    # Cache the result (if available)
                    if self.use_cache and self.redis_client:
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
    
    async def get_historical_climate_baseline(self, latitude: float, longitude: float) -> Optional[Dict]:
        """Get historical climate baseline (1990 or earliest available)"""
        cache_key = f"historical_baseline:{latitude}:{longitude}"
        
        # Check cache (if available) - cache historical data for 30 days
        if self.use_cache and self.redis_client:
            try:
                cached_data = self.redis_client.get(cache_key)
                if cached_data:
                    return json.loads(cached_data)
            except Exception as e:
                print(f"Cache read error: {e}")
        
        async with httpx.AsyncClient() as client:
            try:
                # Get historical data from Open-Meteo Archive API (1990-2020 for baseline)
                url = "https://archive-api.open-meteo.com/v1/archive"
                params = {
                    "latitude": latitude,
                    "longitude": longitude,
                    "start_date": "1990-01-01",
                    "end_date": "2020-12-31",
                    "daily": ["temperature_2m_max", "temperature_2m_min", "precipitation_sum"],
                    "timezone": "auto"
                }
                
                response = await client.get(url, params=params)
                response.raise_for_status()
                
                data = response.json()
                daily = data.get("daily", {})
                
                if not daily:
                    print("No historical data available from Open-Meteo")
                    return await self._get_worldbank_baseline(latitude, longitude)
                
                # Calculate monthly averages for the baseline period (1990-2020)
                baseline_data = self._calculate_monthly_baselines(daily)
                
                # Cache for 30 days (historical data doesn't change)
                if self.use_cache and self.redis_client:
                    try:
                        self.redis_client.setex(cache_key, 2592000, json.dumps(baseline_data))
                    except Exception as e:
                        print(f"Cache write error: {e}")
                
                return baseline_data
                
            except Exception as e:
                print(f"Open-Meteo historical data error: {e}")
                # Fallback to World Bank data
                return await self._get_worldbank_baseline(latitude, longitude)
    
    def _calculate_monthly_baselines(self, daily_data: Dict) -> Dict:
        """Calculate monthly baseline averages from daily historical data"""
        temp_max_data = daily_data.get("temperature_2m_max", [])
        temp_min_data = daily_data.get("temperature_2m_min", [])
        precip_data = daily_data.get("precipitation_sum", [])
        dates = daily_data.get("time", [])
        
        monthly_baselines = {}
        
        # Group data by month (1-12)
        for month in range(1, 13):
            month_temp_max = []
            month_temp_min = []
            month_precip = []
            
            for i, date_str in enumerate(dates):
                if i < len(temp_max_data) and i < len(temp_min_data) and i < len(precip_data):
                    date_obj = datetime.fromisoformat(date_str)
                    if date_obj.month == month:
                        if temp_max_data[i] is not None:
                            month_temp_max.append(temp_max_data[i])
                        if temp_min_data[i] is not None:
                            month_temp_min.append(temp_min_data[i])
                        if precip_data[i] is not None:
                            month_precip.append(precip_data[i])
            
            monthly_baselines[month] = {
                "avg_temp_max": sum(month_temp_max) / len(month_temp_max) if month_temp_max else 15.0,
                "avg_temp_min": sum(month_temp_min) / len(month_temp_min) if month_temp_min else 5.0,
                "avg_precipitation": sum(month_precip) / len(month_precip) if month_precip else 50.0,
                "data_points": len(month_temp_max)
            }
        
        return {
            "monthly_baselines": monthly_baselines,
            "baseline_period": "1990-2020",
            "data_source": "open-meteo-archive",
            "last_updated": datetime.utcnow().isoformat()
        }
    
    async def _get_worldbank_baseline(self, latitude: float, longitude: float) -> Optional[Dict]:
        """Fallback to World Bank climate data for historical baselines"""
        try:
            # For now, use geographic estimates based on latitude
            # In production, you'd integrate with World Bank Climate API
            base_temp = 20 - (abs(latitude) * 0.5)
            
            monthly_baselines = {}
            for month in range(1, 13):
                # Seasonal variation: colder in winter months
                seasonal_adjustment = 5 * math.cos((month - 7) * math.pi / 6)
                
                monthly_baselines[month] = {
                    "avg_temp_max": round(base_temp + 8 + seasonal_adjustment, 1),
                    "avg_temp_min": round(base_temp - 2 + seasonal_adjustment, 1),
                    "avg_precipitation": 60 + (20 * math.sin(month * math.pi / 6)),
                    "data_points": 30  # Estimated
                }
            
            return {
                "monthly_baselines": monthly_baselines,
                "baseline_period": "1990-2020 (estimated)",
                "data_source": "worldbank-estimated",
                "last_updated": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            print(f"World Bank baseline error: {e}")
            return None
    
    async def get_current_climate_data(self, latitude: float, longitude: float) -> Optional[Dict]:
        cache_key = f"current_climate:{latitude}:{longitude}"
        
        # Check cache (if available)
        if self.use_cache and self.redis_client:
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
                
                # Cache for 1 hour (if available)
                if self.use_cache and self.redis_client:
                    self.redis_client.setex(cache_key, 3600, json.dumps(climate_data))
                
    async def get_recent_climate_averages(self, latitude: float, longitude: float) -> Optional[Dict]:
        """Get recent 5-year climate averages (2020-2024) for comparison"""
        cache_key = f"recent_climate:{latitude}:{longitude}"
        
        # Check cache (if available)
        if self.use_cache and self.redis_client:
            try:
                cached_data = self.redis_client.get(cache_key)
                if cached_data:
                    return json.loads(cached_data)
            except Exception as e:
                print(f"Cache read error: {e}")
        
        async with httpx.AsyncClient() as client:
            try:
                # Get recent 5 years of data
                current_year = datetime.now().year
                start_year = current_year - 5
                
                url = "https://archive-api.open-meteo.com/v1/archive"
                params = {
                    "latitude": latitude,
                    "longitude": longitude,
                    "start_date": f"{start_year}-01-01",
                    "end_date": f"{current_year - 1}-12-31",
                    "daily": ["temperature_2m_max", "temperature_2m_min", "precipitation_sum"],
                    "timezone": "auto"
                }
                
                response = await client.get(url, params=params)
                response.raise_for_status()
                
                data = response.json()
                daily = data.get("daily", {})
                
                if not daily:
                    return None
                
                # Calculate recent averages
                recent_data = self._calculate_recent_averages(daily)
                
                # Cache for 24 hours
                if self.use_cache and self.redis_client:
                    try:
                        self.redis_client.setex(cache_key, 86400, json.dumps(recent_data))
                    except Exception as e:
                        print(f"Cache write error: {e}")
                
                return recent_data
                
            except Exception as e:
                print(f"Recent climate data error: {e}")
                return None
    
    def _calculate_recent_averages(self, daily_data: Dict) -> Dict:
        """Calculate recent 5-year averages"""
        temp_max_data = daily_data.get("temperature_2m_max", [])
        temp_min_data = daily_data.get("temperature_2m_min", [])
        precip_data = daily_data.get("precipitation_sum", [])
        dates = daily_data.get("time", [])
        
        current_month = datetime.now().month
        current_year = datetime.now().year
        
        # Get current month data from recent years
        current_month_temp_max = []
        current_month_temp_min = []
        current_month_precip = []
        
        # Get annual averages for temperature increase calculation
        annual_temps = []
        
        for i, date_str in enumerate(dates):
            if i < len(temp_max_data) and i < len(temp_min_data) and i < len(precip_data):
                date_obj = datetime.fromisoformat(date_str)
                
                # Collect current month data
                if date_obj.month == current_month:
                    if temp_max_data[i] is not None:
                        current_month_temp_max.append(temp_max_data[i])
                    if temp_min_data[i] is not None:
                        current_month_temp_min.append(temp_min_data[i])
                    if precip_data[i] is not None:
                        current_month_precip.append(precip_data[i])
                
                # Collect annual temperature data
                if temp_max_data[i] is not None and temp_min_data[i] is not None:
                    daily_avg = (temp_max_data[i] + temp_min_data[i]) / 2
                    annual_temps.append(daily_avg)
        
        return {
            "current_month": current_month,
            "current_month_data": {
                "avg_temp_max": sum(current_month_temp_max) / len(current_month_temp_max) if current_month_temp_max else 15.0,
                "avg_temp_min": sum(current_month_temp_min) / len(current_month_temp_min) if current_month_temp_min else 5.0,
                "avg_precipitation": sum(current_month_precip) / len(current_month_precip) if current_month_precip else 50.0,
                "data_points": len(current_month_temp_max)
            },
            "annual_avg_temp": sum(annual_temps) / len(annual_temps) if annual_temps else 15.0,
            "period": f"{current_year - 5}-{current_year - 1}",
            "data_source": "open-meteo-archive",
            "last_updated": datetime.utcnow().isoformat()
        }
    
    async def get_climate_projections(self, latitude: float, longitude: float) -> Optional[Dict]:
        """Get climate projections from Open-Meteo Climate API"""
        cache_key = f"climate_projections:{latitude}:{longitude}"
        
        # Check cache (if available)
        if self.use_cache and self.redis_client:
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
                if self.use_cache and self.redis_client:
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
        # Create a cache key for the entire analysis
        cache_key = f"full_analysis:{location_name.lower()}"
        
        # Check cache first (if available) - cache full analysis for 6 hours
        if self.use_cache and self.redis_client:
            try:
                cached_data = self.redis_client.get(cache_key)
                if cached_data:
                    print(f"Returning cached analysis for {location_name}")
                    return json.loads(cached_data)
            except Exception as e:
                print(f"Cache read error: {e}")
        
        # Step 1: Get coordinates
        location_data = await self.get_location_coordinates(location_name)
        if not location_data:
            print(f"Could not get coordinates for {location_name}")
            return None
        
        latitude = location_data["latitude"]
        longitude = location_data["longitude"]
        
        print(f"Got coordinates for {location_name}: {latitude}, {longitude}")
        
        # Step 2: Get current climate data, recent averages, historical baseline, and projections
        try:
            current_data, recent_data, baseline_data, projections = await asyncio.gather(
                self.get_current_climate_data(latitude, longitude),
                self.get_recent_climate_averages(latitude, longitude),
                self.get_historical_climate_baseline(latitude, longitude),
                self.get_climate_projections(latitude, longitude)
            )
        except Exception as e:
            print(f"Error getting climate data: {e}")
            current_data, recent_data, baseline_data, projections = None, None, None, None
        
        # If API calls fail, create realistic fallback data based on location
        if not current_data or not recent_data or not baseline_data or not projections:
            print(f"API calls failed, using fallback data for {location_name}")
            current_data = current_data or self._generate_realistic_current_data(location_name, latitude, longitude)
            recent_data = recent_data or self._generate_realistic_recent_data(location_name, latitude, longitude)
            baseline_data = baseline_data or self._generate_realistic_baseline_data(location_name, latitude, longitude)
            projections = projections or self._generate_realistic_projections(location_name, latitude, longitude)
        
        # Calculate climate variations
        climate_variations = self._calculate_climate_variations(recent_data, baseline_data)
        
        # Calculate annual temperature increase
        annual_temp_increase = self._calculate_annual_temp_increase(recent_data, baseline_data)
        
        # Step 3: Calculate resilience score
        resilience_score = await self.calculate_climate_resilience_score(current_data, projections)
        
        # Step 4: Compile comprehensive analysis
        analysis = {
            "location": location_data,
            "current_climate": current_data,
            "climate_variations": climate_variations,
            "annual_temp_increase": annual_temp_increase,
            "projections": projections,
            "resilience_score": resilience_score,
            "risk_assessment": self._generate_risk_assessment(projections, resilience_score),
            "recommendations": self._generate_recommendations(projections, resilience_score),
            "last_updated": datetime.utcnow().isoformat()
        }
        
        # Cache the full analysis for 6 hours (if available)
        if self.use_cache and self.redis_client:
            try:
                self.redis_client.setex(
                    cache_key, 
                    21600,  # 6 hours
                    json.dumps(analysis)
                )
                print(f"Cached analysis for {location_name}")
            except Exception as e:
                print(f"Cache write error: {e}")
        
        return analysis
    
    def _calculate_climate_variations(self, recent_data: Dict, baseline_data: Dict) -> Dict:
        """Calculate climate variations between recent and baseline periods"""
        if not recent_data or not baseline_data:
            return self._get_fallback_variations()
        
        current_month = recent_data.get("current_month", datetime.now().month)
        recent_month_data = recent_data.get("current_month_data", {})
        baseline_monthly = baseline_data.get("monthly_baselines", {}).get(str(current_month), {})
        
        # Calculate temperature variations (°C)
        temp_max_variation = recent_month_data.get("avg_temp_max", 15.0) - baseline_monthly.get("avg_temp_max", 15.0)
        temp_min_variation = recent_month_data.get("avg_temp_min", 5.0) - baseline_monthly.get("avg_temp_min", 5.0)
        
        # Calculate rainfall variation (%)
        recent_precip = recent_month_data.get("avg_precipitation", 50.0)
        baseline_precip = baseline_monthly.get("avg_precipitation", 50.0)
        
        if baseline_precip > 0:
            rainfall_variation_percent = ((recent_precip - baseline_precip) / baseline_precip) * 100
        else:
            rainfall_variation_percent = 0.0
        
        month_name = calendar.month_name[current_month]
        
        return {
            "current_month": current_month,
            "month_name": month_name,
            "temp_max_variation": round(temp_max_variation, 1),
            "temp_min_variation": round(temp_min_variation, 1),
            "rainfall_variation_percent": round(rainfall_variation_percent, 1),
            "baseline_period": baseline_data.get("baseline_period", "1990-2020"),
            "recent_period": recent_data.get("period", "2020-2024"),
            "data_quality": "high" if recent_data.get("data_source") == "open-meteo-archive" else "estimated"
        }
    
    def _calculate_annual_temp_increase(self, recent_data: Dict, baseline_data: Dict) -> Dict:
        """Calculate annual temperature increase from baseline"""
        if not recent_data or not baseline_data:
            return {"increase": 1.5, "period": "estimated", "confidence": "low"}
        
        recent_annual_temp = recent_data.get("annual_avg_temp", 15.0)
        
        # Calculate baseline annual average from monthly data
        baseline_monthly = baseline_data.get("monthly_baselines", {})
        baseline_temps = []
        for month_data in baseline_monthly.values():
            if isinstance(month_data, dict):
                avg_temp = (month_data.get("avg_temp_max", 15.0) + month_data.get("avg_temp_min", 5.0)) / 2
                baseline_temps.append(avg_temp)
        
        baseline_annual_temp = sum(baseline_temps) / len(baseline_temps) if baseline_temps else 10.0
        
        annual_increase = recent_annual_temp - baseline_annual_temp
        
        return {
            "increase": round(annual_increase, 1),
            "recent_avg": round(recent_annual_temp, 1),
            "baseline_avg": round(baseline_annual_temp, 1),
            "baseline_period": baseline_data.get("baseline_period", "1990-2020"),
            "recent_period": recent_data.get("period", "2020-2024"),
            "confidence": "high" if recent_data.get("data_source") == "open-meteo-archive" else "estimated"
        }
    
    def _get_fallback_variations(self) -> Dict:
        """Fallback climate variations when data is unavailable"""
        current_month = datetime.now().month
        month_name = calendar.month_name[current_month]
        
        return {
            "current_month": current_month,
            "month_name": month_name,
            "temp_max_variation": 1.5,
            "temp_min_variation": 1.2,
            "rainfall_variation_percent": 15.0,
            "baseline_period": "1990-2020 (estimated)",
            "recent_period": "2020-2024 (estimated)",
            "data_quality": "estimated"
        }
    
    def _generate_realistic_recent_data(self, location_name: str, latitude: float, longitude: float) -> Dict:
        """Generate realistic fallback recent climate data"""
        current_month = datetime.now().month
        current_year = datetime.now().year
        base_temp = self._get_base_temperature(location_name, latitude)
        
        return {
            "current_month": current_month,
            "current_month_data": {
                "avg_temp_max": base_temp + 8,
                "avg_temp_min": base_temp - 2,
                "avg_precipitation": 60,
                "data_points": 30
            },
            "annual_avg_temp": base_temp + 3,
            "period": f"{current_year - 5}-{current_year - 1}",
            "data_source": "fallback-realistic"
        }
    
    def _generate_realistic_baseline_data(self, location_name: str, latitude: float, longitude: float) -> Dict:
        """Generate realistic fallback baseline climate data"""
        base_temp = self._get_base_temperature(location_name, latitude)
        
        monthly_baselines = {}
        for month in range(1, 13):
            seasonal_adjustment = 5 * math.cos((month - 7) * math.pi / 6)
            monthly_baselines[str(month)] = {
                "avg_temp_max": round(base_temp + 6 + seasonal_adjustment, 1),
                "avg_temp_min": round(base_temp - 4 + seasonal_adjustment, 1),
                "avg_precipitation": 50 + (15 * math.sin(month * math.pi / 6)),
                "data_points": 30
            }
        
        return {
            "monthly_baselines": monthly_baselines,
            "baseline_period": "1990-2020 (estimated)",
            "data_source": "fallback-realistic"
        }
    
    def _get_base_temperature(self, location_name: str, latitude: float) -> float:
        """Get base temperature for a location"""
        # Use latitude to estimate reasonable temperature ranges
        base_temp = 20 - (abs(latitude) * 0.5)
        
        # Add location-specific adjustments
        if "UK" in location_name or "United Kingdom" in location_name:
            base_temp = 10
        elif "France" in location_name:
            base_temp = 14
        elif "Australia" in location_name:
            base_temp = 20
        elif "Canada" in location_name:
            base_temp = 6
        elif "Norway" in location_name or "Finland" in location_name:
            base_temp = 4
        
        return base_temp
    
    def _generate_realistic_current_data(self, location_name: str, latitude: float, longitude: float) -> Dict:
        """Generate realistic fallback data based on geographic location"""
        # Use latitude to estimate reasonable temperature ranges
        base_temp = 20 - (abs(latitude) * 0.5)  # Cooler as you go further from equator
        
        # Add some location-specific adjustments
        if "UK" in location_name or "United Kingdom" in location_name:
            base_temp = 12
        elif "France" in location_name:
            base_temp = 16
        elif "Australia" in location_name:
            base_temp = 22
        elif "Canada" in location_name:
            base_temp = 8
        elif "Norway" in location_name or "Finland" in location_name:
            base_temp = 6
        
        return {
            "current_temperature": round(base_temp + 2, 1),
            "current_humidity": 65,
            "avg_temp_max": round(base_temp + 8, 1),
            "avg_temp_min": round(base_temp - 3, 1),
            "total_precipitation": 80,
            "last_updated": datetime.utcnow().isoformat(),
            "data_source": "fallback-realistic"
        }
    
    def _generate_realistic_projections(self, location_name: str, latitude: float, longitude: float) -> Dict:
        """Generate realistic climate projections based on geography"""
        # More warming expected at higher latitudes
        base_warming = 1.5 + (abs(latitude) * 0.03)
        
        # Regional adjustments based on climate science
        if abs(latitude) > 60:  # Arctic regions
            base_warming += 1.0
        elif abs(latitude) > 45:  # Temperate regions
            base_warming += 0.3
        
        return {
            "temperature_change_2050": round(base_warming, 1),
            "current_avg_temp": 15.0,
            "future_avg_temp": round(15.0 + base_warming, 1),
            "extreme_heat_days_current": max(0, int((35 - abs(latitude)) * 0.5)),
            "extreme_heat_days_future": max(0, int((35 - abs(latitude)) * 0.8)),
            "precipitation_change_percent": round((latitude / 10) + 5, 1),
            "last_updated": datetime.utcnow().isoformat(),
            "data_source": "fallback-realistic"
        }
    
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
