//
//   CreateEvent.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Foundation
import Fluent

struct CreateEvent: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("events")
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("full_description", .string)
            .field("date", .date, .required)
            .field("time", .string, .required)
            .field("duration", .string, .required)
            .field("location", .string, .required)
            .field("address", .string, .required)
            .field("category", .string, .required)
            .field("price", .double, .required)
            .field("capacity", .int, .required)
            .field("available_tickets", .int, .required)
            .field("organizer", .string, .required)
            .field("is_sponsored", .bool, .required)
            .field("requirements", .array(of: .string), .required)
            .field("includes", .array(of: .string), .required)
            .field("tags", .array(of: .string), .required)
            .field("image_name", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("events").delete()
    }
}
