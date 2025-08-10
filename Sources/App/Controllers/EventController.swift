//
//  EventController.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Fluent
import Vapor

struct EventController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let events = routes.grouped("api", "events")
        
        // Public routes
        events.get(use: getAllEvents)
        events.get(":eventID", use: getEvent)
        events.post("search", use: searchEvents)
        events.get("category", ":category", use: getEventsByCategory)
        events.get("featured", use: getFeaturedEvents)
        events.get("upcoming", use: getUpcomingEvents)
        
        // Protected routes (require authentication)
        let protected = events.grouped(JWTAuthenticator())
        let authenticated = protected.grouped(User.guardMiddleware())
        
        authenticated.post(use: createEvent)
        authenticated.put(":eventID", use: updateEvent)
        authenticated.delete(":eventID", use: deleteEvent)
        authenticated.post(":eventID", "purchase", use: purchaseTicket)
        authenticated.get("my-events", use: getMyEvents)
    }
    
    // MARK: - Public Endpoints
    
    @Sendable
    func getAllEvents(req: Request) async throws -> [EventListDTO] {
        let limit = req.query[Int.self, at: "limit"] ?? 50
        let offset = req.query[Int.self, at: "offset"] ?? 0
        
        let events = try await Event.query(on: req.db)
            .filter(\.$date >= Date())
            .sort(\.$date, .ascending)
            .limit(limit)
            .offset(offset)
            .all()
        
        return events.map { EventListDTO(from: $0) }
    }
    
    @Sendable
    func getEvent(req: Request) async throws -> EventResponseDTO {
        guard let event = try await Event.find(req.parameters.get("eventID"), on: req.db) else {
            throw Abort(.notFound, reason: "Evento no encontrado")
        }
        
        return EventResponseDTO(from: event)
    }
    
    @Sendable
    func searchEvents(req: Request) async throws -> [EventListDTO] {
        let searchParams = try req.content.decode(EventSearchDTO.self)
        
        var query = Event.query(on: req.db)
        
        // Apply filters
        if let category = searchParams.category {
            query = query.filter(\.$category == category)
        }
        
        if let location = searchParams.location {
            query = query.filter(\.$location ~~ location)
        }
        
        if let startDate = searchParams.startDate {
            query = query.filter(\.$date >= startDate)
        }
        
        if let endDate = searchParams.endDate {
            query = query.filter(\.$date <= endDate)
        }
        
        if let minPrice = searchParams.minPrice {
            query = query.filter(\.$price >= minPrice)
        }
        
        if let maxPrice = searchParams.maxPrice {
            query = query.filter(\.$price <= maxPrice)
        }
        
        if let isSponsored = searchParams.isSponsored {
            query = query.filter(\.$isSponsored == isSponsored)
        }
        
        if let organizer = searchParams.organizer {
            query = query.filter(\.$organizer ~~ organizer)
        }
        
        // Sort by date
        query = query.sort(\.$date, .ascending)
        
        // Pagination
        let limit = searchParams.limit ?? 20
        let offset = searchParams.offset ?? 0
        
        let events = try await query
            .limit(limit)
            .offset(offset)
            .all()
        
        return events.map { EventListDTO(from: $0) }
    }
    
    @Sendable
    func getEventsByCategory(req: Request) async throws -> [EventListDTO] {
        guard let categoryString = req.parameters.get("category"),
              let category = EventCategory(rawValue: categoryString) else {
            throw Abort(.badRequest, reason: "Categoría inválida")
        }
        
        let limit = req.query[Int.self, at: "limit"] ?? 20
        let offset = req.query[Int.self, at: "offset"] ?? 0
        
        let events = try await Event.query(on: req.db)
            .filter(\.$category == category)
            .filter(\.$date >= Date())
            .sort(\.$date, .ascending)
            .limit(limit)
            .offset(offset)
            .all()
        
        return events.map { EventListDTO(from: $0) }
    }
    
    @Sendable
    func getFeaturedEvents(req: Request) async throws -> [EventListDTO] {
        let events = try await Event.query(on: req.db)
            .filter(\.$isSponsored == true)
            .filter(\.$date >= Date())
            .sort(\.$date, .ascending)
            .limit(10)
            .all()
        
        return events.map { EventListDTO(from: $0) }
    }
    
    @Sendable
    func getUpcomingEvents(req: Request) async throws -> [EventListDTO] {
        let calendar = Calendar.current
        let now = Date()
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        
        let events = try await Event.query(on: req.db)
            .filter(\.$date >= now)
            .filter(\.$date <= nextWeek)
            .sort(\.$date, .ascending)
            .limit(20)
            .all()
        
        return events.map { EventListDTO(from: $0) }
    }
    
    // MARK: - Protected Endpoints
    
    @Sendable
    func createEvent(req: Request) async throws -> EventResponseDTO {
        try CreateEventDTO.validate(content: req)
        let createData = try req.content.decode(CreateEventDTO.self)
        
        let event = Event()
        event.title = createData.title
        event.description = createData.description
        event.fullDescription = createData.fullDescription
        event.date = createData.date
        event.time = createData.time
        event.duration = createData.duration
        event.location = createData.location
        event.address = createData.address
        event.category = createData.category
        event.price = createData.price
        event.capacity = createData.capacity
        event.availableTickets = createData.capacity
        event.organizer = createData.organizer
        event.isSponsored = createData.isSponsored ?? false
        event.requirements = createData.requirements ?? []
        event.includes = createData.includes ?? []
        event.tags = createData.tags ?? []
        event.imageName = createData.imageName
        
        try await event.save(on: req.db)
        return EventResponseDTO(from: event)
    }
    
    @Sendable
    func updateEvent(req: Request) async throws -> EventResponseDTO {
        guard let event = try await Event.find(req.parameters.get("eventID"), on: req.db) else {
            throw Abort(.notFound, reason: "Evento no encontrado")
        }
        
        let updateData = try req.content.decode(UpdateEventDTO.self)
        
        if let title = updateData.title {
            event.title = title
        }
        
        if let description = updateData.description {
            event.description = description
        }
        
        if let fullDescription = updateData.fullDescription {
            event.fullDescription = fullDescription
        }
        
        if let date = updateData.date {
            event.date = date
        }
        
        if let time = updateData.time {
            event.time = time
        }
        
        if let duration = updateData.duration {
            event.duration = duration
        }
        
        if let location = updateData.location {
            event.location = location
        }
        
        if let address = updateData.address {
            event.address = address
        }
        
        if let category = updateData.category {
            event.category = category
        }
        
        if let price = updateData.price {
            event.price = price
        }
        
        if let capacity = updateData.capacity {
            let ticketsSold = event.capacity - event.availableTickets
            event.capacity = capacity
            event.availableTickets = capacity - ticketsSold
        }
        
        if let organizer = updateData.organizer {
            event.organizer = organizer
        }
        
        if let isSponsored = updateData.isSponsored {
            event.isSponsored = isSponsored
        }
        
        if let requirements = updateData.requirements {
            event.requirements = requirements
        }
        
        if let includes = updateData.includes {
            event.includes = includes
        }
        
        if let tags = updateData.tags {
            event.tags = tags
        }
        
        if let imageName = updateData.imageName {
            event.imageName = imageName
        }
        
        try await event.save(on: req.db)
        return EventResponseDTO(from: event)
    }
    
    @Sendable
    func deleteEvent(req: Request) async throws -> HTTPStatus {
        guard let event = try await Event.find(req.parameters.get("eventID"), on: req.db) else {
            throw Abort(.notFound, reason: "Evento no encontrado")
        }
        
        try await event.delete(on: req.db)
        return .noContent
    }
    
    @Sendable
    func purchaseTicket(req: Request) async throws -> EventResponseDTO {
        guard let event = try await Event.find(req.parameters.get("eventID"), on: req.db) else {
            throw Abort(.notFound, reason: "Evento no encontrado")
        }
        
        struct TicketPurchase: Content {
            let quantity: Int
        }
        
        let purchaseData = try req.content.decode(TicketPurchase.self)
        
        guard purchaseData.quantity > 0 else {
            throw Abort(.badRequest, reason: "La cantidad debe ser mayor a 0")
        }
        
        guard event.availableTickets >= purchaseData.quantity else {
            throw Abort(.conflict, reason: "No hay suficientes tickets disponibles")
        }
        
        event.availableTickets -= purchaseData.quantity
        try await event.save(on: req.db)
        
        // Here you would typically create a ticket/order record
        // and possibly add points to the user
        
        return EventResponseDTO(from: event)
    }
    
    @Sendable
    func getMyEvents(req: Request) async throws -> [EventListDTO] {
        // This would typically return events the user has purchased tickets for
        // For now, we'll return events they might be interested in based on their profile
        
        let events = try await Event.query(on: req.db)
            .filter(\.$date >= Date())
            .sort(\.$date, .ascending)
            .limit(20)
            .all()
        
        return events.map { EventListDTO(from: $0) }
    }
}