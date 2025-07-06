#!/bin/bash

# Test script to check geocoding API functionality

echo "Testing geocoding API..."

# Test the geocoding API directly
echo "Testing London geocoding:"
curl -s "https://geocoding-api.open-meteo.com/v1/search?name=London&count=1&language=en&format=json"

echo ""
echo ""
echo "Testing with different location..."

echo "Testing Paris geocoding:"
curl -s "https://geocoding-api.open-meteo.com/v1/search?name=Paris&count=1&language=en&format=json"

echo ""
echo ""
echo "Testing backend endpoint..."

echo "Testing backend location search:"
curl -s "http://localhost:8000/locations/search?q=London&limit=5" 