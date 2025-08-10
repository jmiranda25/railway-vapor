//
//  Store.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Fluent
import Vapor

final class Store: Model, Content, @unchecked Sendable {
    static let schema = "stores"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "description")
    var description: String

    @Enum(key: "category")
    var category: FoodCategory

    @Field(key: "rating")
    var rating: Double

    @Field(key: "review_count")
    var reviewCount: Int

    @Field(key: "delivery_time")
    var deliveryTime: String

    @Field(key: "address")
    var address: String

    @OptionalField(key: "phone")
    var phone: String?

    @Field(key: "is_open")
    var isOpen: Bool

    @OptionalField(key: "latitude")
    var latitude: Double?

    @OptionalField(key: "longitude")
    var longitude: Double?

    @Field(key: "specialties")
    var specialties: [String]

    @Field(key: "features")
    var features: [String]

    @Enum(key: "price_range")
    var priceRange: PriceRange

    @OptionalField(key: "image_name")
    var imageName: String?

    @OptionalField(key: "background_color")
    var backgroundColor: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, name: String, description: String, category: FoodCategory, rating: Double = 0.0, reviewCount: Int = 0, deliveryTime: String, address: String, phone: String? = nil, isOpen: Bool = true, priceRange: PriceRange = .moderate, specialties: [String] = [], features: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.rating = rating
        self.reviewCount = reviewCount
        self.deliveryTime = deliveryTime
        self.address = address
        self.phone = phone
        self.isOpen = isOpen
        self.priceRange = priceRange
        self.specialties = specialties
        self.features = features
    }
}

enum FoodCategory: String, CaseIterable, Codable {
    case pizza = "pizza"
    case sushi = "sushi"
    case sandwich = "sandwich"
    case grocery = "grocery"
    case healthy = "healthy"
    case burger = "burger"
    case bebidas = "bebidas"
    case alimentos = "alimentos"
    case cocteles = "cocteles"
    case promociones = "promociones"
}

enum PriceRange: String, CaseIterable, Codable {
    case budget = "$"
    case moderate = "$$"
    case expensive = "$$$"
    case luxury = "$$$$"
}
