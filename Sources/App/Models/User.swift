//
//  User.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Fluent
import Vapor
import JWT

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @OptionalField(key: "phone")
    var phone: String?

    @OptionalField(key: "avatar_url")
    var avatarURL: String?

    @Enum(key: "membership_level")
    var membershipLevel: MembershipLevel

    @Field(key: "points")
    var points: Int

    @Field(key: "member_since")
    var memberSince: Date

    @Field(key: "email_verified")
    var emailVerified: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, email: String, passwordHash: String, firstName: String, lastName: String, phone: String? = nil, membershipLevel: MembershipLevel = .silver) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.membershipLevel = membershipLevel
        self.points = 0
        self.memberSince = Date()
        self.emailVerified = false
    }
}

enum MembershipLevel: String, CaseIterable, Codable {
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
}

extension User {
    struct Public: Content {
        let id: UUID?
        let email: String
        let firstName: String
        let lastName: String
        let phone: String?
        let avatarURL: String?
        let membershipLevel: MembershipLevel
        let points: Int
        let memberSince: Date
        let emailVerified: Bool
        let createdAt: Date?
    }

    func toPublic() -> Public {
        return Public(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            avatarURL: avatarURL,
            membershipLevel: membershipLevel,
            points: points,
            memberSince: memberSince,
            emailVerified: emailVerified,
            createdAt: createdAt
        )
    }
    
    static func create(from register: RegisterUserDTO) throws -> User {
        guard register.password == register.confirmPassword else {
            throw Abort(.badRequest, reason: "Las contraseñas no coinciden")
        }
        
        guard register.password.count >= 8 else {
            throw Abort(.badRequest, reason: "La contraseña debe tener al menos 8 caracteres")
        }
        
        let hashedPassword = try Bcrypt.hash(register.password)
        
        return User(
            email: register.email,
            passwordHash: hashedPassword,
            firstName: register.firstName,
            lastName: register.lastName,
            phone: register.phone
        )
    }
    
    func generateToken(app: Application) throws -> String {
        let payload = UserToken(userID: self.id!)
        return try app.jwt.signers.sign(payload)
    }
    
    func verifyPassword(_ password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> {
        \User.$email
    }
    
    static var passwordHashKey: KeyPath<User, Field<String>> {
        \User.$passwordHash
    }

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
