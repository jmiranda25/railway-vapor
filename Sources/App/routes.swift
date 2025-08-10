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

    // Register route collections
    try app.register(collection: TodoController())
    try app.register(collection: UserController())
}
