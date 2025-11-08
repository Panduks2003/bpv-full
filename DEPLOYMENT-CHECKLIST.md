# ✅ HOSTINGER DEPLOYMENT CHECKLIST
## Quick Reference for brightplanetventures.com

---

## 📦 BUILD STATUS
- ✅ Frontend built successfully (`frontend/build/` folder created)
- ✅ Backend dependencies installed
- ✅ Deployment files created (.htaccess, ecosystem.config.js)
- ✅ Configuration files ready

---

## 🎯 YOUR NEXT STEPS

### STEP 1: Access Hostinger (5 minutes)
- [ ] Go to https://hpanel.hostinger.com
- [ ] Log in to your account
- [ ] Navigate to Cloud Hosting section

### STEP 2: Set Up Node.js Application (10 minutes)
- [ ] Go to **Advanced** → **Node.js**
- [ ] Click **Create Application**
- [ ] Configure:
  - Application Root: `/domains/brightplanetventures.com/backend`
  - Startup File: `server.js`
  - Node.js Version: 18.x or higher
  - Port: 5000

### STEP 3: Get SFTP Credentials (2 minutes)
- [ ] In hPanel, go to **Files** → **FTP Accounts**
- [ ] Note down:
  - Host: _________________
  - Username: _________________
  - Password: _________________
  - Port: 22 (SFTP)

### STEP 4: Upload Files via SFTP (15 minutes)
Using FileZilla or similar:

**Frontend Files:**
- [ ] Upload `frontend/build/*` → `/domains/brightplanetventures.com/public_html/`
- [ ] Upload `.htaccess` → `/domains/brightplanetventures.com/public_html/`

**Backend Files:**
- [ ] Upload `backend/*` → `/domains/brightplanetventures.com/backend/`
- [ ] Upload `ecosystem.config.js` → `/domains/brightplanetventures.com/`

### STEP 5: Configure Environment Variables (10 minutes)
In hPanel → Node.js → Environment Variables, add:

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
```

### STEP 6: SSH and Start Application (10 minutes)
- [ ] In hPanel, go to **Advanced** → **SSH Access**
- [ ] Enable SSH access
- [ ] Connect via terminal:
  ```bash
  ssh username@your-server-ip
  ```
- [ ] Install PM2:
  ```bash
  npm install -g pm2
  ```
- [ ] Navigate to app:
  ```bash
  cd /domains/brightplanetventures.com
  ```
- [ ] Start application:
  ```bash
  pm2 start ecosystem.config.js --env production
  pm2 save
  pm2 startup
  ```
- [ ] Check status:
  ```bash
  pm2 status
  pm2 logs brightplanet-backend
  ```

### STEP 7: Configure SSL (5 minutes)
- [ ] In hPanel, go to **Security** → **SSL**
- [ ] Select domain: `brightplanetventures.com`
- [ ] Install Let's Encrypt certificate
- [ ] Enable **Force HTTPS**
- [ ] Enable **Auto-Renew**

### STEP 8: Test Deployment (10 minutes)
- [ ] Visit: https://brightplanetventures.com
- [ ] Test API: https://brightplanetventures.com/api/health
- [ ] Login as admin
- [ ] Create test promoter
- [ ] Create test customer
- [ ] Verify commission system
- [ ] Check all major features

---

## 🔍 QUICK TROUBLESHOOTING

### If frontend doesn't load:
```bash
# Check if files are in public_html
ls -la /domains/brightplanetventures.com/public_html/
```

### If backend doesn't start:
```bash
# Check PM2 status
pm2 status
pm2 logs brightplanet-backend

# Restart if needed
pm2 restart brightplanet-backend
```

### If API returns errors:
```bash
# Check environment variables
pm2 env 0

# View detailed logs
pm2 logs brightplanet-backend --lines 50
```

---

## 📞 SUPPORT CONTACTS

- **Hostinger Support**: Via hPanel live chat
- **Hostinger Status**: https://www.hostinger.com/status
- **Supabase Status**: https://status.supabase.com

---

## 📚 DOCUMENTATION

Full detailed guide: `HOSTINGER-DEPLOYMENT-GUIDE.md`

---

## ✅ DEPLOYMENT COMPLETE WHEN:
- [ ] Frontend loads at https://brightplanetventures.com
- [ ] API responds at https://brightplanetventures.com/api/health
- [ ] SSL certificate shows padlock icon
- [ ] Admin login works
- [ ] Promoter creation works
- [ ] Customer creation works
- [ ] Commission distribution works
- [ ] All pages load without errors

---

**Estimated Total Time**: 60-90 minutes
**Difficulty**: Medium
**Prerequisites**: Hostinger account, domain configured

---

Good luck with your deployment! 🚀
