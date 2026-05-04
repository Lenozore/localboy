# Admin Dashboard Setup

## Current Status: ⚠️ INCOMPLETE

The admin folder only contains 3 basic files. This guide helps you build a complete admin dashboard.

---

## 🎯 Recommended Approach: React + Material UI

### Step 1: Setup React Project

```bash
cd localboy-admin

# Remove old files
rm -f app.js styles.css

# Create React app with TypeScript
npx create-react-app . --template typescript

# OR use Vite (faster)
npm create vite@latest . -- --template react-ts
npm install
```

### Step 2: Install Dependencies

```bash
npm install \
  axios \
  react-router-dom \
  @mui/material @emotion/react @emotion/styled \
  @mui/icons-material \
  @mui/lab \
  recharts \
  date-fns
```

### Step 3: Project Structure

```
src/
├── components/
│   ├── Sidebar.tsx
│   ├── Header.tsx
│   └── ...
├── pages/
│   ├── Dashboard.tsx
│   ├── Users.tsx
│   ├── Trips.tsx
│   ├── Payments.tsx
│   ├── Documents.tsx
│   └── Support.tsx
├── services/
│   ├── api.ts
│   ├── auth.ts
│   └── ...
├── types/
│   └── index.ts
├── App.tsx
└── main.tsx
```

### Step 4: API Service (src/services/api.ts)

```typescript
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

// Add auth token to all requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
```

### Step 5: Main Dashboard Pages

#### Dashboard Overview (src/pages/Dashboard.tsx)

```typescript
import { useEffect, useState } from 'react';
import { Box, Grid, Paper, Typography } from '@mui/material';
import api from '../services/api';

export function Dashboard() {
  const [stats, setStats] = useState(null);

  useEffect(() => {
    api.get('/admin/stats').then((res) => setStats(res.data));
  }, []);

  if (!stats) return <Typography>Loading...</Typography>;

  return (
    <Box p={3}>
      <Grid container spacing={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Paper p={2}>
            <Typography color="textSecondary">Total Users</Typography>
            <Typography variant="h4">{stats.totalUsers}</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper p={2}>
            <Typography color="textSecondary">Active Trips</Typography>
            <Typography variant="h4">{stats.activeTrips}</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper p={2}>
            <Typography color="textSecondary">Completed Trips</Typography>
            <Typography variant="h4">{stats.completedTrips}</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper p={2}>
            <Typography color="textSecondary">Revenue</Typography>
            <Typography variant="h4">₹{stats.totalRevenue}</Typography>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
```

#### Users Management (src/pages/Users.tsx)

```typescript
import { useEffect, useState } from 'react';
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Button,
  Box,
} from '@mui/material';
import api from '../services/api';

export function Users() {
  const [users, setUsers] = useState([]);

  useEffect(() => {
    api.get('/admin/users?limit=100').then((res) => setUsers(res.data.data));
  }, []);

  return (
    <TableContainer component={Paper}>
      <Table>
        <TableHead>
          <TableRow sx={{ backgroundColor: '#f5f5f5' }}>
            <TableCell>Name</TableCell>
            <TableCell>Email</TableCell>
            <TableCell>Role</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {users.map((user) => (
            <TableRow key={user.id}>
              <TableCell>{user.name}</TableCell>
              <TableCell>{user.email}</TableCell>
              <TableCell>{user.role}</TableCell>
              <TableCell>{user.status}</TableCell>
              <TableCell>
                <Button size="small" variant="outlined">
                  View
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}
```

#### Document Verification (src/pages/Documents.tsx)

```typescript
import { useEffect, useState } from 'react';
import {
  Card,
  CardContent,
  Button,
  Box,
  Typography,
  Grid,
} from '@mui/material';
import api from '../services/api';

export function Documents() {
  const [documents, setDocuments] = useState([]);

  useEffect(() => {
    // Fetch pending documents for verification
    api.get('/admin/documents?status=pending').then((res) => 
      setDocuments(res.data.data)
    );
  }, []);

  const handleApprove = async (docId: string) => {
    await api.patch(`/admin/documents/${docId}/verify`, {
      status: 'approved',
    });
    // Refresh list
  };

  const handleReject = async (docId: string) => {
    await api.patch(`/admin/documents/${docId}/verify`, {
      status: 'rejected',
      notes: 'Document quality poor',
    });
  };

  return (
    <Grid container spacing={2}>
      {documents.map((doc) => (
        <Grid item xs={12} sm={6} md={4} key={doc.id}>
          <Card>
            <CardContent>
              <Typography variant="h6">{doc.docType}</Typography>
              <Typography color="textSecondary">{doc.userName}</Typography>
              <Box mt={2} display="flex" gap={1}>
                <Button
                  variant="contained"
                  color="success"
                  onClick={() => handleApprove(doc.id)}
                >
                  Approve
                </Button>
                <Button
                  variant="outlined"
                  color="error"
                  onClick={() => handleReject(doc.id)}
                >
                  Reject
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
}
```

### Step 6: Environment Variables (.env)

```
REACT_APP_API_URL=http://localhost:3000/api
REACT_APP_APP_NAME=Localboy Admin
```

### Step 7: Run Admin Dashboard

```bash
npm start
# Opens at http://localhost:3000
```

---

## Alternative Options

### Option B: Next.js (Full-Stack)
```bash
npx create-next-app@latest localboy-admin --typescript --tailwind
```
**Pros:** Better SEO, API routes, better performance
**Cons:** More complex setup

### Option C: Vue 3 + Vuetify
```bash
npm create vite@latest . -- --template vue-ts
npm install vuetify axios
```
**Pros:** Simpler templating, lightweight
**Cons:** Smaller ecosystem than React

---

## Key Admin Features to Implement

### 1. Dashboard
- [ ] KPIs (users, trips, revenue)
- [ ] Charts (revenue trends, trip volume)
- [ ] Recent activities
- [ ] Quick stats

### 2. User Management
- [ ] List all users
- [ ] Filter by role (tourist, driver, guide, admin)
- [ ] Search by name/email/phone
- [ ] Block/unblock users
- [ ] View user details

### 3. Document Verification
- [ ] Pending documents queue
- [ ] View document image
- [ ] Approve/reject with notes
- [ ] Track verification status
- [ ] Bulk operations

### 4. Trip Management
- [ ] View all trips (active/completed/cancelled)
- [ ] Trip details (route, passengers, driver, guide)
- [ ] Cancel trip if needed
- [ ] Refund management

### 5. Payment Management
- [ ] Transaction history
- [ ] Refund requests
- [ ] Revenue reports
- [ ] Payment reconciliation

### 6. Complaints/Support
- [ ] View complaints
- [ ] Assign to support agent
- [ ] Update status
- [ ] Send messages

### 7. Reports
- [ ] Revenue by date/period
- [ ] User acquisition
- [ ] Trip statistics
- [ ] Driver/guide performance

### 8. Settings
- [ ] Admin users management
- [ ] System configuration
- [ ] Email templates
- [ ] Feature flags

---

## Authentication

```typescript
// src/pages/Login.tsx
import { useState } from 'react';
import { Box, Button, TextField, Paper } from '@mui/material';
import api from '../services/api';

export function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleLogin = async () => {
    const res = await api.post('/auth/login', { email, password });
    localStorage.setItem('authToken', res.data.accessToken);
    window.location.href = '/dashboard';
  };

  return (
    <Box display="flex" justifyContent="center" alignItems="center" minHeight="100vh">
      <Paper p={3} sx={{ width: 400 }}>
        <TextField
          fullWidth
          label="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          mb={2}
        />
        <TextField
          fullWidth
          label="Password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          mb={2}
        />
        <Button fullWidth variant="contained" onClick={handleLogin}>
          Login
        </Button>
      </Paper>
    </Box>
  );
}
```

---

## Deployment

### Build
```bash
npm run build
# Creates /build directory
```

### Deploy to Vercel (Recommended)
```bash
npm install -g vercel
vercel
```

### Deploy to AWS S3 + CloudFront
```bash
aws s3 sync build/ s3://your-bucket-name --delete
```

### Deploy to Docker
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

---

## Quick Start (TL;DR)

```bash
cd localboy-admin

# Setup React
npx create-react-app . --template typescript

# Install deps
npm install axios react-router-dom @mui/material @emotion/react @emotion/styled

# Start dev server
npm start

# Build for production
npm run build
```

---

**Status:** Needs implementation
**Estimated Time:** 20-30 hours for full feature set
**Last Updated:** May 3, 2026
