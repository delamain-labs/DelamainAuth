import Foundation

// MARK: - Token

/// Represents an authentication token with optional refresh capability.
public struct Token: Codable, Sendable, Equatable {
    /// The access token string.
    public let accessToken: String

    /// The refresh token string, if available.
    public let refreshToken: String?

    /// The token type (e.g., "Bearer").
    public let tokenType: String

    /// When the access token expires, if known.
    public let expiresAt: Date?

    /// The scopes granted to this token.
    public let scopes: [String]

    /// Creates a new token.
    ///
    /// - Parameters:
    ///   - accessToken: The access token string.
    ///   - refreshToken: Optional refresh token for obtaining new access tokens.
    ///   - tokenType: The token type (default: "Bearer").
    ///   - expiresAt: When the token expires.
    ///   - scopes: The scopes granted to this token.
    public init(
        accessToken: String,
        refreshToken: String? = nil,
        tokenType: String = "Bearer",
        expiresAt: Date? = nil,
        scopes: [String] = []
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresAt = expiresAt
        self.scopes = scopes
    }

    /// Whether the token has expired.
    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() >= expiresAt
    }

    /// Whether the token will expire within the given time interval.
    ///
    /// - Parameter interval: The time interval to check.
    /// - Returns: True if the token will expire within the interval.
    public func willExpire(within interval: TimeInterval) -> Bool {
        guard let expiresAt else { return false }
        return Date().addingTimeInterval(interval) >= expiresAt
    }

    /// Whether this token can be refreshed.
    public var canRefresh: Bool {
        refreshToken != nil
    }

    /// The authorization header value for this token.
    public var authorizationHeader: String {
        "\(tokenType) \(accessToken)"
    }
}

// MARK: - Token Response

/// A response from a token endpoint, used for parsing OAuth responses.
public struct TokenResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let tokenType: String?
    public let expiresIn: Int?
    public let scope: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
    }

    /// Converts this response to a Token.
    public func toToken() -> Token {
        let expiresAt: Date? = expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
        let scopes = scope?.split(separator: " ").map(String.init) ?? []

        return Token(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType ?? "Bearer",
            expiresAt: expiresAt,
            scopes: scopes
        )
    }
}
