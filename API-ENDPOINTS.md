# Proyecto X Backend API - Endpoints

## Base URL
- **Local Development**: `http://localhost:8080`
- **Railway Production**: `https://your-railway-app.up.railway.app`

## Authentication Endpoints

### 1. Register User
```http
POST /api/users/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "confirmPassword": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+1234567890"
}
```

**Response 201:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+1234567890",
    "avatarURL": null,
    "membershipLevel": "silver",
    "points": 0,
    "memberSince": "2025-08-10T...",
    "emailVerified": false,
    "createdAt": "2025-08-10T..."
  },
  "token": "jwt_token_here"
}
```

### 2. Login User
```http
POST /api/users/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response 200:** Same as register response

## Protected Endpoints (Require Bearer Token)

### 3. Get Profile
```http
GET /api/users/profile
Authorization: Bearer jwt_token_here
```

### 4. Update Profile
```http
PUT /api/users/profile
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "firstName": "John Updated",
  "lastName": "Doe Updated",
  "phone": "+0987654321",
  "avatarURL": "https://example.com/avatar.jpg"
}
```

### 5. Change Password
```http
PUT /api/users/change-password
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "currentPassword": "password123",
  "newPassword": "newpassword123",
  "confirmPassword": "newpassword123"
}
```

### 6. Verify Email
```http
POST /api/users/verify-email
Authorization: Bearer jwt_token_here
```

### 7. Update Membership
```http
PUT /api/users/membership
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "membershipLevel": "gold"
}
```

### 8. Get Points
```http
GET /api/users/points
Authorization: Bearer jwt_token_here
```

### 9. Add Points
```http
POST /api/users/points/add
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "points": 100,
  "reason": "Purchase reward"
}
```

### 10. Delete Account
```http
DELETE /api/users/account
Authorization: Bearer jwt_token_here
```

## Health Check Endpoints

### Health Status
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2025-08-10T..."
}
```

## Testing with cURL

### Register a new user:
```bash
curl -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "confirmPassword": "password123",
    "firstName": "Test",
    "lastName": "User",
    "phone": "+1234567890"
  }'
```

### Login:
```bash
curl -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Get profile (replace TOKEN with actual JWT):
```bash
curl -X GET http://localhost:8080/api/users/profile \
  -H "Authorization: Bearer TOKEN"
```

## Error Responses

### 400 Bad Request
```json
{
  "error": true,
  "reason": "Validation error message"
}
```

### 401 Unauthorized
```json
{
  "error": true,
  "reason": "Email o contraseña incorrectos"
}
```

### 409 Conflict
```json
{
  "error": true,
  "reason": "Un usuario con este email ya existe"
}
```