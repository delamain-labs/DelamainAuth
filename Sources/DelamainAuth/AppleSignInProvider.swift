import Foundation
import AuthenticationServices

// MARK: - Apple Sign-In Result

/// The result of a successful Apple Sign-In.
public struct AppleSignInResult: Sendable {
    /// The user identifier (stable across sign-ins).
    public let userID: String

    /// The identity token (JWT) for server verification.
    public let identityToken: String?

    /// The authorization code for server-side token exchange.
    public let authorizationCode: String?

    /// The user's email (only provided on first sign-in).
    public let email: String?

    /// The user's full name (only provided on first sign-in).
    public let fullName: PersonNameComponents?

    /// Creates an AppleSignInResult from an ASAuthorizationAppleIDCredential.
    init(credential: ASAuthorizationAppleIDCredential) {
        self.userID = credential.user
        self.identityToken = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
        self.authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        self.email = credential.email
        self.fullName = credential.fullName
    }

    /// Creates an AppleSignInResult with explicit values (for testing).
    public init(
        userID: String,
        identityToken: String? = nil,
        authorizationCode: String? = nil,
        email: String? = nil,
        fullName: PersonNameComponents? = nil
    ) {
        self.userID = userID
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.email = email
        self.fullName = fullName
    }

    /// Converts to an AuthUser.
    public func toAuthUser() -> AuthUser {
        var fullNameString: String?
        if let fullName {
            let formatter = PersonNameComponentsFormatter()
            fullNameString = formatter.string(from: fullName)
        }

        return AuthUser(
            id: userID,
            email: email,
            fullName: fullNameString,
            givenName: fullName?.givenName,
            familyName: fullName?.familyName
        )
    }

    /// Converts to a Token using the identity token.
    public func toToken() -> Token {
        Token(
            accessToken: identityToken ?? userID,
            tokenType: "Bearer"
        )
    }

    /// Converts to an AuthSession.
    public func toSession() -> AuthSession {
        AuthSession(
            token: toToken(),
            provider: .apple,
            user: toAuthUser()
        )
    }
}

// MARK: - Apple Sign-In Delegate

/// Internal delegate for handling ASAuthorizationController callbacks.
@MainActor
private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    var onComplete: ((Result<AppleSignInResult, AuthError>) -> Void)?

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            onComplete?(.failure(.providerError("Invalid credential type")))
            return
        }

        let result = AppleSignInResult(credential: credential)
        onComplete?(.success(result))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let authError: AuthError
        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                authError = .cancelled
            case .invalidResponse:
                authError = .providerError("Invalid response from Apple")
            case .notHandled:
                authError = .providerError("Request not handled")
            case .failed:
                authError = .providerError("Authorization failed")
            case .notInteractive:
                authError = .providerError("Not interactive")
            case .unknown, .matchedExcludedCredential, .credentialImport, .credentialExport,
                 .preferSignInWithApple, .deviceNotConfiguredForPasskeyCreation:
                authError = .providerError(error.localizedDescription)
            @unknown default:
                authError = .providerError(error.localizedDescription)
            }
        } else {
            authError = .providerError(error.localizedDescription)
        }
        onComplete?(.failure(authError))
    }
}

// MARK: - Presentation Context Provider

#if os(iOS) || os(macOS)
@MainActor
private final class PresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        // Get the key window from the active scene
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

// MARK: - Apple Sign-In Provider

/// Handles Sign in with Apple authentication.
///
/// Example:
/// ```swift
/// let provider = AppleSignInProvider()
/// let result = try await provider.signIn(scopes: [.email, .fullName])
/// let session = result.toSession()
/// ```
///
/// - Note: This provider requires the "Sign in with Apple" capability
///   in your app's entitlements.
@MainActor
public final class AppleSignInProvider {

    // MARK: - Properties

    private var delegate: AppleSignInDelegate?
    private var contextProvider: AnyObject?

    // MARK: - Initialization

    /// Creates a new Apple Sign-In provider.
    public init() {}

    // MARK: - Sign In

    /// Initiates Sign in with Apple.
    ///
    /// - Parameter scopes: The requested scopes (default: email and full name).
    /// - Returns: The sign-in result with user info.
    /// - Throws: `AuthError.cancelled` if the user cancels.
    /// - Throws: `AuthError.providerError` if sign-in fails.
    public func signIn(scopes: [ASAuthorization.Scope] = [.email, .fullName]) async throws -> AppleSignInResult {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = scopes

        let controller = ASAuthorizationController(authorizationRequests: [request])

        let delegate = AppleSignInDelegate()
        self.delegate = delegate

        #if os(iOS) || os(macOS)
        let contextProvider = PresentationContextProvider()
        self.contextProvider = contextProvider
        controller.presentationContextProvider = contextProvider
        #endif

        controller.delegate = delegate

        return try await withCheckedThrowingContinuation { continuation in
            delegate.onComplete = { result in
                continuation.resume(with: result)
            }
            controller.performRequests()
        }
    }

    // MARK: - Credential State

    /// Checks the credential state for a user ID.
    ///
    /// Use this to verify if a previously authenticated user is still valid.
    ///
    /// - Parameter userID: The user identifier from a previous sign-in.
    /// - Returns: `true` if the credential is still authorized.
    public nonisolated func checkCredentialState(for userID: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state == .authorized)
            }
        }
    }
}

// MARK: - AuthManager Extension

extension AuthManager {
    /// Signs in with Apple.
    ///
    /// - Parameter scopes: The requested scopes (default: email and full name).
    /// - Returns: The authenticated session.
    /// - Throws: `AuthError` if sign-in fails.
    @MainActor
    public func signInWithApple(
        scopes: [ASAuthorization.Scope] = [.email, .fullName]
    ) async throws -> AuthSession {
        let provider = AppleSignInProvider()
        let result = try await provider.signIn(scopes: scopes)
        let session = result.toSession()
        await setSession(session)
        return session
    }
}
