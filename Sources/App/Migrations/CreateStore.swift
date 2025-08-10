//
//  CreateStore.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Foundation
import Fluent

struct CreateStore: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("stores")
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("category", .string, .required)
            .field("rating", .double, .required)
            .field("review_count", .int, .required)
            .field("delivery_time", .string, .required)
            .field("address", .string, .required)
            .field("phone", .string)
            .field("is_open", .bool, .required)
            .field("latitude", .double)
            .field("longitude", .double)
            .field("specialties", .array(of: .string), .required)
            .field("features", .array(of: .string), .required)
            .field("price_range", .string, .required)
            .field("image_name", .string)
            .field("background_color", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("stores").delete()
    }
}
