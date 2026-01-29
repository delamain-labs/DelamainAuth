import Testing
import Foundation
@testable import DelamainAuth
import DelamainStorage

@Suite("AuthManager Tests", .serialized)
struct AuthManagerTests {

    // MARK: - Initial State

    @Test("Starts with no session")
    func startsWithNoSession() async {
        let manager = AuthManager(storage: InMemoryStorage())
        let session = await manager.currentSession
        #expect(session == nil)
    }

    @Test("Starts not authenticated")
    func startsNotAuthenticated() async {
        let manager = AuthManager(storage: InMemoryStorage())
        let isAuthenticated = await manager.isAuthenticated
        #expect(isAuthenticated == false)
    }

    // MARK: - Session Management

    @Test("Sets and gets session")
    func setsAndGetsSession() async throws {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)

        let retrieved = await manager.currentSession
        #expect(retrieved == session)
    }

    @Test("Is authenticated after setting session")
    func isAuthenticatedAfterSettingSession() async throws {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)

        let isAuthenticated = await manager.isAuthenticated
        #expect(isAuthenticated == true)
    }

    @Test("Sign out clears session")
    func signOutClearsSession() async throws {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)
        try await manager.signOut()

        let retrieved = await manager.currentSession
        #expect(retrieved == nil)
    }

    @Test("Not authenticated after sign out")
    func notAuthenticatedAfterSignOut() async throws {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)
        try await manager.signOut()

        let isAuthenticated = await manager.isAuthenticated
        #expect(isAuthenticated == false)
    }

    // MARK: - Token Access

    @Test("Gets current token when authenticated")
    func getsCurrentTokenWhenAuthenticated() async throws {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)

        let currentToken = try await manager.currentToken()
        #expect(currentToken == token)
    }

    @Test("Throws when getting token while not authenticated")
    func throwsWhenGettingTokenWhileNotAuthenticated() async throws {
        let manager = AuthManager(storage: InMemoryStorage())

        await #expect(throws: AuthError.self) {
            _ = try await manager.currentToken()
        }
    }

    @Test("Gets token expiration date")
    func getsTokenExpirationDate() async throws {
        let manager = AuthManager(storage: InMemoryStorage())
        let expiresAt = Date().addingTimeInterval(3600)
        let token = Token(accessToken: "access123", expiresAt: expiresAt)
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)

        let tokenExpiresAt = await manager.tokenExpiresAt
        #expect(tokenExpiresAt == expiresAt)
    }

    @Test("Token expiration is nil when not authenticated")
    func tokenExpirationIsNilWhenNotAuthenticated() async {
        let manager = AuthManager(storage: InMemoryStorage())
        let expiresAt = await manager.tokenExpiresAt
        #expect(expiresAt == nil)
    }

    // MARK: - User Info

    @Test("Gets user when authenticated")
    func getsUserWhenAuthenticated() async throws {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(accessToken: "access123")
        let user = AuthUser(id: "user123", email: "test@example.com")
        let session = AuthSession(token: token, provider: .apple, user: user)

        await manager.setSession(session)

        let currentUser = await manager.currentUser
        #expect(currentUser == user)
    }

    @Test("User is nil when not authenticated")
    func userIsNilWhenNotAuthenticated() async {
        let manager = AuthManager(storage: InMemoryStorage())
        let user = await manager.currentUser
        #expect(user == nil)
    }

    // MARK: - Provider Info

    @Test("Gets provider when authenticated")
    func getsProviderWhenAuthenticated() async throws {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)

        let provider = await manager.currentProvider
        #expect(provider == .apple)
    }

    @Test("Provider is nil when not authenticated")
    func providerIsNilWhenNotAuthenticated() async {
        let manager = AuthManager(storage: InMemoryStorage())
        let provider = await manager.currentProvider
        #expect(provider == nil)
    }

    // MARK: - Session Validity

    @Test("Session with valid token is valid")
    func sessionWithValidTokenIsValid() async {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(
            accessToken: "access123",
            expiresAt: Date().addingTimeInterval(3600)
        )
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)

        let hasValidSession = await manager.hasValidSession
        #expect(hasValidSession == true)
    }

    @Test("Session with expired token is not valid")
    func sessionWithExpiredTokenIsNotValid() async {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(
            accessToken: "access123",
            expiresAt: Date().addingTimeInterval(-60)
        )
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)

        let hasValidSession = await manager.hasValidSession
        #expect(hasValidSession == false)
    }

    // MARK: - Token Update

    @Test("Updates token in existing session")
    func updatesTokenInExistingSession() async throws {
        let manager = AuthManager(storage: InMemoryStorage())
        let oldToken = Token(accessToken: "old")
        let newToken = Token(accessToken: "new")
        let session = AuthSession(token: oldToken, provider: .apple)

        await manager.setSession(session)
        await manager.updateToken(newToken)

        let currentToken = try await manager.currentToken()
        #expect(currentToken.accessToken == "new")
    }

    @Test("Update token does nothing when not authenticated")
    func updateTokenDoesNothingWhenNotAuthenticated() async {
        let manager = AuthManager(storage: InMemoryStorage())
        let token = Token(accessToken: "test")

        await manager.updateToken(token)

        let session = await manager.currentSession
        #expect(session == nil)
    }
}
