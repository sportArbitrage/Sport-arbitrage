# Sports Arbitrage App - Backend

This is the backend for the Sports Arbitrage App, built with FastAPI and PostgreSQL.

## Features

- User authentication and management
- Real-time odds scraping from Nigerian bookmakers
- Arbitrage detection engine
- Push notifications via Firebase
- Admin dashboard
- RESTful API for Flutter mobile app

## Setup Instructions

### Prerequisites

- Python 3.9+
- PostgreSQL
- Firebase account (for authentication and push notifications)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/sports-arbitrage-app.git
cd sports-arbitrage-app/backend
```

2. Create and activate a virtual environment
```bash
python -m venv venv
# On Windows
venv\Scripts\activate
# On macOS/Linux
source venv/bin/activate
```

3. Install dependencies
```bash
pip install -r requirements.txt
```

4. Configure environment variables
```bash
# Copy the example env file
cp env.example .env
# Edit the .env file with your configuration
```

5. Set up Firebase
   - Create a Firebase project
   - Download the service account credentials file and save as `firebase-credentials.json` in the backend directory
   - Configure Firebase Authentication and Cloud Messaging

6. Initialize the database
```bash
python -m app.core.init_db
```

### Running the Server

Start the FastAPI server:
```bash
python main.py
```

The API will be available at http://localhost:8000

### API Documentation

FastAPI provides automatic API documentation:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Development Mode

For ease of development, the application includes a development mode that bypasses authentication. 

By default, development mode is **enabled**. This means:

- No authentication tokens are required to access API endpoints
- A mock development user is automatically created and used for all requests
- The mock user has admin privileges

### Disabling Development Mode

When you're ready to test with real authentication, you can disable development mode by setting the `DEV_MODE` environment variable to `False` in your `.env` file:

```
DEV_MODE=False
```

## API Endpoints

### Authentication
- POST `/api/auth/register` - Register a new user
- POST `/api/auth/login` - Login with email and password
- POST `/api/auth/firebase-login` - Login with Firebase token

### Users
- GET `/api/users/me` - Get current user profile
- PUT `/api/users/me` - Update current user profile
- PUT `/api/users/me/preferences` - Update user preferences

### Bookmakers
- GET `/api/bookmakers/` - List all bookmakers
- GET `/api/bookmakers/events` - List events from bookmakers

### Arbitrage
- GET `/api/arbitrage/opportunities` - List arbitrage opportunities
- GET `/api/arbitrage/notifications` - List user notifications
- POST `/api/arbitrage/calculate` - Calculate arbitrage for given odds

### Admin
- GET `/api/admin/stats` - Get system statistics
- GET `/api/admin/logs` - Get system logs
- POST `/api/admin/scraping/trigger` - Trigger scraping job

## Project Structure

```
backend/
├── app/
│   ├── api/
│   │   ├── routes/          # API endpoints
│   │   │   ├── auth.py
│   │   │   ├── users.py
│   │   │   ├── bookmakers.py
│   │   │   ├── arbitrage.py
│   │   │   └── admin.py
│   │   ├── auth/               # Authentication logic
│   │   │   └── jwt.py
│   │   ├── core/               # Core application modules
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── firebase.py
│   │   │   └── init_db.py
│   │   ├── models/             # Database models
│   │   │   ├── base.py
│   │   │   ├── user.py
│   │   │   ├── bookmaker.py
│   │   │   └── arbitrage.py
│   │   ├── schemas/            # Pydantic schemas
│   │   │   ├── user.py
│   │   │   ├── bookmaker.py
│   │   │   └── arbitrage.py
│   │   ├── scrapers/           # Bookmaker scrapers
│   │   │   ├── bet9ja_scraper.py
│   │   │   └── ...
│   │   ├── services/           # Business logic services
│   │   │   ├── arbitrage_calculator.py
│   │   │   ├── notification_service.py
│   │   │   └── scraper_manager.py
│   │   └── main.py             # FastAPI app instance
│   ├── env.example             # Example environment variables
│   ├── requirements.txt        # Python dependencies
│   └── main.py                 # Application entry point
```

## License

This project is licensed under the MIT License. 