# 🚀 HOSTINGER CLOUD HOSTING DEPLOYMENT GUIDE
## BrightPlanet Ventures - Complete Deployment Instructions

---

## 📋 PREREQUISITES

Before you begin, ensure you have:
- ✅ Hostinger Cloud Hosting account (Business plan or higher for Node.js)
- ✅ Domain: `brightplanetventures.com` configured in Hostinger
- ✅ SFTP/SSH credentials from Hostinger
- ✅ FileZilla or similar SFTP client installed
- ✅ Your Supabase credentials ready

---

## 🎯 DEPLOYMENT OVERVIEW

Your application has:
- **Frontend**: React.js (will be served as static files)
- **Backend**: Node.js/Express (will run on port 5000)
- **Database**: Supabase (already configured)

---

## 📦 STEP 1: BUILD YOUR APPLICATION LOCALLY

### 1.1 Run the deployment script:

```bash
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES"
chmod +x deploy-to-hostinger.sh
./deploy-to-hostinger.sh
```

This will:
- Build your React frontend
- Install backend dependencies
- Create necessary directories

### 1.2 Verify the build:

Check that these folders exist:
- ✅ `frontend/build/` - Contains built React app
- ✅ `backend/node_modules/` - Backend dependencies installed

---

## 🌐 STEP 2: SET UP HOSTINGER ACCOUNT

### 2.1 Access Hostinger hPanel:

1. Go to https://hpanel.hostinger.com
2. Log in with your credentials
3. Navigate to **Cloud** → **Your Cloud Hosting**

### 2.2 Configure Node.js:

1. In hPanel, go to **Advanced** → **Node.js**
2. Click **Create Application**
3. Set:
   - **Application Mode**: Production
   - **Application Root**: `/domains/brightplanetventures.com/backend`
   - **Application URL**: `brightplanetventures.com`
   - **Application Startup File**: `server.js`
   - **Node.js Version**: 18.x or higher

### 2.3 Configure Domain:

1. Go to **Domains** in hPanel
2. Add domain: `brightplanetventures.com`
3. Add subdomain (optional): `www.brightplanetventures.com`
4. Point DNS to Hostinger nameservers (if not already done)

---

## 📤 STEP 3: UPLOAD FILES TO HOSTINGER

### 3.1 Get SFTP Credentials:

1. In hPanel, go to **Files** → **FTP Accounts**
2. Note down:
   - Host: `ftp.brightplanetventures.com` (or provided by Hostinger)
   - Username: Your FTP username
   - Password: Your FTP password
   - Port: 21 (FTP) or 22 (SFTP)

### 3.2 Connect via SFTP (using FileZilla):

1. Open FileZilla
2. Enter:
   - **Host**: `sftp://your-host-from-hostinger`
   - **Username**: Your FTP username
   - **Password**: Your FTP password
   - **Port**: 22
3. Click **Quickconnect**

### 3.3 Upload Frontend Files:

**Local Path**: `frontend/build/*`
**Remote Path**: `/domains/brightplanetventures.com/public_html/`

Upload ALL files from the `build` folder:
- index.html
- static/ folder
- asset-manifest.json
- favicon.ico
- manifest.json
- robots.txt
- All other files

### 3.4 Upload Backend Files:

**Local Path**: `backend/*`
**Remote Path**: `/domains/brightplanetventures.com/backend/`

Upload:
- server.js
- package.json
- package-lock.json
- node_modules/ folder (or install on server)

### 3.5 Upload Configuration Files:

Upload to `/domains/brightplanetventures.com/`:
- `ecosystem.config.js`
- `.htaccess` (to public_html/)

---

## 🔐 STEP 4: CONFIGURE ENVIRONMENT VARIABLES

### 4.1 In Hostinger hPanel:

1. Go to **Advanced** → **Node.js**
2. Click on your application
3. Find **Environment Variables** section
4. Add these variables:

```
NODE_ENV=production
PORT=5000
SUPABASE_URL=https://ubokvxgxszhpzmjonuss.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk1MTgzMSwiZXhwIjoyMDc0NTI3ODMxfQ.S9YcbQqlgXMMFE-5gpd-NfrglVbBscBh72eYgCmVRSY
CORS_ORIGIN=https://brightplanetventures.com,https://www.brightplanetventures.com
COMMISSION_TOTAL=800
COMMISSION_LEVELS=500,100,100,100
ENABLE_COMMISSION_FALLBACK=true
ENABLE_RATE_LIMITING=true
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX_REQUESTS=100
LOG_LEVEL=info
ENABLE_ACCESS_LOGS=true
ENABLE_ERROR_LOGS=true
DB_POOL_SIZE=10
DB_TIMEOUT=30000
ENABLE_HEALTH_CHECKS=true
HEALTH_CHECK_INTERVAL=30000
```

---

## 🖥️ STEP 5: SSH INTO SERVER AND START APPLICATION

### 5.1 Connect via SSH:

1. In hPanel, go to **Advanced** → **SSH Access**
2. Enable SSH if not already enabled
3. Use the provided credentials

```bash
ssh username@your-server-ip
```

### 5.2 Navigate to your application:

```bash
cd /domains/brightplanetventures.com
```

### 5.3 Install PM2 (Process Manager):

```bash
npm install -g pm2
```

### 5.4 Install Backend Dependencies (if not uploaded):

```bash
cd backend
npm install --production
cd ..
```

### 5.5 Start Application with PM2:

```bash
pm2 start ecosystem.config.js --env production
```

### 5.6 Save PM2 Configuration:

```bash
pm2 save
pm2 startup
```

Follow the instructions shown to enable PM2 on system startup.

### 5.7 Check Application Status:

```bash
pm2 status
pm2 logs brightplanet-backend
```

---

## 🔒 STEP 6: CONFIGURE SSL CERTIFICATE

### 6.1 Enable SSL in hPanel:

1. Go to **Security** → **SSL**
2. Select your domain: `brightplanetventures.com`
3. Click **Install SSL Certificate**
4. Choose **Let's Encrypt** (Free)
5. Enable **Force HTTPS**
6. Enable **Auto-Renew**

### 6.2 Verify SSL:

Visit: `https://brightplanetventures.com`
- You should see a padlock icon in the browser

---

## 🔧 STEP 7: CONFIGURE NGINX (OPTIONAL BUT RECOMMENDED)

If you want to serve both frontend and backend through the same domain:

### 7.1 Edit Nginx Configuration:

```bash
sudo nano /etc/nginx/sites-available/brightplanetventures.com
```

### 7.2 Add this configuration:

```nginx
server {
    listen 80;
    server_name brightplanetventures.com www.brightplanetventures.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name brightplanetventures.com www.brightplanetventures.com;

    ssl_certificate /etc/letsencrypt/live/brightplanetventures.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/brightplanetventures.com/privkey.pem;

    # Frontend - Serve React app
    location / {
        root /domains/brightplanetventures.com/public_html;
        try_files $uri $uri/ /index.html;
        index index.html;
    }

    # Backend API - Proxy to Node.js
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;
}
```

### 7.3 Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/brightplanetventures.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## ✅ STEP 8: TEST YOUR DEPLOYMENT

### 8.1 Test Frontend:

Visit: `https://brightplanetventures.com`
- Should load your React application
- Check browser console for errors

### 8.2 Test Backend API:

Visit: `https://brightplanetventures.com/api/health`
- Should return: `{"status":"ok","message":"Backend server is running"}`

### 8.3 Test Full Functionality:

1. Try logging in as admin
2. Create a promoter
3. Create a customer
4. Check commission distribution
5. Test all major features

---

## 🔍 TROUBLESHOOTING

### Issue: Application not starting

**Solution:**
```bash
pm2 logs brightplanet-backend
pm2 restart brightplanet-backend
```

### Issue: 502 Bad Gateway

**Causes:**
- Node.js app not running
- Wrong port configuration
- Nginx not configured properly

**Solution:**
```bash
pm2 status
pm2 restart all
sudo systemctl status nginx
```

### Issue: Environment variables not loading

**Solution:**
1. Check hPanel → Node.js → Environment Variables
2. Restart PM2: `pm2 restart all`
3. Verify with: `pm2 env 0`

### Issue: CORS errors

**Solution:**
- Verify CORS_ORIGIN in environment variables
- Check backend server.js CORS configuration
- Restart backend: `pm2 restart brightplanet-backend`

### Issue: Frontend shows blank page

**Solution:**
1. Check browser console for errors
2. Verify all files uploaded to public_html
3. Check .htaccess file is present
4. Clear browser cache

---

## 📊 MONITORING

### Check Application Status:

```bash
pm2 status
pm2 monit
```

### View Logs:

```bash
pm2 logs brightplanet-backend
pm2 logs brightplanet-backend --lines 100
```

### Restart Application:

```bash
pm2 restart brightplanet-backend
```

### Stop Application:

```bash
pm2 stop brightplanet-backend
```

---

## 🔄 UPDATING YOUR APPLICATION

### To deploy updates:

1. Make changes locally
2. Build frontend: `npm run build`
3. Upload changed files via SFTP
4. Restart PM2: `pm2 restart brightplanet-backend`

---

## 📞 SUPPORT

If you encounter issues:

1. **Check Logs**: `pm2 logs brightplanet-backend`
2. **Check Hostinger Status**: https://www.hostinger.com/status
3. **Contact Hostinger Support**: Via hPanel chat
4. **Check Supabase Status**: https://status.supabase.com

---

## 🎉 DEPLOYMENT COMPLETE!

Your application should now be live at:
- **Frontend**: https://brightplanetventures.com
- **Backend API**: https://brightplanetventures.com/api

**Next Steps:**
- Set up automated backups
- Configure monitoring alerts
- Set up CI/CD for automatic deployments
- Monitor application performance

---

**Last Updated**: November 7, 2025
**Version**: 1.0.0
