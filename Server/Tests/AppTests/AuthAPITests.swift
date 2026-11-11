import Foundation
import Testing
import VaporTesting
import FitTrackerAPI
@testable import App

/// Sign-in rules that protect accounts.
@Suite("Auth API")
struct AuthAPITests {

    @Test("A wrong password is refused, and so is an unknown email, with the same answer")
    func wrongPassword() async throws {
        try await withTestApp { app in
            _ = try await register(app, email: "a@example.com", password: "correct-horse-battery")

            for attempt in [
                Credentials(email: "a@example.com", password: "wrong-password-here"),
                Credentials(email: "nobody@example.com", password: "correct-horse-battery")
            ] {
                try await app.testing().test(.POST, "v1/auth/login", beforeRequest: { request in
                    try request.content.encode(attempt)
                }, afterResponse: { response async in
                    #expect(response.status == .unauthorized)
                })
            }

            try await app.testing().test(.POST, "v1/auth/login", beforeRequest: { request in
                try request.content.encode(Credentials(email: " A@Example.com ", password: "correct-horse-battery"))
            }, afterResponse: { response async in
                #expect(response.status == .ok, "email matching ignores case and surrounding spaces")
            })
        }
    }

    @Test("A refresh token works once; reusing it is refused")
    func refreshTokenIsSingleUse() async throws {
        try await withTestApp { app in
            let original = try await register(app, email: "a@example.com")
            var renewed: AuthResponse?

            try await app.testing().test(.POST, "v1/auth/refresh", beforeRequest: { request in
                try request.content.encode(RefreshRequest(refreshToken: original.refreshToken))
            }, afterResponse: { response async throws in
                #expect(response.status == .ok)
                renewed = try response.content.decode(AuthResponse.self)
            })
            #expect(renewed?.refreshToken != original.refreshToken)

            // The old token was spent by the refresh above.
            try await app.testing().test(.POST, "v1/auth/refresh", beforeRequest: { request in
                try request.content.encode(RefreshRequest(refreshToken: original.refreshToken))
            }, afterResponse: { response async in
                #expect(response.status == .unauthorized)
            })
        }
    }
}
