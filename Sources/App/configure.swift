import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
     // Configuración de DB - Railway Environment Variables
     let hostname = Environment.get("PGHOST") ?? "localhost"
     let port = Environment.get("PGPORT").flatMap(Int.init(_:)) ?? 5432
     let username = Environment.get("PGUSER") ?? "postgres"
     let password = Environment.get("POSTGRES_PASSWORD") ?? "admin123"
     let database = Environment.get("PGDATABASE") ?? "railway"

     let configuration = SQLPostgresConfiguration(
         hostname: hostname,
         port: port,
         username: username,
         password: password,
         database: database,
         tls: .disable // TLS configurado desde Railway environment
     )

     app.databases.use(.postgres(configuration: configuration), as: .psql,
 isDefault: true)

     // Migraciones - Orden importante: las tablas padre primero
     app.migrations.add(CreateUser())
     app.migrations.add(CreateStore())
     app.migrations.add(CreateProduct()) // Depende de Store (foreign key)
     app.migrations.add(CreateEvent())
     // Mantenemos las migraciones existentes
     app.migrations.add(CreateTodo())

     // Rutas
     try routes(app)
 }
