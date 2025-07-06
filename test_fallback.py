#!/usr/bin/env python3

import re

def normalize_location(loc: str) -> str:
    loc = loc.lower().strip()
    loc = re.sub(r'[^a-z ]', '', loc)
    loc = re.sub(r'\s+', ' ', loc).strip()
    return loc

fallback_coordinates = {
    "london": {"name": "London", "country": "United Kingdom", "latitude": 51.5074, "longitude": -0.1278, "timezone": "Europe/London"},
    "new york": {"name": "New York", "country": "United States", "latitude": 40.7128, "longitude": -74.0060, "timezone": "America/New_York"},
    "paris": {"name": "Paris", "country": "France", "latitude": 48.8566, "longitude": 2.3522, "timezone": "Europe/Paris"},
    "tokyo": {"name": "Tokyo", "country": "Japan", "latitude": 35.6762, "longitude": 139.6503, "timezone": "Asia/Tokyo"},
    "sydney": {"name": "Sydney", "country": "Australia", "latitude": -33.8688, "longitude": 151.2093, "timezone": "Australia/Sydney"},
    "mumbai": {"name": "Mumbai", "country": "India", "latitude": 19.0760, "longitude": 72.8777, "timezone": "Asia/Kolkata"},
    "beijing": {"name": "Beijing", "country": "China", "latitude": 39.9042, "longitude": 116.4074, "timezone": "Asia/Shanghai"},
    "moscow": {"name": "Moscow", "country": "Russia", "latitude": 55.7558, "longitude": 37.6176, "timezone": "Europe/Moscow"},
    "cairo": {"name": "Cairo", "country": "Egypt", "latitude": 30.0444, "longitude": 31.2357, "timezone": "Africa/Cairo"}
}

def test_location(location_name: str):
    print(f"Testing location: '{location_name}'")
    
    location_normalized = normalize_location(location_name)
    print(f"Normalized: '{location_normalized}'")
    
    # Try exact match
    if location_normalized in fallback_coordinates:
        print(f"✓ Exact match found: {location_normalized}")
        return fallback_coordinates[location_normalized]
    
    # Try flexible match: check if the normalized location starts with a city name or contains it as a word
    for key in fallback_coordinates:
        if location_normalized.startswith(key) or f" {key} " in f" {location_normalized} ":
            print(f"✓ Flexible match found: {key}")
            return fallback_coordinates[key]
    
    # Try if any fallback key is a substring of the normalized location (last resort)
    for key in fallback_coordinates:
        if key in location_normalized:
            print(f"✓ Substring match found: {key}")
            return fallback_coordinates[key]
    
    print(f"✗ No match found")
    print(f"Available keys: {list(fallback_coordinates.keys())}")
    return None

# Test various formats
test_cases = [
    "London",
    "London, UK",
    "London, England, United Kingdom",
    "London UK",
    "london uk",
    "London, England",
    "New York",
    "New York, USA",
    "Paris, France"
]

for test_case in test_cases:
    result = test_location(test_case)
    if result:
        print(f"Result: {result['name']}, {result['country']}")
    else:
        print("Result: None")
    print("-" * 50) 