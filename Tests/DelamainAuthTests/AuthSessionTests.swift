import Testing
import Foundation
@testable import DelamainAuth

@Suite("AuthSession Tests")
struct AuthSessionTests {

    // MARK: - Creation

    @Test("Creates session with all properties")
    func createsSessionWithAllProperties() {
        let token = Token(accessToken: "access123")
        let user = AuthUser(id: "user123", email: "test@example.com")
        let createdAt = Date()

        let session = AuthSession(
            id: "session123",
            token: token,
            provider: .apple,
            createdAt: createdAt,
            user: user
        )

        #expect(session.id == "session123")
        #expect(session.token == token)
        #expect(session.provider == .apple)
        #expect(session.createdAt == createdAt)
        #expect(session.user == user)
    }

    @Test("Creates session with defaults")
    func createsSessionWithDefaults() {
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .oauth)

        #expect(!session.id.isEmpty)
        #expect(session.token == token)
        #expect(session.provider == .oauth)
        #expect(session.user == nil)
    }

    // MARK: - Validity

    @Test("Session with valid token is valid")
    func sessionWithValidTokenIsValid() {
        let token = Token(
            accessToken: "access123",
            expiresAt: Date().addingTimeInterval(3600)
        )
        let session = AuthSession(token: token, provider: .apple)

        #expect(session.isValid == true)
    }

    @Test("Session with expired token is not valid")
    func sessionWithExpiredTokenIsNotValid() {
        let token = Token(
            accessToken: "access123",
            expiresAt: Date().addingTimeInterval(-60)
        )
        let session = AuthSession(token: token, provider: .apple)

        #expect(session.isValid == false)
    }

    // MARK: - Token Update

    @Test("Updates session with new token")
    func updatesSessionWithNewToken() {
        let oldToken = Token(accessToken: "old")
        let newToken = Token(accessToken: "new")
        let user = AuthUser(id: "user123")

        let session = AuthSession(
            id: "session123",
            token: oldToken,
            provider: .apple,
            user: user
        )

        let updated = session.withUpdatedToken(newToken)

        #expect(updated.id == "session123")
        #expect(updated.token == newToken)
        #expect(updated.provider == .apple)
        #expect(updated.user == user)
    }

    // MARK: - Codable

    @Test("Session is encodable and decodable")
    func sessionIsEncodableAndDecodable() throws {
        let token = Token(
            accessToken: "access123",
            expiresAt: Date(timeIntervalSince1970: 1000000)
        )
        let user = AuthUser(id: "user123", email: "test@example.com")
        let original = AuthSession(
            id: "session123",
            token: token,
            provider: .apple,
            createdAt: Date(timeIntervalSince1970: 999999),
            user: user
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AuthSession.self, from: data)

        #expect(decoded == original)
    }
}

@Suite("AuthProvider Tests")
struct AuthProviderTests {

    @Test("All providers have raw values")
    func allProvidersHaveRawValues() {
        #expect(AuthProvider.apple.rawValue == "apple")
        #expect(AuthProvider.oauth.rawValue == "oauth")
        #expect(AuthProvider.credentials.rawValue == "credentials")
        #expect(AuthProvider.biometric.rawValue == "biometric")
        #expect(AuthProvider.custom.rawValue == "custom")
    }

    @Test("Provider is codable")
    func providerIsCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for provider in AuthProvider.allCases {
            let data = try encoder.encode(provider)
            let decoded = try decoder.decode(AuthProvider.self, from: data)
            #expect(decoded == provider)
        }
    }
}

@Suite("AuthUser Tests")
struct AuthUserTests {

    @Test("Creates user with all properties")
    func createsUserWithAllProperties() {
        let user = AuthUser(
            id: "user123",
            email: "test@example.com",
            fullName: "John Doe",
            givenName: "John",
            familyName: "Doe"
        )

        #expect(user.id == "user123")
        #expect(user.email == "test@example.com")
        #expect(user.fullName == "John Doe")
        #expect(user.givenName == "John")
        #expect(user.familyName == "Doe")
    }

    @Test("Creates user with minimal properties")
    func createsUserWithMinimalProperties() {
        let user = AuthUser(id: "user123")

        #expect(user.id == "user123")
        #expect(user.email == nil)
        #expect(user.fullName == nil)
    }

    @Test("User is encodable and decodable")
    func userIsEncodableAndDecodable() throws {
        let original = AuthUser(
            id: "user123",
            email: "test@example.com",
            fullName: "John Doe"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AuthUser.self, from: data)

        #expect(decoded == original)
    }
}
