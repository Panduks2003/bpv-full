# 🚀 BrightPlanet Ventures - Permanent Setup Guide

This guide provides a **permanent solution** for setting up the complete BrightPlanet Ventures system with all features working properly.

## 📋 **What This Setup Includes**

✅ **Complete Backend Service** (Port 5001)
✅ **Triple Port Frontend** (Ports 3000, 3001, 3002)  
✅ **Commission Distribution System**
✅ **Promoter Creation** (Admin & Promoter accounts)
✅ **Customer Creation** with PIN system
✅ **Authentication System**
✅ **Database Functions**

---

## 🎯 **One-Time Setup (Permanent)**

### **Step 1: Automatic System Setup**

Run the complete setup script:

```bash
chmod +x setup-complete-system.sh
./setup-complete-system.sh
```

This will:
- Install all dependencies
- Start backend service (port 5001)
- Start frontend on triple ports (3000, 3001, 3002)
- Prepare database deployment files

### **Step 2: Deploy Database Functions (Required)**

**⚠️ This step is REQUIRED for commission distribution to work:**

1. **Go to your Supabase project dashboard**
2. **Navigate to SQL Editor**
3. **Copy the entire contents of:** `deploy-commission-system-permanent.sql`
4. **Paste and execute the SQL script**

**This creates:**
- `affiliate_commissions` table
- `promoter_wallet` table  
- `admin_wallet` table
- `distribute_affiliate_commission()` function
- All necessary indexes and permissions

---

## 🌐 **Access URLs**

| Service | URL | Purpose |
|---------|-----|---------|
| **Admin Panel** | http://localhost:3000 | Admin management |
| **Promoter Panel** | http://localhost:3001 | Promoter operations |
| **Customer Panel** | http://localhost:3002 | Customer interface |
| **Backend API** | http://localhost:5001 | Backend services |

---

## 🔑 **Login Credentials**

### **Admin Account**
- **Email:** `admin@brightplanet.com`
- **Password:** `admin123`

### **Promoter Account**  
- **Email:** `promoter@brightplanet.com`
- **Password:** `promoter123`

### **Customer Account**
- **Email:** `customer@brightplanet.com`
- **Password:** `customer123`

---

## ✅ **Features & Functionality**

### **1. Promoter Creation**
- **From Admin Panel:** Create promoters with full management
- **From Promoter Panel:** Create sub-promoters in hierarchy
- **Authentication:** Uses backend service (no auth interference)
- **Database:** Proper WHERE clauses, no SQL errors

### **2. Customer Creation**
- **PIN System:** Deducts pins from promoter balance
- **Commission Distribution:** Automatic ₹800 distribution across 4 levels
- **Error Handling:** Customer creation succeeds even if commission fails
- **Wallet Updates:** Automatic promoter wallet management

### **3. Commission System**
- **Level 1:** ₹500 (Direct promoter)
- **Level 2-4:** ₹100 each (Upline promoters)
- **Admin Fallback:** Unclaimed commissions go to admin
- **Transaction Tracking:** Complete audit trail
- **Wallet Management:** Real-time balance updates

### **4. Authentication**
- **Multi-Role System:** Admin, Promoter, Customer
- **Session Management:** Proper isolation between roles
- **No Redirections:** Auth context protected during operations
- **Backend Auth:** Service role key for admin operations

---

## 🔧 **System Architecture**

### **Backend Service (Port 5001)**
- **Express.js** server with Supabase integration
- **Service Role Key** for admin operations
- **Auth Creation Endpoint:** `/api/create-promoter-auth`
- **Health Check:** `/api/health`

### **Frontend (Triple Ports)**
- **Port 3000:** Admin interface
- **Port 3001:** Promoter interface  
- **Port 3002:** Customer interface
- **React.js** with Tailwind CSS
- **Unified Components** for consistency

### **Database (Supabase)**
- **PostgreSQL** with custom functions
- **RLS Policies** for security
- **Commission Tables** for tracking
- **Wallet System** for balance management

---

## 🛠️ **Troubleshooting**

### **Backend Not Starting**
```bash
# Kill existing processes
pkill -f "PORT=5001"

# Restart backend
cd backend && PORT=5001 npm start
```

### **Frontend Issues**
```bash
# Kill existing processes
pkill -f "PORT=300[0-2]"

# Restart triple ports
./start-triple-ports.sh
```

### **Commission Not Working**
1. **Check database deployment:** Run `deploy-commission-system-permanent.sql`
2. **Verify function exists:** Check Supabase dashboard
3. **Check backend logs:** Look for commission errors

### **Promoter Creation Fails**
1. **Check backend service:** http://localhost:5001/api/health
2. **Verify database functions:** Run database fix scripts
3. **Check auth context:** Ensure no session conflicts

---

## 📁 **Important Files**

| File | Purpose |
|------|---------|
| `setup-complete-system.sh` | Complete system setup script |
| `deploy-commission-system-permanent.sql` | Database functions deployment |
| `start-triple-ports.sh` | Frontend triple port startup |
| `backend/server.js` | Backend service with all endpoints |
| `fix-commission-system-now.js` | Browser-based commission fix |

---

## 🚀 **Daily Usage**

### **Starting the System**
```bash
./setup-complete-system.sh
```

### **Stopping the System**
```bash
# Press Ctrl+C in the setup script terminal
# OR manually kill processes:
pkill -f "PORT=300[0-2]" && pkill -f "PORT=5001"
```

### **Testing Features**
1. **Create Promoter:** Admin panel → Promoters → Create
2. **Create Customer:** Promoter panel → Create Customer
3. **Check Commission:** Verify wallet updates
4. **Multi-Role Testing:** Use different ports simultaneously

---

## 🎉 **Success Indicators**

When everything is working correctly, you should see:

✅ **Backend:** Health check returns `{"status":"ok"}`
✅ **Frontend:** All three ports accessible
✅ **Promoter Creation:** Success message with Promoter ID
✅ **Customer Creation:** Success with commission distribution
✅ **No Errors:** Clean console logs
✅ **Auth Context:** No unwanted redirections

---

## 📞 **Support**

If you encounter issues:

1. **Check the console logs** for specific error messages
2. **Verify database deployment** using the SQL file
3. **Restart services** using the setup script
4. **Check Supabase dashboard** for function existence

**This setup provides a permanent, production-ready solution for the BrightPlanet Ventures system!** 🎯
