# 🗺️ DEPLOYMENT FLOWCHART
## BrightPlanet Ventures - Visual Deployment Guide

---

## 📊 DEPLOYMENT ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                    BRIGHTPLANET VENTURES                         │
│                     Deployment Architecture                      │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐
│   YOUR MAC       │         │   HOSTINGER      │
│   (Development)  │────────▶│   VPS + CLOUD    │
└──────────────────┘         └──────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
            ┌───────▼────────┐              ┌──────────▼─────────┐
            │  VPS SERVER    │              │  CLOUD HOSTING     │
            │  (Backend API) │              │  (Frontend Static) │
            │                │              │                    │
            │  Node.js       │              │  React Build       │
            │  Express       │              │  HTML/CSS/JS       │
            │  PM2           │              │  Apache/Nginx      │
            │  Port: 5000    │              │  Port: 80/443      │
            └───────┬────────┘              └──────────┬─────────┘
                    │                                   │
                    └─────────────────┬─────────────────┘
                                      │
                            ┌─────────▼──────────┐
                            │   SUPABASE         │
                            │   (Database)       │
                            │                    │
                            │   PostgreSQL       │
                            │   Auth             │
                            │   Storage          │
                            └────────────────────┘
```

---

## 🔄 DEPLOYMENT WORKFLOW

```
START
  │
  ├─ STEP 1: PREPARE LOCAL FILES
  │   │
  │   ├─ Build Frontend (npm run build)
  │   │   └─ Creates: build/ folder
  │   │
  │   ├─ Prepare Backend
  │   │   └─ server.js, package.json, .env
  │   │
  │   └─ Run: ./hostinger-deploy-script.sh
  │       └─ Creates: hostinger-deploy/ package
  │
  ├─ STEP 2: DEPLOY BACKEND TO VPS
  │   │
  │   ├─ Connect via SSH
  │   │   └─ ssh root@YOUR_VPS_IP
  │   │
  │   ├─ Install Node.js & PM2
  │   │   ├─ Node.js 18.x
  │   │   └─ PM2 (process manager)
  │   │
  │   ├─ Upload Backend Files
  │   │   └─ /var/www/brightplanet-backend/
  │   │
  │   ├─ Configure Environment
  │   │   └─ Edit .env file
  │   │
  │   ├─ Install Dependencies
  │   │   └─ npm install --production
  │   │
  │   ├─ Start with PM2
  │   │   └─ pm2 start ecosystem.config.js
  │   │
  │   └─ Configure Firewall
  │       └─ Open ports: 22, 80, 443, 5000
  │
  ├─ STEP 3: DEPLOY FRONTEND TO CLOUD HOSTING
  │   │
  │   ├─ Update Frontend .env
  │   │   └─ REACT_APP_API_URL=http://VPS_IP:5000/api
  │   │
  │   ├─ Rebuild Frontend
  │   │   └─ npm run build
  │   │
  │   ├─ Access Hostinger File Manager
  │   │   └─ Navigate to public_html/
  │   │
  │   ├─ Upload Build Files
  │   │   └─ Upload all from build/ folder
  │   │
  │   └─ Configure .htaccess
  │       └─ React Router support
  │
  ├─ STEP 4: SETUP SSL (OPTIONAL)
  │   │
  │   ├─ Frontend SSL
  │   │   └─ Hostinger Panel → SSL → Free SSL
  │   │
  │   └─ Backend SSL
  │       └─ certbot --nginx
  │
  ├─ STEP 5: VERIFY DEPLOYMENT
  │   │
  │   ├─ Test Backend API
  │   │   └─ curl http://VPS_IP:5000/api/health
  │   │
  │   ├─ Test Frontend
  │   │   └─ Open http://yourdomain.com
  │   │
  │   ├─ Test Admin Login
  │   │   └─ http://yourdomain.com/admin
  │   │
  │   └─ Test All Features
  │       ├─ Promoter creation
  │       ├─ Customer creation
  │       ├─ Commission distribution
  │       └─ PIN management
  │
  └─ DEPLOYMENT COMPLETE ✅
```

---

## 🎯 DEPLOYMENT DECISION TREE

```
Need to Deploy?
      │
      ├─ First Time Deployment?
      │   │
      │   YES ─▶ Follow QUICK-START-DEPLOYMENT.md
      │   │     (Complete setup from scratch)
      │   │
      │   NO ──▶ Updating Existing Deployment?
      │           │
      │           ├─ Backend Changes?
      │           │   │
      │           │   YES ─▶ 1. Upload new backend files
      │           │          2. npm install
      │           │          3. pm2 restart
      │           │
      │           └─ Frontend Changes?
      │               │
      │               YES ─▶ 1. npm run build
      │                      2. Upload build/ to public_html/
      │                      3. Clear browser cache
```

---

## 📦 FILE STRUCTURE AFTER DEPLOYMENT

### VPS Server Structure:
```
/var/www/brightplanet-backend/
├── server.js                    # Main backend server
├── package.json                 # Dependencies
├── .env                         # Environment variables
├── ecosystem.config.js          # PM2 configuration
├── node_modules/                # Installed packages
└── logs/                        # PM2 logs
    ├── error.log
    ├── out.log
    └── combined.log
```

### Cloud Hosting Structure:
```
public_html/
├── index.html                   # Main HTML file
├── .htaccess                    # Apache configuration
├── static/                      # Static assets
│   ├── css/                     # Stylesheets
│   │   └── main.*.css
│   ├── js/                      # JavaScript bundles
│   │   └── main.*.js
│   └── media/                   # Images, fonts
├── asset-manifest.json          # Build manifest
├── favicon.ico                  # Site icon
├── logo192.png                  # PWA icon
├── logo512.png                  # PWA icon
├── manifest.json                # PWA manifest
└── robots.txt                   # SEO robots file
```

---

## 🔌 CONNECTION FLOW

```
┌─────────────┐
│   BROWSER   │
│   (User)    │
└──────┬──────┘
       │
       │ HTTP/HTTPS Request
       │
       ▼
┌──────────────────────────────┐
│   CLOUD HOSTING              │
│   (Frontend - React App)     │
│   http://yourdomain.com      │
└──────┬───────────────────────┘
       │
       │ API Calls
       │ (fetch/axios)
       │
       ▼
┌──────────────────────────────┐
│   VPS SERVER                 │
│   (Backend - Express API)    │
│   http://VPS_IP:5000/api     │
└──────┬───────────────────────┘
       │
       │ Database Queries
       │ (Supabase Client)
       │
       ▼
┌──────────────────────────────┐
│   SUPABASE                   │
│   (Database + Auth)          │
│   PostgreSQL                 │
└──────────────────────────────┘
```

---

## 🚦 DEPLOYMENT STATUS INDICATORS

### ✅ Successful Deployment Checklist:

```
BACKEND (VPS):
  ✓ Node.js installed (v18.x)
  ✓ PM2 installed and running
  ✓ Backend files uploaded
  ✓ .env configured correctly
  ✓ Dependencies installed
  ✓ PM2 process running (pm2 status shows "online")
  ✓ Firewall configured
  ✓ API health check returns 200 OK
  ✓ Logs show no errors (pm2 logs)

FRONTEND (Cloud Hosting):
  ✓ Build files uploaded to public_html/
  ✓ .htaccess present and configured
  ✓ index.html accessible
  ✓ Static assets loading (CSS, JS, images)
  ✓ React Router working (no 404 on refresh)
  ✓ API calls reaching backend
  ✓ No CORS errors in console

DATABASE (Supabase):
  ✓ Project active
  ✓ Tables created
  ✓ RLS policies configured
  ✓ Connection from backend working
  ✓ Connection from frontend working

SECURITY:
  ✓ SSL certificates installed (optional but recommended)
  ✓ Firewall rules configured
  ✓ Environment variables secured
  ✓ No sensitive data in logs
```

---

## 🔧 MAINTENANCE WORKFLOW

```
Regular Maintenance
      │
      ├─ Daily
      │   └─ Check PM2 status: pm2 status
      │
      ├─ Weekly
      │   ├─ Review logs: pm2 logs --lines 100
      │   └─ Check disk space: df -h
      │
      ├─ Monthly
      │   ├─ Update dependencies: npm update
      │   ├─ Security updates: apt update && apt upgrade
      │   └─ Review SSL certificates
      │
      └─ As Needed
          ├─ Deploy updates
          ├─ Scale resources
          └─ Backup database
```

---

## 📊 MONITORING SETUP

```
┌─────────────────────────────────────────┐
│         MONITORING STACK                │
└─────────────────────────────────────────┘

1. PM2 Built-in Monitoring
   └─ pm2 monit
      ├─ CPU usage
      ├─ Memory usage
      └─ Process status

2. External Uptime Monitoring
   └─ UptimeRobot (Free)
      ├─ Monitor: http://VPS_IP:5000/api/health
      ├─ Check interval: 5 minutes
      └─ Email alerts on downtime

3. Log Monitoring
   └─ PM2 Logs
      ├─ Error logs: pm2 logs --err
      ├─ Output logs: pm2 logs --out
      └─ Real-time: pm2 logs --lines 50

4. System Monitoring
   └─ htop / top
      ├─ CPU usage
      ├─ Memory usage
      └─ Process list
```

---

## 🎯 QUICK REFERENCE COMMANDS

### VPS Commands:
```bash
# Connect
ssh root@YOUR_VPS_IP

# Check Status
pm2 status
pm2 logs brightplanet-backend
pm2 monit

# Restart
pm2 restart brightplanet-backend

# Stop
pm2 stop brightplanet-backend

# System Info
htop
df -h
free -h
```

### Local Commands:
```bash
# Build Frontend
cd frontend
npm run build

# Deploy Script
./hostinger-deploy-script.sh

# Test Backend Locally
cd backend
node server.js
```

---

## 🎉 SUCCESS INDICATORS

Your deployment is successful when:

1. ✅ Backend API responds: `curl http://VPS_IP:5000/api/health`
2. ✅ Frontend loads: Open `http://yourdomain.com`
3. ✅ Admin login works: `http://yourdomain.com/admin`
4. ✅ Promoter login works: `http://yourdomain.com/promoter`
5. ✅ Customer login works: `http://yourdomain.com/customer`
6. ✅ PM2 shows "online": `pm2 status`
7. ✅ No errors in logs: `pm2 logs`
8. ✅ Database connections work
9. ✅ Commission system functions
10. ✅ All features operational

---

**Ready to Deploy?** Start with: `QUICK-START-DEPLOYMENT.md`
