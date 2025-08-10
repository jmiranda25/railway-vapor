//
//  ProductDTO.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Vapor
import Fluent

struct CreateProductDTO: Content {
    let storeID: UUID
    let name: String
    let description: String
    let fullDescription: String?
    let category: FoodCategory
    let basePrice: Double
    let originalPrice: Double?
    let preparationTime: String?
    let calories: Int?
    let isOrganic: Bool?
    let isVegan: Bool?
    let isGlutenFree: Bool?
    let isSpicy: Bool?
    let isSponsored: Bool?
    let isAvailable: Bool?
    let stockQuantity: Int?
    let ingredients: [String]?
    let allergens: [String]?
    let tags: [String]?
    let imageName: String?
}

struct UpdateProductDTO: Content {
    let name: String?
    let description: String?
    let fullDescription: String?
    let category: FoodCategory?
    let basePrice: Double?
    let originalPrice: Double?
    let preparationTime: String?
    let calories: Int?
    let isOrganic: Bool?
    let isVegan: Bool?
    let isGlutenFree: Bool?
    let isSpicy: Bool?
    let isSponsored: Bool?
    let isAvailable: Bool?
    let stockQuantity: Int?
    let ingredients: [String]?
    let allergens: [String]?
    let tags: [String]?
    let imageName: String?
}

struct ProductResponseDTO: Content {
    let id: UUID
    let storeID: UUID
    let storeName: String?
    let name: String
    let description: String
    let fullDescription: String?
    let category: FoodCategory
    let basePrice: Double
    let originalPrice: Double?
    let rating: Double
    let reviewCount: Int
    let preparationTime: String
    let calories: Int?
    let isOrganic: Bool
    let isVegan: Bool
    let isGlutenFree: Bool
    let isSpicy: Bool
    let isSponsored: Bool
    let isAvailable: Bool
    let stockQuantity: Int?
    let ingredients: [String]
    let allergens: [String]
    let tags: [String]
    let imageName: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from product: Product, store: Store? = nil) {
        self.id = product.id!
        self.storeID = product.$store.id
        self.storeName = store?.name
        self.name = product.name
        self.description = product.description
        self.fullDescription = product.fullDescription
        self.category = product.category
        self.basePrice = product.basePrice
        self.originalPrice = product.originalPrice
        self.rating = product.rating
        self.reviewCount = product.reviewCount
        self.preparationTime = product.preparationTime
        self.calories = product.calories
        self.isOrganic = product.isOrganic
        self.isVegan = product.isVegan
        self.isGlutenFree = product.isGlutenFree
        self.isSpicy = product.isSpicy
        self.isSponsored = product.isSponsored
        self.isAvailable = product.isAvailable
        self.stockQuantity = product.stockQuantity
        self.ingredients = product.ingredients
        self.allergens = product.allergens
        self.tags = product.tags
        self.imageName = product.imageName
        self.createdAt = product.createdAt
        self.updatedAt = product.updatedAt
    }
}

struct ProductListDTO: Content {
    let id: UUID
    let storeID: UUID
    let storeName: String?
    let name: String
    let description: String
    let category: FoodCategory
    let basePrice: Double
    let originalPrice: Double?
    let rating: Double
    let reviewCount: Int
    let preparationTime: String
    let isOrganic: Bool
    let isVegan: Bool
    let isGlutenFree: Bool
    let isSpicy: Bool
    let isSponsored: Bool
    let isAvailable: Bool
    let imageName: String?
    
    init(from product: Product, store: Store? = nil) {
        self.id = product.id!
        self.storeID = product.$store.id
        self.storeName = store?.name
        self.name = product.name
        self.description = product.description
        self.category = product.category
        self.basePrice = product.basePrice
        self.originalPrice = product.originalPrice
        self.rating = product.rating
        self.reviewCount = product.reviewCount
        self.preparationTime = product.preparationTime
        self.isOrganic = product.isOrganic
        self.isVegan = product.isVegan
        self.isGlutenFree = product.isGlutenFree
        self.isSpicy = product.isSpicy
        self.isSponsored = product.isSponsored
        self.isAvailable = product.isAvailable
        self.imageName = product.imageName
    }
}

struct ProductSearchDTO: Content {
    let category: FoodCategory?
    let storeID: UUID?
    let minPrice: Double?
    let maxPrice: Double?
    let minRating: Double?
    let isOrganic: Bool?
    let isVegan: Bool?
    let isGlutenFree: Bool?
    let isSpicy: Bool?
    let isSponsored: Bool?
    let isAvailable: Bool?
    let maxCalories: Int?
    let maxPreparationTime: Int? // in minutes
    let ingredients: [String]?
    let excludeAllergens: [String]?
    let tags: [String]?
    let query: String? // text search
    let limit: Int?
    let offset: Int?
    let sortBy: ProductSortOption?
}

enum ProductSortOption: String, Content {
    case rating = "rating"
    case price = "price"
    case name = "name"
    case newest = "newest"
    case preparationTime = "preparation_time"
}

struct ProductRatingDTO: Content {
    let rating: Double
    let review: String?
}

struct ProductFilterDTO: Content {
    let dietary: DietaryFilter?
    let priceRange: PriceFilterRange?
    let features: FeatureFilter?
}

struct DietaryFilter: Content {
    let isOrganic: Bool?
    let isVegan: Bool?
    let isGlutenFree: Bool?
    let maxCalories: Int?
}

struct PriceFilterRange: Content {
    let min: Double?
    let max: Double?
}

struct FeatureFilter: Content {
    let isSpicy: Bool?
    let maxPreparationTime: Int?
    let minRating: Double?
}

extension CreateProductDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .count(...100))
        validations.add("description", as: String.self, is: !.empty && .count(...500))
        validations.add("basePrice", as: Double.self, is: .range(0...))
        validations.add("originalPrice", as: Double?.self, is: .nil || .range(0...))
        validations.add("calories", as: Int?.self, is: .nil || .range(0...))
        validations.add("stockQuantity", as: Int?.self, is: .nil || .range(0...))
    }
}

extension ProductRatingDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("rating", as: Double.self, is: .range(1...5))
    }
}