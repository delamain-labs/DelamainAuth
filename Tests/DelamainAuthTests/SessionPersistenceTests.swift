import Testing
import Foundation
@testable import DelamainAuth
import DelamainStorage

@Suite("Session Persistence Tests", .serialized)
struct SessionPersistenceTests {

    // MARK: - Persist Session

    @Test("Persists session to storage")
    func persistsSessionToStorage() async throws {
        let storage = InMemoryStorage()
        let manager = AuthManager(storage: storage)

        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)

        await manager.setSession(session)
        try await manager.persistSession()

        // Verify session was stored
        let stored: AuthSession? = try await storage.get("com.delamain.auth.session")
        #expect(stored == session)
    }

    @Test("Persist session throws when not authenticated")
    func persistSessionThrowsWhenNotAuthenticated() async {
        let storage = InMemoryStorage()
        let manager = AuthManager(storage: storage)

        await #expect(throws: AuthError.self) {
            try await manager.persistSession()
        }
    }

    // MARK: - Load Session

    @Test("Loads session from storage")
    func loadsSessionFromStorage() async throws {
        let storage = InMemoryStorage()

        // Pre-populate storage with a session
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)
        try await storage.set(session, forKey: "com.delamain.auth.session")

        // Create manager and load
        let manager = AuthManager(storage: storage)
        let loaded = try await manager.loadSession()

        #expect(loaded == true)
        #expect(await manager.currentSession == session)
    }

    @Test("Load session returns false when no stored session")
    func loadSessionReturnsFalseWhenNoStoredSession() async throws {
        let storage = InMemoryStorage()
        let manager = AuthManager(storage: storage)

        let loaded = try await manager.loadSession()

        #expect(loaded == false)
        #expect(await manager.currentSession == nil)
    }

    @Test("Load session does not overwrite existing session")
    func loadSessionDoesNotOverwriteExistingSession() async throws {
        let storage = InMemoryStorage()

        // Pre-populate storage
        let storedToken = Token(accessToken: "stored")
        let storedSession = AuthSession(token: storedToken, provider: .oauth)
        try await storage.set(storedSession, forKey: "com.delamain.auth.session")

        // Create manager with existing session
        let manager = AuthManager(storage: storage)
        let currentToken = Token(accessToken: "current")
        let currentSession = AuthSession(token: currentToken, provider: .apple)
        await manager.setSession(currentSession)

        // Try to load - should not overwrite
        let loaded = try await manager.loadSession()

        #expect(loaded == false) // Returns false because session already exists
        #expect(await manager.currentSession == currentSession)
    }

    // MARK: - Clear Persisted Session

    @Test("Sign out clears persisted session")
    func signOutClearsPersistedSession() async throws {
        let storage = InMemoryStorage()
        let manager = AuthManager(storage: storage)

        // Set and persist session
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)
        await manager.setSession(session)
        try await manager.persistSession()

        // Sign out
        try await manager.signOut(clearPersisted: true)

        // Verify storage was cleared
        let stored: AuthSession? = try await storage.get("com.delamain.auth.session")
        #expect(stored == nil)
    }

    @Test("Sign out without clearing persisted keeps stored session")
    func signOutWithoutClearingPersistedKeepsStoredSession() async throws {
        let storage = InMemoryStorage()
        let manager = AuthManager(storage: storage)

        // Set and persist session
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)
        await manager.setSession(session)
        try await manager.persistSession()

        // Sign out without clearing persisted
        try await manager.signOut(clearPersisted: false)

        // Memory session should be cleared
        #expect(await manager.currentSession == nil)

        // But storage should still have the session
        let stored: AuthSession? = try await storage.get("com.delamain.auth.session")
        #expect(stored == session)
    }

    // MARK: - Auto-Load on Init

    @Test("Can initialize and load in one step")
    func canInitializeAndLoadInOneStep() async throws {
        let storage = InMemoryStorage()

        // Pre-populate storage
        let token = Token(accessToken: "access123")
        let session = AuthSession(token: token, provider: .apple)
        try await storage.set(session, forKey: "com.delamain.auth.session")

        // Create manager and load
        let manager = AuthManager(storage: storage)
        _ = try await manager.loadSession()

        #expect(await manager.isAuthenticated == true)
    }

    // MARK: - Expired Session Handling

    @Test("Loads expired session but marks as invalid")
    func loadsExpiredSessionButMarksAsInvalid() async throws {
        let storage = InMemoryStorage()

        // Pre-populate storage with expired session
        let token = Token(
            accessToken: "expired",
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        let session = AuthSession(token: token, provider: .apple)
        try await storage.set(session, forKey: "com.delamain.auth.session")

        // Create manager and load
        let manager = AuthManager(storage: storage)
        let loaded = try await manager.loadSession()

        #expect(loaded == true)
        #expect(await manager.isAuthenticated == true)
        #expect(await manager.hasValidSession == false) // Expired
    }
}
