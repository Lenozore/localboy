# Docker & Production Deployment Guide

## 📦 Docker Setup

### Current Status
✅ Dockerfile created for API
✅ docker-compose.yml for development
✅ docker-compose.production.yml created

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│        Load Balancer / Reverse Proxy     │
│         (Nginx or AWS ALB)               │
└────────────────┬────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
┌───▼───────────┐    ┌───────▼──────────┐
│  API Container│    │  API Container   │
│   (NestJS)    │    │   (NestJS)       │
└───┬───────────┘    └────────┬─────────┘
    │                         │
    └────────────┬────────────┘
                 │
          ┌──────▼───────┐
          │  PostgreSQL  │
          │  (Database)  │
          └──────────────┘
```

---

## 🚀 Development Setup

### 1. Start Services Locally

```bash
cd localboy-backend

# Start with docker-compose (development mode)
docker-compose up -d

# Verify services
docker ps
```

Expected output:
```
CONTAINER ID   IMAGE                    STATUS
xxx            postgres:15-alpine       Up 2 minutes
```

### 2. Check Logs

```bash
docker-compose logs -f postgres
docker-compose logs -f api  # After we start API in container
```

### 3. Stop Services

```bash
docker-compose down

# Remove volumes too (clears database)
docker-compose down -v
```

---

## 🏭 Production Build

### Step 1: Build Docker Image

```bash
cd localboy-backend/localboy-api

# Build image
docker build -t localboy-api:1.0.0 .

# Or use docker-compose
cd ..
docker-compose -f docker-compose.production.yml build
```

### Step 2: Verify Image

```bash
docker images | grep localboy-api

# Test image locally
docker run -p 3000:3000 \
  -e DATABASE_HOST=postgres \
  -e DATABASE_USER=localboy \
  -e DATABASE_PASSWORD=prod_password \
  -e DATABASE_NAME=localboy_prod \
  -e NODE_ENV=production \
  localboy-api:1.0.0
```

### Step 3: Push to Registry

#### Option A: Docker Hub
```bash
docker login
docker tag localboy-api:1.0.0 your_dockerhub_username/localboy-api:1.0.0
docker push your_dockerhub_username/localboy-api:1.0.0
```

#### Option B: AWS ECR
```bash
# Create ECR repository
aws ecr create-repository --repository-name localboy-api

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Tag & push
docker tag localboy-api:1.0.0 ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/localboy-api:1.0.0
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/localboy-api:1.0.0
```

#### Option C: GitHub Container Registry
```bash
docker login ghcr.io
docker tag localboy-api:1.0.0 ghcr.io/your-org/localboy-api:1.0.0
docker push ghcr.io/your-org/localboy-api:1.0.0
```

---

## 🌐 Deployment Strategies

### Strategy 1: AWS (Recommended for B2C)

#### 1A. ECS (Elastic Container Service)

**Prerequisites:**
- AWS account
- RDS PostgreSQL (managed database)
- ECR repository

**Steps:**

1. Create RDS PostgreSQL:
```bash
aws rds create-db-instance \
  --db-instance-identifier localboy-prod \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password YourSecurePassword123!
```

2. Create ECS Task Definition:
```json
{
  "family": "localboy-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "localboy-api",
      "image": "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/localboy-api:1.0.0",
      "portMappings": [{"containerPort": 3000}],
      "environment": [
        {"name": "NODE_ENV", "value": "production"},
        {"name": "PORT", "value": "3000"},
        {"name": "DATABASE_HOST", "value": "localboy-prod.xxx.rds.amazonaws.com"},
        {"name": "DATABASE_USER", "value": "admin"}
      ],
      "secrets": [
        {
          "name": "DATABASE_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:localboy/db-password"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/localboy-api",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

3. Create ECS Service:
```bash
aws ecs create-service \
  --cluster localboy-cluster \
  --service-name localboy-api \
  --task-definition localboy-api:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
```

#### 1B. EKS (Kubernetes)

Create `k8s/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: localboy-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: localboy-api
  template:
    metadata:
      labels:
        app: localboy-api
    spec:
      containers:
      - name: api
        image: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/localboy-api:1.0.0
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_HOST
          value: "postgres-service"
        envFrom:
        - secretRef:
            name: localboy-secrets
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: localboy-api-service
spec:
  selector:
    app: localboy-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
```

Deploy:
```bash
kubectl apply -f k8s/deployment.yaml
```

### Strategy 2: Docker Compose on Single VPS

**Cost:** $5-20/month (small VPS)
**Best for:** MVP/small scale

```bash
# SSH into VPS
ssh user@your-vps-ip

# Clone repository
git clone https://github.com/your-org/localboy.git
cd localboy/localboy-backend

# Create .env.production
nano .env.production
# Add production variables

# Start services
docker-compose -f docker-compose.production.yml up -d

# View logs
docker-compose logs -f api
```

Enable auto-restart:
```bash
docker-compose -f docker-compose.production.yml up -d --restart-policy always
```

### Strategy 3: Heroku (Simplest)

```bash
# Install Heroku CLI
brew install heroku

# Login
heroku login

# Create app
heroku create localboy-api-prod

# Add PostgreSQL addon
heroku addons:create heroku-postgresql:standard-0

# Set environment variables
heroku config:set NODE_ENV=production
heroku config:set JWT_SECRET=$(openssl rand -base64 32)

# Deploy
git push heroku main

# View logs
heroku logs -t
```

### Strategy 4: DigitalOcean App Platform

1. Push code to GitHub
2. Link GitHub to DigitalOcean
3. Create new App
4. Select `Dockerfile` runtime
5. Configure PostgreSQL database
6. Deploy

---

## 🔐 Environment Variables (Production)

Create and secure `.env.production`:

```env
# Database (from RDS/Managed DB)
DATABASE_HOST=localboy-prod.xxx.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_USER=admin
DATABASE_PASSWORD=${DB_PASSWORD}  # Use secrets manager
DATABASE_NAME=localboy_prod

# Server
PORT=3000
NODE_ENV=production

# JWT (generate: openssl rand -base64 32)
JWT_SECRET=${JWT_SECRET}

# Twilio
TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID}
TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN}
TWILIO_MESSAGING_SERVICE_SID=${TWILIO_MESSAGING_SERVICE_SID}
TWILIO_PHONE_NUMBER=+1234567890

# Email
EMAIL_USER=${EMAIL_USER}
EMAIL_APP_PASS=${EMAIL_APP_PASS}

# Razorpay (USE LIVE KEYS)
RAZORPAY_KEY_ID=${RAZORPAY_KEY_ID_PROD}
RAZORPAY_KEY_SECRET=${RAZORPAY_KEY_SECRET_PROD}

# Google
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}

# Gemini
GEMINI_API_KEY=${GEMINI_API_KEY}

# CORS
CORS_ORIGIN=https://localboy.com,https://admin.localboy.com,https://app.localboy.com

# Logging
LOG_LEVEL=info
```

### Store Secrets Securely

**AWS Secrets Manager:**
```bash
aws secretsmanager create-secret \
  --name localboy/production \
  --secret-string '{
    "DATABASE_PASSWORD":"xxx",
    "JWT_SECRET":"xxx",
    "TWILIO_AUTH_TOKEN":"xxx"
  }'
```

**GitHub Secrets:**
1. Go to Settings → Secrets and variables → Actions
2. Add each secret individually
3. Use in workflow: `${{ secrets.JWT_SECRET }}`

---

## 📊 Monitoring & Logging

### CloudWatch (AWS)
```bash
# View logs
aws logs tail /ecs/localboy-api -f

# Create alarm
aws cloudwatch put-metric-alarm \
  --alarm-name localboy-api-cpu \
  --alarm-description "Alert if CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

### Local Logging
```bash
# Docker logs
docker-compose logs -f api

# Get specific timeframe
docker-compose logs --since 10m api
```

### Application Logging (NestJS)

Update `main.ts`:
```typescript
import { Logger } from '@nestjs/common';

const logger = new Logger('Bootstrap');

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  logger.log(`Server running on port ${port}`);
  
  // Catch unhandled exceptions
  process.on('unhandledRejection', (reason) => {
    logger.error('Unhandled Rejection:', reason);
  });
}
```

---

## 🔄 CI/CD Pipeline

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: |
          docker build -t localboy-api:${{ github.sha }} \
            localboy-backend/localboy-api
      
      - name: Push to ECR
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          aws ecr get-login-password | docker login --username AWS \
            --password-stdin ${{ secrets.AWS_ECR_PREFIX }}
          docker tag localboy-api:${{ github.sha }} \
            ${{ secrets.AWS_ECR_PREFIX }}/localboy-api:${{ github.sha }}
          docker push ${{ secrets.AWS_ECR_PREFIX }}/localboy-api:${{ github.sha }}
      
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster localboy-cluster \
            --service localboy-api \
            --force-new-deployment
```

---

## 🧪 Testing Before Production

### Load Testing
```bash
# Install k6
brew install k6

# Create load test
cat > load-test.js << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  vus: 50,
  duration: '5m',
  thresholds: {
    http_req_duration: ['p(99)<500'],
    http_req_failed: ['<5%'],
  },
};

export default function() {
  let res = http.get('https://api.localboy.com/api/health');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
EOF

k6 run load-test.js
```

### Smoke Tests
```bash
# Check API health
curl https://api.localboy.com/api/health

# Check database connection
curl https://api.localboy.com/api/admin/stats
```

---

## 🆘 Troubleshooting

### Container won't start
```bash
docker-compose logs api
# Check: database connection, env variables, port conflicts
```

### Database migration fails
```bash
# Check database connectivity
docker-compose exec postgres psql -U localboy -d localboy_prod -c "SELECT 1"
```

### Memory/CPU issues
```bash
# Increase resource limits in docker-compose.yml
docker-compose update --cpus="1.0" --memory="1024m" api
```

---

## 📋 Production Checklist

- [ ] Database backups configured
- [ ] SSL/TLS certificates installed
- [ ] CDN setup (images, static content)
- [ ] Rate limiting enabled
- [ ] CORS properly configured
- [ ] DDoS protection (CloudFlare/AWS Shield)
- [ ] Monitoring & alerting active
- [ ] Log aggregation (CloudWatch, DataDog)
- [ ] Auto-scaling policies set
- [ ] Disaster recovery plan documented
- [ ] Load testing passed
- [ ] Security audit completed

---

## 💰 Cost Estimation

### AWS (Small Scale)
- ECS Fargate: $15-30/month
- RDS PostgreSQL: $20-50/month
- Data transfer: $5-10/month
- **Total:** $40-90/month

### Heroku
- Dyno: $7/month (hobby) or $25+/month (standard)
- PostgreSQL: $9/month (hobby) or $50+/month (standard)
- **Total:** $16-75+/month

### DigitalOcean
- App Platform: $12/month
- Managed DB: $15/month
- **Total:** $27/month

### Self-hosted VPS
- VPS: $5-20/month
- Domain: $10-15/year
- **Total:** $5-20/month

---

**Status:** Ready for Production
**Last Updated:** May 3, 2026
