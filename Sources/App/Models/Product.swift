//
//  Product.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Vapor
import Fluent

final class Product: Model, Content, @unchecked Sendable {
    static let schema = "products"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "store_id")
    var store: Store

    @Field(key: "name")
    var name: String

    @Field(key: "description")
    var description: String

    @OptionalField(key: "full_description")
    var fullDescription: String?

    @Enum(key: "category")
    var category: FoodCategory

    @Field(key: "base_price")
    var basePrice: Double

    @OptionalField(key: "original_price")
    var originalPrice: Double?

    @Field(key: "rating")
    var rating: Double

    @Field(key: "review_count")
    var reviewCount: Int

    @Field(key: "preparation_time")
    var preparationTime: String

    @OptionalField(key: "calories")
    var calories: Int?

    @Field(key: "is_organic")
    var isOrganic: Bool

    @Field(key: "is_vegan")
    var isVegan: Bool

    @Field(key: "is_gluten_free")
    var isGlutenFree: Bool

    @Field(key: "is_spicy")
    var isSpicy: Bool

    @Field(key: "is_sponsored")
    var isSponsored: Bool

    @Field(key: "is_available")
    var isAvailable: Bool

    @OptionalField(key: "stock_quantity")
    var stockQuantity: Int?

    @Field(key: "ingredients")
    var ingredients: [String]

    @Field(key: "allergens")
    var allergens: [String]

    @Field(key: "tags")
    var tags: [String]

    @OptionalField(key: "image_name")
    var imageName: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, storeID: UUID, name: String, description: String, category: FoodCategory, basePrice: Double, isAvailable: Bool = true) {
        self.id = id
        self.$store.id = storeID
        self.name = name
        self.description = description
        self.category = category
        self.basePrice = basePrice
        self.rating = 0.0
        self.reviewCount = 0
        self.preparationTime = "15 min"
        self.isOrganic = false
        self.isVegan = false
        self.isGlutenFree = false
        self.isSpicy = false
        self.isSponsored = false
        self.isAvailable = isAvailable
        self.ingredients = []
        self.allergens = []
        self.tags = []
    }
}
