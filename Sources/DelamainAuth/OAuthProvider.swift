import Foundation
import AuthenticationServices

// MARK: - OAuth Provider

/// Handles OAuth 2.0 authentication with PKCE support.
///
/// Example:
/// ```swift
/// let config = OAuthConfig(
///     clientID: "your-client-id",
///     authorizationURL: URL(string: "https://auth.example.com/authorize")!,
///     tokenURL: URL(string: "https://auth.example.com/token")!,
///     redirectURL: URL(string: "myapp://callback")!,
///     scopes: ["openid", "profile"]
/// )
///
/// let provider = OAuthProvider(config: config)
/// let session = try await provider.signIn()
/// ```
@MainActor
public final class OAuthProvider {

    // MARK: - Properties

    private let config: OAuthConfig
    private var pkce: PKCEGenerator?
    private var webAuthSession: ASWebAuthenticationSession?
    private var contextProvider: AnyObject?

    // MARK: - Initialization

    /// Creates an OAuth provider with the given configuration.
    ///
    /// - Parameter config: The OAuth configuration.
    public init(config: OAuthConfig) {
        self.config = config
    }

    // MARK: - Sign In

    /// Initiates the OAuth authorization flow.
    ///
    /// - Returns: The authenticated session.
    /// - Throws: `AuthError.cancelled` if the user cancels.
    /// - Throws: `AuthError.providerError` if authorization fails.
    public func signIn() async throws -> AuthSession {
        // Generate PKCE if enabled
        let pkce: PKCEGenerator? = config.usePKCE ? PKCEGenerator() : nil
        self.pkce = pkce

        // Build authorization URL
        let authURL = try buildAuthorizationURL(pkce: pkce)

        // Present authentication session
        let callbackURL = try await presentAuthSession(url: authURL)

        // Extract authorization code from callback
        let code = try extractAuthorizationCode(from: callbackURL)

        // Exchange code for tokens
        let token = try await exchangeCodeForToken(code: code, pkce: pkce)

        // Create session
        return AuthSession(token: token, provider: .oauth)
    }

    // MARK: - Token Refresh

    /// Refreshes the access token using a refresh token.
    ///
    /// - Parameter refreshToken: The refresh token.
    /// - Returns: The new token.
    /// - Throws: `AuthError.refreshFailed` if refresh fails.
    public func refreshToken(_ refreshToken: String) async throws -> Token {
        var components = URLComponents(url: config.tokenURL, resolvingAgainstBaseURL: false)

        var queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: config.clientID)
        ]

        if let clientSecret = config.clientSecret {
            queryItems.append(URLQueryItem(name: "client_secret", value: clientSecret))
        }

        components?.queryItems = queryItems

        guard let requestBody = components?.query?.data(using: .utf8) else {
            throw AuthError.invalidConfiguration("Failed to build token request")
        }

        var request = URLRequest(url: config.tokenURL)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.refreshFailed("Invalid response")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AuthError.refreshFailed("Token refresh failed: \(errorMessage)")
            }

            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse.toToken()
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.refreshFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    private func buildAuthorizationURL(pkce: PKCEGenerator?) throws -> URL {
        var components = URLComponents(url: config.authorizationURL, resolvingAgainstBaseURL: false)

        var queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "redirect_uri", value: config.redirectURL.absoluteString)
        ]

        if !config.scopes.isEmpty {
            queryItems.append(URLQueryItem(name: "scope", value: config.scopes.joined(separator: " ")))
        }

        if let pkce {
            queryItems.append(URLQueryItem(name: "code_challenge", value: pkce.codeChallenge))
            queryItems.append(URLQueryItem(name: "code_challenge_method", value: pkce.codeChallengeMethod))
        }

        // Add additional parameters
        for (key, value) in config.additionalParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw AuthError.invalidConfiguration("Failed to build authorization URL")
        }

        return url
    }

    private func presentAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: config.redirectURL.scheme
            ) { callbackURL, error in
                if let error = error as? ASWebAuthenticationSessionError {
                    switch error.code {
                    case .canceledLogin:
                        continuation.resume(throwing: AuthError.cancelled)
                    case .presentationContextNotProvided:
                        continuation.resume(throwing: AuthError.providerError("No presentation context"))
                    case .presentationContextInvalid:
                        continuation.resume(throwing: AuthError.providerError("Invalid presentation context"))
                    @unknown default:
                        continuation.resume(throwing: AuthError.providerError(error.localizedDescription))
                    }
                    return
                }

                if let error {
                    continuation.resume(throwing: AuthError.providerError(error.localizedDescription))
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: AuthError.providerError("No callback URL received"))
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            #if os(iOS) || os(macOS)
            let contextProvider = WebAuthContextProvider()
            self.contextProvider = contextProvider
            session.presentationContextProvider = contextProvider
            #endif

            session.prefersEphemeralWebBrowserSession = true
            self.webAuthSession = session

            if !session.start() {
                continuation.resume(throwing: AuthError.providerError("Failed to start authentication session"))
            }
        }
    }

    private func extractAuthorizationCode(from url: URL) throws -> String {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        // Check for error
        if let error = components?.queryItems?.first(where: { $0.name == "error" })?.value {
            let description = components?.queryItems?.first(where: { $0.name == "error_description" })?.value
            throw AuthError.providerError(description ?? error)
        }

        // Extract code
        guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.providerError("No authorization code in callback")
        }

        return code
    }

    private func exchangeCodeForToken(code: String, pkce: PKCEGenerator?) async throws -> Token {
        var components = URLComponents(url: config.tokenURL, resolvingAgainstBaseURL: false)

        var queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: config.redirectURL.absoluteString),
            URLQueryItem(name: "client_id", value: config.clientID)
        ]

        if let clientSecret = config.clientSecret {
            queryItems.append(URLQueryItem(name: "client_secret", value: clientSecret))
        }

        if let pkce {
            queryItems.append(URLQueryItem(name: "code_verifier", value: pkce.codeVerifier))
        }

        components?.queryItems = queryItems

        guard let requestBody = components?.query?.data(using: .utf8) else {
            throw AuthError.invalidConfiguration("Failed to build token request")
        }

        var request = URLRequest(url: config.tokenURL)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.providerError("Invalid response")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AuthError.providerError("Token exchange failed: \(errorMessage)")
            }

            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse.toToken()
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.providerError(error.localizedDescription)
        }
    }
}

// MARK: - Presentation Context Provider

#if os(iOS) || os(macOS)
@MainActor
private final class WebAuthContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window available for presentation")
        }
        return window
        #elseif os(macOS)
        return NSApplication.shared.keyWindow ?? NSWindow()
        #endif
    }
}
#endif

// MARK: - AuthManager Extension

extension AuthManager {
    /// Signs in using OAuth 2.0.
    ///
    /// - Parameter config: The OAuth configuration.
    /// - Returns: The authenticated session.
    /// - Throws: `AuthError` if sign-in fails.
    @MainActor
    public func signInWithOAuth(config: OAuthConfig) async throws -> AuthSession {
        let provider = OAuthProvider(config: config)
        let session = try await provider.signIn()
        await setSession(session)
        return session
    }
}
