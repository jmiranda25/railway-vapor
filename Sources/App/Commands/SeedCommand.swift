//
//  SeedCommand.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Vapor
import Fluent

struct SeedCommand: Command {
    struct Signature: CommandSignature {
        @Flag(name: "clear", short: "c", help: "Clear existing data before seeding")
        var clear: Bool
        
        @Option(name: "count", short: "n", help: "Number of items to create (default varies by type)")
        var count: Int?
    }
    
    var help: String {
        "Seeds the database with sample data for development and testing"
    }
    
    func run(using context: CommandContext, signature: Signature) throws {
        let app = context.application
        
        context.console.info("🌱 Starting database seeding...")
        
        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        
        Task {
            do {
                if signature.clear {
                    context.console.info("🧹 Clearing existing data...")
                    try await clearDatabase(app)
                }
                
                context.console.info("👥 Seeding users...")
                try await seedUsers(app, count: signature.count ?? 15)
                
                context.console.info("🏪 Seeding stores...")
                try await seedStores(app, count: signature.count ?? 20)
                
                context.console.info("🍕 Seeding products...")
                try await seedProducts(app, count: signature.count ?? 60)
                
                context.console.info("🎉 Seeding events...")
                try await seedEvents(app, count: signature.count ?? 25)
                
                context.console.success("✅ Database seeding completed!")
                context.console.info("🚀 You can now test your API endpoints with realistic data")
                
                promise.succeed(())
            } catch {
                context.console.error("❌ Seeding failed: \(error)")
                promise.fail(error)
            }
        }
        
        try promise.futureResult.wait()
    }
    
    // MARK: - Clear Database
    
    private func clearDatabase(_ app: Application) async throws {
        try await Product.query(on: app.db).delete()
        try await Event.query(on: app.db).delete()
        try await Store.query(on: app.db).delete()
        try await User.query(on: app.db).delete()
        try await Todo.query(on: app.db).delete()
    }
    
    // MARK: - Seed Users
    
    private func seedUsers(_ app: Application, count: Int) async throws {
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
        
        for (index, userData) in sampleUsers.prefix(min(count, sampleUsers.count)).enumerated() {
            let hashedPassword = try Bcrypt.hash("password123")
            
            let user = User()
            user.email = userData.0
            user.passwordHash = hashedPassword
            user.firstName = userData.1
            user.lastName = userData.2
            user.phone = phones[safe: index]
            user.membershipLevel = userData.3
            user.points = userData.4
            user.memberSince = Date().addingTimeInterval(-Double.random(in: 86400...31536000)) // Random date in last year
            user.emailVerified = Bool.random() && index > 2 // Admin and first users verified
            
            try await user.save(on: app.db)
        }
    }
    
    // MARK: - Seed Stores
    
    private func seedStores(_ app: Application, count: Int) async throws {
        let storeData: [(String, String, FoodCategory, String, String, String, Bool, Double, Double, PriceRange, [String], [String], String?)] = [
            // Name, Description, Category, DeliveryTime, Address, Phone, IsOpen, Lat, Lng, PriceRange, Specialties, Features, ImageName
            ("Pizzería Roma", "Auténtica pizza italiana con ingredientes frescos importados directamente de Italia", .pizza, "25-35 min", "Calle Gran Vía 45, Madrid", "+34915551234", true, 40.4200, -3.7038, .moderate, ["Pizza Napoletana", "Pasta Fresca", "Tiramisu"], ["Terraza", "WiFi Gratis", "Delivery 24h"], "pizza_roma"),
            
            ("Sushi Zen", "Experiencia culinaria japonesa auténtica con chef especializado en Tokyo", .sushi, "35-45 min", "Calle Serrano 123, Madrid", "+34915552345", true, 40.4250, -3.6900, .expensive, ["Sashimi Premium", "Rolls Especiales", "Teppanyaki"], ["Barra de Sushi", "Sake Premium", "Ambiente Zen"], "sushi_zen"),
            
            ("Burger Station", "Las mejores hamburguesas gourmet con carne 100% Angus", .burger, "20-30 min", "Plaza Mayor 8, Madrid", "+34915553456", true, 40.4156, -3.7073, .moderate, ["Angus Burger", "Crispy Chicken", "Vegetarian Options"], ["Terraza", "Música en Vivo", "Happy Hour"], "burger_station"),
            
            ("Healthy Corner", "Comida saludable y orgánica para un estilo de vida equilibrado", .healthy, "15-25 min", "Calle Alcalá 200, Madrid", "+34915554567", true, 40.4300, -3.6800, .moderate, ["Bowls Detox", "Smoothies Verdes", "Ensaladas Gourmet"], ["Productos Orgánicos", "Opciones Veganas", "Sin Gluten"], "healthy_corner"),
            
            ("Mercado Gourmet", "Selección premium de productos gourmet y delicatessen", .grocery, "40-60 min", "Calle Fuencarral 78, Madrid", "+34915555678", true, 40.4280, -3.7020, .expensive, ["Quesos Artesanales", "Vinos Premium", "Jamón Ibérico"], ["Productos Importados", "Maridajes", "Asesoramiento"], "mercado_gourmet"),
            
            ("Sandwich & Co", "Sandwiches artesanales con pan recién horneado cada día", .sandwich, "10-20 min", "Calle Preciados 15, Madrid", "+34915556789", true, 40.4190, -3.7040, .budget, ["Club Sandwich", "Bocadillos Tradicionales", "Wraps"], ["Pan Artesanal", "Ingredientes Frescos", "Para Llevar"], "sandwich_co"),
            
            ("Cocktails & Dreams", "Los mejores cócteles de Madrid con bartenders internacionales", .cocteles, "15-25 min", "Gran Vía 28, Madrid", "+34915557890", false, 40.4215, -3.7030, .expensive, ["Cócteles de Autor", "Gin Tonics Premium", "Mojitos Cubanos"], ["Terraza Rooftop", "DJ Sets", "Carta de Vinos"], "cocktails_dreams"),
            
            ("Fresh Drinks", "Bebidas naturales, zumos detox y smoothies energéticos", .bebidas, "5-15 min", "Calle Hortaleza 65, Madrid", "+34915558901", true, 40.4260, -3.6950, .budget, ["Zumos Detox", "Smoothies Proteicos", "Kombuchas"], ["Sin Azúcar Añadido", "Ingredientes Orgánicos", "Delivery Rápido"], "fresh_drinks"),
            
            ("Promociones Express", "Las mejores ofertas y promociones en comida rápida", .promociones, "15-25 min", "Calle Montera 22, Madrid", "+34915559012", true, 40.4180, -3.7050, .budget, ["2x1 Pizzas", "Menús Estudiante", "Happy Meals"], ["Ofertas Diarias", "Descuentos Online", "Acumula Puntos"], "promociones_express"),
            
            ("Alimentos Frescos", "Productos frescos de temporada directo del campo", .alimentos, "30-45 min", "Mercado San Miguel, Madrid", "+34915550123", true, 40.4150, -3.7080, .moderate, ["Frutas de Temporada", "Verduras Ecológicas", "Carnes Frescas"], ["Productos Locales", "Sin Pesticidas", "Entrega Mismo Día"], "alimentos_frescos"),
            
            ("Dragon Palace", "Auténtica cocina china con recetas familiares tradicionales", .pizza, "30-40 min", "Calle Atocha 89, Madrid", "+34915551357", true, 40.4100, -3.7000, .moderate, ["Pato Laqueado", "Dim Sum", "Fideos Chinos"], ["Cocina Abierta", "Menú Degustación", "Té Chino"], nil),
            
            ("Taco Libre", "Auténticos tacos mexicanos con salsas picantes artesanales", .burger, "20-30 min", "Calle Malasaña 34, Madrid", "+34915552468", true, 40.4240, -3.7010, .budget, ["Tacos de Carnitas", "Guacamole Fresco", "Quesadillas"], ["Salsas Picantes", "Ambiente Mexicano", "Música Latina"], nil),
            
            ("Med Delights", "Sabores del Mediterráneo con aceite de oliva virgen extra", .healthy, "25-35 min", "Paseo de la Castellana 95, Madrid", "+34915553579", true, 40.4350, -3.6880, .moderate, ["Hummus Casero", "Falafel", "Ensaladas Griegas"], ["Aceite de Oliva Virgen", "Ingredientes Mediterráneos", "Opciones Vegetarianas"], nil),
            
            ("Coffee & More", "Café de especialidad con repostería artesanal", .bebidas, "10-20 min", "Calle Velázquez 87, Madrid", "+34915554680", true, 40.4300, -3.6850, .moderate, ["Café de Especialidad", "Pasteles Caseros", "Brunchs"], ["Café en Grano", "Repostería Artesanal", "WiFi Gratis"], nil),
            
            ("Street Food Market", "Lo mejor de la comida callejera mundial en un solo lugar", .burger, "15-25 min", "Plaza de Chueca 12, Madrid", "+34915555791", true, 40.4220, -3.6960, .budget, ["Hot Dogs Gourmet", "Fish & Chips", "Crepes"], ["Comida Internacional", "Precios Accesibles", "Ambiente Informal"], nil),
            
            ("Vegan Paradise", "100% vegano con opciones sin gluten y orgánicas", .healthy, "20-30 min", "Calle Tribunal 45, Madrid", "+34915556802", true, 40.4210, -3.7000, .moderate, ["Burger Vegana", "Bowl Buddha", "Leches Vegetales"], ["100% Vegano", "Sin Gluten", "Productos Orgánicos"], nil),
            
            ("Fish Market", "Pescado fresco del Cantábrico preparado al momento", .alimentos, "35-45 min", "Mercado de Maravillas, Madrid", "+34915557913", true, 40.4320, -3.7100, .expensive, ["Pescado del Día", "Mariscos Frescos", "Paellas"], ["Pescado Fresco", "Preparación al Momento", "Especialidad en Paellas"], nil),
            
            ("Pasta Corner", "Pasta italiana casera con salsas tradicionales", .pizza, "20-30 min", "Calle Princesa 67, Madrid", "+34915558024", true, 40.4280, -3.7150, .moderate, ["Pasta Fresca", "Salsas Caseras", "Risottos"], ["Pasta Casera", "Ingredientes Italianos", "Ambiente Familiar"], nil),
            
            ("Spice Route", "Cocina india auténtica con especias importadas", .alimentos, "30-40 min", "Calle Embajadores 123, Madrid", "+34915559135", true, 40.4080, -3.7020, .moderate, ["Curry de Pollo", "Naan Bread", "Biryani"], ["Especias Auténticas", "Platos Picantes", "Ambiente Hindú"], nil),
            
            ("Sweet Dreams", "Postres artesanales y dulces tradicionales", .alimentos, "15-25 min", "Calle Mayor 89, Madrid", "+34915550246", true, 40.4170, -3.7060, .moderate, ["Torrijas", "Crema Catalana", "Churros"], ["Postres Caseros", "Dulces Tradicionales", "Sin Conservantes"], nil)
        ]
        
        for (index, data) in storeData.prefix(min(count, storeData.count)).enumerated() {
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
            store.imageName = data.12
            store.rating = Double.random(in: 3.8...4.9)
            store.reviewCount = Int.random(in: 12...456)
            
            // Random background colors
            let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"]
            store.backgroundColor = colors[safe: index % colors.count]
            
            try await store.save(on: app.db)
        }
    }
    
    // MARK: - Seed Products
    
    private func seedProducts(_ app: Application, count: Int) async throws {
        let stores = try await Store.query(on: app.db).all()
        guard !stores.isEmpty else {
            throw Abort(.internalServerError, reason: "No stores found. Please seed stores first.")
        }
        
        let productTemplates: [(String, String, String?, FoodCategory, Double, Double?, String, [String], [String], [String], Bool, Bool, Bool, Bool, Int?)] = [
            // Pizza Products
            ("Pizza Margherita", "Pizza clásica con salsa de tomate, mozzarella fresca y albahaca", "La pizza más icónica de Italia, preparada con ingredientes frescos de la mejor calidad. Masa fermentada 24 horas.", .pizza, 12.50, 15.00, "20-25 min", ["Masa de trigo", "Tomate San Marzano", "Mozzarella di Bufala", "Albahaca fresca", "Aceite de oliva"], ["Gluten", "Lactosa"], ["Clásica", "Italiana", "Popular"], false, false, false, false, 280),
            
            ("Pizza Quattro Stagioni", "Pizza dividida en cuatro estaciones con ingredientes de temporada", "Cada cuarto representa una estación del año con ingredientes frescos y de temporada.", .pizza, 16.90, 19.50, "25-30 min", ["Masa artesanal", "Salsa de tomate", "Mozzarella", "Jamón", "Champiñones", "Alcachofas", "Aceitunas"], ["Gluten", "Lactosa"], ["Gourmet", "Temporada", "Artesanal"], false, false, false, false, 320),
            
            ("Pizza Vegana Supreme", "Pizza completamente vegana con queso vegetal y verduras", "Deliciosa pizza sin ingredientes de origen animal, con queso vegano artesanal.", .pizza, 14.80, nil, "22-28 min", ["Masa integral", "Salsa de tomate", "Queso vegano", "Pimientos", "Calabacín", "Berenjena", "Rúcula"], ["Gluten"], ["Vegana", "Saludable", "Plant-Based"], true, true, false, false, 240),
            
            // Sushi Products
            ("Sashimi de Salmón", "Láminas finas de salmón noruego fresco", "Salmón noruego de la más alta calidad, cortado por nuestro chef especializado.", .sushi, 18.90, nil, "15-20 min", ["Salmón noruego", "Wasabi", "Jengibre encurtido", "Salsa de soja"], ["Pescado"], ["Premium", "Fresco", "Tradicional"], false, false, true, false, 180),
            
            ("Dragon Roll", "Roll especial con tempura de langostino y aguacate", "Nuestro roll más popular con langostinos en tempura, aguacate y salsa especial.", .sushi, 22.50, nil, "20-25 min", ["Arroz sushi", "Langostinos", "Aguacate", "Pepino", "Alga nori", "Sésamo", "Salsa dragon"], ["Pescado", "Gluten", "Sésamo"], ["Especial", "Popular", "Gourmet"], false, false, true, false, 220),
            
            ("Poke Bowl Salmón", "Bowl hawaiano con salmón, arroz y vegetales frescos", "Combinación perfecta de salmón fresco, arroz sushi y vegetales de temporada.", .sushi, 15.80, nil, "15-20 min", ["Salmón fresco", "Arroz sushi", "Edamame", "Aguacate", "Zanahoria", "Pepino", "Algas wakame"], ["Pescado", "Soja"], ["Saludable", "Hawaiian", "Fresco"], false, false, true, false, 290),
            
            // Burger Products  
            ("Angus Classic", "Hamburguesa de ternera Angus con queso cheddar", "Hamburguesa clásica con carne Angus 200g, queso cheddar curado y verduras frescas.", .burger, 13.90, nil, "15-20 min", ["Carne Angus 200g", "Pan brioche", "Queso cheddar", "Lechuga", "Tomate", "Cebolla", "Pepinillos"], ["Gluten", "Lactosa"], ["Angus", "Clásica", "Premium"], false, false, false, false, 580),
            
            ("Chicken Crispy", "Pollo crujiente con salsa barbacoa casera", "Pechuga de pollo empanizada con nuestro mix secreto de especias.", .burger, 11.50, nil, "12-18 min", ["Pechuga de pollo", "Pan integral", "Salsa BBQ casera", "Lechuga iceberg", "Tomate", "Cebolla morada"], ["Gluten"], ["Crispy", "BBQ", "Pollo"], false, false, false, true, 490),
            
            ("Vegan Deluxe", "Hamburguesa vegana con proteína de soja y queso vegano", "Hamburguesa 100% vegetal con proteína de soja texturizada y vegetales frescos.", .burger, 12.80, nil, "15-22 min", ["Proteína de soja", "Pan integral", "Queso vegano", "Aguacate", "Lechuga", "Tomate", "Cebolla"], ["Gluten", "Soja"], ["Vegana", "Plant-Based", "Saludable"], true, true, false, false, 380),
            
            // Healthy Products
            ("Buddha Bowl", "Bowl nutritivo con quinoa, verduras y proteína", "Combinación equilibrada de superalimentos para una comida completa y nutritiva.", .healthy, 13.50, nil, "15-20 min", ["Quinoa", "Aguacate", "Brócoli", "Zanahoria", "Espinacas", "Garbanzos", "Semillas de sésamo"], ["Sésamo"], ["Superfood", "Proteínas", "Detox"], true, true, true, false, 420),
            
            ("Smoothie Green Power", "Batido verde con espinacas, manzana y jengibre", "Batido detox con vegetales de hoja verde, frutas frescas y superalimentos.", .healthy, 6.80, nil, "5-8 min", ["Espinacas frescas", "Manzana verde", "Jengibre", "Limón", "Chía", "Agua de coco"], [], ["Detox", "Verde", "Energético"], true, true, true, false, 120),
            
            ("Ensalada Caesar Vegana", "Versión vegana de la clásica ensalada Caesar", "Caesar tradicional pero completamente vegano con nuestro aderezo especial.", .healthy, 11.90, nil, "10-15 min", ["Lechuga romana", "Crutones integrales", "Queso vegano", "Aderezo caesar vegano", "Tomates cherry"], ["Gluten"], ["Caesar", "Vegana", "Clásica"], true, true, false, false, 180),
            
            // Sandwich Products
            ("Club Sandwich", "Sándwich de tres pisos con pollo, bacon y verduras", "El clásico americano con ingredientes premium y pan tostado artesanal.", .sandwich, 8.90, nil, "8-12 min", ["Pan de molde artesanal", "Pechuga de pollo", "Bacon", "Lechuga", "Tomate", "Mayonesa casera"], ["Gluten"], ["Clásico", "Americano", "Triple"], false, false, false, false, 450),
            
            ("Bocadillo Ibérico", "Bocadillo de jamón ibérico con tomate y aceite", "Jamón ibérico de bellota con pan artesanal, tomate fresco y aceite de oliva virgen.", .sandwich, 12.50, nil, "5-8 min", ["Pan artesanal", "Jamón ibérico de bellota", "Tomate natural", "Aceite de oliva virgen extra"], ["Gluten"], ["Ibérico", "Tradicional", "Premium"], false, false, false, false, 380),
            
            ("Wrap Mediterranean", "Wrap con hummus, verduras y queso feta", "Tortilla integral rellena de hummus casero, verduras frescas y queso feta.", .sandwich, 7.80, nil, "6-10 min", ["Tortilla integral", "Hummus casero", "Pepino", "Tomate", "Pimiento rojo", "Queso feta", "Aceitunas"], ["Gluten", "Lactosa"], ["Mediterranean", "Wrap", "Vegetariano"], false, false, false, false, 320),
            
            // Beverage Products
            ("Zumo Detox Verde", "Zumo natural con apio, pepino y manzana verde", "Combinación perfecta de vegetales verdes para depurar y energizar tu cuerpo.", .bebidas, 5.50, nil, "3-5 min", ["Apio fresco", "Pepino", "Manzana verde", "Espinacas", "Limón", "Jengibre"], [], ["Detox", "Natural", "Verde"], true, true, true, false, 85),
            
            ("Smoothie Proteico", "Batido con proteína vegetal, plátano y mantequilla de cacahuete", "Perfecto post-entreno con 25g de proteína vegetal y ingredientes naturales.", .bebidas, 7.20, nil, "4-6 min", ["Proteína de guisante", "Plátano", "Mantequilla de cacahuete", "Leche de avena", "Canela"], ["Cacahuetes"], ["Proteico", "Post-Entreno", "Vegano"], true, true, false, false, 280),
            
            ("Kombucha Jengibre", "Bebida fermentada probiótica con jengibre fresco", "Kombucha artesanal fermentada durante 14 días con jengibre fresco y especias.", .bebidas, 4.80, nil, "Inmediato", ["Té verde fermentado", "Jengibre fresco", "Cultivos probióticos", "Azúcar de caña"], [], ["Probiótico", "Fermentado", "Natural"], true, true, true, false, 35)
        ]
        
        var productCount = 0
        let maxProductsPerStore = count / stores.count + 1
        
        for store in stores {
            let productsForThisStore = productTemplates.filter { template in
                return template.3 == store.category || 
                       (store.category == .alimentos && [.healthy, .bebidas].contains(template.3)) ||
                       (store.category == .promociones && [.pizza, .burger, .sandwich].contains(template.3))
            }
            
            for (index, template) in productsForThisStore.prefix(maxProductsPerStore).enumerated() {
                if productCount >= count { break }
                
                let product = Product()
                product.$store.id = store.id!
                product.name = template.0
                product.description = template.1
                product.fullDescription = template.2
                product.category = template.3
                product.basePrice = template.4 * Double.random(in: 0.9...1.1) // Slight price variation
                product.originalPrice = template.5
                product.preparationTime = template.6
                product.ingredients = template.7
                product.allergens = template.8
                product.tags = template.9
                product.isOrganic = template.10
                product.isVegan = template.11
                product.isGlutenFree = template.12
                product.isSpicy = template.13
                product.calories = template.14
                product.rating = Double.random(in: 3.5...4.8)
                product.reviewCount = Int.random(in: 5...234)
                product.isSponsored = index == 0 && Bool.random() // First product might be sponsored
                product.isAvailable = Double.random(in: 0...1) > 0.1 // 90% available
                product.stockQuantity = product.isAvailable ? Int.random(in: 5...50) : 0
                
                try await product.save(on: app.db)
                productCount += 1
            }
            
            if productCount >= count { break }
        }
    }
    
    // MARK: - Seed Events
    
    private func seedEvents(_ app: Application, count: Int) async throws {
        let eventData: [(String, String, String, EventCategory, Double, Int, String, [String], [String], [String])] = [
            ("Taller de Cocina Italiana", "Aprende a cocinar pasta fresca y salsas tradicionales", "Sumérgete en la auténtica cocina italiana con nuestro chef especializado. Aprenderás técnicas tradicionales para hacer pasta fresca desde cero, preparar salsas clásicas como carbonara y bolognesa, y descubrir los secretos de la cocina italiana casera.", .gastronomico, 35.0, 20, "Chef Marco Antonelli", ["Conocimientos básicos de cocina", "Delantal propio"], ["Todos los ingredientes", "Recetario digital", "Cena incluida"], ["Italiano", "Pasta", "Tradicional"]),
            
            ("Cata de Vinos Rioja", "Degustación de 6 vinos de la D.O. Rioja con maridaje", "Descubre la riqueza y complejidad de los vinos de Rioja en esta cata dirigida por sommelier certificado. Incluye maridaje con tapas españolas tradicionales.", .bebidas, 45.0, 15, "Sommelier Ana Ruiz", ["Mayor de 18 años"], ["6 vinos premium", "Tapas de maridaje", "Material didáctico"], ["Vino", "Maridaje", "Español"]),
            
            ("Masterclass Sushi Making", "Curso intensivo de preparación de sushi con chef japonés", "Aprende las técnicas tradicionales del sushi de la mano de un auténtico chef japonés. Desde el corte del pescado hasta la preparación del arroz perfecto.", .gastronomico, 60.0, 12, "Chef Hiroshi Tanaka", ["Sin experiencia previa necesaria"], ["Todos los ingredientes", "Kit de cuchillos", "Certificado"], ["Japonés", "Sushi", "Masterclass"]),
            
            ("Festival de Cócteles", "Noche de cócteles con los mejores bartenders de Madrid", "Una noche única con los bartenders más reconocidos de Madrid. Degusta cócteles únicos y aprende técnicas de mixología.", .bebidas, 25.0, 100, "Asociación Bartenders Madrid", ["Mayor de 18 años"], ["3 cócteles incluidos", "Aperitivos", "Música en vivo"], ["Cócteles", "Bartender", "Nocturno"]),
            
            ("Curso de Repostería Francesa", "Técnicas clásicas de repostería francesa", "Domina las técnicas básicas de la repostería francesa: macarons, éclairs, croissants y más.", .gastronomico, 50.0, 16, "Chef Pâtissier Marie Dubois", ["Experiencia básica recomendada"], ["Ingredientes premium", "Recetario", "Degustación"], ["Francés", "Repostería", "Dulces"]),
            
            ("Taller de Fermentación", "Aprende a fermentar vegetales y hacer kimchi", "Descubre el mundo de la fermentación natural. Aprende a hacer kimchi, chucrut y otros fermentados beneficiosos para la salud.", .educativo, 30.0, 18, "Nutricionista Laura González", [], ["Frascos para llevar", "Cultivos iniciadores", "Guía de fermentación"], ["Fermentación", "Saludable", "Probióticos"]),
            
            ("Noche de Jazz y Tapas", "Concierto íntimo con degustación de tapas", "Una velada perfecta combinando el mejor jazz en directo con una selección de tapas españolas tradicionales.", .cultural, 20.0, 80, "Trío Jazz Madrid", [], ["Tapas variadas", "Bebida incluida", "Concierto completo"], ["Jazz", "Música", "Tapas"]),
            
            ("Networking Gastronómico", "Conecta con profesionales del sector alimentario", "Evento de networking para profesionales del sector gastronómico, productores locales y emprendedores culinarios.", .networking, 15.0, 50, "Asociación Gastronómica Madrid", ["Profesionales del sector"], ["Cocktail de bienvenida", "Directorio de contactos", "Certificado de asistencia"], ["Networking", "Profesional", "Gastronómico"]),
            
            ("Show Cooking Mediterranean", "Demostración culinaria de platos mediterráneos", "Disfruta de un espectáculo culinario donde nuestro chef prepara platos mediterráneos en vivo mientras explica técnicas y secretos.", .entretenimiento, 40.0, 25, "Chef Carlos Mediterráneo", [], ["Degustación completa", "Recetas digitales", "Bebida incluida"], ["Mediterráneo", "Show", "Degustación"]),
            
            ("Taller de Café Specialty", "Aprende sobre café de especialidad y métodos de extracción", "Descubre el mundo del café de especialidad: origen, tueste, métodos de extracción y cata profesional.", .educativo, 25.0, 20, "Barista Campeón Nacional", [], ["Degustación de 5 cafés", "Kit de cata", "Manual del café"], ["Café", "Specialty", "Barista"]),
            
            ("Cena Maridaje Exclusiva", "Menú degustación con maridaje de vinos", "Una experiencia gastronómica única con menú de 7 platos maridados con vinos seleccionados especialmente.", .gastronomico, 85.0, 10, "Chef Estrella Michelin", ["Reserva anticipada"], ["Menú completo 7 platos", "Maridaje de vinos", "Experiencia premium"], ["Michelin", "Maridaje", "Exclusivo"]),
            
            ("Festival de Cerveza Artesanal", "Degustación de cervezas artesanales locales", "Conoce las mejores cervecerías artesanales de Madrid. Degusta diferentes estilos y aprende sobre el proceso de elaboración.", .bebidas, 18.0, 60, "Asociación Cerveceros Artesanales", ["Mayor de 18 años"], ["Degustación 8 cervezas", "Aperitivos", "Charla magistral"], ["Cerveza", "Artesanal", "Local"]),
            
            ("Taller de Panadería Artesanal", "Aprende a hacer pan con masa madre", "Técnicas tradicionales de panadería. Aprende a crear y mantener masa madre, y hornea tu propio pan artesanal.", .gastronomico, 40.0, 14, "Maestro Panadero Juan Carlos", [], ["Masa madre para llevar", "Pan horneado", "Manual de técnicas"], ["Pan", "Artesanal", "Tradicional"]),
            
            ("Gastro Market", "Mercado gastronómico con productores locales", "Evento mensual donde los mejores productores locales presentan sus productos. Degustaciones gratuitas y venta directa.", .cultural, 0.0, 200, "Mercado Central Madrid", [], ["Degustaciones gratuitas", "Música ambiente", "Productos locales"], ["Mercado", "Local", "Gratuito"]),
            
            ("Taller de Cocina Asiática Fusion", "Fusión de cocinas asiáticas con técnicas modernas", "Explora la fusión de sabores asiáticos con técnicas culinarias modernas. Tailandesa, china, japonesa y coreana en un solo taller.", .gastronomico, 55.0, 18, "Chef Fusion David Kim", [], ["Ingredientes exóticos", "3 platos completos", "Técnicas modernas"], ["Asiático", "Fusion", "Moderno"]),
            
            ("Noche de Flamenco y Tapas", "Espectáculo de flamenco con cena tradicional", "Una noche auténticamente española con espectáculo de flamenco profesional y cena de tapas tradicionales.", .cultural, 35.0, 40, "Compañía Flamenca Andaluza", [], ["Cena completa tapas", "Espectáculo completo", "Bebida incluida"], ["Flamenco", "Tradicional", "Espectáculo"]),
            
            ("Workshop de Food Photography", "Aprende fotografía gastronómica profesional", "Taller práctico de fotografía gastronómica. Aprende composición, iluminación y edición para redes sociales.", .educativo, 45.0, 12, "Fotógrafo Food Stylist", ["Cámara propia recomendada"], ["Platillos para fotografiar", "Atrezzo profesional", "Edición digital"], ["Fotografía", "Food", "Redes Sociales"]),
            
            ("Degustación de Quesos Artesanales", "Cata dirigida de quesos españoles artesanales", "Recorrido por la geografía quesera española. Degusta quesos únicos de pequeños productores artesanales.", .gastronomico, 28.0, 22, "Afinador de Quesos Profesional", [], ["12 variedades de queso", "Maridaje con vinos", "Manual del queso"], ["Queso", "Artesanal", "Español"]),
            
            ("Taller Infantil Mini Chefs", "Cocina divertida para niños de 6 a 12 años", "Taller de cocina diseñado especialmente para niños. Aprenden jugando y se divierten cocinando platos sencillos y saludables.", .educativo, 20.0, 15, "Chef Infantil Patricia", ["Niños de 6 a 12 años", "Acompañante adulto"], ["Delantal y gorro", "Comida preparada", "Diploma mini chef"], ["Infantil", "Educativo", "Saludable"]),
            
            ("Sunset Rooftop Experience", "Cócteles al atardecer con vistas panorámicas", "Experiencia única en rooftop con los mejores cócteles de la ciudad mientras disfrutas del atardecer madrileño.", .entretenimiento, 30.0, 35, "Mixologist Premium", ["Mayor de 18 años"], ["2 cócteles premium", "Aperitivos gourmet", "Vistas panorámicas"], ["Rooftop", "Atardecer", "Premium"]),
            
            ("Masterclass de Chocolate", "El arte de trabajar con chocolate premium", "Aprende las técnicas profesionales del chocolatier. Desde templar chocolate hasta crear bombones y postres sofisticados.", .gastronomico, 48.0, 16, "Chocolatier Maestro François", [], ["Chocolate premium Valrhona", "Moldes profesionales", "Creaciones para llevar"], ["Chocolate", "Premium", "Profesional"]),
            
            ("Brunch Dominical Especial", "Brunch gourmet con productos de temporada", "El brunch perfecto para el domingo con productos frescos de temporada, opciones dulces y saladas, y ambiente relajado.", .gastronomico, 22.0, 30, "Chef de Brunch especializado", [], ["Brunch completo", "Bebida caliente", "Zumo natural"], ["Brunch", "Domingo", "Relajado"]),
            
            ("Taller de Cocina Mexicana Auténtica", "Sabores mexicanos tradicionales", "Aprende a cocinar auténticos platos mexicanos: tacos, salsas picantes, guacamole y más, con ingredientes importados de México.", .gastronomico, 42.0, 20, "Chef Mexicana Esperanza", [], ["Ingredientes auténticos", "Especias mexicanas", "Recetario tradicional"], ["Mexicano", "Auténtico", "Picante"]),
            
            ("Wine & Paint Night", "Pintura creativa con maridaje de vinos", "Libera tu creatividad mientras disfrutas de una selección de vinos. No necesitas experiencia previa en pintura.", .cultural, 25.0, 24, "Artista y Sommelier", ["Sin experiencia necesaria"], ["Materiales de pintura", "2 copas de vino", "Lienzo para llevar"], ["Arte", "Vino", "Creativo"]),
            
            ("Gastro Tour por Madrid", "Ruta gastronómica por el centro de Madrid", "Descubre los sabores tradicionales de Madrid en esta ruta gastronómica por el centro histórico. 5 paradas, 5 sabores únicos.", .cultural, 35.0, 25, "Guía Gastronómico Local", ["Caminar 2 horas"], ["5 degustaciones", "Guía experto", "Historia gastronómica"], ["Tour", "Madrid", "Tradicional"])
        ]
        
        for (index, data) in eventData.prefix(min(count, eventData.count)).enumerated() {
            let event = Event()
            event.title = data.0
            event.description = data.1
            event.fullDescription = data.2
            event.category = data.3
            event.price = data.4
            event.capacity = data.5
            event.organizer = data.6
            event.requirements = data.7
            event.includes = data.8
            event.tags = data.9
            
            // Random dates in the future (next 3 months)
            let randomDays = Double.random(in: 1...90)
            event.date = Date().addingTimeInterval(randomDays * 86400)
            
            // Random times
            let times = ["18:00", "19:30", "20:00", "12:00", "13:30", "17:00", "21:00", "11:00", "16:00"]
            event.time = times[safe: index % times.count] ?? "19:00"
            
            // Random durations
            let durations = ["1 hora", "1.5 horas", "2 horas", "2.5 horas", "3 horas", "4 horas"]
            event.duration = durations[safe: index % durations.count] ?? "2 horas"
            
            // Madrid addresses
            let addresses = [
                "Centro Cultural Conde Duque, Madrid",
                "Matadero Madrid, Paseo de la Chopera 14",
                "Mercado de San Miguel, Plaza de San Miguel",
                "Casa de América, Paseo de la Castellana 45",
                "Círculo de Bellas Artes, Calle Alcalá 42",
                "Espacio Cultural Serrería Belga, Calle San Bernardino 1",
                "La Casa Encendida, Ronda de Valencia 2",
                "Caixaforum Madrid, Paseo del Prado 36"
            ]
            event.address = addresses[safe: index % addresses.count] ?? "Centro de Madrid"
            event.location = event.address.components(separatedBy: ",").first ?? "Madrid"
            
            event.availableTickets = Int.random(in: max(1, event.capacity - 15)...event.capacity)
            event.isSponsored = index < 5 || (index % 7 == 0) // Some featured events
            
            try await event.save(on: app.db)
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}