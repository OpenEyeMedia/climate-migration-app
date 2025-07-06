from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql://climate_user:climate_pass@localhost:5432/climate_migration"
    redis_url: str = "redis://localhost:6379"
    
    # API URLs
    open_meteo_api_url: str = "https://api.open-meteo.com/v1"
    geocoding_api_url: str = "https://geocoding-api.open-meteo.com/v1"
    world_bank_api_url: str = "https://climateknowledgeportal.worldbank.org/api"
    
    # App settings
    secret_key: str = "your-secret-key-change-this-in-production"
    cors_origins: str = "https://climate-migration-app.openeyemedia.net,http://localhost:3000"
    environment: str = "development"
    
    @property
    def cors_origins_list(self) -> List[str]:
        """Convert comma-separated CORS origins string to list"""
        return [origin.strip() for origin in self.cors_origins.split(",")]
    
    # Rate limiting
    requests_per_minute: int = 60
    requests_per_day: int = 1000
    
    class Config:
        env_file = ".env"
        extra = "ignore"  # Ignore extra fields from .env

settings = Settings()
