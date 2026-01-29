import Foundation

// MARK: - OAuth Config

/// Configuration for OAuth 2.0 authentication.
public struct OAuthConfig: Sendable {
    /// The OAuth client identifier.
    public let clientID: String

    /// The OAuth client secret (optional, not recommended for mobile apps).
    public let clientSecret: String?

    /// The authorization endpoint URL.
    public let authorizationURL: URL

    /// The token exchange endpoint URL.
    public let tokenURL: URL

    /// The redirect URL for the OAuth callback.
    public let redirectURL: URL

    /// The requested OAuth scopes.
    public let scopes: [String]

    /// Additional parameters to include in the authorization request.
    public let additionalParameters: [String: String]

    /// Whether to use PKCE (recommended for mobile apps).
    public let usePKCE: Bool

    /// Creates an OAuth configuration.
    ///
    /// - Parameters:
    ///   - clientID: The OAuth client identifier.
    ///   - clientSecret: Optional client secret (avoid for mobile apps).
    ///   - authorizationURL: The authorization endpoint URL.
    ///   - tokenURL: The token exchange endpoint URL.
    ///   - redirectURL: The redirect URL for callbacks.
    ///   - scopes: The requested scopes.
    ///   - additionalParameters: Extra authorization parameters.
    ///   - usePKCE: Whether to use PKCE (default: true).
    public init(
        clientID: String,
        clientSecret: String? = nil,
        authorizationURL: URL,
        tokenURL: URL,
        redirectURL: URL,
        scopes: [String] = [],
        additionalParameters: [String: String] = [:],
        usePKCE: Bool = true
    ) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.authorizationURL = authorizationURL
        self.tokenURL = tokenURL
        self.redirectURL = redirectURL
        self.scopes = scopes
        self.additionalParameters = additionalParameters
        self.usePKCE = usePKCE
    }
}

// MARK: - PKCE Helper

/// Generates PKCE code verifier and challenge.
public struct PKCEGenerator: Sendable {
    /// The code verifier (random string).
    public let codeVerifier: String

    /// The code challenge (SHA256 hash of verifier, base64url encoded).
    public let codeChallenge: String

    /// The code challenge method (always "S256").
    public let codeChallengeMethod: String = "S256"

    /// Creates a new PKCE pair.
    public init() {
        // Generate a random 32-byte code verifier
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        self.codeVerifier = Data(bytes).base64URLEncodedString()

        // Generate code challenge: SHA256(verifier) base64url encoded
        let verifierData = Data(codeVerifier.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        verifierData.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(verifierData.count), &hash)
        }
        self.codeChallenge = Data(hash).base64URLEncodedString()
    }
}

// MARK: - Data Extension

extension Data {
    /// Encodes data as base64url (URL-safe base64 without padding).
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// Import CommonCrypto for SHA256
import CommonCrypto
