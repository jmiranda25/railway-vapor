//
//  CreateUser.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Foundation
import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("phone", .string)
            .field("avatar_url", .string)
            .field("membership_level", .string, .required)
            .field("points", .int, .required)
            .field("member_since", .datetime, .required)
            .field("email_verified", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}
