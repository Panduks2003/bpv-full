# BrightPlanet Backend API

Express.js backend API server with Supabase integration.

## Setup

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Create `.env` file:
```bash
PORT=5000
SUPABASE_URL=https://ubokvxgxszhpzmjonuss.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
NODE_ENV=development
```

### 3. Start Server
```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Health Check
```
GET /api/health
```
Response:
```json
{
  "status": "ok",
  "message": "Backend server is running"
}
```

### Get Users (Example)
```
GET /api/users
```
Response:
```json
{
  "success": true,
  "data": [...]
}
```

## Add Your API Routes

Edit `server.js` to add custom endpoints for your application.

## Deployment

See main [DEPLOYMENT-GUIDE.md](../DEPLOYMENT-GUIDE.md) for deployment options.
