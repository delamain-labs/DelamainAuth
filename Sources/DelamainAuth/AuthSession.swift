import Foundation

// MARK: - Auth Session

/// Represents an authenticated user session.
public struct AuthSession: Codable, Sendable, Equatable {
    /// Unique identifier for this session.
    public let id: String

    /// The authentication token.
    public let token: Token

    /// The authentication provider used.
    public let provider: AuthProvider

    /// When the session was created.
    public let createdAt: Date

    /// User information, if available.
    public let user: AuthUser?

    /// Creates a new auth session.
    ///
    /// - Parameters:
    ///   - id: Unique session identifier (defaults to UUID).
    ///   - token: The authentication token.
    ///   - provider: The provider used for authentication.
    ///   - createdAt: When the session was created (defaults to now).
    ///   - user: Optional user information.
    public init(
        id: String = UUID().uuidString,
        token: Token,
        provider: AuthProvider,
        createdAt: Date = Date(),
        user: AuthUser? = nil
    ) {
        self.id = id
        self.token = token
        self.provider = provider
        self.createdAt = createdAt
        self.user = user
    }

    /// Whether the session is still valid (token not expired).
    public var isValid: Bool {
        !token.isExpired
    }

    /// Updates the session with a new token.
    ///
    /// - Parameter newToken: The new token.
    /// - Returns: A new session with the updated token.
    public func withUpdatedToken(_ newToken: Token) -> AuthSession {
        AuthSession(
            id: id,
            token: newToken,
            provider: provider,
            createdAt: createdAt,
            user: user
        )
    }
}

// MARK: - Auth Provider

/// The authentication provider used for sign-in.
public enum AuthProvider: String, Codable, Sendable, CaseIterable {
    /// Apple Sign-In.
    case apple

    /// OAuth 2.0 / OpenID Connect.
    case oauth

    /// Username/password credentials.
    case credentials

    /// Biometric authentication (local only, no remote auth).
    case biometric

    /// Custom provider.
    case custom
}

// MARK: - Auth User

/// Basic user information from authentication.
public struct AuthUser: Codable, Sendable, Equatable {
    /// User identifier from the auth provider.
    public let id: String

    /// User's email address, if available.
    public let email: String?

    /// User's full name, if available.
    public let fullName: String?

    /// User's given (first) name, if available.
    public let givenName: String?

    /// User's family (last) name, if available.
    public let familyName: String?

    /// Creates a new auth user.
    public init(
        id: String,
        email: String? = nil,
        fullName: String? = nil,
        givenName: String? = nil,
        familyName: String? = nil
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.givenName = givenName
        self.familyName = familyName
    }
}
