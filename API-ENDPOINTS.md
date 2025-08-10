# Proyecto X Backend API - Complete Endpoints

## Base URL
- **Local Development**: `http://localhost:8080`
- **Railway Production**: `https://your-railway-app.up.railway.app`

## 🔐 Authentication Endpoints

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

## 🎉 Event Endpoints

### Get All Events
```http
GET /api/events?limit=20&offset=0
```

### Get Event by ID
```http
GET /api/events/:eventID
```

### Search Events
```http
POST /api/events/search
Content-Type: application/json

{
  "category": "gastronomico",
  "location": "Madrid",
  "startDate": "2025-08-10T00:00:00Z",
  "endDate": "2025-08-17T00:00:00Z",
  "minPrice": 0,
  "maxPrice": 100,
  "limit": 10
}
```

### Get Events by Category
```http
GET /api/events/category/gastronomico?limit=20
```

### Get Featured Events
```http
GET /api/events/featured
```

### Get Upcoming Events
```http
GET /api/events/upcoming
```

### Create Event (Protected)
```http
POST /api/events
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "title": "Evento de Cocina",
  "description": "Aprende a cocinar platos deliciosos",
  "date": "2025-08-20T18:00:00Z",
  "time": "18:00",
  "duration": "2 horas",
  "location": "Centro Culinario Madrid",
  "address": "Calle Principal 123",
  "category": "gastronomico",
  "price": 25.0,
  "capacity": 30,
  "organizer": "Chef María"
}
```

### Update Event (Protected)
```http
PUT /api/events/:eventID
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "title": "Nuevo título del evento",
  "price": 30.0
}
```

### Purchase Ticket (Protected)
```http
POST /api/events/:eventID/purchase
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "quantity": 2
}
```

## 🏪 Store Endpoints

### Get All Stores
```http
GET /api/stores?limit=20&offset=0
```

### Get Store by ID
```http
GET /api/stores/:storeID
```

### Search Stores
```http
POST /api/stores/search
Content-Type: application/json

{
  "category": "pizza",
  "location": "Madrid",
  "isOpen": true,
  "minRating": 4.0,
  "priceRange": "$$",
  "latitude": 40.4168,
  "longitude": -3.7038,
  "radius": 5.0
}
```

### Get Stores by Category
```http
GET /api/stores/category/pizza?limit=20
```

### Get Nearby Stores
```http
GET /api/stores/nearby?latitude=40.4168&longitude=-3.7038&radius=5.0
```

### Get Featured Stores
```http
GET /api/stores/featured
```

### Get Store Products
```http
GET /api/stores/:storeID/products
```

### Create Store (Protected)
```http
POST /api/stores
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "name": "Pizzería Roma",
  "description": "Auténtica pizza italiana",
  "category": "pizza",
  "deliveryTime": "30-45 min",
  "address": "Calle Italia 456",
  "phone": "+34123456789",
  "isOpen": true,
  "latitude": 40.4168,
  "longitude": -3.7038,
  "priceRange": "$$"
}
```

### Rate Store (Protected)
```http
POST /api/stores/:storeID/rate
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "rating": 4.5,
  "review": "Excelente servicio y comida deliciosa"
}
```

## 🍕 Product Endpoints

### Get All Products
```http
GET /api/products?limit=20&offset=0
```

### Get Product by ID
```http
GET /api/products/:productID
```

### Search Products
```http
POST /api/products/search
Content-Type: application/json

{
  "category": "pizza",
  "storeID": "uuid-here",
  "minPrice": 10,
  "maxPrice": 25,
  "minRating": 4.0,
  "isVegan": true,
  "isGlutenFree": false,
  "query": "margherita",
  "sortBy": "rating"
}
```

### Filter Products
```http
POST /api/products/filter
Content-Type: application/json

{
  "dietary": {
    "isVegan": true,
    "isGlutenFree": false,
    "maxCalories": 500
  },
  "priceRange": {
    "min": 5,
    "max": 20
  },
  "features": {
    "minRating": 4.0,
    "maxPreparationTime": 30
  }
}
```

### Get Products by Category
```http
GET /api/products/category/pizza?limit=20
```

### Get Featured Products
```http
GET /api/products/featured
```

### Get Deals and Offers
```http
GET /api/products/deals
```

### Get Trending Products
```http
GET /api/products/trending
```

### Get Healthy Products
```http
GET /api/products/healthy
```

### Get Quick Products
```http
GET /api/products/quick
```

### Create Product (Protected)
```http
POST /api/products
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "storeID": "uuid-here",
  "name": "Pizza Margherita",
  "description": "Pizza clásica con tomate, mozzarella y albahaca",
  "category": "pizza",
  "basePrice": 12.50,
  "originalPrice": 15.00,
  "preparationTime": "20 min",
  "calories": 280,
  "isVegan": false,
  "isGlutenFree": false,
  "ingredients": ["tomate", "mozzarella", "albahaca", "masa"],
  "allergens": ["gluten", "lactosa"]
}
```

### Rate Product (Protected)
```http
POST /api/products/:productID/rate
Authorization: Bearer jwt_token_here
Content-Type: application/json

{
  "rating": 5.0,
  "review": "La mejor pizza que he probado"
}
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

### 404 Not Found
```json
{
  "error": true,
  "reason": "Recurso no encontrado"
}
```

### 409 Conflict
```json
{
  "error": true,
  "reason": "Un usuario con este email ya existe"
}
```

## Available Categories

### Event Categories
- `gastronomico`
- `bebidas`
- `educativo`
- `cultural`
- `networking`
- `entretenimiento`

### Food Categories
- `pizza`
- `sushi`
- `sandwich`
- `grocery`
- `healthy`
- `burger`
- `bebidas`
- `alimentos`
- `cocteles`
- `promociones`

### Price Ranges
- `$` (Budget)
- `$$` (Moderate)
- `$$$` (Expensive)
- `$$$$` (Luxury)

### Membership Levels
- `silver`
- `gold`
- `platinum`