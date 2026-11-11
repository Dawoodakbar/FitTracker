import JWT
import Vapor

/// The contents of an access token: who it's for (`subject` is the user's id) and when it expires.
/// The server signs it with a secret key; changing any byte invalidates the signature.
struct AccessToken: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try expiration.verifyNotExpired()
    }
}

/// The signed-in user for the current request, set by `AccessTokenMiddleware`.
struct AuthenticatedUser: Authenticatable {
    let id: UUID
}

/// Rejects requests without a valid, unexpired access token, and otherwise records who is calling.
struct AccessTokenMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let bearer = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Sign in to use this endpoint.")
        }
        let token: AccessToken
        do {
            token = try await request.jwt.verify(bearer.token, as: AccessToken.self)
        } catch {
            // The reason is deliberately vague: it doesn't tell an attacker whether a token
            // was malformed, forged or merely expired.
            throw Abort(.unauthorized, reason: "Invalid or expired token.")
        }
        guard let userID = UUID(uuidString: token.subject.value) else {
            throw Abort(.unauthorized, reason: "Invalid or expired token.")
        }
        request.auth.login(AuthenticatedUser(id: userID))
        return try await next.respond(to: request)
    }
}
