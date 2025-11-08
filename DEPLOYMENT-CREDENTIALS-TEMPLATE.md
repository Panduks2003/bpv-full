# 🔐 DEPLOYMENT CREDENTIALS TEMPLATE
## BrightPlanet Ventures - Secure Information Storage

⚠️ **IMPORTANT**: Keep this file secure and never commit to public repositories!

---

## 📝 DEPLOYMENT INFORMATION

**Deployment Date**: _________________  
**Deployed By**: _________________  
**Last Updated**: _________________

---

## 🖥️ HOSTINGER VPS (BACKEND)

### VPS Access:
- **IP Address**: `___________________`
- **SSH Port**: `22`
- **SSH Username**: `root` or `___________________`
- **SSH Password**: `___________________`
- **SSH Key Path** (if using): `___________________`

### Backend Details:
- **Backend URL**: `http://YOUR_VPS_IP:5000/api`
- **Health Check**: `http://YOUR_VPS_IP:5000/api/health`
- **Installation Path**: `/var/www/brightplanet-backend`
- **PM2 Process Name**: `brightplanet-backend`
- **Node.js Version**: `18.x`
- **PM2 Version**: `___________________`

### SSH Connection Command:
```bash
ssh root@YOUR_VPS_IP
# or
ssh -i ~/.ssh/your_key root@YOUR_VPS_IP
```

---

## 🌐 HOSTINGER CLOUD HOSTING (FRONTEND)

### Hosting Access:
- **Hosting Panel URL**: `https://hpanel.hostinger.com`
- **Username/Email**: `___________________`
- **Password**: `___________________`

### FTP/SFTP Access:
- **FTP Host**: `ftp.yourdomain.com` or `___________________`
- **FTP Username**: `___________________`
- **FTP Password**: `___________________`
- **FTP Port**: `21` (FTP) or `22` (SFTP)

### Domain Details:
- **Primary Domain**: `___________________`
- **Frontend URL**: `http://yourdomain.com`
- **Admin Panel**: `http://yourdomain.com/admin`
- **Promoter Panel**: `http://yourdomain.com/promoter`
- **Customer Panel**: `http://yourdomain.com/customer`

### File Manager Path:
- **Root Directory**: `public_html/`
- **Installation Path**: `public_html/` (or subdirectory)

---

## 🗄️ SUPABASE (DATABASE)

### Supabase Project:
- **Project URL**: `https://ubokvxgxszhpzmjonuss.supabase.co`
- **Project Name**: `___________________`
- **Project ID**: `ubokvxgxszhpzmjonuss`
- **Region**: `___________________`

### Supabase Dashboard:
- **Dashboard URL**: `https://supabase.com/dashboard`
- **Email**: `___________________`
- **Password**: `___________________`

### API Keys:
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5NTE4MzEsImV4cCI6MjA3NDUyNzgzMX0.rkPYllqA2-oxPtWowjwosGiYzgMfwYQFSbCRZ3tTcA4`

- **Service Role Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk1MTgzMSwiZXhwIjoyMDc0NTI3ODMxfQ.S9YcbQqlgXMMFE-5gpd-NfrglVbBscBh72eYgCmVRSY`

### Database Connection:
- **Database Host**: `db.ubokvxgxszhpzmjonuss.supabase.co`
- **Database Name**: `postgres`
- **Database Port**: `5432`
- **Database User**: `postgres`
- **Database Password**: `___________________`

---

## 👤 APPLICATION ADMIN CREDENTIALS

### Super Admin:
- **Email**: `___________________`
- **Password**: `___________________`
- **Role**: `admin`
- **Promoter ID**: `___________________`

### Test Accounts (if any):
- **Test Admin**: `___________________`
- **Test Promoter**: `___________________`
- **Test Customer**: `___________________`

---

## 🔐 SSL CERTIFICATES

### Frontend SSL:
- **Provider**: Hostinger Free SSL (Let's Encrypt)
- **Status**: ☐ Not Installed / ☐ Installed
- **Expiry Date**: `___________________`
- **Auto-Renewal**: ☐ Enabled / ☐ Disabled

### Backend SSL (if using domain):
- **Provider**: Let's Encrypt (Certbot)
- **Domain**: `api.yourdomain.com` or `___________________`
- **Status**: ☐ Not Installed / ☐ Installed
- **Expiry Date**: `___________________`
- **Auto-Renewal**: ☐ Enabled / ☐ Disabled
- **Certificate Path**: `/etc/letsencrypt/live/api.yourdomain.com/`

---

## 📧 EMAIL CONFIGURATION (if applicable)

### Email Service:
- **Provider**: `___________________`
- **SMTP Host**: `___________________`
- **SMTP Port**: `___________________`
- **SMTP Username**: `___________________`
- **SMTP Password**: `___________________`
- **From Email**: `___________________`

---

## 🔔 MONITORING & ALERTS

### UptimeRobot (or similar):
- **Account Email**: `___________________`
- **Password**: `___________________`
- **Monitor URL**: `http://YOUR_VPS_IP:5000/api/health`
- **Alert Email**: `___________________`
- **Alert Phone** (if SMS): `___________________`

---

## 💳 PAYMENT GATEWAY (if applicable)

### Payment Provider:
- **Provider Name**: `___________________`
- **Merchant ID**: `___________________`
- **API Key**: `___________________`
- **API Secret**: `___________________`
- **Webhook URL**: `___________________`
- **Test Mode**: ☐ Enabled / ☐ Disabled

---

## 🔧 THIRD-PARTY SERVICES

### Service 1:
- **Service Name**: `___________________`
- **API Key**: `___________________`
- **API Secret**: `___________________`
- **Endpoint**: `___________________`

### Service 2:
- **Service Name**: `___________________`
- **API Key**: `___________________`
- **API Secret**: `___________________`
- **Endpoint**: `___________________`

---

## 📱 DOMAIN & DNS

### Domain Registrar:
- **Registrar**: `___________________`
- **Account Email**: `___________________`
- **Account Password**: `___________________`

### DNS Settings:
```
A Record:
  @ → YOUR_VPS_IP (for main domain)
  www → YOUR_VPS_IP (for www subdomain)
  api → YOUR_VPS_IP (for API subdomain)

CNAME Record:
  www → yourdomain.com

MX Record (if using email):
  @ → mail.yourdomain.com (Priority: 10)
```

---

## 🔄 BACKUP INFORMATION

### Backup Schedule:
- **Frequency**: Daily / Weekly / Monthly
- **Backup Location**: `___________________`
- **Backup Method**: Manual / Automated
- **Last Backup Date**: `___________________`

### Backup Access:
- **Backup Service**: `___________________`
- **Access Credentials**: `___________________`
- **Backup Retention**: `___________________` days

---

## 📞 SUPPORT CONTACTS

### Hostinger Support:
- **Support URL**: `https://www.hostinger.com/contact`
- **Live Chat**: Available 24/7
- **Email**: `support@hostinger.com`
- **Phone**: `___________________`

### Developer Contact:
- **Name**: `___________________`
- **Email**: `___________________`
- **Phone**: `___________________`
- **Available Hours**: `___________________`

### Emergency Contact:
- **Name**: `___________________`
- **Email**: `___________________`
- **Phone**: `___________________`

---

## 🔑 IMPORTANT COMMANDS

### SSH into VPS:
```bash
ssh root@YOUR_VPS_IP
```

### Check Backend Status:
```bash
pm2 status
pm2 logs brightplanet-backend
```

### Restart Backend:
```bash
pm2 restart brightplanet-backend
```

### View System Resources:
```bash
htop
df -h
free -h
```

---

## 📋 DEPLOYMENT CHECKLIST

- [ ] VPS access verified
- [ ] Cloud hosting access verified
- [ ] Supabase access verified
- [ ] Backend deployed and running
- [ ] Frontend deployed and accessible
- [ ] SSL certificates installed
- [ ] Domain DNS configured
- [ ] Monitoring setup complete
- [ ] Backup system configured
- [ ] All credentials documented
- [ ] Emergency contacts saved
- [ ] Team members notified

---

## 🚨 EMERGENCY PROCEDURES

### If Backend Goes Down:
1. SSH into VPS: `ssh root@YOUR_VPS_IP`
2. Check PM2 status: `pm2 status`
3. View logs: `pm2 logs brightplanet-backend --lines 50`
4. Restart: `pm2 restart brightplanet-backend`
5. If still down, check: `pm2 monit` for resource issues

### If Frontend Not Loading:
1. Check Hostinger File Manager
2. Verify files in `public_html/`
3. Check `.htaccess` is present
4. Clear browser cache
5. Check SSL certificate status

### If Database Connection Fails:
1. Check Supabase dashboard
2. Verify project is active
3. Check API keys in `.env`
4. Verify RLS policies
5. Check network connectivity

---

## 📝 NOTES

```
Add any additional notes, special configurations, or important information here:

_______________________________________________________________________________

_______________________________________________________________________________

_______________________________________________________________________________

_______________________________________________________________________________

_______________________________________________________________________________
```

---

## ⚠️ SECURITY REMINDERS

1. ✅ Never share this file publicly
2. ✅ Store in secure location (password manager recommended)
3. ✅ Use strong, unique passwords
4. ✅ Enable 2FA where available
5. ✅ Regularly update passwords
6. ✅ Review access logs periodically
7. ✅ Keep backup of this file offline
8. ✅ Encrypt sensitive files
9. ✅ Limit access to authorized personnel only
10. ✅ Update this file when credentials change

---

**Last Updated**: _________________  
**Updated By**: _________________  
**Next Review Date**: _________________
