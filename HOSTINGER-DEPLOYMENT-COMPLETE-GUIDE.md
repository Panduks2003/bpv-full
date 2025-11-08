# 🚀 HOSTINGER VPS + CLOUD HOSTING DEPLOYMENT GUIDE
## Complete Step-by-Step Guide for BrightPlanet Ventures

---

## 📋 OVERVIEW

**Deployment Strategy:**
- **Frontend**: Hostinger Cloud Hosting (Static files)
- **Backend**: Hostinger VPS (Node.js server)
- **Database**: Supabase (Already configured)

**What You'll Deploy:**
- React Frontend (Admin + Promoter + Customer dashboards)
- Express.js Backend API
- Environment configurations
- SSL certificates (automatic via Hostinger)

---

## 🎯 PREREQUISITES CHECKLIST

### ✅ What You Need:
- [ ] Hostinger VPS access (SSH credentials)
- [ ] Hostinger Cloud Hosting access (cPanel/File Manager)
- [ ] Domain name (if using custom domain)
- [ ] Supabase credentials (already have)
- [ ] Your local project files (ready)

---

## 📦 PART 1: PREPARE DEPLOYMENT PACKAGE

### Step 1.1: Build Frontend
```bash
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/frontend"
npm install
npm run build
```

**Expected Output:**
- Creates `build/` folder with optimized static files
- Size: ~2-5 MB
- Contains: HTML, CSS, JS, assets

### Step 1.2: Prepare Backend
```bash
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/backend"
npm install --production
```

**Files to Deploy:**
- `server.js`
- `package.json`
- `.env` (create from .env.example)
- `node_modules/` (or install on VPS)

---

## 🖥️ PART 2: VPS SETUP (BACKEND)

### Step 2.1: Connect to VPS via SSH

**Get Your VPS Details from Hostinger:**
1. Login to Hostinger
2. Go to VPS → Your VPS
3. Note down:
   - IP Address: `xxx.xxx.xxx.xxx`
   - SSH Port: `22` (default)
   - Username: `root` or custom
   - Password: (from Hostinger panel)

**Connect via Terminal:**
```bash
ssh root@YOUR_VPS_IP
# Enter password when prompted
```

**Alternative (if you have SSH key):**
```bash
ssh -i ~/.ssh/your_key root@YOUR_VPS_IP
```

### Step 2.2: Install Node.js on VPS

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18.x (LTS)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version  # Should show v18.x.x
npm --version   # Should show 9.x.x or higher
```

### Step 2.3: Install PM2 (Process Manager)

```bash
# Install PM2 globally
sudo npm install -g pm2

# Verify installation
pm2 --version
```

### Step 2.4: Create Application Directory

```bash
# Create app directory
mkdir -p /var/www/brightplanet-backend
cd /var/www/brightplanet-backend

# Set permissions
sudo chown -R $USER:$USER /var/www/brightplanet-backend
```

### Step 2.5: Upload Backend Files to VPS

**Option A: Using SCP (from your local machine)**
```bash
# From your local terminal (NOT VPS)
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES"

# Upload backend files
scp -r backend/* root@YOUR_VPS_IP:/var/www/brightplanet-backend/

# Upload .env file separately
scp backend/.env root@YOUR_VPS_IP:/var/www/brightplanet-backend/.env
```

**Option B: Using SFTP Client (Easier)**
1. Download FileZilla or Cyberduck
2. Connect to VPS:
   - Host: `YOUR_VPS_IP`
   - Port: `22`
   - Protocol: SFTP
   - Username: `root`
   - Password: (from Hostinger)
3. Navigate to `/var/www/brightplanet-backend`
4. Upload all backend files

**Option C: Using Git (Recommended)**
```bash
# On VPS
cd /var/www/brightplanet-backend

# Clone your repository (if you have one)
git clone YOUR_REPO_URL .

# Or initialize and pull
git init
git remote add origin YOUR_REPO_URL
git pull origin main
```

### Step 2.6: Configure Backend Environment

```bash
# On VPS
cd /var/www/brightplanet-backend

# Create .env file
nano .env
```

**Paste this content:**
```env
PORT=5000
NODE_ENV=production
SUPABASE_URL=https://ubokvxgxszhpzmjonuss.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk1MTgzMSwiZXhwIjoyMDc0NTI3ODMxfQ.S9YcbQqlgXMMFE-5gpd-NfrglVbBscBh72eYgCmVRSY
```

**Save and exit:**
- Press `CTRL + X`
- Press `Y`
- Press `ENTER`

### Step 2.7: Install Dependencies on VPS

```bash
# On VPS
cd /var/www/brightplanet-backend
npm install --production
```

### Step 2.8: Start Backend with PM2

```bash
# Start application
pm2 start server.js --name brightplanet-backend

# Save PM2 configuration
pm2 save

# Setup PM2 to start on system boot
pm2 startup
# Follow the command it outputs

# Check status
pm2 status
pm2 logs brightplanet-backend
```

**Expected Output:**
```
┌─────┬──────────────────────────┬─────────┬─────────┬──────────┐
│ id  │ name                     │ mode    │ status  │ cpu      │
├─────┼──────────────────────────┼─────────┼─────────┼──────────┤
│ 0   │ brightplanet-backend     │ fork    │ online  │ 0%       │
└─────┴──────────────────────────┴─────────┴─────────┴──────────┘
```

### Step 2.9: Configure Firewall

```bash
# Allow port 5000 for backend
sudo ufw allow 5000/tcp

# Allow SSH (important!)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Step 2.10: Setup Nginx Reverse Proxy (Optional but Recommended)

```bash
# Install Nginx
sudo apt install nginx -y

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/brightplanet-backend
```

**Paste this configuration:**
```nginx
server {
    listen 80;
    server_name YOUR_VPS_IP;  # or your domain: api.yourdomain.com

    location / {
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
}
```

**Enable the configuration:**
```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/brightplanet-backend /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Enable Nginx to start on boot
sudo systemctl enable nginx
```

### Step 2.11: Test Backend API

```bash
# Test from VPS
curl http://localhost:5000/api/health

# Test from your local machine
curl http://YOUR_VPS_IP/api/health
```

**Expected Response:**
```json
{"status":"ok","message":"Backend server is running"}
```

---

## 🌐 PART 3: CLOUD HOSTING SETUP (FRONTEND)

### Step 3.1: Access Hostinger Cloud Hosting

1. Login to Hostinger
2. Go to **Hosting** → **Your Hosting Plan**
3. Click **File Manager** or use **FTP**

### Step 3.2: Update Frontend Environment

**Before building, update frontend .env:**
```bash
# On your local machine
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/frontend"
nano .env
```

**Update with your VPS backend URL:**
```env
# Supabase Configuration
REACT_APP_SUPABASE_URL=https://ubokvxgxszhpzmjonuss.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NTE4MzEsImV4cCI6MjA3NDUyNzgzMX0.rkPYllqA2-oxPtWowjwosGiYzgMfwYQFSbCRZ3tTcA4

# Backend API URL (UPDATE THIS!)
REACT_APP_API_URL=http://YOUR_VPS_IP:5000/api
# Or if using domain: https://api.yourdomain.com/api

# App Configuration
REACT_APP_APP_NAME=BrightPlanetVentures
REACT_APP_VERSION=1.0.0
REACT_APP_MAX_LOGIN_ATTEMPTS=5
REACT_APP_RATE_LIMIT_WINDOW=15
REACT_APP_SESSION_TIMEOUT=1440
REACT_APP_ENABLE_LOGIN_LOGGING=true
REACT_APP_ENABLE_SESSION_TRACKING=true
```

### Step 3.3: Build Frontend with Production Config

```bash
# Clean previous build
rm -rf build/

# Build for production
npm run build
```

### Step 3.4: Upload Frontend Files

**Option A: Using File Manager (Easiest)**
1. In Hostinger File Manager
2. Navigate to `public_html/` (or your domain folder)
3. Delete default files (index.html, etc.)
4. Upload entire `build/` folder contents
5. Extract if uploaded as ZIP

**Option B: Using FTP Client**
1. Get FTP credentials from Hostinger:
   - Host: `ftp.yourdomain.com`
   - Username: (from Hostinger)
   - Password: (from Hostinger)
   - Port: `21`
2. Connect with FileZilla/Cyberduck
3. Navigate to `public_html/`
4. Upload all files from `build/` folder

**Option C: Using Command Line (Advanced)**
```bash
# From your local machine
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/frontend/build"

# Upload via FTP (install lftp first: brew install lftp)
lftp -u YOUR_FTP_USERNAME,YOUR_FTP_PASSWORD ftp.yourdomain.com
cd public_html
mirror -R . .
exit
```

### Step 3.5: Configure .htaccess for React Router

**Create/Edit .htaccess in public_html:**
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  
  # Handle React Router
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteCond %{REQUEST_FILENAME} !-l
  RewriteRule . /index.html [L]
  
  # Security headers
  Header set X-Content-Type-Options "nosniff"
  Header set X-Frame-Options "SAMEORIGIN"
  Header set X-XSS-Protection "1; mode=block"
  
  # Compression
  <IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
  </IfModule>
  
  # Browser caching
  <IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType text/javascript "access plus 1 month"
  </IfModule>
</IfModule>
```

### Step 3.6: Test Frontend

1. Open browser
2. Go to: `http://yourdomain.com` or `http://your-hosting-ip`
3. Test all routes:
   - `/` - Landing page
   - `/admin` - Admin login
   - `/promoter` - Promoter login
   - `/customer` - Customer login

---

## 🔐 PART 4: SSL CERTIFICATE (HTTPS)

### For VPS (Backend):

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate (if using domain)
sudo certbot --nginx -d api.yourdomain.com

# Auto-renewal test
sudo certbot renew --dry-run
```

### For Cloud Hosting (Frontend):

1. In Hostinger panel
2. Go to **SSL** section
3. Click **Install SSL**
4. Choose **Free SSL** (Let's Encrypt)
5. Wait 5-10 minutes for activation

---

## 🧪 PART 5: TESTING & VERIFICATION

### Test Checklist:

```bash
# 1. Backend Health
curl http://YOUR_VPS_IP/api/health

# 2. Backend from Frontend
# Open browser console on your site
fetch('http://YOUR_VPS_IP:5000/api/health')
  .then(r => r.json())
  .then(console.log)

# 3. Test Login
# Try logging in as admin/promoter/customer

# 4. Test Commission System
# Create a customer and verify commission distribution

# 5. Check PM2 Status
ssh root@YOUR_VPS_IP
pm2 status
pm2 logs brightplanet-backend --lines 50
```

---

## 🔧 PART 6: MAINTENANCE COMMANDS

### VPS Backend Commands:

```bash
# SSH into VPS
ssh root@YOUR_VPS_IP

# View logs
pm2 logs brightplanet-backend

# Restart backend
pm2 restart brightplanet-backend

# Stop backend
pm2 stop brightplanet-backend

# Update backend code
cd /var/www/brightplanet-backend
git pull origin main  # if using git
npm install
pm2 restart brightplanet-backend

# Check system resources
pm2 monit
htop
df -h  # disk space
free -h  # memory
```

### Frontend Update:

```bash
# On local machine
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/frontend"

# Make changes
# ...

# Rebuild
npm run build

# Upload new build/ folder to Hostinger
# (Use File Manager or FTP)
```

---

## 🚨 TROUBLESHOOTING

### Backend Not Accessible:

```bash
# Check if backend is running
pm2 status

# Check logs
pm2 logs brightplanet-backend --lines 100

# Check port
sudo netstat -tulpn | grep 5000

# Restart
pm2 restart brightplanet-backend
```

### Frontend Shows Blank Page:

1. Check browser console for errors
2. Verify .env variables are correct
3. Check .htaccess is present
4. Clear browser cache
5. Check file permissions: `chmod -R 755 public_html`

### CORS Errors:

Update backend `server.js`:
```javascript
app.use(cors({
  origin: ['http://yourdomain.com', 'https://yourdomain.com'],
  credentials: true
}));
```

### Database Connection Issues:

1. Verify Supabase credentials in .env
2. Check Supabase project is active
3. Verify RLS policies allow access
4. Check network connectivity from VPS

---

## 📊 MONITORING

### Setup Monitoring:

```bash
# Install monitoring tools
sudo npm install -g pm2-logrotate
pm2 install pm2-logrotate

# Configure log rotation
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

### Health Check Endpoint:

Your backend has: `GET /api/health`

Setup external monitoring:
- UptimeRobot (free)
- Pingdom
- StatusCake

---

## 🎉 DEPLOYMENT COMPLETE!

### Your Live URLs:

- **Frontend**: `http://yourdomain.com` or `http://hosting-ip`
- **Backend API**: `http://YOUR_VPS_IP:5000/api` or `http://api.yourdomain.com/api`
- **Admin Panel**: `http://yourdomain.com/admin`
- **Promoter Panel**: `http://yourdomain.com/promoter`
- **Customer Panel**: `http://yourdomain.com/customer`

### Next Steps:

1. ✅ Test all functionality
2. ✅ Setup SSL certificates
3. ✅ Configure domain DNS
4. ✅ Setup monitoring
5. ✅ Create backups
6. ✅ Document credentials

---

## 📞 SUPPORT

If you encounter issues:
1. Check logs: `pm2 logs`
2. Review this guide
3. Check Hostinger documentation
4. Contact Hostinger support

---

**Deployment Date**: November 8, 2024
**Version**: 1.0.0
**Status**: Production Ready ✅
