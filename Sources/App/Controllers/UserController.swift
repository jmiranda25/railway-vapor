//
//  UserController.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Fluent
import Vapor
import JWT

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        
        // Public routes
        users.post("register", use: register)
        users.post("login", use: login)
        
        // Protected routes
        let protected = users.grouped(JWTAuthenticator())
        let authenticated = protected.grouped(User.guardMiddleware())
        
        authenticated.get("profile", use: getProfile)
        authenticated.put("profile", use: updateProfile)
        authenticated.put("change-password", use: changePassword)
        authenticated.delete("account", use: deleteAccount)
        authenticated.post("verify-email", use: verifyEmail)
        authenticated.put("membership", use: updateMembership)
        authenticated.get("points", use: getPoints)
        authenticated.post("points", "add", use: addPoints)
    }
    
    // MARK: - Public Endpoints
    
    @Sendable
    func register(req: Request) async throws -> LoginResponseDTO {
        try RegisterUserDTO.validate(content: req)
        let registerData = try req.content.decode(RegisterUserDTO.self)
        
        // Verificar que el email no existe
        let existingUser = try await User.query(on: req.db)
            .filter(\.$email == registerData.email.lowercased())
            .first()
        
        if existingUser != nil {
            throw Abort(.conflict, reason: "Un usuario con este email ya existe")
        }
        
        // Crear nuevo usuario
        let user = try User.create(from: registerData)
        try await user.save(on: req.db)
        
        // Generar token
        let token = try user.generateToken(app: req.application)
        
        return LoginResponseDTO(
            user: UserResponseDTO(from: user),
            token: token
        )
    }
    
    @Sendable
    func login(req: Request) async throws -> LoginResponseDTO {
        let loginData = try req.content.decode(LoginUserDTO.self)
        
        // Buscar usuario
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginData.email.lowercased())
            .first() else {
            throw Abort(.unauthorized, reason: "Email o contraseña incorrectos")
        }
        
        // Verificar contraseña
        guard try user.verifyPassword(loginData.password) else {
            throw Abort(.unauthorized, reason: "Email o contraseña incorrectos")
        }
        
        // Generar token
        let token = try user.generateToken(app: req.application)
        
        return LoginResponseDTO(
            user: UserResponseDTO(from: user),
            token: token
        )
    }
    
    // MARK: - Protected Endpoints
    
    @Sendable
    func getProfile(req: Request) async throws -> UserResponseDTO {
        let user = try req.auth.require(User.self)
        return UserResponseDTO(from: user)
    }
    
    @Sendable
    func updateProfile(req: Request) async throws -> UserResponseDTO {
        let user = try req.auth.require(User.self)
        let updateData = try req.content.decode(UpdateUserDTO.self)
        
        if let firstName = updateData.firstName {
            user.firstName = firstName
        }
        
        if let lastName = updateData.lastName {
            user.lastName = lastName
        }
        
        if let phone = updateData.phone {
            user.phone = phone
        }
        
        if let avatarURL = updateData.avatarURL {
            user.avatarURL = avatarURL
        }
        
        try await user.save(on: req.db)
        return UserResponseDTO(from: user)
    }
    
    @Sendable
    func changePassword(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let changeData = try req.content.decode(ChangePasswordDTO.self)
        
        // Verificar contraseña actual
        guard try user.verifyPassword(changeData.currentPassword) else {
            throw Abort(.unauthorized, reason: "La contraseña actual es incorrecta")
        }
        
        // Validar nueva contraseña
        guard changeData.newPassword == changeData.confirmPassword else {
            throw Abort(.badRequest, reason: "Las nuevas contraseñas no coinciden")
        }
        
        guard changeData.newPassword.count >= 8 else {
            throw Abort(.badRequest, reason: "La nueva contraseña debe tener al menos 8 caracteres")
        }
        
        // Hash nueva contraseña y guardar
        user.passwordHash = try Bcrypt.hash(changeData.newPassword)
        try await user.save(on: req.db)
        
        return .ok
    }
    
    @Sendable
    func deleteAccount(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        try await user.delete(on: req.db)
        return .noContent
    }
    
    @Sendable
    func verifyEmail(req: Request) async throws -> UserResponseDTO {
        let user = try req.auth.require(User.self)
        user.emailVerified = true
        try await user.save(on: req.db)
        return UserResponseDTO(from: user)
    }
    
    @Sendable
    func updateMembership(req: Request) async throws -> UserResponseDTO {
        let user = try req.auth.require(User.self)
        
        struct MembershipUpdate: Content {
            let membershipLevel: MembershipLevel
        }
        
        let membershipData = try req.content.decode(MembershipUpdate.self)
        user.membershipLevel = membershipData.membershipLevel
        
        try await user.save(on: req.db)
        return UserResponseDTO(from: user)
    }
    
    @Sendable
    func getPoints(req: Request) async throws -> [String: Int] {
        let user = try req.auth.require(User.self)
        return ["points": user.points]
    }
    
    @Sendable
    func addPoints(req: Request) async throws -> UserResponseDTO {
        let user = try req.auth.require(User.self)
        
        struct PointsAdd: Content {
            let points: Int
            let reason: String?
        }
        
        let pointsData = try req.content.decode(PointsAdd.self)
        
        guard pointsData.points > 0 else {
            throw Abort(.badRequest, reason: "Los puntos deben ser positivos")
        }
        
        user.points += pointsData.points
        try await user.save(on: req.db)
        
        return UserResponseDTO(from: user)
    }
}

// MARK: - Validations

extension RegisterUserDTO: Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("firstName", as: String.self, is: !.empty)
        validations.add("lastName", as: String.self, is: !.empty)
    }
}