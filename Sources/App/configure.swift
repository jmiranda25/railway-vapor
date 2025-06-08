import NIOSSL
import Fluent
import FluentSQLiteDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Use absolute path for production, relative for development.
    // /app is the configured volume path in the Railway template.
    let dbPath = app.environment == .production ? "/app/db.sqlite" : "db.sqlite"
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file(dbPath)), as: .sqlite)

    app.migrations.add(CreateTodo())

    app.views.use(.leaf)

    try await app.autoMigrate()

    // register routes
    try routes(app)
}
