# BrightPlanet Ventures - Complete Deployment Guide

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Build for Production](#build-for-production)
4. [Deployment Options](#deployment-options)
5. [Environment Variables](#environment-variables)
6. [Post-Deployment Checklist](#post-deployment-checklist)

---

## Prerequisites

Before deploying, ensure you have:
- Node.js 18+ installed
- npm or yarn package manager
- Git installed
- Supabase account and project
- Your Supabase Service Role Key (from Supabase Dashboard → Settings → API)

---

## Local Development Setup

### 1. Install Backend Dependencies
```bash
cd backend
npm install
```

### 2. Configure Backend Environment
Edit `backend/.env` with your Supabase credentials:
```
PORT=5000
SUPABASE_URL=https://ubokvxgxszhpzmjonuss.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_actual_service_role_key
NODE_ENV=development
```

### 3. Start Backend Server
```bash
npm run dev
```
Backend will run on http://localhost:5000

### 4. Start Frontend (Already Set Up)
```bash
cd ../frontend
npm start
```
Frontend will run on http://localhost:3000

---

## Build for Production

### Build Frontend
```bash
cd frontend
npm run build
```
This creates a production build in `frontend/build/`

### Test Production Build Locally
```bash
npm run serve
```

---

## Deployment Options

### Option 1: Docker Deployment (Full Stack)

**Best for:** VPS, AWS EC2, DigitalOcean, etc.

#### Steps:
1. **Install Docker & Docker Compose** on your server

2. **Update environment variables** in root `.env` file:
```bash
# Create .env file in root directory
cp .env.example .env
# Edit with your actual credentials
```

3. **Build and start containers**:
```bash
docker-compose up -d --build
```

4. **Access your app**:
   - Frontend: http://your-server-ip
   - Backend: http://your-server-ip:5000

5. **Check logs**:
```bash
docker-compose logs -f
```

6. **Stop containers**:
```bash
docker-compose down
```

---

### Option 2: Vercel (Frontend Only - Recommended)

**Best for:** Quick frontend deployment with CDN

#### Steps:
1. **Install Vercel CLI**:
```bash
npm install -g vercel
```

2. **Deploy from frontend directory**:
```bash
cd frontend
vercel
```

3. **Configure environment variables** in Vercel Dashboard:
   - Go to Project Settings → Environment Variables
   - Add all `REACT_APP_*` variables from `frontend/.env`

4. **For production**:
```bash
vercel --prod
```

**URL:** Your app will be live at `https://your-project.vercel.app`

---

### Option 3: Netlify (Frontend Only)

**Best for:** Static site hosting with continuous deployment

#### Steps:
1. **Install Netlify CLI**:
```bash
npm install -g netlify-cli
```

2. **Deploy from frontend directory**:
```bash
cd frontend
netlify deploy
```

3. **For production**:
```bash
netlify deploy --prod
```

4. **Or use Netlify Dashboard**:
   - Connect your GitHub repository
   - Build command: `npm run build`
   - Publish directory: `build`
   - Add environment variables in Site Settings

**URL:** Your app will be live at `https://your-site.netlify.app`

---

### Option 4: Railway (Full Stack - Easiest)

**Best for:** Full stack deployment with database support

#### Steps:
1. **Sign up** at https://railway.app

2. **Install Railway CLI**:
```bash
npm install -g @railway/cli
```

3. **Login**:
```bash
railway login
```

4. **Initialize project**:
```bash
railway init
```

5. **Deploy Backend**:
```bash
cd backend
railway up
```

6. **Deploy Frontend**:
```bash
cd ../frontend
railway up
```

7. **Add environment variables** in Railway Dashboard for each service

**URL:** Railway provides automatic URLs for both services

---

### Option 5: AWS (Full Stack - Advanced)

**Best for:** Enterprise production deployment

#### Backend (Elastic Beanstalk):
1. Install AWS CLI and EB CLI
2. Initialize EB application:
```bash
cd backend
eb init
eb create production-backend
eb deploy
```

#### Frontend (S3 + CloudFront):
1. Build frontend:
```bash
cd frontend
npm run build
```

2. Deploy to S3:
```bash
aws s3 sync build/ s3://your-bucket-name --delete
```

3. Set up CloudFront distribution pointing to S3 bucket

---

### Option 6: DigitalOcean App Platform (Full Stack)

**Best for:** Managed deployment with reasonable pricing

#### Steps:
1. **Sign up** at https://www.digitalocean.com

2. **Create App** → "From GitHub"

3. **Configure Backend Service**:
   - Source: `backend/`
   - Build Command: `npm install`
   - Run Command: `node server.js`
   - Port: 5000

4. **Configure Frontend Service**:
   - Source: `frontend/`
   - Build Command: `npm run build`
   - Output Directory: `build`

5. **Add environment variables** for each service

**URL:** DigitalOcean provides automatic URLs

---

### Option 7: Heroku (Backend)

**Best for:** Quick backend API deployment

#### Steps:
1. **Install Heroku CLI**:
```bash
npm install -g heroku
```

2. **Login**:
```bash
heroku login
```

3. **Create app and deploy backend**:
```bash
cd backend
heroku create your-app-name
git init
git add .
git commit -m "Initial commit"
git push heroku main
```

4. **Set environment variables**:
```bash
heroku config:set SUPABASE_URL=your_url
heroku config:set SUPABASE_SERVICE_ROLE_KEY=your_key
```

**URL:** `https://your-app-name.herokuapp.com`

---

## Environment Variables

### Frontend (.env)
```bash
REACT_APP_SUPABASE_URL=https://ubokvxgxszhpzmjonuss.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your_anon_key
REACT_APP_SUPABASE_SERVICE_ROLE_KEY=your_service_key (optional)
REACT_APP_API_URL=https://your-backend-url.com
REACT_APP_APP_NAME=BrightPlanetVentures
REACT_APP_VERSION=1.0.0
REACT_APP_MAX_LOGIN_ATTEMPTS=5
REACT_APP_RATE_LIMIT_WINDOW=15
REACT_APP_SESSION_TIMEOUT=1440
REACT_APP_ENABLE_LOGIN_LOGGING=true
REACT_APP_ENABLE_SESSION_TRACKING=true
```

### Backend (.env)
```bash
PORT=5000
SUPABASE_URL=https://ubokvxgxszhpzmjonuss.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
NODE_ENV=production
```

### Get Supabase Keys:
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Settings → API
4. Copy:
   - **Project URL** → SUPABASE_URL
   - **anon public** → REACT_APP_SUPABASE_ANON_KEY
   - **service_role** → SUPABASE_SERVICE_ROLE_KEY (Keep secret!)

---

## Post-Deployment Checklist

### ✅ Security
- [ ] Update all `.env` files with production credentials
- [ ] Add `.env` to `.gitignore` (already done)
- [ ] Enable HTTPS on your domain
- [ ] Set up CORS properly in backend
- [ ] Never expose service_role key to frontend

### ✅ Performance
- [ ] Enable Supabase Row Level Security (RLS)
- [ ] Set up database indexes for queries
- [ ] Enable CDN for static assets
- [ ] Configure caching headers

### ✅ Monitoring
- [ ] Set up error tracking (Sentry, LogRocket)
- [ ] Monitor API response times
- [ ] Set up uptime monitoring
- [ ] Configure Supabase usage alerts

### ✅ Domain Setup
1. Buy domain from Namecheap, GoDaddy, etc.
2. Add DNS records:
   - Frontend: A record or CNAME to deployment platform
   - Backend: A record or CNAME to backend server
3. Update environment variables with production URLs

---

## Quick Start Commands

### Local Development
```bash
# Terminal 1 - Backend
cd backend && npm install && npm run dev

# Terminal 2 - Frontend
cd frontend && npm start
```

### Docker Deployment
```bash
# From root directory
docker-compose up -d --build
```

### Vercel Deployment
```bash
cd frontend && vercel --prod
```

### Railway Deployment
```bash
cd backend && railway up
cd ../frontend && railway up
```

---

## Troubleshooting

### Backend won't start
- Check if PORT 5000 is available
- Verify Supabase credentials in `.env`
- Check logs: `npm run dev` or `docker-compose logs backend`

### Frontend won't connect to backend
- Update `REACT_APP_API_URL` in frontend `.env`
- Check CORS settings in `backend/server.js`
- Verify backend is running and accessible

### Database connection issues
- Verify Supabase URL and keys
- Check Supabase project status
- Ensure network allows connections to Supabase

### Build errors
- Clear node_modules: `rm -rf node_modules && npm install`
- Clear build cache: `rm -rf build`
- Check Node version: `node -v` (should be 18+)

---

## Recommended Production Setup

**For Best Results:**
1. **Frontend:** Vercel or Netlify (fast, free tier, CDN)
2. **Backend:** Railway or Render (easy setup, good free tier)
3. **Database:** Supabase (already set up)
4. **Domain:** Custom domain from Namecheap
5. **Monitoring:** Sentry for errors, UptimeRobot for uptime

**Cost:** $0-15/month for small traffic

---

## Support

For issues:
1. Check Supabase dashboard for database errors
2. Check deployment platform logs
3. Test API endpoints with Postman
4. Verify environment variables are set correctly

**Need help?** Check the deployment platform documentation:
- Vercel: https://vercel.com/docs
- Netlify: https://docs.netlify.com
- Railway: https://docs.railway.app
- AWS: https://docs.aws.amazon.com

---

## Next Steps

1. ✅ Install backend dependencies: `cd backend && npm install`
2. ✅ Test locally: Start both frontend and backend
3. ✅ Choose deployment platform from options above
4. ✅ Deploy and test production build
5. ✅ Set up custom domain
6. ✅ Configure monitoring and analytics

**Your app is ready to deploy! 🚀**
