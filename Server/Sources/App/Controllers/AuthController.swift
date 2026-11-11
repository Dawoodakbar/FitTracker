import Crypto
import Fluent
import JWT
import Vapor
import FitTrackerAPI

/// `/v1/auth`: create an account, sign in, and renew tokens.
struct AuthController: RouteCollection {
    static let accessTokenLifetime: TimeInterval = 15 * 60
    static let refreshTokenLifetime: TimeInterval = 30 * 24 * 60 * 60

    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("v1", "auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
        auth.post("refresh", use: refresh)
    }

    func register(req: Request) async throws -> Response {
        let credentials = try req.content.decode(Credentials.self)
        let email = credentials.email.trimmingCharacters(in: .whitespaces).lowercased()

        guard email.count <= 254, email.contains("@"), email.contains(".") else {
            throw Abort(.unprocessableEntity, reason: "Enter a valid email address.")
        }
        // bcrypt only uses the first 72 bytes, so longer passwords would be silently truncated.
        guard (8...72).contains(credentials.password.utf8.count) else {
            throw Abort(.unprocessableEntity, reason: "The password must be 8 to 72 characters.")
        }
        guard try await UserModel.query(on: req.db).filter(\.$email == email).first() == nil else {
            throw Abort(.conflict, reason: "An account with this email already exists.")
        }

        let user = UserModel(email: email, passwordHash: try await req.password.async.hash(credentials.password))
        try await user.create(on: req.db)
        return try await issueTokens(for: user, on: req).encodeResponse(status: .created, for: req)
    }

    func login(req: Request) async throws -> AuthResponse {
        let credentials = try req.content.decode(Credentials.self)
        let email = credentials.email.trimmingCharacters(in: .whitespaces).lowercased()

        // Unknown email and wrong password give the same answer, so the endpoint can't be used
        // to find out which emails have accounts.
        guard
            let user = try await UserModel.query(on: req.db).filter(\.$email == email).first(),
            try await req.password.async.verify(credentials.password, created: user.passwordHash)
        else {
            throw Abort(.unauthorized, reason: "Wrong email or password.")
        }
        return try await issueTokens(for: user, on: req)
    }

    /// Trades a refresh token for a new pair. The old refresh token is deleted, so it works once:
    /// if a stolen one is used after the real app already refreshed, it's refused.
    func refresh(req: Request) async throws -> AuthResponse {
        let body = try req.content.decode(RefreshRequest.self)
        let hash = Self.hash(body.refreshToken)

        guard
            let stored = try await RefreshTokenModel.query(on: req.db).filter(\.$tokenHash == hash).first(),
            stored.expiresAt > .now,
            let user = try await UserModel.find(stored.userID, on: req.db)
        else {
            throw Abort(.unauthorized, reason: "Sign in again.")
        }
        try await stored.delete(on: req.db)
        return try await issueTokens(for: user, on: req)
    }

    // MARK: - Tokens

    private func issueTokens(for user: UserModel, on req: Request) async throws -> AuthResponse {
        let userID = try user.requireID()

        let accessToken = try await req.jwt.sign(AccessToken(
            subject: .init(value: userID.uuidString),
            expiration: .init(value: .now.addingTimeInterval(Self.accessTokenLifetime))
        ))

        // 32 random bytes: far too many possibilities to guess. Only its hash is stored.
        let refreshToken = Data([UInt8].random(count: 32)).base64EncodedString()
        try await RefreshTokenModel(
            userID: userID,
            tokenHash: Self.hash(refreshToken),
            expiresAt: .now.addingTimeInterval(Self.refreshTokenLifetime)
        ).create(on: req.db)

        return AuthResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: Int(Self.accessTokenLifetime)
        )
    }

    private static func hash(_ token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

extension Credentials: Content {}
extension RefreshRequest: Content {}
extension AuthResponse: Content {}
