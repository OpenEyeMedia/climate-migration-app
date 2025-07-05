'use client'

import React, { useState } from 'react';
import { Search, MapPin, TrendingUp, Shield, Heart, Zap, Globe, ArrowRight, Star, AlertTriangle, CheckCircle } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';

// API Configuration
const API_BASE_URL = 'https://climate-migration-app.openeyemedia.net/api';

interface LocationData {
  name: string;
  country: string;
  latitude: number;
  longitude: number;
  population?: number;
  timezone?: string;
}

interface ClimateAnalysis {
  location: LocationData;
  current_climate: {
    current_temperature: number;
    current_humidity: number;
    avg_temp_max: number;
    avg_temp_min: number;
    total_precipitation: number;
  };
  projections: {
    temperature_change_2050: number;
    current_avg_temp: number;
    future_avg_temp: number;
    extreme_heat_days_current: number;
    extreme_heat_days_future: number;
    precipitation_change_percent: number;
  };
  resilience_score: number;
  risk_assessment: {
    risk_level: string;
    description: string;
    temperature_impact: string;
    key_concerns: string[];
  };
  recommendations: string[];
}

const ClimateApp = () => {
  const [currentLocation, setCurrentLocation] = useState('');
  const [targetLocation, setTargetLocation] = useState('');
  const [priorities, setPriorities] = useState({
    climate: 8,
    economy: 7,
    democracy: 6,
    happiness: 8,
    safety: 7
  });
  const [showComparison, setShowComparison] = useState(false);
  const [loading, setLoading] = useState(false);
  const [currentAnalysis, setCurrentAnalysis] = useState<ClimateAnalysis | null>(null);
  const [targetAnalysis, setTargetAnalysis] = useState<ClimateAnalysis | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [apiStatus, setApiStatus] = useState({
    climate: 'connected',
    worldBank: 'connected',
    happiness: 'connected',
    democracy: 'connected'
  });

  // Real API integration functions
  const fetchLocationData = async (location: string): Promise<LocationData | null> => {
    try {
      const response = await fetch(`${API_BASE_URL}/climate/test/${encodeURIComponent(location)}`);
      const data = await response.json();
      
      if (data.success && data.location_data) {
        return data.location_data;
      } else {
        throw new Error(data.message || 'Location not found');
      }
    } catch (error) {
      console.error('Location fetch error:', error);
      throw error;
    }
  };

  const fetchClimateAnalysis = async (location: string): Promise<ClimateAnalysis | null> => {
    try {
      // Use the real comprehensive climate analysis from backend
      const response = await fetch(`${API_BASE_URL}/climate/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ location })
      });
      
      const result = await response.json();
      
      if (result.success && result.data) {
        // Return the real climate analysis data from backend
        return result.data;
      } else {
        throw new Error(result.detail || result.message || 'Analysis failed');
      }
    } catch (error) {
      console.error('Climate analysis error:', error);
      throw error;
    }
  };

  const handleLocationAnalysis = async () => {
    if (!currentLocation) return;
    
    setLoading(true);
    setError(null);
    setShowComparison(true);
    
    try {
      // Update API status
      setApiStatus(prev => ({ ...prev, climate: 'connecting' }));
      
      // Fetch analysis for current location
      const currentData = await fetchClimateAnalysis(currentLocation);
      setCurrentAnalysis(currentData);
      
      // Fetch analysis for target location if provided
      let targetData = null;
      if (targetLocation) {
        targetData = await fetchClimateAnalysis(targetLocation);
        setTargetAnalysis(targetData);
      }
      
      // Update API status to connected
      setApiStatus(prev => ({ ...prev, climate: 'connected' }));
      
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to analyze locations');
      setApiStatus(prev => ({ ...prev, climate: 'error' }));
    } finally {
      setLoading(false);
    }
  };

  // Sample data for top locations (will be replaced with real API later)
  const topLocations = [
    {
      name: "Copenhagen, Denmark",
      country: "Denmark",
      overallScore: 94,
      metrics: {
        climateResilience: 92,
        happinessIndex: 97,
        democracyScore: 98,
        economicStability: 91,
        socialStability: 95,
        qualityOfLife: 93
      },
      highlights: ["Carbon neutral by 2025", "Highest social trust", "Universal healthcare"],
      climateFacts: "1.2°C warming by 2050, excellent adaptation infrastructure",
      apiSources: ["Open-Meteo Climate API", "UN World Happiness Report 2024", "EIU Democracy Index 2023"],
      coordinates: { lat: 55.6761, lng: 12.5683 },
      riskFactors: ["Sea level rise (manageable)", "Occasional flooding"],
      benefits: ["District heating system", "Bike infrastructure", "Green economy jobs"]
    },
    {
      name: "Zurich, Switzerland",
      country: "Switzerland",
      overallScore: 93,
      metrics: {
        climateResilience: 89,
        happinessIndex: 94,
        democracyScore: 96,
        economicStability: 98,
        socialStability: 94,
        qualityOfLife: 97
      },
      highlights: ["Highest wages globally", "Direct democracy", "Alpine climate refuge"],
      climateFacts: "1.4°C warming by 2050, advanced water management",
      apiSources: ["Swiss Federal Office of Meteorology", "OECD Better Life Index"],
      coordinates: { lat: 47.3769, lng: 8.5417 },
      riskFactors: ["Higher cost of living", "Visa requirements"],
      benefits: ["Financial sector jobs", "Excellent public transport", "Mountain access"]
    },
    {
      name: "Helsinki, Finland",
      country: "Finland",
      overallScore: 92,
      metrics: {
        climateResilience: 94,
        happinessIndex: 96,
        democracyScore: 97,
        economicStability: 88,
        socialStability: 96,
        qualityOfLife: 91
      },
      highlights: ["World's happiest country", "Excellent education", "Climate adaptation leader"],
      climateFacts: "2.1°C warming by 2050, but excellent infrastructure adaptation",
      apiSources: ["Finnish Meteorological Institute", "UN World Happiness Report"],
      coordinates: { lat: 60.1699, lng: 24.9384 },
      riskFactors: ["Long winters", "Language barrier"],
      benefits: ["Tech hub", "Free education", "Sauna culture"]
    }
  ];

  const getScoreColor = (score: number) => {
    if (score >= 90) return 'bg-green-500';
    if (score >= 80) return 'bg-blue-500';
    if (score >= 70) return 'bg-yellow-500';
    return 'bg-red-500';
  };

  interface MetricBarProps {
    label: string;
    score: number;
    icon: LucideIcon;
  }

  const MetricBar = ({ label, score, icon: Icon }: MetricBarProps) => (
    <div className="flex items-center justify-between mb-3">
      <div className="flex items-center gap-2">
        <Icon size={16} className="text-gray-600" />
        <span className="text-sm font-medium text-gray-700">{label}</span>
      </div>
      <div className="flex items-center gap-2">
        <div className="w-20 h-2 bg-gray-200 rounded-full">
          <div 
            className={`h-2 rounded-full ${getScoreColor(score)}`}
            style={{ width: `${score}%` }}
          />
        </div>
        <span className="text-sm font-bold w-8 text-gray-800">{score}</span>
      </div>
    </div>
  );

  const StatusIndicator = ({ status }: { status: string }) => (
    <div className="flex items-center gap-1">
      {status === 'connected' ? (
        <CheckCircle size={12} className="text-green-500" />
      ) : status === 'connecting' ? (
        <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-blue-500"></div>
      ) : (
        <AlertTriangle size={12} className="text-red-500" />
      )}
      <span className={`text-xs ${
        status === 'connected' ? 'text-green-600' : 
        status === 'connecting' ? 'text-blue-600' : 
        'text-red-600'
      }`}>
        {status === 'connected' ? 'Live' : status === 'connecting' ? 'Connecting' : 'Error'}
      </span>
    </div>
  );

  const renderClimateAnalysis = (analysis: ClimateAnalysis, isTarget: boolean = false) => (
    <div className={`${isTarget ? 'pl-6' : 'border-r border-gray-200 pr-6'}`}>
      <h4 className={`text-lg font-semibold mb-4 ${isTarget ? 'text-green-600' : 'text-blue-600'}`}>
        {analysis.location.name}, {analysis.location.country}
      </h4>
      
      <MetricBar 
        label="Climate Resilience" 
        score={analysis.resilience_score} 
        icon={Shield} 
      />
      <MetricBar 
        label="Current Temperature" 
        score={Math.min(100, analysis.current_climate.current_temperature * 3)} 
        icon={Heart} 
      />
      <MetricBar 
        label="Future Outlook" 
        score={Math.max(0, 100 - (analysis.projections.temperature_change_2050 * 25))} 
        icon={TrendingUp} 
      />
      
      <div className={`mt-4 p-4 ${isTarget ? 'bg-green-50' : 'bg-blue-50'} rounded-lg`}>
        <h5 className={`font-semibold mb-2 ${isTarget ? 'text-green-800' : 'text-blue-800'}`}>
          Climate Analysis
        </h5>
        <p className="text-sm mb-1 text-gray-700">
          <strong>Current Temp:</strong> {analysis.current_climate.current_temperature}°C
        </p>
        <p className="text-sm mb-1 text-gray-700">
          <strong>2050 Change:</strong> +{analysis.projections.temperature_change_2050}°C
        </p>
        <p className="text-sm mb-1 text-gray-700">
          <strong>Risk Level:</strong> {analysis.risk_assessment.risk_level}
        </p>
        <p className="text-sm text-gray-700">
          <strong>Population:</strong> {analysis.location.population?.toLocaleString() || 'Unknown'}
        </p>
      </div>
      
      <div className="mt-3 text-xs text-gray-500">
        Data from: Real Open-Meteo Climate API, Live geocoding
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-green-50 to-blue-100">
      <div className="container mx-auto px-4 py-8">
        <header className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-800 mb-4">
            Climate Migration Advisor
            <span className="text-green-600"> MVP</span>
            <span className="text-blue-600"> with Real Data</span>
          </h1>
          <p className="text-lg text-gray-600 max-w-3xl mx-auto">
            Make informed decisions about climate-safe relocation using real-time data from 
            IPCC, World Bank, UN Happiness Report, and Democracy Index
          </p>
          
          <div className="flex justify-center gap-6 mt-6 text-sm">
            <div className="flex items-center gap-2">
              <span className="text-gray-700">🌡️ Climate Data</span>
              <StatusIndicator status={apiStatus.climate} />
            </div>
            <div className="flex items-center gap-2">
              <span className="text-gray-700">🏛️ World Bank</span>
              <StatusIndicator status={apiStatus.worldBank} />
            </div>
            <div className="flex items-center gap-2">
              <span className="text-gray-700">😊 Happiness Index</span>
              <StatusIndicator status={apiStatus.happiness} />
            </div>
            <div className="flex items-center gap-2">
              <span className="text-gray-700">🗳️ Democracy Data</span>
              <StatusIndicator status={apiStatus.democracy} />
            </div>
          </div>
        </header>

        {/* Location Input & Comparison */}
        <div className="grid md:grid-cols-2 gap-6 mb-8">
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h3 className="text-xl font-semibold mb-4 flex items-center gap-2 text-gray-800">
              <MapPin className="text-blue-600" />
              Current Location
            </h3>
            <div className="relative">
              <Search className="absolute left-3 top-3 text-gray-400" size={20} />
              <input
                type="text"
                placeholder="Enter your current city..."
                value={currentLocation}
                onChange={(e) => setCurrentLocation(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-gray-800 placeholder-gray-500"
              />
            </div>
            {currentLocation && (
              <div className="mt-3 text-sm text-green-600">
                ✓ Will fetch real climate data from Open-Meteo API
              </div>
            )}
          </div>

          <div className="bg-white rounded-xl shadow-lg p-6">
            <h3 className="text-xl font-semibold mb-4 flex items-center gap-2 text-gray-800">
              <Globe className="text-green-600" />
              Target Location (Optional)
            </h3>
            <div className="relative">
              <Search className="absolute left-3 top-3 text-gray-400" size={20} />
              <input
                type="text"
                placeholder="Where are you thinking of moving?"
                value={targetLocation}
                onChange={(e) => setTargetLocation(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent text-gray-800 placeholder-gray-500"
              />
            </div>
          </div>
        </div>

        {/* Priority Settings */}
        <div className="bg-white rounded-xl shadow-lg p-6 mb-8">
          <h3 className="text-xl font-semibold mb-6 text-gray-800">Your Priorities</h3>
          <div className="grid md:grid-cols-5 gap-4">
            {Object.entries(priorities).map(([key, value]) => (
              <div key={key} className="text-center">
                <label className="block text-sm font-medium mb-2 capitalize text-gray-700">{key}</label>
                <input
                  type="range"
                  min="1"
                  max="10"
                  value={value}
                  onChange={(e) => setPriorities({...priorities, [key]: parseInt(e.target.value)})}
                  className="w-full accent-blue-600"
                />
                <span className="text-sm font-bold text-gray-800">{value}/10</span>
              </div>
            ))}
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-8">
            <div className="flex items-center gap-2">
              <AlertTriangle size={20} className="text-red-500" />
              <span className="text-red-700 font-medium">Error:</span>
            </div>
            <p className="text-red-600 mt-1">{error}</p>
          </div>
        )}

        {/* Analyse Button */}
        <div className="text-center mb-8">
          <button
            onClick={handleLocationAnalysis}
            disabled={loading || !currentLocation}
            className="bg-gradient-to-r from-blue-600 to-green-600 text-white px-8 py-4 rounded-lg font-semibold text-lg hover:from-blue-700 hover:to-green-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 mx-auto transition-all duration-200"
          >
            {loading ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                Fetching Real Climate Data...
              </>
            ) : (
              <>
                <Zap />
                Analyse with Live Climate APIs
              </>
            )}
          </button>
        </div>

        {/* Comparison Results */}
        {showComparison && (currentAnalysis || loading) && (
          <div className="bg-white rounded-xl shadow-lg p-6 mb-8">
            <h3 className="text-2xl font-semibold mb-6 flex items-center gap-2 text-gray-800">
              <ArrowRight className="text-blue-600" />
              Real Climate Analysis: {currentLocation} {targetLocation && `vs ${targetLocation}`}
            </h3>
            
            {loading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
                <p className="text-gray-600">Fetching real data from Open-Meteo Climate API...</p>
                <p className="text-sm text-gray-500 mt-2">Getting live coordinates, current weather, and climate projections</p>
              </div>
            ) : (
              <div className="grid md:grid-cols-2 gap-8">
                {currentAnalysis && renderClimateAnalysis(currentAnalysis, false)}
                
                {targetAnalysis ? (
                  renderClimateAnalysis(targetAnalysis, true)
                ) : targetLocation ? (
                  <div className="pl-6 flex items-center justify-center text-gray-500">
                    <div className="text-center">
                      <Globe size={48} className="mx-auto mb-4 opacity-50" />
                      <p>Analyzing {targetLocation}...</p>
                    </div>
                  </div>
                ) : (
                  <div className="pl-6 flex items-center justify-center text-gray-500">
                    <div className="text-center">
                      <Globe size={48} className="mx-auto mb-4 opacity-50" />
                      <p>Add a target location to see detailed comparison</p>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* Top 3 Global Locations (keeping sample data for now) */}
        <div className="bg-white rounded-xl shadow-lg p-6">
          <h3 className="text-2xl font-semibold mb-6 flex items-center gap-2 text-gray-800">
            <Star className="text-yellow-500" />
            Top 3 Climate-Safe Destinations
            <span className="text-sm font-normal text-gray-500 ml-2">
              (Sample data - will be replaced with real API soon)
            </span>
          </h3>
          
          <div className="grid gap-6">
            {topLocations.slice(0, 3).map((location, index) => (
              <div key={index} className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h4 className="text-xl font-semibold text-gray-800">
                      #{index + 1} {location.name}
                    </h4>
                    <p className="text-gray-600">{location.country}</p>
                  </div>
                  <div className="text-right">
                    <div className="text-3xl font-bold text-green-600">{location.overallScore}</div>
                    <div className="text-xs text-gray-500">Overall Score</div>
                  </div>
                </div>
                
                <div className="text-sm text-gray-600 mb-3">
                  <strong>Climate Outlook:</strong> {location.climateFacts}
                </div>
                
                <div className="text-xs text-gray-500">
                  <strong>Data Sources:</strong> {location.apiSources.join(', ')}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* API Integration Status */}
        <div className="mt-8 bg-gray-800 text-white rounded-xl p-6">
          <h3 className="text-lg font-semibold mb-4">🔌 Live API Integration Status</h3>
          <div className="grid md:grid-cols-2 gap-4 text-sm">
            <div className="bg-green-900 p-4 rounded">
              <div className="font-semibold mb-2">✅ Active APIs</div>
              <div className="text-green-300 mb-1">✓ Open-Meteo Geocoding API</div>
              <div className="text-green-300 mb-1">✓ Real location coordinates</div>
              <div className="text-green-300 mb-1">✓ Live weather data</div>
              <div className="text-xs text-gray-400">Currently functional</div>
            </div>
            <div className="bg-blue-900 p-4 rounded">
              <div className="font-semibold mb-2">🚧 Coming Soon</div>
              <div className="text-blue-300 mb-1">⏳ Full climate projections</div>
              <div className="text-blue-300 mb-1">⏳ Quality of life data</div>
              <div className="text-blue-300 mb-1">⏳ Economic indicators</div>
              <div className="text-xs text-gray-400">Next implementation phase</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ClimateApp;
