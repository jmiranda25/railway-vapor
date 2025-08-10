//
//  EventDTO.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Vapor
import Fluent

struct CreateEventDTO: Content {
    let title: String
    let description: String
    let fullDescription: String?
    let date: Date
    let time: String
    let duration: String
    let location: String
    let address: String
    let category: EventCategory
    let price: Double
    let capacity: Int
    let organizer: String
    let isSponsored: Bool?
    let requirements: [String]?
    let includes: [String]?
    let tags: [String]?
    let imageName: String?
}

struct UpdateEventDTO: Content {
    let title: String?
    let description: String?
    let fullDescription: String?
    let date: Date?
    let time: String?
    let duration: String?
    let location: String?
    let address: String?
    let category: EventCategory?
    let price: Double?
    let capacity: Int?
    let organizer: String?
    let isSponsored: Bool?
    let requirements: [String]?
    let includes: [String]?
    let tags: [String]?
    let imageName: String?
}

struct EventResponseDTO: Content {
    let id: UUID
    let title: String
    let description: String
    let fullDescription: String?
    let date: Date
    let time: String
    let duration: String
    let location: String
    let address: String
    let category: EventCategory
    let price: Double
    let capacity: Int
    let availableTickets: Int
    let organizer: String
    let isSponsored: Bool
    let requirements: [String]
    let includes: [String]
    let tags: [String]
    let imageName: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from event: Event) {
        self.id = event.id!
        self.title = event.title
        self.description = event.description
        self.fullDescription = event.fullDescription
        self.date = event.date
        self.time = event.time
        self.duration = event.duration
        self.location = event.location
        self.address = event.address
        self.category = event.category
        self.price = event.price
        self.capacity = event.capacity
        self.availableTickets = event.availableTickets
        self.organizer = event.organizer
        self.isSponsored = event.isSponsored
        self.requirements = event.requirements
        self.includes = event.includes
        self.tags = event.tags
        self.imageName = event.imageName
        self.createdAt = event.createdAt
        self.updatedAt = event.updatedAt
    }
}

struct EventListDTO: Content {
    let id: UUID
    let title: String
    let description: String
    let date: Date
    let time: String
    let location: String
    let category: EventCategory
    let price: Double
    let availableTickets: Int
    let organizer: String
    let isSponsored: Bool
    let imageName: String?
    
    init(from event: Event) {
        self.id = event.id!
        self.title = event.title
        self.description = event.description
        self.date = event.date
        self.time = event.time
        self.location = event.location
        self.category = event.category
        self.price = event.price
        self.availableTickets = event.availableTickets
        self.organizer = event.organizer
        self.isSponsored = event.isSponsored
        self.imageName = event.imageName
    }
}

struct EventSearchDTO: Content {
    let category: EventCategory?
    let location: String?
    let startDate: Date?
    let endDate: Date?
    let minPrice: Double?
    let maxPrice: Double?
    let isSponsored: Bool?
    let organizer: String?
    let tags: [String]?
    let limit: Int?
    let offset: Int?
}

extension CreateEventDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty && .count(...100))
        validations.add("description", as: String.self, is: !.empty && .count(...500))
        validations.add("time", as: String.self, is: !.empty)
        validations.add("duration", as: String.self, is: !.empty)
        validations.add("location", as: String.self, is: !.empty)
        validations.add("address", as: String.self, is: !.empty)
        validations.add("price", as: Double.self, is: .range(0...))
        validations.add("capacity", as: Int.self, is: .range(1...))
        validations.add("organizer", as: String.self, is: !.empty)
    }
}