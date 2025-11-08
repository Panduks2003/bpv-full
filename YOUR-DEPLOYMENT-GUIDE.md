# 🚀 YOUR PERSONALIZED DEPLOYMENT GUIDE
## BrightPlanet Ventures - Ready to Deploy!

---

## ✅ YOUR CREDENTIALS (SAVED)

### VPS Details:
- **IP Address**: `72.61.169.111`
- **SSH Username**: `root`
- **SSH Password**: `Brightplanetventures@2025`
- **Domain**: `brightplanetventures.com`
- **OS**: Ubuntu 24.04 with OpenLiteSpeed and Node.js
- **Location**: Mumbai, India

### SSH Connection:
```bash
ssh root@72.61.169.111
# Password: Brightplanetventures@2025
```

---

## 🎯 DEPLOYMENT STEPS (CUSTOMIZED)

### ⚡ STEP 1: PREPARE PACKAGE (5 minutes)

```bash
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES"
./hostinger-deploy-script.sh
```

**Choose Option 4**: Create Complete Deployment Package

---

### 🖥️ STEP 2: DEPLOY BACKEND TO VPS (10 minutes)

#### 2.1 Connect to VPS
```bash
ssh root@72.61.169.111
# Enter password: Brightplanetventures@2025
```

#### 2.2 Check Node.js (Already Installed!)
```bash
node --version
npm --version
```

✅ **Node.js is already installed!** Skip installation step.

#### 2.3 Install PM2
```bash
npm install -g pm2
pm2 --version
```

#### 2.4 Create Application Directory
```bash
mkdir -p /var/www/brightplanet-backend
cd /var/www/brightplanet-backend
```

#### 2.5 Upload Backend Files

**Open NEW terminal on your Mac** (keep VPS connection open):
```bash
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/hostinger-deploy/backend"

# Upload files
scp -r * root@72.61.169.111:/var/www/brightplanet-backend/
# Enter password when prompted: Brightplanetventures@2025
```

#### 2.6 Configure Backend

**Back on VPS terminal**:
```bash
cd /var/www/brightplanet-backend

# Edit .env file
nano .env
```

**Paste this (already configured for you)**:
```env
PORT=5000
NODE_ENV=production
SUPABASE_URL=https://ubokvxgxszhpzmjonuss.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk1MTgzMSwiZXhwIjoyMDc0NTI3ODMxfQ.S9YcbQqlgXMMFE-5gpd-NfrglVbBscBh72eYgCmVRSY
```

**Save**: Press `CTRL+X`, then `Y`, then `ENTER`

#### 2.7 Install Dependencies & Start
```bash
# Install dependencies
npm install --production

# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup auto-start on boot
pm2 startup
# Copy and run the command it shows

# Check status
pm2 status
pm2 logs brightplanet-backend
```

#### 2.8 Configure Firewall
```bash
# Allow necessary ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 5000/tcp  # Backend API

# Enable firewall
ufw --force enable

# Check status
ufw status
```

#### 2.9 Test Backend
```bash
# Test from VPS
curl http://localhost:5000/api/health

# Should return: {"status":"ok","message":"Backend server is running"}
```

**From your Mac**:
```bash
curl http://72.61.169.111:5000/api/health
```

✅ **Backend Deployed!** API at: `http://72.61.169.111:5000/api`

---

### 🌐 STEP 3: DEPLOY FRONTEND TO CLOUD HOSTING (10 minutes)

#### 3.1 Update Frontend Environment

**On your Mac**:
```bash
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/frontend"

# Edit .env
nano .env
```

**Update this line**:
```env
REACT_APP_API_URL=http://72.61.169.111:5000/api
```

**Save and rebuild**:
```bash
npm run build
```

#### 3.2 Access Hostinger File Manager

1. Login to Hostinger: https://hpanel.hostinger.com
2. Go to **Hosting** → **brightplanetventures.com**
3. Click **File Manager**
4. Navigate to `public_html/`

#### 3.3 Upload Frontend Files

**Option A - File Manager (Easiest)**:
1. In File Manager, go to `public_html/`
2. Delete any default files
3. Click **Upload**
4. Select all files from `frontend/build/` folder
5. Wait for upload to complete
6. Verify `.htaccess` is present

**Option B - FTP**:
1. Get FTP credentials from Hostinger panel
2. Use FileZilla to connect
3. Upload all files from `build/` to `public_html/`

#### 3.4 Test Frontend

Open browser and go to:
- `https://brightplanetventures.com`
- `https://brightplanetventures.com/admin`
- `https://brightplanetventures.com/promoter`
- `https://brightplanetventures.com/customer`

✅ **Frontend Deployed!**

---

## 🔐 STEP 4: SETUP SSL (OPTIONAL - 5 minutes)

### For Frontend (Cloud Hosting):
1. Hostinger Panel → **SSL**
2. Click **Install SSL**
3. Choose **Free SSL** (Let's Encrypt)
4. Wait 5-10 minutes

### Update Frontend .env after SSL:
```env
REACT_APP_API_URL=https://72.61.169.111:5000/api
# or better: https://api.brightplanetventures.com/api
```

---

## 🎯 YOUR LIVE URLS

After deployment:

| Service | URL |
|---------|-----|
| **Frontend** | `https://brightplanetventures.com` |
| **Backend API** | `http://72.61.169.111:5000/api` |
| **Admin Panel** | `https://brightplanetventures.com/admin` |
| **Promoter Panel** | `https://brightplanetventures.com/promoter` |
| **Customer Panel** | `https://brightplanetventures.com/customer` |
| **API Health** | `http://72.61.169.111:5000/api/health` |

---

## 🔧 USEFUL COMMANDS

### Connect to VPS:
```bash
ssh root@72.61.169.111
```

### Check Backend Status:
```bash
pm2 status
pm2 logs brightplanet-backend
pm2 monit
```

### Restart Backend:
```bash
pm2 restart brightplanet-backend
```

### View System Resources:
```bash
htop
df -h  # disk space
free -h  # memory
```

---

## 🆘 TROUBLESHOOTING

### Backend Not Accessible:
```bash
ssh root@72.61.169.111
pm2 logs brightplanet-backend --lines 50
pm2 restart brightplanet-backend
```

### Frontend Shows Blank Page:
1. Check browser console (F12)
2. Verify `.htaccess` is in `public_html/`
3. Clear browser cache
4. Check API URL in frontend .env

### CORS Errors:
Update `backend/server.js`:
```javascript
app.use(cors({
  origin: [
    'http://brightplanetventures.com',
    'https://brightplanetventures.com',
    'http://www.brightplanetventures.com',
    'https://www.brightplanetventures.com'
  ],
  credentials: true
}));
```

Then restart:
```bash
pm2 restart brightplanet-backend
```

---

## ✅ POST-DEPLOYMENT CHECKLIST

- [ ] Backend API responding: `curl http://72.61.169.111:5000/api/health`
- [ ] Frontend loading: `https://brightplanetventures.com`
- [ ] Admin login working
- [ ] Promoter login working
- [ ] Customer login working
- [ ] Commission system functional
- [ ] PIN management working
- [ ] PM2 process running: `pm2 status`
- [ ] No errors in logs: `pm2 logs`
- [ ] SSL certificate installed
- [ ] Monitoring setup

---

## 🔄 UPDATE DEPLOYMENT

### Update Backend:
```bash
# SSH into VPS
ssh root@72.61.169.111

# Navigate to backend
cd /var/www/brightplanet-backend

# Upload new files (from Mac)
# Then:
npm install --production
pm2 restart brightplanet-backend
```

### Update Frontend:
```bash
# On your Mac
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/frontend"

# Make changes, then:
npm run build

# Upload new build/ contents to public_html/
```

---

## 📊 MONITORING

### Setup UptimeRobot (Free):
1. Go to: https://uptimerobot.com
2. Create account
3. Add monitor:
   - Type: HTTP(s)
   - URL: `http://72.61.169.111:5000/api/health`
   - Interval: 5 minutes
4. Add email for alerts

### Check Backend Health:
```bash
# From your Mac
curl http://72.61.169.111:5000/api/health

# From VPS
ssh root@72.61.169.111
pm2 monit
```

---

## 🎉 DEPLOYMENT COMPLETE!

Your BrightPlanet Ventures application is now live!

### What's Working:
✅ Backend API on VPS (Mumbai)  
✅ Frontend on Cloud Hosting  
✅ Database on Supabase  
✅ Node.js already installed  
✅ PM2 process manager  
✅ Firewall configured  
✅ Auto-restart enabled  

### Next Steps:
1. Test all features thoroughly
2. Setup SSL certificates
3. Configure domain DNS (if needed)
4. Setup monitoring (UptimeRobot)
5. Create regular backups
6. Document admin credentials

---

## 📞 SUPPORT

### Hostinger Support:
- **Live Chat**: https://www.hostinger.com/contact (24/7)
- **Email**: support@hostinger.com

### Your VPS:
- **IP**: 72.61.169.111
- **SSH**: `ssh root@72.61.169.111`
- **Password**: Brightplanetventures@2025

---

**Deployment Date**: November 8, 2024  
**Status**: ✅ Ready to Deploy  
**Estimated Time**: 25-30 minutes (Node.js already installed!)
