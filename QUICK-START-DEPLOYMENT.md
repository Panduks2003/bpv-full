# ⚡ QUICK START DEPLOYMENT GUIDE
## BrightPlanet Ventures - Hostinger VPS + Cloud Hosting

---

## 🎯 BEFORE YOU START

### Get These Ready:
1. ✅ Hostinger VPS IP Address: `___________________`
2. ✅ Hostinger VPS SSH Password: `___________________`
3. ✅ Hostinger Cloud Hosting FTP: `___________________`
4. ✅ Your Domain Name (if any): `___________________`

---

## 📦 STEP 1: PREPARE FILES (5 minutes)

### On Your Mac:

```bash
# Navigate to project
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES"

# Make script executable
chmod +x hostinger-deploy-script.sh

# Run deployment script
./hostinger-deploy-script.sh
```

**Choose Option 4**: Create Complete Deployment Package

**Result**: Creates `hostinger-deploy/` folder with everything ready

---

## 🖥️ STEP 2: DEPLOY BACKEND TO VPS (15 minutes)

### 2.1 Connect to VPS

```bash
# Replace YOUR_VPS_IP with actual IP
ssh root@YOUR_VPS_IP
```

### 2.2 Install Node.js

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2
sudo npm install -g pm2

# Verify
node --version
pm2 --version
```

### 2.3 Create App Directory

```bash
mkdir -p /var/www/brightplanet-backend
cd /var/www/brightplanet-backend
```

### 2.4 Upload Backend Files

**Option A - Using SCP (from your Mac):**
```bash
# Open NEW terminal on your Mac
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/hostinger-deploy/backend"

# Upload files (replace YOUR_VPS_IP)
scp -r * root@YOUR_VPS_IP:/var/www/brightplanet-backend/
```

**Option B - Using FileZilla:**
1. Download FileZilla
2. Connect: SFTP, YOUR_VPS_IP, Port 22, root, password
3. Upload all files from `hostinger-deploy/backend/` to `/var/www/brightplanet-backend/`

### 2.5 Configure Backend

```bash
# On VPS
cd /var/www/brightplanet-backend

# Edit .env file
nano .env
```

**Update these lines:**
```env
PORT=5000
NODE_ENV=production
SUPABASE_URL=https://ubokvxgxszhpzmjonuss.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk1MTgzMSwiZXhwIjoyMDc0NTI3ODMxfQ.S9YcbQqlgXMMFE-5gpd-NfrglVbBscBh72eYgCmVRSY
```

**Save**: `CTRL+X`, then `Y`, then `ENTER`

### 2.6 Install Dependencies & Start

```bash
# Install dependencies
npm install --production

# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 config
pm2 save

# Setup auto-start on boot
pm2 startup
# Copy and run the command it shows

# Check status
pm2 status
pm2 logs brightplanet-backend
```

### 2.7 Configure Firewall

```bash
# Allow necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 5000/tcp  # Backend API

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### 2.8 Test Backend

```bash
# Test from VPS
curl http://localhost:5000/api/health

# Should return: {"status":"ok","message":"Backend server is running"}
```

**From your Mac:**
```bash
curl http://YOUR_VPS_IP:5000/api/health
```

✅ **Backend Deployed!** API running at: `http://YOUR_VPS_IP:5000/api`

---

## 🌐 STEP 3: DEPLOY FRONTEND TO CLOUD HOSTING (10 minutes)

### 3.1 Update Frontend Environment

**On your Mac:**
```bash
cd "/Users/pandushirabur/Desktop/pandu/BRIGHTPLANET VENTURES/frontend"

# Edit .env
nano .env
```

**Add/Update this line:**
```env
REACT_APP_API_URL=http://YOUR_VPS_IP:5000/api
```

**Save and rebuild:**
```bash
npm run build
```

### 3.2 Access Hostinger File Manager

1. Login to Hostinger
2. Go to **Hosting** → **Your Plan**
3. Click **File Manager**
4. Navigate to `public_html/`

### 3.3 Clean public_html

1. Select all default files in `public_html/`
2. Delete them (backup if needed)

### 3.4 Upload Frontend Files

**Option A - File Manager:**
1. Click **Upload** button
2. Select all files from `frontend/build/` folder
3. Upload (may take 2-5 minutes)
4. Ensure `.htaccess` is uploaded

**Option B - FTP:**
1. Get FTP credentials from Hostinger
2. Use FileZilla to connect
3. Upload all files from `build/` to `public_html/`

### 3.5 Verify .htaccess

Make sure `.htaccess` exists in `public_html/` with this content:
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteCond %{REQUEST_FILENAME} !-l
  RewriteRule . /index.html [L]
</IfModule>
```

### 3.6 Test Frontend

1. Open browser
2. Go to: `http://yourdomain.com` or `http://your-hosting-ip`
3. Test pages:
   - `/` - Home
   - `/admin` - Admin login
   - `/promoter` - Promoter login
   - `/customer` - Customer login

✅ **Frontend Deployed!**

---

## 🔐 STEP 4: SETUP SSL (OPTIONAL - 5 minutes)

### For Frontend (Cloud Hosting):
1. Hostinger Panel → **SSL**
2. Click **Install SSL**
3. Choose **Free SSL** (Let's Encrypt)
4. Wait 5-10 minutes

### For Backend (VPS):
```bash
# On VPS
sudo apt install certbot python3-certbot-nginx -y

# If using domain for API
sudo certbot --nginx -d api.yourdomain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

---

## ✅ STEP 5: FINAL VERIFICATION

### Test Everything:

```bash
# 1. Backend Health
curl http://YOUR_VPS_IP:5000/api/health

# 2. Frontend loads
# Open: http://yourdomain.com

# 3. Login as Admin
# Go to: http://yourdomain.com/admin
# Use your admin credentials

# 4. Check PM2 Status
ssh root@YOUR_VPS_IP
pm2 status
pm2 logs brightplanet-backend --lines 20
```

### Check These Features:
- [ ] Admin login works
- [ ] Promoter login works
- [ ] Customer login works
- [ ] Create new promoter
- [ ] Create new customer
- [ ] Commission distribution
- [ ] PIN management
- [ ] Withdrawal requests

---

## 🔧 COMMON ISSUES & FIXES

### Backend Not Accessible:
```bash
# On VPS
pm2 restart brightplanet-backend
pm2 logs brightplanet-backend --lines 50

# Check if port is open
sudo netstat -tulpn | grep 5000
```

### Frontend Shows Blank Page:
1. Check browser console (F12)
2. Verify `.htaccess` is present
3. Clear browser cache
4. Check file permissions: `chmod -R 755 public_html`

### CORS Errors:
Update `backend/server.js`:
```javascript
app.use(cors({
  origin: ['http://yourdomain.com', 'https://yourdomain.com'],
  credentials: true
}));
```

Then restart:
```bash
pm2 restart brightplanet-backend
```

---

## 📊 MONITORING

### Check Backend Status:
```bash
# SSH into VPS
ssh root@YOUR_VPS_IP

# View logs
pm2 logs brightplanet-backend

# Monitor resources
pm2 monit

# System resources
htop
df -h  # disk space
free -h  # memory
```

### Setup External Monitoring:
1. Create account on [UptimeRobot](https://uptimerobot.com) (free)
2. Add monitor: `http://YOUR_VPS_IP:5000/api/health`
3. Get email alerts if backend goes down

---

## 🔄 UPDATE DEPLOYMENT

### Update Backend:
```bash
# SSH into VPS
ssh root@YOUR_VPS_IP
cd /var/www/brightplanet-backend

# Upload new files (via SCP or SFTP)
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

## 📝 IMPORTANT NOTES

### Save These URLs:
- **Frontend**: `http://yourdomain.com`
- **Backend API**: `http://YOUR_VPS_IP:5000/api`
- **Admin Panel**: `http://yourdomain.com/admin`
- **Promoter Panel**: `http://yourdomain.com/promoter`
- **Customer Panel**: `http://yourdomain.com/customer`

### Save These Commands:
```bash
# SSH to VPS
ssh root@YOUR_VPS_IP

# Check backend status
pm2 status

# View logs
pm2 logs brightplanet-backend

# Restart backend
pm2 restart brightplanet-backend

# Stop backend
pm2 stop brightplanet-backend
```

---

## 🎉 DEPLOYMENT COMPLETE!

Your BrightPlanet Ventures application is now live!

### Next Steps:
1. ✅ Test all features thoroughly
2. ✅ Setup SSL certificates
3. ✅ Configure domain DNS (if using custom domain)
4. ✅ Setup monitoring (UptimeRobot)
5. ✅ Create regular backups
6. ✅ Document admin credentials securely

### Need Help?
- Check logs: `pm2 logs brightplanet-backend`
- Review: `HOSTINGER-DEPLOYMENT-COMPLETE-GUIDE.md`
- Contact Hostinger support for hosting issues

---

**Deployment Date**: _________________
**Deployed By**: _________________
**Status**: ✅ Production Ready
