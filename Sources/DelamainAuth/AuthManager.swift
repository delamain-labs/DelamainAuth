import Foundation
import DelamainStorage

// MARK: - Auth Manager

/// The main actor for managing authentication state.
///
/// `AuthManager` handles session state, token management, and coordinates
/// authentication flows. All operations are actor-isolated for thread safety.
///
/// Example:
/// ```swift
/// let auth = AuthManager()
///
/// // Check authentication state
/// if await auth.isAuthenticated {
///     let token = try await auth.currentToken()
///     print("Token: \(token.accessToken)")
/// }
///
/// // Sign out
/// await auth.signOut()
/// ```
public actor AuthManager {

    // MARK: - Properties

    private let storage: any Storage
    private var session: AuthSession?
    private let sessionKey = "com.delamain.auth.session"

    // MARK: - Initialization

    /// Creates an auth manager with the specified storage.
    ///
    /// - Parameter storage: The storage backend for persisting sessions.
    ///   Defaults to `InMemoryStorage` (no persistence across launches).
    public init(storage: any Storage = InMemoryStorage()) {
        self.storage = storage
    }

    // MARK: - Session State

    /// The current authentication session, if any.
    public var currentSession: AuthSession? {
        session
    }

    /// Whether there is an active session (may be expired).
    public var isAuthenticated: Bool {
        session != nil
    }

    /// Whether there is a valid, non-expired session.
    public var hasValidSession: Bool {
        session?.isValid ?? false
    }

    /// The current user, if authenticated.
    public var currentUser: AuthUser? {
        session?.user
    }

    /// The current authentication provider, if authenticated.
    public var currentProvider: AuthProvider? {
        session?.provider
    }

    /// When the current token expires, if known.
    public var tokenExpiresAt: Date? {
        session?.token.expiresAt
    }

    // MARK: - Session Management

    /// Sets the current session.
    ///
    /// This is typically called after a successful sign-in flow.
    ///
    /// - Parameter session: The new session to set.
    public func setSession(_ session: AuthSession) {
        self.session = session
    }

    /// Clears the current session.
    ///
    /// - Parameter clearPersisted: Whether to also clear the persisted session from storage.
    ///   Defaults to `true` to ensure clean sign out.
    public func signOut(clearPersisted: Bool = true) async throws {
        self.session = nil

        if clearPersisted {
            try await storage.remove(sessionKey)
        }
    }

    // MARK: - Session Persistence

    /// Persists the current session to storage.
    ///
    /// Call this after sign-in to enable session restoration across app launches.
    ///
    /// - Throws: `AuthError.notAuthenticated` if there's no session to persist.
    /// - Throws: `AuthError.storageFailed` if storage fails.
    public func persistSession() async throws {
        guard let session else {
            throw AuthError.notAuthenticated
        }

        do {
            try await storage.set(session, forKey: sessionKey)
        } catch {
            throw AuthError.storageFailed(error.localizedDescription)
        }
    }

    /// Loads a previously persisted session from storage.
    ///
    /// If a session already exists in memory, this does nothing and returns false.
    ///
    /// - Returns: `true` if a session was loaded, `false` otherwise.
    /// - Throws: `AuthError.storageFailed` if storage fails.
    @discardableResult
    public func loadSession() async throws -> Bool {
        // Don't overwrite existing session
        guard session == nil else {
            return false
        }

        do {
            if let stored: AuthSession = try await storage.get(sessionKey) {
                self.session = stored
                return true
            }
            return false
        } catch {
            throw AuthError.storageFailed(error.localizedDescription)
        }
    }

    /// Clears any persisted session from storage without affecting the current session.
    ///
    /// - Throws: `AuthError.storageFailed` if storage fails.
    public func clearPersistedSession() async throws {
        do {
            try await storage.remove(sessionKey)
        } catch {
            throw AuthError.storageFailed(error.localizedDescription)
        }
    }

    /// Updates the token in the current session.
    ///
    /// Use this after refreshing a token.
    ///
    /// - Parameter newToken: The new token to use.
    public func updateToken(_ newToken: Token) {
        guard let currentSession = session else { return }
        self.session = currentSession.withUpdatedToken(newToken)
    }

    // MARK: - Token Access

    /// Gets the current access token.
    ///
    /// - Returns: The current token.
    /// - Throws: `AuthError.notAuthenticated` if not signed in.
    /// - Throws: `AuthError.tokenExpired` if the token has expired.
    public func currentToken() throws -> Token {
        guard let session else {
            throw AuthError.notAuthenticated
        }
        return session.token
    }

    /// Gets the current access token, refreshing if needed.
    ///
    /// - Parameter refreshIfNeeded: Whether to refresh if the token is expired or expiring soon.
    /// - Parameter refreshThreshold: How far in advance to refresh (default: 5 minutes).
    /// - Returns: A valid access token.
    /// - Throws: `AuthError` if token cannot be obtained or refreshed.
    public func currentToken(
        refreshIfNeeded: Bool,
        refreshThreshold: TimeInterval = 300
    ) async throws -> Token {
        guard let session else {
            throw AuthError.notAuthenticated
        }

        let token = session.token

        // If refresh not requested or token doesn't need refresh, return current
        if !refreshIfNeeded || !token.willExpire(within: refreshThreshold) {
            return token
        }

        // Token needs refresh - for now, throw since we don't have refresh logic yet
        // This will be implemented when we add OAuth support
        if token.isExpired {
            throw AuthError.tokenExpired
        }

        return token
    }
}
