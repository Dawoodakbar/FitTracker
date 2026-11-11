import Foundation

/// Body of `POST /v1/auth/register` and `POST /v1/auth/login`.
public struct Credentials: Codable, Equatable, Sendable {
    public var email: String
    public var password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

/// Body of `POST /v1/auth/refresh`.
public struct RefreshRequest: Codable, Equatable, Sendable {
    public var refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

/// The reply to register, login and refresh.
///
/// The app sends `accessToken` with every request (`Authorization: Bearer …`). It's short-lived,
/// so a stolen one stops working quickly. `refreshToken` lasts longer, is single-use, and is
/// exchanged for a fresh pair. It belongs in the Keychain.
public struct AuthResponse: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String
    /// Seconds until `accessToken` expires.
    public var expiresIn: Int

    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}
