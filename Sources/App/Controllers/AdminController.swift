//
//  AdminController.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Fluent
import Vapor
import SQLKit

// MARK: - Response DTOs
struct SeedResponse: Content {
    let success: Bool
    let message: String
    let counts: SeedCounts
    let seededBy: String
    let timestamp: String
}

struct SeedCounts: Content {
    let users: Int
    let stores: Int
    let products: Int
    let events: Int
}

struct DatabaseStats: Content {
    let totalRecords: Int
    let users: Int
    let stores: Int
    let products: Int
    let events: Int
    let todos: Int
    
    enum CodingKeys: String, CodingKey {
        case totalRecords = "total_records"
        case users, stores, products, events, todos
    }
}

struct UserDistribution: Content {
    let silver: Int
    let gold: Int
    let platinum: Int
}

struct StoreCategories: Content {
    let pizza: Int
    let sushi: Int
    let burger: Int
}

struct EventCategories: Content {
    let gastronomico: Int
    let bebidas: Int
    let educativo: Int
}

struct StatsResponse: Content {
    let databaseStats: DatabaseStats
    let userDistribution: UserDistribution
    let storeCategories: StoreCategories
    let eventCategories: EventCategories
    let checkedBy: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case databaseStats = "database_stats"
        case userDistribution = "user_distribution"
        case storeCategories = "store_categories"
        case eventCategories = "event_categories"
        case checkedBy = "checked_by"
        case timestamp
    }
}

struct BackupResponse: Content {
    let backupCreated: Bool
    let timestamp: String
    let stats: StatsResponse
    let note: String
    
    enum CodingKeys: String, CodingKey {
        case backupCreated = "backup_created"
        case timestamp, stats, note
    }
}

struct AdminController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let admin = routes.grouped("admin")
        
        // Protected admin routes
        let protected = admin.grouped(JWTAuthenticator())
        let authenticated = protected.grouped(User.guardMiddleware())
        
        // Admin endpoints
        authenticated.post("seed", use: seedDatabase)
        authenticated.post("seed", "clear", use: clearAndSeedDatabase)
        authenticated.get("stats", use: getDatabaseStats)
        authenticated.post("backup", use: createBackup)
    }
    
    @Sendable
    func seedDatabase(req: Request) async throws -> SeedResponse {
        let user = try req.auth.require(User.self)
        
        // Only allow platinum users to seed (admin function)
        guard user.membershipLevel == .platinum else {
            throw Abort(.forbidden, reason: "Solo usuarios Platinum pueden realizar seeding")
        }
        
        struct SeedRequest: Content {
            let users: Int?
            let stores: Int?
            let products: Int?
            let events: Int?
            let clear: Bool?
        }
        
        let seedReq = try req.content.decode(SeedRequest.self)
        
        if seedReq.clear == true {
            try await clearDatabase(req.db)
        }
        
        let userCount = try await seedUsers(req.db, count: seedReq.users ?? 15)
        let storeCount = try await seedStores(req.db, count: seedReq.stores ?? 20)
        let productCount = try await seedProducts(req.db, count: seedReq.products ?? 60)
        let eventCount = try await seedEvents(req.db, count: seedReq.events ?? 25)
        
        return SeedResponse(
            success: true,
            message: "Database seeded successfully",
            counts: SeedCounts(
                users: userCount,
                stores: storeCount,
                products: productCount,
                events: eventCount
            ),
            seededBy: user.email,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    @Sendable
    func clearAndSeedDatabase(req: Request) async throws -> SeedResponse {
        let user = try req.auth.require(User.self)
        
        guard user.membershipLevel == .platinum else {
            throw Abort(.forbidden, reason: "Solo usuarios Platinum pueden realizar seeding")
        }
        
        // Clear all data
        try await clearDatabase(req.db)
        
        // Seed with default amounts
        let userCount = try await seedUsers(req.db, count: 15)
        let storeCount = try await seedStores(req.db, count: 20) 
        let productCount = try await seedProducts(req.db, count: 60)
        let eventCount = try await seedEvents(req.db, count: 25)
        
        return SeedResponse(
            success: true,
            message: "Database cleared and seeded successfully",
            counts: SeedCounts(
                users: userCount,
                stores: storeCount,
                products: productCount,
                events: eventCount
            ),
            seededBy: user.email,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    @Sendable
    func getDatabaseStats(req: Request) async throws -> StatsResponse {
        let user = try req.auth.require(User.self)
        
        guard user.membershipLevel == .platinum else {
            throw Abort(.forbidden, reason: "Solo usuarios Platinum pueden ver estadísticas")
        }
        
        let userCount = try await User.query(on: req.db).count()
        let storeCount = try await Store.query(on: req.db).count()
        let productCount = try await Product.query(on: req.db).count()
        let eventCount = try await Event.query(on: req.db).count()
        let todoCount = try await Todo.query(on: req.db).count()
        
        // Get membership distribution
        let silverCount = try await User.query(on: req.db).filter(\.$membershipLevel == .silver).count()
        let goldCount = try await User.query(on: req.db).filter(\.$membershipLevel == .gold).count()
        let platinumCount = try await User.query(on: req.db).filter(\.$membershipLevel == .platinum).count()
        
        // Get category distribution for stores
        let pizzaStores = try await Store.query(on: req.db).filter(\.$category == .pizza).count()
        let sushiStores = try await Store.query(on: req.db).filter(\.$category == .sushi).count()
        let burgerStores = try await Store.query(on: req.db).filter(\.$category == .burger).count()
        
        // Get event categories
        let gastronomicEvents = try await Event.query(on: req.db).filter(\.$category == .gastronomico).count()
        let drinkEvents = try await Event.query(on: req.db).filter(\.$category == .bebidas).count()
        let educationalEvents = try await Event.query(on: req.db).filter(\.$category == .educativo).count()
        
        return StatsResponse(
            databaseStats: DatabaseStats(
                totalRecords: userCount + storeCount + productCount + eventCount + todoCount,
                users: userCount,
                stores: storeCount,
                products: productCount,
                events: eventCount,
                todos: todoCount
            ),
            userDistribution: UserDistribution(
                silver: silverCount,
                gold: goldCount,
                platinum: platinumCount
            ),
            storeCategories: StoreCategories(
                pizza: pizzaStores,
                sushi: sushiStores,
                burger: burgerStores
            ),
            eventCategories: EventCategories(
                gastronomico: gastronomicEvents,
                bebidas: drinkEvents,
                educativo: educationalEvents
            ),
            checkedBy: user.email,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    @Sendable
    func createBackup(req: Request) async throws -> BackupResponse {
        let user = try req.auth.require(User.self)
        
        guard user.membershipLevel == .platinum else {
            throw Abort(.forbidden, reason: "Solo usuarios Platinum pueden crear backups")
        }
        
        // This would typically export data to JSON or CSV
        // For now, just return a summary
        let stats = try await getDatabaseStats(req: req)
        
        return BackupResponse(
            backupCreated: true,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            stats: stats,
            note: "Backup functionality would export actual data in production"
        )
    }
    
    // MARK: - Helper Functions (copied from SeedCommand)
    
    private func clearDatabase(_ db: any Database) async throws {
        guard let sql = db as? any SQLDatabase else {
            throw Abort(.internalServerError, reason: "Database does not support raw SQL queries.")
        }

        // Borrar en orden inverso a la creación para respetar FKs
        try await sql.raw("DELETE FROM products").run()
        try await sql.raw("DELETE FROM events").run()
        try await sql.raw("DELETE FROM stores").run()
        try await sql.raw("DELETE FROM todos").run()
        // Borrar todos los usuarios excepto el admin para mantener el acceso
        try await sql.raw("DELETE FROM users WHERE email != 'admin@proyectox.com'").run()
    }
    
    private func seedUsers(_ db: any Database, count: Int) async throws -> Int {
        let sampleUsers = [
            ("admin@proyectox.com", "Admin", "Sistema", MembershipLevel.platinum, 5000),
            ("maria.garcia@email.com", "María", "García", MembershipLevel.gold, 1250),
            ("carlos.lopez@email.com", "Carlos", "López", MembershipLevel.silver, 340),
            ("ana.martinez@email.com", "Ana", "Martínez", MembershipLevel.gold, 890),
            ("david.rodriguez@email.com", "David", "Rodríguez", MembershipLevel.silver, 125),
            ("laura.fernandez@email.com", "Laura", "Fernández", MembershipLevel.platinum, 2100),
            ("miguel.gonzalez@email.com", "Miguel", "González", MembershipLevel.silver, 560),
            ("sofia.ruiz@email.com", "Sofía", "Ruiz", MembershipLevel.gold, 1780),
            ("antonio.jimenez@email.com", "Antonio", "Jiménez", MembershipLevel.silver, 89),
            ("carmen.moreno@email.com", "Carmen", "Moreno", MembershipLevel.gold, 945),
            ("francisco.alvarez@email.com", "Francisco", "Álvarez", MembershipLevel.silver, 234),
            ("isabel.romero@email.com", "Isabel", "Romero", MembershipLevel.platinum, 3200),
            ("jose.torres@email.com", "José", "Torres", MembershipLevel.silver, 67),
            ("pilar.ramos@email.com", "Pilar", "Ramos", MembershipLevel.gold, 1456),
            ("rafael.castro@email.com", "Rafael", "Castro", MembershipLevel.silver, 298)
        ]
        
        let phones = ["+34612345678", "+34687654321", "+34698765432", "+34665443322", "+34677889900", "+34634567890", "+34654321098", "+34678901234", "+34645678901", "+34656789012", "+34667890123", "+34689012345", "+34690123456", "+34601234567", "+34623456789"]
        
        var created = 0
        for (index, userData) in sampleUsers.prefix(min(count, sampleUsers.count)).enumerated() {
            // Check if user already exists
            let existingUser = try await User.query(on: db)
                .filter(\.$email == userData.0)
                .first()
            
            if existingUser == nil {
                let hashedPassword = try Bcrypt.hash("password123")
                
                let user = User()
                user.email = userData.0
                user.passwordHash = hashedPassword
                user.firstName = userData.1
                user.lastName = userData.2
                user.phone = phones[safe: index]
                user.membershipLevel = userData.3
                user.points = userData.4
                user.memberSince = Date().addingTimeInterval(-Double.random(in: 86400...31536000))
                user.emailVerified = Bool.random() && index > 2
                
                try await user.save(on: db)
                created += 1
            }
        }
        
        return created
    }
    
    private func seedStores(_ db: any Database, count: Int) async throws -> Int {
        // Using a smaller subset for web seeding
        let storeData: [(String, String, FoodCategory, String, String, String, Bool, Double, Double, PriceRange, [String], [String])] = [
            ("Pizzería Roma", "Auténtica pizza italiana con ingredientes frescos", .pizza, "25-35 min", "Calle Gran Vía 45, Madrid", "+34915551234", true, 40.4200, -3.7038, .moderate, ["Pizza Napoletana", "Pasta Fresca"], ["Terraza", "WiFi Gratis"]),
            ("Sushi Zen", "Experiencia culinaria japonesa auténtica", .sushi, "35-45 min", "Calle Serrano 123, Madrid", "+34915552345", true, 40.4250, -3.6900, .expensive, ["Sashimi Premium", "Rolls Especiales"], ["Barra de Sushi", "Sake Premium"]),
            ("Burger Station", "Las mejores hamburguesas gourmet", .burger, "20-30 min", "Plaza Mayor 8, Madrid", "+34915553456", true, 40.4156, -3.7073, .moderate, ["Angus Burger", "Crispy Chicken"], ["Terraza", "Música en Vivo"]),
            ("Healthy Corner", "Comida saludable y orgánica", .healthy, "15-25 min", "Calle Alcalá 200, Madrid", "+34915554567", true, 40.4300, -3.6800, .moderate, ["Bowls Detox", "Smoothies Verdes"], ["Productos Orgánicos", "Opciones Veganas"]),
            ("Mercado Gourmet", "Selección premium de productos gourmet", .grocery, "40-60 min", "Calle Fuencarral 78, Madrid", "+34915555678", true, 40.4280, -3.7020, .expensive, ["Quesos Artesanales", "Vinos Premium"], ["Productos Importados", "Maridajes"])
        ]
        
        var created = 0
        for (_, data) in storeData.prefix(min(count, storeData.count)).enumerated() {
            let store = Store()
            store.name = data.0
            store.description = data.1
            store.category = data.2
            store.deliveryTime = data.3
            store.address = data.4
            store.phone = data.5
            store.isOpen = data.6
            store.latitude = data.7
            store.longitude = data.8
            store.priceRange = data.9
            store.specialties = data.10
            store.features = data.11
            store.rating = Double.random(in: 3.8...4.9)
            store.reviewCount = Int.random(in: 12...456)
            
            try await store.save(on: db)
            created += 1
        }
        
        return created
    }
    
    private func seedProducts(_ db: any Database, count: Int) async throws -> Int {
        let stores = try await Store.query(on: db).all()
        guard !stores.isEmpty else {
            throw Abort(.internalServerError, reason: "No stores found")
        }
        
        var created = 0
        for store in stores {
            // Create 3-5 products per store
            let productsPerStore = min(5, count / stores.count + 1)
            
            for i in 0..<productsPerStore {
                let product = Product()
                product.$store.id = store.id!
                
                // Generate product based on store category
                switch store.category {
                case .pizza:
                    product.name = ["Pizza Margherita", "Pizza Quattro Stagioni", "Pizza Vegana", "Pizza Pepperoni"][i % 4]
                    product.description = "Deliciosa pizza italiana con ingredientes frescos"
                    product.basePrice = Double.random(in: 12.0...18.0)
                case .sushi:
                    product.name = ["Sashimi Salmón", "Dragon Roll", "California Roll", "Poke Bowl"][i % 4]
                    product.description = "Sushi fresco preparado por chef especializado"
                    product.basePrice = Double.random(in: 15.0...25.0)
                case .burger:
                    product.name = ["Angus Classic", "Chicken Crispy", "Vegan Deluxe", "Cheese Bacon"][i % 4]
                    product.description = "Hamburguesa gourmet con ingredientes premium"
                    product.basePrice = Double.random(in: 11.0...16.0)
                case .healthy:
                    product.name = ["Buddha Bowl", "Smoothie Verde", "Ensalada Quinoa", "Wrap Vegano"][i % 4]
                    product.description = "Opción saludable con ingredientes orgánicos"
                    product.basePrice = Double.random(in: 8.0...14.0)
                default:
                    product.name = "Producto \(store.category.rawValue.capitalized) \(i+1)"
                    product.description = "Producto de calidad de \(store.name)"
                    product.basePrice = Double.random(in: 5.0...20.0)
                }
                
                product.category = store.category
                product.preparationTime = "\(Int.random(in: 10...30)) min"
                product.rating = Double.random(in: 3.5...4.8)
                product.reviewCount = Int.random(in: 5...100)
                product.isAvailable = Double.random(in: 0...1) > 0.1
                product.stockQuantity = product.isAvailable ? Int.random(in: 5...50) : 0
                product.isVegan = Bool.random() && Double.random(in: 0...1) > 0.8
                product.isGlutenFree = Bool.random() && Double.random(in: 0...1) > 0.9
                product.isOrganic = Bool.random() && Double.random(in: 0...1) > 0.7
                product.ingredients = ["Ingrediente 1", "Ingrediente 2", "Ingrediente 3"]
                product.allergens = ["Gluten"]
                product.tags = ["Popular", "Recomendado"]
                
                try await product.save(on: db)
                created += 1
                
                if created >= count { break }
            }
            
            if created >= count { break }
        }
        
        return created
    }
    
    private func seedEvents(_ db: any Database, count: Int) async throws -> Int {
        let eventData: [(String, String, EventCategory, Double, Int, String)] = [
            ("Taller de Cocina Italiana", "Aprende a cocinar pasta fresca y salsas tradicionales", .gastronomico, 35.0, 20, "Chef Marco"),
            ("Cata de Vinos Rioja", "Degustación de 6 vinos de la D.O. Rioja", .bebidas, 45.0, 15, "Sommelier Ana"),
            ("Masterclass Sushi", "Curso intensivo de preparación de sushi", .gastronomico, 60.0, 12, "Chef Hiroshi"),
            ("Festival de Cócteles", "Noche de cócteles con bartenders expertos", .bebidas, 25.0, 50, "Bartenders Madrid"),
            ("Curso Repostería Francesa", "Técnicas clásicas de repostería", .gastronomico, 50.0, 16, "Chef Marie")
        ]
        
        var created = 0
        for (index, data) in eventData.prefix(min(count, eventData.count)).enumerated() {
            let event = Event()
            event.title = data.0
            event.description = data.1
            event.category = data.2
            event.price = data.3
            event.capacity = data.4
            event.organizer = data.5
            
            // Random future date
            let randomDays = Double.random(in: 1...90)
            event.date = Date().addingTimeInterval(randomDays * 86400)
            event.time = ["18:00", "19:30", "20:00"][index % 3]
            event.duration = "2 horas"
            event.location = "Centro Cultural Madrid"
            event.address = "Calle Principal \(index + 1), Madrid"
            event.availableTickets = Int.random(in: max(1, event.capacity - 10)...event.capacity)
            event.isSponsored = index == 0
            event.requirements = []
            event.includes = ["Material incluido", "Certificado"]
            event.tags = ["Popular", "Recomendado"]
            
            try await event.save(on: db)
            created += 1
        }
        
        return created
    }
}

