# BrightPlanet Ventures - Web Application

A full-stack web application with React frontend and Express backend, powered by Supabase.

## 🚀 Quick Start

### Local Development

#### 1. Install Backend Dependencies
```bash
cd backend
npm install
```

#### 2. Configure Backend
Edit `backend/.env` with your Supabase Service Role Key:
```
SUPABASE_SERVICE_ROLE_KEY=your_actual_key_here
```

#### 3. Start Both Services
```bash
# Terminal 1 - Backend
cd backend
npm run dev

# Terminal 2 - Frontend
cd frontend
npm start
```

- Frontend: http://localhost:3000
- Backend: http://localhost:5000

---

## 📦 Project Structure

```
BRIGHTPLANET VENTURES/
├── frontend/              # React application
│   ├── src/
│   ├── public/
│   ├── build/            # Production build
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── vercel.json
│   └── netlify.toml
│
├── backend/              # Express API server
│   ├── server.js
│   ├── package.json
│   ├── .env
│   └── Dockerfile
│
├── database/             # SQL scripts
│
├── docker-compose.yml    # Full stack deployment
├── .env.example         # Environment template
└── DEPLOYMENT-GUIDE.md  # Complete hosting guide
```

---

## 🌐 Deployment

See **[DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)** for complete instructions.

### Quick Deploy Options:

#### Docker (Full Stack)
```bash
docker-compose up -d --build
```

#### Vercel (Frontend)
```bash
cd frontend
vercel --prod
```

#### Railway (Full Stack)
```bash
# Backend
cd backend && railway up

# Frontend
cd frontend && railway up
```

#### Netlify (Frontend)
```bash
cd frontend
netlify deploy --prod
```

---

## 🔑 Environment Variables

### Get Supabase Keys:
1. Go to https://supabase.com/dashboard
2. Select your project
3. Settings → API
4. Copy **service_role** key (keep secret!)

### Update Files:
- `backend/.env` - Add service_role key
- `frontend/.env` - Already configured

---

## 📋 Features

- ✅ React frontend with Tailwind CSS
- ✅ Express backend API
- ✅ Supabase database integration
- ✅ Multi-role system (Admin, Promoter, Customer)
- ✅ Authentication & authorization
- ✅ Docker ready
- ✅ Production deployment configs

---

## 🛠️ Tech Stack

**Frontend:**
- React 18
- React Router
- Tailwind CSS
- Supabase Client
- Recharts

**Backend:**
- Node.js
- Express
- Supabase
- CORS

**Database:**
- Supabase (PostgreSQL)

**DevOps:**
- Docker
- Docker Compose
- Nginx

---

## 📝 Available Scripts

### Frontend
```bash
npm start          # Development server
npm run build      # Production build
npm run serve      # Serve production build
npm test           # Run tests
```

### Backend
```bash
npm start          # Production server
npm run dev        # Development with nodemon
```

---

## 🐛 Troubleshooting

**Backend won't start?**
- Check PORT 5000 availability
- Verify Supabase credentials

**Frontend can't connect?**
- Update `REACT_APP_API_URL` in `.env`
- Check backend is running

**Build errors?**
```bash
rm -rf node_modules
npm install
```

---

## 📚 Documentation

- [Complete Deployment Guide](./DEPLOYMENT-GUIDE.md)
- [Supabase Documentation](https://supabase.com/docs)
- [React Documentation](https://react.dev)
- [Express Documentation](https://expressjs.com)

---

## 🎯 Recommended Hosting

**Best for Production:**
- **Frontend:** Vercel or Netlify (Free tier available)
- **Backend:** Railway or Render (Free tier available)
- **Database:** Supabase (Already set up)

**Cost:** $0-15/month for small to medium traffic

---

## 📞 Support

For deployment help, see troubleshooting section in [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)

---

## ✅ Next Steps

1. [ ] Install backend dependencies
2. [ ] Add Supabase Service Role Key
3. [ ] Test locally
4. [ ] Choose deployment platform
5. [ ] Deploy!

**Ready to deploy? Check [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)! 🚀**
