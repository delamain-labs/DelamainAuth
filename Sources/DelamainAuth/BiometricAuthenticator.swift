import Foundation
import LocalAuthentication

// MARK: - Biometric Type

/// The type of biometric authentication available.
public enum BiometricType: Sendable {
    /// Face ID
    case faceID
    /// Touch ID
    case touchID
    /// No biometric authentication available
    case none
}

// MARK: - Biometric Authenticator

/// Handles biometric authentication using Face ID or Touch ID.
///
/// Example:
/// ```swift
/// let biometric = BiometricAuthenticator()
///
/// if biometric.isAvailable {
///     do {
///         try await biometric.authenticate(reason: "Unlock your account")
///         print("Authentication successful!")
///     } catch {
///         print("Authentication failed: \(error)")
///     }
/// }
/// ```
public actor BiometricAuthenticator {

    // MARK: - Properties

    private let context: LAContext

    // MARK: - Initialization

    /// Creates a new biometric authenticator.
    ///
    /// - Parameter context: The LAContext to use (defaults to a new instance).
    public init(context: LAContext = LAContext()) {
        self.context = context
    }

    // MARK: - Availability

    /// Whether biometric authentication is available on this device.
    public nonisolated var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// The type of biometric authentication available.
    public nonisolated var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .faceID // Treat optic ID like Face ID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// A human-readable name for the available biometric type.
    public nonisolated var biometricName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometric Authentication"
        }
    }

    // MARK: - Authentication

    /// Authenticates the user with biometrics.
    ///
    /// - Parameter reason: The reason to display to the user.
    /// - Throws: `AuthError.biometricNotAvailable` if biometrics aren't available.
    /// - Throws: `AuthError.biometricFailed` if authentication fails.
    /// - Throws: `AuthError.cancelled` if the user cancels.
    public func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error {
                throw mapLAError(error)
            }
            throw AuthError.biometricNotAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if !success {
                throw AuthError.biometricFailed("Authentication was not successful")
            }
        } catch let error as LAError {
            throw mapLAError(error)
        } catch {
            throw AuthError.biometricFailed(error.localizedDescription)
        }
    }

    /// Authenticates with biometrics, falling back to device passcode if biometrics fail.
    ///
    /// - Parameter reason: The reason to display to the user.
    /// - Throws: `AuthError` if authentication fails completely.
    public func authenticateWithFallback(reason: String) async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error {
                throw mapLAError(error)
            }
            throw AuthError.biometricNotAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            if !success {
                throw AuthError.biometricFailed("Authentication was not successful")
            }
        } catch let error as LAError {
            throw mapLAError(error)
        } catch {
            throw AuthError.biometricFailed(error.localizedDescription)
        }
    }

    // MARK: - Error Mapping

    private func mapLAError(_ error: Error) -> AuthError {
        guard let laError = error as? LAError else {
            return AuthError.biometricFailed(error.localizedDescription)
        }

        switch laError.code {
        case .userCancel, .appCancel, .systemCancel:
            return AuthError.cancelled
        case .biometryNotAvailable:
            return AuthError.biometricNotAvailable
        case .biometryNotEnrolled:
            return AuthError.biometricFailed("No biometric data enrolled. Please set up \(biometricName) in Settings.")
        case .biometryLockout:
            return AuthError.biometricFailed("\(biometricName) is locked. Please use your passcode.")
        case .authenticationFailed:
            return AuthError.biometricFailed("Authentication failed. Please try again.")
        case .userFallback:
            return AuthError.biometricFailed("User chose to use fallback authentication.")
        case .passcodeNotSet:
            return AuthError.biometricFailed("No passcode set on device.")
        default:
            return AuthError.biometricFailed(laError.localizedDescription)
        }
    }
}

// MARK: - AuthManager Extension

extension AuthManager {
    /// Authenticates the user with biometrics before accessing sensitive data.
    ///
    /// - Parameter reason: The reason to display to the user.
    /// - Throws: `AuthError` if authentication fails.
    public func requireBiometric(
        reason: String = "Authenticate to continue",
        _ operation: () async throws -> Void
    ) async throws {
        let biometric = BiometricAuthenticator()
        try await biometric.authenticate(reason: reason)
        try await operation()
    }
}
