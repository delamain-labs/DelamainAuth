import Foundation

// MARK: - Auth Error

/// Errors that can occur during authentication operations.
public enum AuthError: Error, Sendable, Equatable {
    /// No valid session exists.
    case notAuthenticated

    /// The access token has expired and could not be refreshed.
    case tokenExpired

    /// Token refresh failed.
    case refreshFailed(String)

    /// The authentication flow was cancelled by the user.
    case cancelled

    /// The authentication provider returned an error.
    case providerError(String)

    /// Biometric authentication failed.
    case biometricFailed(String)

    /// Biometric authentication is not available.
    case biometricNotAvailable

    /// Invalid credentials were provided.
    case invalidCredentials

    /// The OAuth configuration is invalid.
    case invalidConfiguration(String)

    /// Network error during authentication.
    case networkError(String)

    /// Token storage failed.
    case storageFailed(String)

    /// An unknown error occurred.
    case unknown(String)
}

// MARK: - LocalizedError

extension AuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please sign in."
        case .tokenExpired:
            return "Session expired. Please sign in again."
        case .refreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .cancelled:
            return "Authentication was cancelled."
        case .providerError(let message):
            return "Authentication provider error: \(message)"
        case .biometricFailed(let message):
            return "Biometric authentication failed: \(message)"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device."
        case .invalidCredentials:
            return "Invalid credentials. Please try again."
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .storageFailed(let message):
            return "Failed to store credentials: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
