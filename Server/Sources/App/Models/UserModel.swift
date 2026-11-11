import Fluent
import Vapor

/// An account. Only a bcrypt hash of the password is stored, never the password itself.
final class UserModel: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id) var id: UUID?
    @Field(key: "email") var email: String
    @Field(key: "password_hash") var passwordHash: String

    init() {}

    init(email: String, passwordHash: String) {
        self.email = email
        self.passwordHash = passwordHash
    }
}

/// A refresh token the server has issued. Like passwords, only a hash is stored, so a leaked
/// database can't be used to sign in. Each token works once and is deleted when used.
final class RefreshTokenModel: Model, @unchecked Sendable {
    static let schema = "refresh_tokens"

    @ID(key: .id) var id: UUID?
    @Field(key: "user_id") var userID: UUID
    @Field(key: "token_hash") var tokenHash: String
    @Field(key: "expires_at") var expiresAt: Date

    init() {}

    init(userID: UUID, tokenHash: String, expiresAt: Date) {
        self.userID = userID
        self.tokenHash = tokenHash
        self.expiresAt = expiresAt
    }
}
