//
//  JWTAuthenticator.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Vapor
import JWT
import Fluent

struct JWTAuthenticator: AsyncRequestAuthenticator {
    typealias User = App.User
    
    func authenticate(request: Request) async throws {
        guard let bearerAuthorization = request.headers.bearerAuthorization else {
            return
        }
        
        do {
            let payload = try request.jwt.verify(bearerAuthorization.token, as: UserToken.self)
            
            guard let userID = UUID(uuidString: payload.subject.value) else {
                throw JWTError.claimVerificationFailure(name: "sub", reason: "Invalid UUID")
            }
            
            if let user = try await User.find(userID, on: request.db) {
                request.auth.login(user)
            }
        } catch {
            // Token is invalid, but don't throw an error
            // Let the protected route handler decide what to do
            return
        }
    }
}

extension User: JWTPayload {
    func verify(using signer: JWTSigner) throws {
        // Basic verification - can add more checks here
    }
}