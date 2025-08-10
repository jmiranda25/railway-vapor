//
//  StoreController.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Fluent
import Vapor

struct StoreController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let stores = routes.grouped("api", "stores")
        
        // Public routes
        stores.get(use: getAllStores)
        stores.get(":storeID", use: getStore)
        stores.post("search", use: searchStores)
        stores.get("category", ":category", use: getStoresByCategory)
        stores.get("nearby", use: getNearbyStores)
        stores.get("featured", use: getFeaturedStores)
        stores.get("open", use: getOpenStores)
        stores.get(":storeID", "products", use: getStoreProducts)
        
        // Protected routes (require authentication)
        let protected = stores.grouped(JWTAuthenticator())
        let authenticated = protected.grouped(User.guardMiddleware())
        
        authenticated.post(use: createStore)
        authenticated.put(":storeID", use: updateStore)
        authenticated.delete(":storeID", use: deleteStore)
        authenticated.post(":storeID", "rate", use: rateStore)
        authenticated.get("favorites", use: getFavoriteStores)
        authenticated.post(":storeID", "favorite", use: addToFavorites)
        authenticated.delete(":storeID", "favorite", use: removeFromFavorites)
    }
    
    // MARK: - Public Endpoints
    
    @Sendable
    func getAllStores(req: Request) async throws -> [StoreListDTO] {
        let limit = req.query[Int.self, at: "limit"] ?? 50
        let offset = req.query[Int.self, at: "offset"] ?? 0
        
        let stores = try await Store.query(on: req.db)
            .sort(\.$rating, .descending)
            .limit(limit)
            .offset(offset)
            .all()
        
        return stores.map { StoreListDTO(from: $0) }
    }
    
    @Sendable
    func getStore(req: Request) async throws -> StoreResponseDTO {
        guard let store = try await Store.find(req.parameters.get("storeID"), on: req.db) else {
            throw Abort(.notFound, reason: "Tienda no encontrada")
        }
        
        return StoreResponseDTO(from: store)
    }
    
    @Sendable
    func searchStores(req: Request) async throws -> [StoreListDTO] {
        let searchParams = try req.content.decode(StoreSearchDTO.self)
        
        var query = Store.query(on: req.db)
        
        // Apply filters
        if let category = searchParams.category {
            query = query.filter(\.$category == category)
        }
        
        if let location = searchParams.location {
            query = query.filter(\.$address ~~ location)
        }
        
        if let isOpen = searchParams.isOpen {
            query = query.filter(\.$isOpen == isOpen)
        }
        
        if let minRating = searchParams.minRating {
            query = query.filter(\.$rating >= minRating)
        }
        
        if let priceRange = searchParams.priceRange {
            query = query.filter(\.$priceRange == priceRange)
        }
        
        // Geographic search (basic implementation)
        if let latitude = searchParams.latitude,
           let longitude = searchParams.longitude {
            // This is a simplified version - in production you'd want to use PostGIS
            let radius = searchParams.radius ?? 10.0
            let latRange = radius / 111.0 // rough conversion to degrees
            let lngRange = radius / (111.0 * cos(latitude * .pi / 180))
            
            query = query.filter(\.$latitude != nil)
                .filter(\.$longitude != nil)
                .filter(\.$latitude >= latitude - latRange)
                .filter(\.$latitude <= latitude + latRange)
                .filter(\.$longitude >= longitude - lngRange)
                .filter(\.$longitude <= longitude + lngRange)
        }
        
        // Sort by rating
        query = query.sort(\.$rating, .descending)
        
        // Pagination
        let limit = searchParams.limit ?? 20
        let offset = searchParams.offset ?? 0
        
        let stores = try await query
            .limit(limit)
            .offset(offset)
            .all()
        
        return stores.map { StoreListDTO(from: $0) }
    }
    
    @Sendable
    func getStoresByCategory(req: Request) async throws -> [StoreListDTO] {
        guard let categoryString = req.parameters.get("category"),
              let category = FoodCategory(rawValue: categoryString) else {
            throw Abort(.badRequest, reason: "Categoría inválida")
        }
        
        let limit = req.query[Int.self, at: "limit"] ?? 20
        let offset = req.query[Int.self, at: "offset"] ?? 0
        
        let stores = try await Store.query(on: req.db)
            .filter(\.$category == category)
            .sort(\.$rating, .descending)
            .limit(limit)
            .offset(offset)
            .all()
        
        return stores.map { StoreListDTO(from: $0) }
    }
    
    @Sendable
    func getNearbyStores(req: Request) async throws -> [StoreListDTO] {
        guard let latitude = req.query[Double.self, at: "latitude"],
              let longitude = req.query[Double.self, at: "longitude"] else {
            throw Abort(.badRequest, reason: "Se requieren coordenadas latitude y longitude")
        }
        
        let radius = req.query[Double.self, at: "radius"] ?? 5.0
        let limit = req.query[Int.self, at: "limit"] ?? 20
        
        // Simplified geographic query
        let latRange = radius / 111.0
        let lngRange = radius / (111.0 * cos(latitude * .pi / 180))
        
        let stores = try await Store.query(on: req.db)
            .filter(\.$latitude != nil)
            .filter(\.$longitude != nil)
            .filter(\.$latitude >= latitude - latRange)
            .filter(\.$latitude <= latitude + latRange)
            .filter(\.$longitude >= longitude - lngRange)
            .filter(\.$longitude <= longitude + lngRange)
            .sort(\.$rating, .descending)
            .limit(limit)
            .all()
        
        return stores.map { StoreListDTO(from: $0) }
    }
    
    @Sendable
    func getFeaturedStores(req: Request) async throws -> [StoreListDTO] {
        let stores = try await Store.query(on: req.db)
            .filter(\.$rating >= 4.5)
            .sort(\.$reviewCount, .descending)
            .limit(10)
            .all()
        
        return stores.map { StoreListDTO(from: $0) }
    }
    
    @Sendable
    func getOpenStores(req: Request) async throws -> [StoreListDTO] {
        let limit = req.query[Int.self, at: "limit"] ?? 20
        
        let stores = try await Store.query(on: req.db)
            .filter(\.$isOpen == true)
            .sort(\.$rating, .descending)
            .limit(limit)
            .all()
        
        return stores.map { StoreListDTO(from: $0) }
    }
    
    @Sendable
    func getStoreProducts(req: Request) async throws -> [ProductListDTO] {
        guard let storeID = req.parameters.get("storeID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID de tienda inválido")
        }
        
        guard let _ = try await Store.find(storeID, on: req.db) else {
            throw Abort(.notFound, reason: "Tienda no encontrada")
        }
        
        let products = try await Product.query(on: req.db)
            .filter(\.$store.$id == storeID)
            .filter(\.$isAvailable == true)
            .sort(\.$rating, .descending)
            .all()
        
        return products.map { ProductListDTO(from: $0) }
    }
    
    // MARK: - Protected Endpoints
    
    @Sendable
    func createStore(req: Request) async throws -> StoreResponseDTO {
        try CreateStoreDTO.validate(content: req)
        let createData = try req.content.decode(CreateStoreDTO.self)
        
        let store = Store()
        store.name = createData.name
        store.description = createData.description
        store.category = createData.category
        store.deliveryTime = createData.deliveryTime
        store.address = createData.address
        store.phone = createData.phone
        store.isOpen = createData.isOpen ?? true
        store.latitude = createData.latitude
        store.longitude = createData.longitude
        store.specialties = createData.specialties ?? []
        store.features = createData.features ?? []
        store.priceRange = createData.priceRange ?? .moderate
        store.imageName = createData.imageName
        store.backgroundColor = createData.backgroundColor
        store.rating = 0.0
        store.reviewCount = 0
        
        try await store.save(on: req.db)
        return StoreResponseDTO(from: store)
    }
    
    @Sendable
    func updateStore(req: Request) async throws -> StoreResponseDTO {
        guard let store = try await Store.find(req.parameters.get("storeID"), on: req.db) else {
            throw Abort(.notFound, reason: "Tienda no encontrada")
        }
        
        let updateData = try req.content.decode(UpdateStoreDTO.self)
        
        if let name = updateData.name {
            store.name = name
        }
        
        if let description = updateData.description {
            store.description = description
        }
        
        if let category = updateData.category {
            store.category = category
        }
        
        if let deliveryTime = updateData.deliveryTime {
            store.deliveryTime = deliveryTime
        }
        
        if let address = updateData.address {
            store.address = address
        }
        
        if let phone = updateData.phone {
            store.phone = phone
        }
        
        if let isOpen = updateData.isOpen {
            store.isOpen = isOpen
        }
        
        if let latitude = updateData.latitude {
            store.latitude = latitude
        }
        
        if let longitude = updateData.longitude {
            store.longitude = longitude
        }
        
        if let specialties = updateData.specialties {
            store.specialties = specialties
        }
        
        if let features = updateData.features {
            store.features = features
        }
        
        if let priceRange = updateData.priceRange {
            store.priceRange = priceRange
        }
        
        if let imageName = updateData.imageName {
            store.imageName = imageName
        }
        
        if let backgroundColor = updateData.backgroundColor {
            store.backgroundColor = backgroundColor
        }
        
        try await store.save(on: req.db)
        return StoreResponseDTO(from: store)
    }
    
    @Sendable
    func deleteStore(req: Request) async throws -> HTTPStatus {
        guard let store = try await Store.find(req.parameters.get("storeID"), on: req.db) else {
            throw Abort(.notFound, reason: "Tienda no encontrada")
        }
        
        try await store.delete(on: req.db)
        return .noContent
    }
    
    @Sendable
    func rateStore(req: Request) async throws -> StoreResponseDTO {
        guard let store = try await Store.find(req.parameters.get("storeID"), on: req.db) else {
            throw Abort(.notFound, reason: "Tienda no encontrada")
        }
        
        try StoreRatingDTO.validate(content: req)
        let ratingData = try req.content.decode(StoreRatingDTO.self)
        
        // Update store rating (simplified version)
        let totalRating = store.rating * Double(store.reviewCount) + ratingData.rating
        store.reviewCount += 1
        store.rating = totalRating / Double(store.reviewCount)
        
        try await store.save(on: req.db)
        return StoreResponseDTO(from: store)
    }
    
    @Sendable
    func getFavoriteStores(req: Request) async throws -> [StoreListDTO] {
        // This would typically return user's favorite stores
        // For now, returning top-rated stores as placeholder
        let stores = try await Store.query(on: req.db)
            .filter(\.$rating >= 4.0)
            .sort(\.$rating, .descending)
            .limit(10)
            .all()
        
        return stores.map { StoreListDTO(from: $0) }
    }
    
    @Sendable
    func addToFavorites(req: Request) async throws -> HTTPStatus {
        // Implementation would typically create a user-store favorite relationship
        return .ok
    }
    
    @Sendable
    func removeFromFavorites(req: Request) async throws -> HTTPStatus {
        // Implementation would typically remove user-store favorite relationship
        return .noContent
    }
}