# Database Setup Guide

## Current Setup

The Localboy API uses **TypeORM** with **PostgreSQL** for database management.

### Database Configuration
- Database: PostgreSQL 15 (Alpine)
- Host: `localhost` (development) or `postgres` service (Docker)
- Port: `5432`
- User: `localboy`
- Database: `localboy_mvp`

## Local Development Setup

### 1. Start PostgreSQL Docker Container
```bash
cd localboy-backend
docker-compose up -d postgres
```

Verify PostgreSQL is running:
```bash
docker ps
```

### 2. Tables & Schema

TypeORM will automatically create tables from entity definitions when the app starts (due to `synchronize: true`).

Tables created:
- `users` - User accounts (tourists, drivers, guides, admins)
- `otp_verifications` - OTP verification records
- `driver_profiles` - Driver information
- `guide_profiles` - Guide information
- `documents` - KYC/verification documents
- `pois` - Points of Interest
- `trips` - Trip bookings
- `trip_stops` - Individual stops within a trip
- `payments` - Payment records
- `messages` - User messages/chat
- `complaints` - User complaints

### 3. Initialize Database

```bash
# Start the API server (it will auto-create tables)
cd localboy-api
npm install
npx nest start

# Or with Docker
docker-compose -f docker-compose.production.yml up -d
```

## Production Setup

### ⚠️ Important: Disable Auto-Sync in Production

For production, update `app.module.ts`:

```typescript
TypeOrmModule.forRoot({
  // ... other config ...
  synchronize: false,  // ← CHANGE THIS
  migrationsRun: true,
  migrations: ['dist/migrations/*.js'],
})
```

### Create Migrations (Optional but Recommended)

```bash
# Install CLI
npm install -g typeorm

# Create new migration
npx typeorm migration:create src/migrations/InitialSchema

# Auto-generate migration from entities
npx typeorm migration:generate src/migrations/CreateSchema -d src/data-source.ts

# Run migrations
npx typeorm migration:run -d src/data-source.ts

# Revert migration
npx typeorm migration:revert -d src/data-source.ts
```

## Database Backups

### Manual Backup
```bash
# Backup
pg_dump -h localhost -U localboy -d localboy_mvp > backup.sql

# Restore
psql -h localhost -U localboy -d localboy_mvp < backup.sql
```

### Docker Volume Backup
```bash
# The PostgreSQL data persists in the `postgres_data` Docker volume
docker volume inspect localboy_postgres_data
```

## Connection String

For external tools (DBeaver, pgAdmin, etc.):
```
postgresql://localboy:localboy123@localhost:5432/localboy_mvp
```

## Common Issues

### 1. Connection Refused
```
Error: connect ECONNREFUSED 127.0.0.1:5432
```
**Solution:** Ensure PostgreSQL container is running
```bash
docker-compose up -d postgres
```

### 2. Database Already Exists
```sql
-- Drop and recreate
DROP DATABASE localboy_mvp;
CREATE DATABASE localboy_mvp;
```

### 3. Permission Denied
Ensure user has correct permissions:
```sql
-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE localboy_mvp TO localboy;
```

## Environment Variables

```env
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=localboy
DATABASE_PASSWORD=your_secure_password
DATABASE_NAME=localboy_mvp
```

## Next Steps

1. Run the API server - tables will auto-create
2. Create seed data (users, POIs, etc.)
3. Test database connections
4. Set up backups for production
