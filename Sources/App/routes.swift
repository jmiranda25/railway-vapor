import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Proyecto X Backend API"])
    }

    app.get("hello") { req async -> String in
        "Hello, Proyecto X!"
    }
    
    // Health check endpoint
    app.get("health") { req async -> [String: String] in
        return [
            "status": "healthy",
            "version": "1.0.0",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }

    // Canary endpoint to verify deployment
    app.get("verify-deployment-aug10") { req async -> [String: String] in
        return [
            "deployment_verified": "true",
            "version": "2.0.0-canary",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }

    // Register route collections
    try app.register(collection: TodoController())
    try app.register(collection: UserController())
    try app.register(collection: EventController())
    try app.register(collection: StoreController())
    try app.register(collection: ProductController())
    try app.register(collection: AdminController())
}
