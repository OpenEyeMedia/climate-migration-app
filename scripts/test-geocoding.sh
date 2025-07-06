#!/bin/bash

# Test script to check geocoding API functionality

echo "Testing geocoding API..."

# Test the geocoding API directly
curl -s "https://geocoding-api.open-meteo.com/v1/search?name=London&count=1&language=en&format=json" | jq .

echo ""
echo "Testing with different location..."

curl -s "https://geocoding-api.open-meteo.com/v1/search?name=Paris&count=1&language=en&format=json" | jq .

echo ""
echo "Testing backend endpoint..."

curl -s "http://localhost:8000/locations/search?q=London&limit=5" | jq . 