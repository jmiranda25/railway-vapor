# Vapor Swift Web API Template

A production-ready Vapor web framework template for Railway deployment. This template includes a complete REST API with database integration, perfect for building modern web applications and APIs.

## ✨ Features

- **Swift 6.0** with Vapor 4 web framework
- **Postgres database** with Fluent ORM
- **Leaf templating** engine for server-side rendering
- **RESTful API** with Todo CRUD operations
- **Docker** containerization for consistent deployment
- **Production-ready** configuration with optimized builds

## 🚀 One-Click Deploy

Deploy this template to Railway with a single click:

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/JOQEiS?referralCode=mT7-6r)

## 🛠 Local Development

### Prerequisites

- Swift 6.0 or later
- Docker (optional, for containerized development)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/dangdennis/railway-vapor-template
cd railway
```

2. Run Postgres via docker compose
```bash
docker compose up
```

2. Build the project:
```bash
swift build
```

3. Run the server:
```bash
swift run
```

The server will start on `http://localhost:8080`

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/todos` | Get all todos |
| POST | `/todos` | Create a new todo |
| DELETE | `/todos/:id` | Delete a todo by ID |

### Example Usage

```bash
# Get all todos
curl http://localhost:8080/todos

# Create a new todo
curl -X POST http://localhost:8080/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Vapor"}'

# Delete a todo
curl -X DELETE http://localhost:8080/todos/YOUR_TODO_ID
```

## 🐳 Docker

Build and run with Docker:

```bash
docker build -t vapor-app .
docker run -p 8080:8080 vapor-app
```

## 🧪 Testing

Run the test suite:

```bash
swift test
```

## 📁 Project Structure

```
Sources/App/
├── Controllers/     # Route handlers
├── DTOs/           # Data transfer objects
├── Models/         # Database models
├── Migrations/     # Database migrations
├── configure.swift # App configuration
├── entrypoint.swift # App entry point
└── routes.swift    # Route definitions
```

## 🔧 Configuration

The app is configured for Railway deployment with:

- Environment-based configuration
- Production-optimized Docker builds
- Automatic database migrations

## 📚 Learn More

- [Vapor Documentation](https://docs.vapor.codes)
- [Railway Documentation](https://docs.railway.app)
- [Swift Package Manager](https://www.swift.org/documentation/package-manager/)

## 📄 License

This template is available as open source under the terms of the [MIT License](LICENSE).
