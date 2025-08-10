//
//  Event.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Foundation
import Fluent
import Vapor

final class Event: Model, Content, @unchecked Sendable {
    static let schema = "events"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "description")
    var description: String

    @OptionalField(key: "full_description")
    var fullDescription: String?

    @Field(key: "date")
    var date: Date

    @Field(key: "time")
    var time: String

    @Field(key: "duration")
    var duration: String

    @Field(key: "location")
    var location: String

    @Field(key: "address")
    var address: String

    @Enum(key: "category")
    var category: EventCategory

    @Field(key: "price")
    var price: Double

    @Field(key: "capacity")
    var capacity: Int

    @Field(key: "available_tickets")
    var availableTickets: Int

    @Field(key: "organizer")
    var organizer: String

    @Field(key: "is_sponsored")
    var isSponsored: Bool

    @Field(key: "requirements")
    var requirements: [String]

    @Field(key: "includes")
    var includes: [String]

    @Field(key: "tags")
    var tags: [String]

    @OptionalField(key: "image_name")
    var imageName: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, title: String, description: String, date: Date, time: String, duration: String, location: String, address: String, category: EventCategory, price: Double, capacity: Int, organizer: String, isSponsored: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.time = time
        self.duration = duration
        self.location = location
        self.address = address
        self.category = category
        self.price = price
        self.capacity = capacity
        self.availableTickets = capacity
        self.organizer = organizer
        self.isSponsored = isSponsored
        self.requirements = []
        self.includes = []
        self.tags = []
    }
}

enum EventCategory: String, CaseIterable, Codable {
    case gastronomico = "gastronomico"
    case bebidas = "bebidas"
    case educativo = "educativo"
    case cultural = "cultural"
    case networking = "networking"
    case entretenimiento = "entretenimiento"
}
