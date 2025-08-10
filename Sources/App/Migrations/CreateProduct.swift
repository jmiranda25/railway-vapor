//
//  CreateProduct.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Fluent

struct CreateProduct: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("products")
            .id()
            .field("store_id", .uuid, .required, .references("stores", "id"))
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("full_description", .string)
            .field("category", .string, .required)
            .field("base_price", .double, .required)
            .field("original_price", .double)
            .field("rating", .double, .required)
            .field("review_count", .int, .required)
            .field("preparation_time", .string, .required)
            .field("calories", .int)
            .field("is_organic", .bool, .required)
            .field("is_vegan", .bool, .required)
            .field("is_gluten_free", .bool, .required)
            .field("is_spicy", .bool, .required)
            .field("is_sponsored", .bool, .required)
            .field("is_available", .bool, .required)
            .field("stock_quantity", .int)
            .field("ingredients", .array(of: .string), .required)
            .field("allergens", .array(of: .string), .required)
            .field("tags", .array(of: .string), .required)
            .field("image_name", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("products").delete()
    }
}
