# Localboy B2C Platform - Complete Setup Guide

## 🎯 Overview

Localboy is a B2C platform connecting tourists with local guides and drivers for authentic travel experiences. This guide covers complete deployment setup.

### Architecture

```
┌─────────────────────────────────────────────────────┐
│  Frontend Layer                                     │
├─────────────────────────────────────────────────────┤
│  • localboy-frontend (Flutter - Tourist App)        │
│  • localboy-driver (Flutter - Driver/Guide App)     │
│  • localboy-admin (Web - Admin Dashboard)           │
├─────────────────────────────────────────────────────┤
│  API Layer                                          │
├─────────────────────────────────────────────────────┤
│  • localboy-api (NestJS REST API)                   │
├─────────────────────────────────────────────────────┤
│  Data & Services Layer                              │
├─────────────────────────────────────────────────────┤
│  • PostgreSQL (Database)                            │
│  • Twilio (SMS/OTP)                                 │
│  • Razorpay (Payments)                              │
│  • Google OAuth (Authentication)                    │
│  • Gemini AI (Recommendations)                      │
│  • OpenStreetMap (Maps/Geocoding)                   │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

### System Requirements
- **Node.js**: 20.x or later
- **Flutter**: 3.0 or later
- **Docker**: 20.x or later & Docker Compose
- **PostgreSQL**: 15+ (or use Docker)
- **Git**: Latest version

### Required Accounts
- [ ] Twilio (SMS service)
- [ ] Razorpay (Payment gateway)
- [ ] Google Cloud (OAuth & optional services)
- [ ] Gmail account (Email service)

### Optional APIs
- [ ] Gemini AI (for recommendations) - Free tier available
- [ ] Google Maps (replaced with OpenStreetMap - FREE)

---

## 🚀 Step 1: Environment Setup

### 1.1 Clone & Navigate
```bash
cd c:\Projects\localboy
```

### 1.2 Backend Environment Variables
```bash
cd localboy-backend/localboy-api

# Copy example to create .env with actual values
copy .env.example .env  # Windows
# or
cp .env.example .env     # Mac/Linux
```

Edit `.env` with your actual credentials:
```env
# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=localboy
DATABASE_PASSWORD=localboy123
DATABASE_NAME=localboy_mvp

# Server
PORT=3000
NODE_ENV=development

# JWT (Generate strong key: openssl rand -base64 32)
JWT_SECRET=your-strong-secret-key-here

# Twilio SMS (from https://www.twilio.com/console)
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_MESSAGING_SERVICE_SID=your_messaging_service_sid
TWILIO_PHONE_NUMBER=+1234567890

# Email (Gmail app password - not your actual password!)
EMAIL_USER=your_gmail@gmail.com
EMAIL_APP_PASS=your_16_char_app_password

# Razorpay TEST keys (switch to LIVE in production)
RAZORPAY_KEY_ID=rzp_test_XXXXXX
RAZORPAY_KEY_SECRET=your_razorpay_secret

# Google OAuth (optional)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Gemini AI (optional - free tier)
GEMINI_API_KEY=your_gemini_api_key

# CORS
CORS_ORIGIN=http://localhost:3000,http://localhost:3001,http://localhost:8100
```

---

## 🗄️ Step 2: Database Setup

### 2.1 Start PostgreSQL
```bash
cd localboy-backend

# Start PostgreSQL container
docker-compose up -d postgres

# Verify it's running
docker ps
```

### 2.2 Initialize Database
```bash
# Tables will auto-create when API starts
# See DATABASE_SETUP.md for details
```

---

## ⚙️ Step 3: Backend Setup

### 3.1 Install Dependencies
```bash
cd localboy-backend/localboy-api

npm install
```

### 3.2 Build & Start in Development
```bash
# Development mode (with hot reload)
npm run start:dev

# Or production build & start
npm run build
npm run start:prod
```

### 3.3 Verify API is Running
```bash
curl http://localhost:3000/api/health
```

Should return: `{ "status": "ok" }`

---

## 📱 Step 4: Flutter Apps Setup

### 4.1 Tourist App (Frontend)
```bash
cd ../../localboy-frontend

# Get dependencies (includes updated flutter_map)
flutter pub get

# Select device/emulator
flutter devices

# Run on device/emulator
flutter run -d <device_id>

# Or build for Android
flutter build apk --release
```

### 4.2 Driver App
```bash
cd ../localboy-driver

flutter pub get
flutter run -d <device_id>
```

### 📍 Maps Migration
Both Flutter apps have been updated to use **OpenStreetMap** (flutter_map) instead of Google Maps.

**Benefits:**
- ✅ FREE (no API costs)
- ✅ No API key required
- ✅ Open source

See [MAPS_MIGRATION_GUIDE.md](localboy-frontend/MAPS_MIGRATION_GUIDE.md) for code examples.

---

## 🌐 Step 5: Admin Dashboard Setup

### Current Status: ⚠️ INCOMPLETE
The admin frontend currently has only 3 files:
- `app.js`
- `index.html`
- `styles.css`

### 5.1 Complete the Admin Dashboard

**Option A: Use React (Recommended)**
```bash
cd localboy-admin

# Remove old files
rm -rf app.js styles.css

# Create React app
npx create-react-app . --template typescript

# Install admin dependencies
npm install axios react-router-dom @mui/material @emotion/react @emotion/styled

# Start dev server
npm start
```

**Option B: Use Vue 3**
```bash
npm create vite@latest . -- --template vue-ts
npm install
npm run dev
```

**Option C: Use Next.js (Best for full-stack)**
```bash
npx create-next-app@latest .
npm run dev
```

### 5.2 Key Admin Features Needed
- [ ] User management (tourists, drivers, guides)
- [ ] Trip/booking management
- [ ] Payment tracking
- [ ] Document verification
- [ ] Analytics dashboard
- [ ] Support/complaint handling

---

## 🐳 Step 6: Docker Production Build

### 6.1 Build Docker Image
```bash
cd localboy-backend

# Build API Docker image
docker build -t localboy-api:latest ./localboy-api

# Or use docker-compose to build both API and DB
docker-compose -f docker-compose.production.yml build
```

### 6.2 Run with Docker Compose
```bash
# Start all services
docker-compose -f docker-compose.production.yml up -d

# Check services
docker ps

# View logs
docker-compose logs -f api
docker-compose logs -f postgres
```

### 6.3 Verify Services
```bash
# API health check
curl http://localhost:3000/api/health

# DB connection
docker exec localboy-db-prod psql -U localboy -d localboy_mvp -c "SELECT 1"
```

---

## 🔐 Step 7: Secrets Management

### ⚠️ NEVER Commit `.env` Files!

For production deployments:

### Option 1: AWS Secrets Manager
```bash
# Store secrets
aws secretsmanager create-secret \
  --name localboy/production \
  --secret-string file://secrets.json

# Retrieve in app
const secret = await secretsManager.getSecretValue(...)
```

### Option 2: Kubernetes Secrets
```bash
kubectl create secret generic localboy-secrets \
  --from-env-file=.env.production
```

### Option 3: GitHub Actions Secrets
```yaml
# In GitHub Actions workflow
- name: Deploy to Production
  env:
    DATABASE_PASSWORD: ${{ secrets.DATABASE_PASSWORD }}
    JWT_SECRET: ${{ secrets.JWT_SECRET }}
```

---

## ✅ Pre-Production Checklist

- [ ] **Security**
  - [ ] All API endpoints protected with JWT
  - [ ] CORS properly restricted (not `*`)
  - [ ] Password hashing enabled
  - [ ] SQL injection prevention (TypeORM queries)
  - [ ] Rate limiting implemented
  
- [ ] **Configuration**
  - [ ] `NODE_ENV=production`
  - [ ] All required API keys configured
  - [ ] Database backups set up
  - [ ] Proper error logging
  
- [ ] **Testing**
  - [ ] Unit tests passing
  - [ ] E2E tests passing
  - [ ] Load testing completed
  - [ ] Security audit done
  
- [ ] **Deployment**
  - [ ] CI/CD pipeline ready
  - [ ] Monitoring & alerting set up
  - [ ] Health checks configured
  - [ ] Rollback plan documented

---

## 🚢 Step 8: Deployment Options

### Option 1: AWS (Recommended for B2C)
```bash
# 1. Push Docker image to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com
docker tag localboy-api:latest <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/localboy-api:latest
docker push <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/localboy-api:latest

# 2. Deploy to ECS or EKS
# ... ECS task definition or K8s manifest

# 3. RDS for managed PostgreSQL
# ... Create RDS instance
```

### Option 2: Heroku (Quick & simple)
```bash
heroku create localboy-api
heroku addons:create heroku-postgresql:standard-0
git push heroku main
```

### Option 3: DigitalOcean/Linode
```bash
# Deploy via Docker compose or K8s
docker-compose -f docker-compose.production.yml up -d
```

---

## 📊 Monitoring & Logging

### Logging
```bash
# Docker logs
docker logs -f localboy-api

# Application logs (configure in app)
tail -f logs/app.log
```

### Health Checks
```bash
# Add to .env
HEALTH_CHECK_INTERVAL=30s

# API endpoint
GET /api/health → { "status": "ok", "db": "connected", "timestamp": "..." }
```

---

## 🐛 Troubleshooting

### API won't start
```
Error: Connect ECONNREFUSED
```
→ Ensure PostgreSQL is running: `docker-compose up -d postgres`

### CORS Errors
```
Access to XMLHttpRequest blocked by CORS
```
→ Update `CORS_ORIGIN` in `.env` to include your frontend URL

### Database connection fails
```
Error: password authentication failed
```
→ Check `DATABASE_PASSWORD` in `.env`

### Docker container exits
```bash
# Check logs
docker logs <container_id>

# Rebuild with verbose output
docker-compose logs -f
```

---

## 📚 Additional Resources

- [Backend Setup](localboy-backend/README.md)
- [Database Guide](localboy-backend/DATABASE_SETUP.md)
- [Maps Migration](localboy-frontend/MAPS_MIGRATION_GUIDE.md)
- [NestJS Docs](https://docs.nestjs.com)
- [Flutter Docs](https://flutter.dev/docs)
- [TypeORM Migration Guide](https://typeorm.io/migrations)

---

## 🎬 Quick Start (Summary)

```bash
# 1. Environment
cd c:\Projects\localboy\localboy-backend\localboy-api
copy .env.example .env
# Edit .env with your values

# 2. Database
cd ..
docker-compose up -d postgres

# 3. API
cd localboy-api
npm install
npm run start:dev

# 4. Flutter Apps (in separate terminals)
cd ../../localboy-frontend
flutter pub get && flutter run

cd ../localboy-driver
flutter pub get && flutter run

# 5. Admin Dashboard (optional)
cd ../localboy-admin
# Set up React/Vue/Next.js and npm start
```

---

## 📞 Support

For issues:
1. Check logs: `docker logs -f <service>`
2. Review environment variables: `cat .env`
3. Verify services: `docker ps`
4. Check database: `psql -U localboy -d localboy_mvp`

---

**Last Updated:** May 3, 2026
**Status:** In Development → Production Ready
