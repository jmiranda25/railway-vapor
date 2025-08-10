//
//  UserToken.swift
//  App
//
//  Created by Jhon Miranda on 10/08/25.
//

import Vapor
import JWT

struct UserToken: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var issuedAt: IssuedAtClaim
    
    init(userID: UUID) {
        self.subject = SubjectClaim(value: userID.uuidString)
        self.issuedAt = IssuedAtClaim(value: Date())
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(60 * 60 * 24 * 7)) // 7 days
    }
    
    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}