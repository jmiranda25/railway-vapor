//
//  StoreDTO.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Vapor
import Fluent

struct CreateStoreDTO: Content {
    let name: String
    let description: String
    let category: FoodCategory
    let deliveryTime: String
    let address: String
    let phone: String?
    let isOpen: Bool?
    let latitude: Double?
    let longitude: Double?
    let specialties: [String]?
    let features: [String]?
    let priceRange: PriceRange?
    let imageName: String?
    let backgroundColor: String?
}

struct UpdateStoreDTO: Content {
    let name: String?
    let description: String?
    let category: FoodCategory?
    let deliveryTime: String?
    let address: String?
    let phone: String?
    let isOpen: Bool?
    let latitude: Double?
    let longitude: Double?
    let specialties: [String]?
    let features: [String]?
    let priceRange: PriceRange?
    let imageName: String?
    let backgroundColor: String?
}

struct StoreResponseDTO: Content {
    let id: UUID
    let name: String
    let description: String
    let category: FoodCategory
    let rating: Double
    let reviewCount: Int
    let deliveryTime: String
    let address: String
    let phone: String?
    let isOpen: Bool
    let latitude: Double?
    let longitude: Double?
    let specialties: [String]
    let features: [String]
    let priceRange: PriceRange
    let imageName: String?
    let backgroundColor: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from store: Store) {
        self.id = store.id!
        self.name = store.name
        self.description = store.description
        self.category = store.category
        self.rating = store.rating
        self.reviewCount = store.reviewCount
        self.deliveryTime = store.deliveryTime
        self.address = store.address
        self.phone = store.phone
        self.isOpen = store.isOpen
        self.latitude = store.latitude
        self.longitude = store.longitude
        self.specialties = store.specialties
        self.features = store.features
        self.priceRange = store.priceRange
        self.imageName = store.imageName
        self.backgroundColor = store.backgroundColor
        self.createdAt = store.createdAt
        self.updatedAt = store.updatedAt
    }
}

struct StoreListDTO: Content {
    let id: UUID
    let name: String
    let description: String
    let category: FoodCategory
    let rating: Double
    let reviewCount: Int
    let deliveryTime: String
    let address: String
    let isOpen: Bool
    let priceRange: PriceRange
    let imageName: String?
    let backgroundColor: String?
    
    init(from store: Store) {
        self.id = store.id!
        self.name = store.name
        self.description = store.description
        self.category = store.category
        self.rating = store.rating
        self.reviewCount = store.reviewCount
        self.deliveryTime = store.deliveryTime
        self.address = store.address
        self.isOpen = store.isOpen
        self.priceRange = store.priceRange
        self.imageName = store.imageName
        self.backgroundColor = store.backgroundColor
    }
}

struct StoreSearchDTO: Content {
    let category: FoodCategory?
    let location: String?
    let isOpen: Bool?
    let minRating: Double?
    let maxDeliveryTime: Int? // in minutes
    let priceRange: PriceRange?
    let features: [String]?
    let specialties: [String]?
    let latitude: Double?
    let longitude: Double?
    let radius: Double? // in kilometers
    let limit: Int?
    let offset: Int?
}

struct StoreRatingDTO: Content {
    let rating: Double
    let review: String?
}

extension CreateStoreDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(...100))
        validations.add("description", as: String.self, is: !.empty && .count(...500))
        validations.add("deliveryTime", as: String.self, is: !.empty)
        validations.add("address", as: String.self, is: !.empty)
        validations.add("latitude", as: Double?.self, is: .nil || .range(-90...90))
        validations.add("longitude", as: Double?.self, is: .nil || .range(-180...180))
    }
}

extension StoreRatingDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("rating", as: Double.self, is: .range(1...5))
    }
}