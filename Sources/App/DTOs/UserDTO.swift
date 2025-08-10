//
//  UserDTO.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Vapor
import Fluent

struct RegisterUserDTO: Content {
    let email: String
    let password: String
    let confirmPassword: String
    let firstName: String
    let lastName: String
    let phone: String?
}

struct LoginUserDTO: Content {
    let email: String
    let password: String
}

struct UserResponseDTO: Content {
    let id: UUID
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
    
    init(from user: User) {
        self.id = user.id!
        self.email = user.email
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.phone = user.phone
        self.avatarURL = user.avatarURL
        self.membershipLevel = user.membershipLevel
        self.points = user.points
        self.memberSince = user.memberSince
        self.emailVerified = user.emailVerified
        self.createdAt = user.createdAt
    }
}

struct LoginResponseDTO: Content {
    let user: UserResponseDTO
    let token: String
}

struct UpdateUserDTO: Content {
    let firstName: String?
    let lastName: String?
    let phone: String?
    let avatarURL: String?
}

struct ChangePasswordDTO: Content {
    let currentPassword: String
    let newPassword: String
    let confirmPassword: String
}