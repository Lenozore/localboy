# Localboy API Documentation

## Base URL
- **Development:** `http://localhost:3000/api`
- **Production:** `https://api.localboy.com/api`

---

## 🔐 Authentication

All endpoints (except `/auth/register` and `/auth/login`) require JWT token in header:
```
Authorization: Bearer <your_jwt_token>
```

---

## 📋 API Endpoints

### Auth Module (`/auth`)

#### Register
```
POST /auth/register
Content-Type: application/json

{
  "phone": "+1234567890",
  "email": "user@example.com",
  "name": "John Doe",
  "role": "tourist"  // or "driver", "guide", "admin"
}

Response 201:
{
  "id": "uuid",
  "phone": "+1234567890",
  "email": "user@example.com",
  "name": "John Doe",
  "role": "tourist",
  "createdAt": "2026-05-03T00:00:00Z"
}
```

#### Send OTP (SMS)
```
POST /auth/send-otp
Content-Type: application/json

{
  "phone": "+1234567890"
}

Response 200:
{
  "message": "OTP sent to phone"
}
```

#### Verify OTP & Login
```
POST /auth/verify-otp
Content-Type: application/json

{
  "phone": "+1234567890",
  "otp": "123456"
}

Response 200:
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": { ... }
}
```

#### Google OAuth Login
```
POST /auth/google
Content-Type: application/json

{
  "idToken": "google_id_token"
}

Response 200:
{
  "accessToken": "...",
  "user": { ... }
}
```

#### Logout
```
POST /auth/logout
Authorization: Bearer <token>

Response 200:
{
  "message": "Logged out successfully"
}
```

---

### Points of Interest Module (`/pois`)

#### List All POIs
```
GET /pois?city=Goa&limit=20&offset=0&rating=4.5

Response 200:
{
  "data": [
    {
      "id": "uuid",
      "name": "Baga Beach",
      "description": "...",
      "city": "Goa",
      "latitude": 15.595,
      "longitude": 73.755,
      "rating": 4.8,
      "photos": ["url1", "url2"],
      "tags": ["beach", "swimming", "nightlife"]
    }
  ],
  "total": 150,
  "limit": 20,
  "offset": 0
}
```

#### Get POI Details
```
GET /pois/:id

Response 200:
{
  "id": "uuid",
  "name": "Baga Beach",
  "description": "...",
  "address": "...",
  "city": "Goa",
  "latitude": 15.595,
  "longitude": 73.755,
  "rating": 4.8,
  "reviewCount": 342,
  "photos": ["url1", "url2"],
  "tags": ["beach", "swimming"],
  "openingHours": "06:00-22:00",
  "entryFee": "free",
  "reviews": [
    {
      "userId": "uuid",
      "userName": "John",
      "rating": 5,
      "comment": "Amazing experience!",
      "date": "2026-05-01"
    }
  ]
}
```

#### Create POI (Admin only)
```
POST /pois
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "name": "New Beach",
  "description": "...",
  "city": "Goa",
  "latitude": 15.595,
  "longitude": 73.755,
  "tags": ["beach", "swimming"]
}

Response 201:
{
  "id": "uuid",
  "name": "New Beach",
  ...
}
```

#### Review POI
```
POST /pois/:id/reviews
Authorization: Bearer <token>
Content-Type: application/json

{
  "rating": 5,
  "comment": "Great place!"
}

Response 201:
{
  "id": "review_uuid",
  "rating": 5,
  "comment": "Great place!",
  "userId": "user_uuid",
  "date": "2026-05-03"
}
```

---

### Bookings Module (`/bookings`)

#### Create Booking
```
POST /bookings
Authorization: Bearer <token>
Content-Type: application/json

{
  "driverId": "uuid",
  "guideId": "uuid",
  "startPoint": {
    "latitude": 15.3,
    "longitude": 73.8
  },
  "endPoint": {
    "latitude": 15.5,
    "longitude": 73.9
  },
  "startTime": "2026-05-10T09:00:00Z",
  "endTime": "2026-05-10T18:00:00Z",
  "pois": ["poi_uuid_1", "poi_uuid_2"],
  "numberOfTourists": 3,
  "budget": 5000
}

Response 201:
{
  "id": "booking_uuid",
  "status": "pending",
  "driverId": "uuid",
  "guideId": "uuid",
  "totalAmount": 5000,
  "createdAt": "2026-05-03"
}
```

#### List My Bookings
```
GET /bookings?status=confirmed&limit=10
Authorization: Bearer <token>

Response 200:
{
  "data": [
    {
      "id": "booking_uuid",
      "status": "confirmed",
      "driverId": "uuid",
      "driverName": "John",
      "startTime": "2026-05-10T09:00:00Z",
      "totalAmount": 5000
    }
  ],
  "total": 3
}
```

#### Cancel Booking
```
DELETE /bookings/:id
Authorization: Bearer <token>

Response 200:
{
  "message": "Booking cancelled",
  "refundAmount": 5000
}
```

---

### Payments Module (`/payments`)

#### Create Payment Intent (Razorpay)
```
POST /payments/create-order
Authorization: Bearer <token>
Content-Type: application/json

{
  "bookingId": "booking_uuid",
  "amount": 5000
}

Response 201:
{
  "orderId": "order_uuid",
  "amount": 5000,
  "razorpayOrderId": "order_IDxxxx",
  "currency": "INR"
}
```

#### Verify Payment
```
POST /payments/verify
Authorization: Bearer <token>
Content-Type: application/json

{
  "orderId": "razorpay_order_id",
  "paymentId": "razorpay_payment_id",
  "signature": "razorpay_signature"
}

Response 200:
{
  "status": "success",
  "bookingId": "booking_uuid",
  "amount": 5000,
  "transactionId": "payment_uuid"
}
```

#### Get Payment History
```
GET /payments?bookingId=uuid&limit=20
Authorization: Bearer <token>

Response 200:
{
  "data": [
    {
      "id": "payment_uuid",
      "bookingId": "booking_uuid",
      "amount": 5000,
      "status": "completed",
      "paymentMethod": "razorpay",
      "date": "2026-05-03"
    }
  ]
}
```

---

### Trips Module (`/trips`)

#### Start Trip (Driver)
```
POST /trips/start
Authorization: Bearer <driver_token>
Content-Type: application/json

{
  "bookingId": "booking_uuid"
}

Response 201:
{
  "id": "trip_uuid",
  "status": "started",
  "bookingId": "booking_uuid",
  "startTime": "2026-05-10T09:05:00Z"
}
```

#### Update Trip Location (Real-time)
```
PATCH /trips/:id/location
Authorization: Bearer <driver_token>
Content-Type: application/json

{
  "latitude": 15.4,
  "longitude": 73.85
}

Response 200:
{
  "id": "trip_uuid",
  "currentLocation": {
    "latitude": 15.4,
    "longitude": 73.85
  }
}
```

#### Complete Trip-Stop
```
POST /trips/:id/complete-stop
Authorization: Bearer <driver_token>
Content-Type: application/json

{
  "stopId": "stop_uuid"
}

Response 200:
{
  "id": "trip_uuid",
  "completedStops": 2,
  "remainingStops": 1
}
```

#### End Trip
```
POST /trips/:id/end
Authorization: Bearer <driver_token>

Response 200:
{
  "id": "trip_uuid",
  "status": "completed",
  "endTime": "2026-05-10T18:00:00Z",
  "totalDistance": 45.5,
  "duration": "9 hours"
}
```

---

### Messages Module (`/messages`)

#### Send Message
```
POST /messages
Authorization: Bearer <token>
Content-Type: application/json

{
  "recipientId": "user_uuid",
  "tripId": "trip_uuid",
  "message": "On my way!"
}

Response 201:
{
  "id": "message_uuid",
  "senderId": "...",
  "recipientId": "...",
  "message": "On my way!",
  "timestamp": "2026-05-10T09:15:00Z",
  "read": false
}
```

#### Get Messages (with pagination)
```
GET /messages/trip/:tripId?limit=50
Authorization: Bearer <token>

Response 200:
{
  "data": [
    {
      "id": "message_uuid",
      "senderId": "...",
      "senderName": "John",
      "message": "On my way!",
      "timestamp": "2026-05-10T09:15:00Z",
      "read": true
    }
  ],
  "total": 15
}
```

#### Mark as Read
```
PATCH /messages/:id/read
Authorization: Bearer <token>

Response 200:
{
  "message": "Marked as read"
}
```

---

### Driver Profile Module (`/drivers`)

#### Get Driver Profile
```
GET /drivers/profile
Authorization: Bearer <driver_token>

Response 200:
{
  "id": "uuid",
  "userId": "uuid",
  "name": "John Doe",
  "rating": 4.8,
  "totalTrips": 45,
  "vehicleType": "sedan",
  "vehicleNumber": "KA-01-AB-1234",
  "vehicleModel": "Hyundai Creta 2022",
  "documents": [
    {
      "type": "license",
      "status": "approved"
    },
    {
      "type": "registration",
      "status": "approved"
    }
  ]
}
```

#### Update Driver Status (Available/Busy)
```
PATCH /drivers/status
Authorization: Bearer <driver_token>
Content-Type: application/json

{
  "isAvailable": true
}

Response 200:
{
  "status": "available",
  "lastUpdated": "2026-05-03T10:30:00Z"
}
```

#### Get Ratings & Reviews
```
GET /drivers/:id/reviews?limit=20
Authorization: Bearer <token>

Response 200:
{
  "data": [
    {
      "id": "review_uuid",
      "rating": 5,
      "comment": "Great driver!",
      "touristName": "Jane",
      "date": "2026-05-02"
    }
  ],
  "averageRating": 4.8,
  "totalReviews": 42
}
```

---

### Documents Module (`/documents`)

#### Upload Document
```
POST /documents
Authorization: Bearer <token>
Content-Type: multipart/form-data

{
  "docType": "aadhar",  // or "license", "registration", "insurance"
  "file": <file_binary>
}

Response 201:
{
  "id": "document_uuid",
  "docType": "aadhar",
  "status": "pending",
  "uploadedAt": "2026-05-03T10:30:00Z"
}
```

#### Get My Documents
```
GET /documents
Authorization: Bearer <token>

Response 200:
{
  "data": [
    {
      "id": "doc_uuid",
      "docType": "aadhar",
      "status": "approved",
      "uploadedAt": "2026-04-01",
      "reviewedAt": "2026-04-02",
      "fileUrl": "https://..."
    }
  ]
}
```

#### Download Document (Admin)
```
GET /documents/:id/download
Authorization: Bearer <admin_token>

Response: File binary
```

---

### Admin Module (`/admin`)

#### Get Platform Statistics
```
GET /admin/stats
Authorization: Bearer <admin_token>

Response 200:
{
  "totalUsers": 1250,
  "activeTrips": 12,
  "completedTrips": 3420,
  "totalRevenue": 125000,
  "averageRating": 4.7
}
```

#### List All Users
```
GET /admin/users?role=driver&status=verified&limit=50
Authorization: Bearer <admin_token>

Response 200:
{
  "data": [
    {
      "id": "uuid",
      "name": "John",
      "email": "john@email.com",
      "role": "driver",
      "status": "verified",
      "createdAt": "2026-01-01"
    }
  ],
  "total": 450
}
```

#### Verify Document 
```
PATCH /admin/documents/:id/verify
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "status": "approved",  // or "rejected"
  "notes": "Document verified"
}

Response 200:
{
  "id": "doc_uuid",
  "status": "approved",
  "reviewedAt": "2026-05-03T10:30:00Z"
}
```

---

## Error Responses

### 401 Unauthorized
```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "error": "Invalid token"
}
```

### 403 Forbidden
```json
{
  "statusCode": 403,
  "message": "Forbidden",
  "error": "Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "statusCode": 404,
  "message": "Not Found",
  "error": "Resource not found"
}
```

### 400 Bad Request
```json
{
  "statusCode": 400,
  "message": "Bad Request",
  "error": {
    "field": ["Field is required"],
    "email": ["Invalid email format"]
  }
}
```

### 500 Server Error
```json
{
  "statusCode": 500,
  "message": "Internal Server Error",
  "error": "Something went wrong"
}
```

---

## Rate Limiting

Currently configured per endpoint. Future: Add global rate limiting.

---

## Webhooks (Planned)

- Payment success/failure
- Trip status updates
- User verification status
- Support ticket updates

---

## Testing Endpoints

### Health Check (No auth required)
```
GET /api/health

Response 200:
{
  "status": "ok",
  "timestamp": "2026-05-03T10:30:00Z"
}
```

### Test Your Token
```
GET /api/profile
Authorization: Bearer <token>

Returns your user profile
```

---

**Last Updated:** May 3, 2026
**API Version:** 1.0.0
