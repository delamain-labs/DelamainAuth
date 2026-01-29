// DelamainAuth
// Type-safe authentication for Swift 6.

/// DelamainAuth provides a unified, type-safe interface for authentication in iOS/macOS apps.
///
/// ## Overview
///
/// DelamainAuth offers multiple authentication methods with a consistent async/await API:
/// - **Token Management** — Secure storage and automatic refresh
/// - **Apple Sign-In** — Native ASAuthorizationController integration
/// - **OAuth 2.0 / PKCE** — Standard OAuth flows
/// - **Biometric Auth** — Face ID / Touch ID
///
/// ## Quick Start
///
/// ```swift
/// import DelamainAuth
///
/// let auth = AuthManager()
///
/// // Sign in with Apple
/// let session = try await auth.signIn(with: .apple)
///
/// // Get current token for API calls
/// let token = try await auth.currentToken()
///
/// // Sign out
/// await auth.signOut()
/// ```
///
/// ## Thread Safety
///
/// AuthManager is actor-isolated, making it safe to use from any context.
public enum DelamainAuth {
    /// The current version of DelamainAuth.
    public static let version = "1.0.0"
}
