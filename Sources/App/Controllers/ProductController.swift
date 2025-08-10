//
//  ProductController.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Fluent
import Vapor

struct ProductController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let products = routes.grouped("api", "products")
        
        // Public routes
        products.get(use: getAllProducts)
        products.get(":productID", use: getProduct)
        products.post("search", use: searchProducts)
        products.post("filter", use: filterProducts)
        products.get("category", ":category", use: getProductsByCategory)
        products.get("featured", use: getFeaturedProducts)
        products.get("deals", use: getDealsAndOffers)
        products.get("trending", use: getTrendingProducts)
        products.get("healthy", use: getHealthyProducts)
        products.get("quick", use: getQuickProducts)
        
        // Protected routes (require authentication)
        let protected = products.grouped(JWTAuthenticator())
        let authenticated = protected.grouped(User.guardMiddleware())
        
        authenticated.post(use: createProduct)
        authenticated.put(":productID", use: updateProduct)
        authenticated.delete(":productID", use: deleteProduct)
        authenticated.post(":productID", "rate", use: rateProduct)
        authenticated.get("favorites", use: getFavoriteProducts)
        authenticated.post(":productID", "favorite", use: addToFavorites)
        authenticated.delete(":productID", "favorite", use: removeFromFavorites)
        authenticated.get("recommendations", use: getRecommendedProducts)
    }
    
    // MARK: - Public Endpoints
    
    @Sendable
    func getAllProducts(req: Request) async throws -> [ProductListDTO] {
        let limit = req.query[Int.self, at: "limit"] ?? 50
        let offset = req.query[Int.self, at: "offset"] ?? 0
        
        let products = try await Product.query(on: req.db)
            .filter(\.$isAvailable == true)
            .with(\.$store)
            .sort(\.$rating, .descending)
            .limit(limit)
            .offset(offset)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    @Sendable
    func getProduct(req: Request) async throws -> ProductResponseDTO {
        guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else {
            throw Abort(.notFound, reason: "Producto no encontrado")
        }
        
        try await product.$store.load(on: req.db)
        return ProductResponseDTO(from: product, store: product.store)
    }
    
    @Sendable
    func searchProducts(req: Request) async throws -> [ProductListDTO] {
        let searchParams = try req.content.decode(ProductSearchDTO.self)
        
        var query = Product.query(on: req.db)
            .filter(\.$isAvailable == true)
            .with(\.$store)
        
        // Apply filters
        if let category = searchParams.category {
            query = query.filter(\.$category == category)
        }
        
        if let storeID = searchParams.storeID {
            query = query.filter(\.$store.$id == storeID)
        }
        
        if let minPrice = searchParams.minPrice {
            query = query.filter(\.$basePrice >= minPrice)
        }
        
        if let maxPrice = searchParams.maxPrice {
            query = query.filter(\.$basePrice <= maxPrice)
        }
        
        if let minRating = searchParams.minRating {
            query = query.filter(\.$rating >= minRating)
        }
        
        if let isOrganic = searchParams.isOrganic {
            query = query.filter(\.$isOrganic == isOrganic)
        }
        
        if let isVegan = searchParams.isVegan {
            query = query.filter(\.$isVegan == isVegan)
        }
        
        if let isGlutenFree = searchParams.isGlutenFree {
            query = query.filter(\.$isGlutenFree == isGlutenFree)
        }
        
        if let isSpicy = searchParams.isSpicy {
            query = query.filter(\.$isSpicy == isSpicy)
        }
        
        if let isSponsored = searchParams.isSponsored {
            query = query.filter(\.$isSponsored == isSponsored)
        }
        
        if let maxCalories = searchParams.maxCalories {
            query = query.filter(\.$calories != nil)
                .filter(\.$calories <= maxCalories)
        }
        
        // Text search (simplified)
        if let searchQuery = searchParams.query {
            query = query.group(.or) { or in
                or.filter(\.$name ~~ searchQuery)
                    .filter(\.$description ~~ searchQuery)
            }
        }
        
        // Sorting
        let sortBy = searchParams.sortBy ?? .rating
        switch sortBy {
        case .rating:
            query = query.sort(\.$rating, .descending)
        case .price:
            query = query.sort(\.$basePrice, .ascending)
        case .name:
            query = query.sort(\.$name, .ascending)
        case .newest:
            query = query.sort(\.$createdAt, .descending)
        case .preparationTime:
            query = query.sort(\.$preparationTime, .ascending)
        }
        
        // Pagination
        let limit = searchParams.limit ?? 20
        let offset = searchParams.offset ?? 0
        
        let products = try await query
            .limit(limit)
            .offset(offset)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    @Sendable
    func filterProducts(req: Request) async throws -> [ProductListDTO] {
        let filter = try req.content.decode(ProductFilterDTO.self)
        
        var query = Product.query(on: req.db)
            .filter(\.$isAvailable == true)
            .with(\.$store)
        
        // Dietary filters
        if let dietary = filter.dietary {
            if let isOrganic = dietary.isOrganic {
                query = query.filter(\.$isOrganic == isOrganic)
            }
            
            if let isVegan = dietary.isVegan {
                query = query.filter(\.$isVegan == isVegan)
            }
            
            if let isGlutenFree = dietary.isGlutenFree {
                query = query.filter(\.$isGlutenFree == isGlutenFree)
            }
            
            if let maxCalories = dietary.maxCalories {
                query = query.filter(\.$calories != nil)
                    .filter(\.$calories <= maxCalories)
            }
        }
        
        // Price filters
        if let priceRange = filter.priceRange {
            if let min = priceRange.min {
                query = query.filter(\.$basePrice >= min)
            }
            
            if let max = priceRange.max {
                query = query.filter(\.$basePrice <= max)
            }
        }
        
        // Feature filters
        if let features = filter.features {
            if let isSpicy = features.isSpicy {
                query = query.filter(\.$isSpicy == isSpicy)
            }
            
            if let minRating = features.minRating {
                query = query.filter(\.$rating >= minRating)
            }
        }
        
        let products = try await query
            .sort(\.$rating, .descending)
            .limit(20)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    @Sendable
    func getProductsByCategory(req: Request) async throws -> [ProductListDTO] {
        guard let categoryString = req.parameters.get("category"),
              let category = FoodCategory(rawValue: categoryString) else {
            throw Abort(.badRequest, reason: "Categoría inválida")
        }
        
        let limit = req.query[Int.self, at: "limit"] ?? 20
        let offset = req.query[Int.self, at: "offset"] ?? 0
        
        let products = try await Product.query(on: req.db)
            .filter(\.$category == category)
            .filter(\.$isAvailable == true)
            .with(\.$store)
            .sort(\.$rating, .descending)
            .limit(limit)
            .offset(offset)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    @Sendable
    func getFeaturedProducts(req: Request) async throws -> [ProductListDTO] {
        let products = try await Product.query(on: req.db)
            .filter(\.$isSponsored == true)
            .filter(\.$isAvailable == true)
            .with(\.$store)
            .sort(\.$rating, .descending)
            .limit(10)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    @Sendable
    func getDealsAndOffers(req: Request) async throws -> [ProductListDTO] {
        let products = try await Product.query(on: req.db)
            .filter(\.$originalPrice != nil)
            .filter(\.$isAvailable == true)
            .with(\.$store)
            .sort(\.$rating, .descending)
            .limit(20)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    @Sendable
    func getTrendingProducts(req: Request) async throws -> [ProductListDTO] {
        let products = try await Product.query(on: req.db)
            .filter(\.$rating >= 4.0)
            .filter(\.$reviewCount >= 10)
            .filter(\.$isAvailable == true)
            .with(\.$store)
            .sort(\.$reviewCount, .descending)
            .limit(15)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    @Sendable
    func getHealthyProducts(req: Request) async throws -> [ProductListDTO] {
        let products = try await Product.query(on: req.db)
            .group(.or) { or in
                or.filter(\.$isOrganic == true)
                    .filter(\.$isVegan == true)
                    .filter(\.$calories != nil)
                    .filter(\.$calories <= 500)
            }
            .filter(\.$isAvailable == true)
            .with(\.$store)
            .sort(\.$rating, .descending)
            .limit(20)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    @Sendable
    func getQuickProducts(req: Request) async throws -> [ProductListDTO] {
        let products = try await Product.query(on: req.db)
            .filter(\.$preparationTime ~~ "5")
            .filter(\.$preparationTime ~~ "10")
            .filter(\.$preparationTime ~~ "15")
            .filter(\.$isAvailable == true)
            .with(\.$store)
            .sort(\.$rating, .descending)
            .limit(20)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    // MARK: - Protected Endpoints
    
    @Sendable
    func createProduct(req: Request) async throws -> ProductResponseDTO {
        try CreateProductDTO.validate(content: req)
        let createData = try req.content.decode(CreateProductDTO.self)
        
        // Verify store exists
        guard let _ = try await Store.find(createData.storeID, on: req.db) else {
            throw Abort(.notFound, reason: "Tienda no encontrada")
        }
        
        let product = Product()
        product.$store.id = createData.storeID
        product.name = createData.name
        product.description = createData.description
        product.fullDescription = createData.fullDescription
        product.category = createData.category
        product.basePrice = createData.basePrice
        product.originalPrice = createData.originalPrice
        product.preparationTime = createData.preparationTime ?? "15 min"
        product.calories = createData.calories
        product.isOrganic = createData.isOrganic ?? false
        product.isVegan = createData.isVegan ?? false
        product.isGlutenFree = createData.isGlutenFree ?? false
        product.isSpicy = createData.isSpicy ?? false
        product.isSponsored = createData.isSponsored ?? false
        product.isAvailable = createData.isAvailable ?? true
        product.stockQuantity = createData.stockQuantity
        product.ingredients = createData.ingredients ?? []
        product.allergens = createData.allergens ?? []
        product.tags = createData.tags ?? []
        product.imageName = createData.imageName
        product.rating = 0.0
        product.reviewCount = 0
        
        try await product.save(on: req.db)
        try await product.$store.load(on: req.db)
        
        return ProductResponseDTO(from: product, store: product.store)
    }
    
    @Sendable
    func updateProduct(req: Request) async throws -> ProductResponseDTO {
        guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else {
            throw Abort(.notFound, reason: "Producto no encontrado")
        }
        
        let updateData = try req.content.decode(UpdateProductDTO.self)
        
        if let name = updateData.name {
            product.name = name
        }
        
        if let description = updateData.description {
            product.description = description
        }
        
        if let fullDescription = updateData.fullDescription {
            product.fullDescription = fullDescription
        }
        
        if let category = updateData.category {
            product.category = category
        }
        
        if let basePrice = updateData.basePrice {
            product.basePrice = basePrice
        }
        
        if let originalPrice = updateData.originalPrice {
            product.originalPrice = originalPrice
        }
        
        if let preparationTime = updateData.preparationTime {
            product.preparationTime = preparationTime
        }
        
        if let calories = updateData.calories {
            product.calories = calories
        }
        
        if let isOrganic = updateData.isOrganic {
            product.isOrganic = isOrganic
        }
        
        if let isVegan = updateData.isVegan {
            product.isVegan = isVegan
        }
        
        if let isGlutenFree = updateData.isGlutenFree {
            product.isGlutenFree = isGlutenFree
        }
        
        if let isSpicy = updateData.isSpicy {
            product.isSpicy = isSpicy
        }
        
        if let isSponsored = updateData.isSponsored {
            product.isSponsored = isSponsored
        }
        
        if let isAvailable = updateData.isAvailable {
            product.isAvailable = isAvailable
        }
        
        if let stockQuantity = updateData.stockQuantity {
            product.stockQuantity = stockQuantity
        }
        
        if let ingredients = updateData.ingredients {
            product.ingredients = ingredients
        }
        
        if let allergens = updateData.allergens {
            product.allergens = allergens
        }
        
        if let tags = updateData.tags {
            product.tags = tags
        }
        
        if let imageName = updateData.imageName {
            product.imageName = imageName
        }
        
        try await product.save(on: req.db)
        try await product.$store.load(on: req.db)
        
        return ProductResponseDTO(from: product, store: product.store)
    }
    
    @Sendable
    func deleteProduct(req: Request) async throws -> HTTPStatus {
        guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else {
            throw Abort(.notFound, reason: "Producto no encontrado")
        }
        
        try await product.delete(on: req.db)
        return .noContent
    }
    
    @Sendable
    func rateProduct(req: Request) async throws -> ProductResponseDTO {
        guard let product = try await Product.find(req.parameters.get("productID"), on: req.db) else {
            throw Abort(.notFound, reason: "Producto no encontrado")
        }
        
        try ProductRatingDTO.validate(content: req)
        let ratingData = try req.content.decode(ProductRatingDTO.self)
        
        // Update product rating (simplified version)
        let totalRating = product.rating * Double(product.reviewCount) + ratingData.rating
        product.reviewCount += 1
        product.rating = totalRating / Double(product.reviewCount)
        
        try await product.save(on: req.db)
        try await product.$store.load(on: req.db)
        
        return ProductResponseDTO(from: product, store: product.store)
    }
    
    @Sendable
    func getFavoriteProducts(req: Request) async throws -> [ProductListDTO] {
        // This would typically return user's favorite products
        // For now, returning top-rated products as placeholder
        let products = try await Product.query(on: req.db)
            .filter(\.$rating >= 4.0)
            .filter(\.$isAvailable == true)
            .with(\.$store)
            .sort(\.$rating, .descending)
            .limit(10)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
    
    @Sendable
    func addToFavorites(req: Request) async throws -> HTTPStatus {
        // Implementation would typically create a user-product favorite relationship
        return .ok
    }
    
    @Sendable
    func removeFromFavorites(req: Request) async throws -> HTTPStatus {
        // Implementation would typically remove user-product favorite relationship
        return .noContent
    }
    
    @Sendable
    func getRecommendedProducts(req: Request) async throws -> [ProductListDTO] {
        // This would typically use ML/AI to recommend products based on user preferences
        // For now, returning trending products as placeholder
        let products = try await Product.query(on: req.db)
            .filter(\.$rating >= 4.0)
            .filter(\.$isAvailable == true)
            .with(\.$store)
            .sort(\.$reviewCount, .descending)
            .limit(15)
            .all()
        
        return products.map { ProductListDTO(from: $0, store: $0.store) }
    }
}