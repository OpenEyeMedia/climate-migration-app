# Climate Adaptation App

## Overview

The Climate Adaptation App is a comprehensive location intelligence platform that aggregates and analyses data from multiple authoritative sources to help users make informed decisions about where to live, work, or invest. The app transforms complex multi-dimensional data (climate, economic, social, environmental) into clear, actionable insights through intuitive visualisations and comparative analysis tools.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourorg/climate-adaptation-app.git
cd climate-adaptation-app

# Set up backend
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your settings

# Set up frontend
cd ../frontend
npm install
cp .env.example .env.local
# Edit .env.local with your settings

# Run with Docker (recommended)
docker-compose up
```

Access the app at http://localhost:3000

## Features

- 🌍 **Global Location Search**: Search and analyse any location worldwide
- 📊 **Comprehensive Analysis**: 9 categories with 50+ indicators
- 🔄 **Real-time Data**: Integration with 20+ authoritative sources
- 📈 **Comparison Tools**: Compare up to 4 locations side-by-side
- ⚖️ **Custom Weighting**: Personalise metric importance
- 📱 **Responsive Design**: Works on desktop and mobile devices
- 📄 **Export Reports**: Download analyses as PDF or CSV
- 🔍 **Data Transparency**: Clear sourcing for all metrics

## Documentation

- [Installation Guide](docs/installation.md)
- [User Guide](docs/user-guide/README.md)
- [API Documentation](docs/api/README.md)
- [Development Guide](docs/development.md)

## License

[Your License Here]
