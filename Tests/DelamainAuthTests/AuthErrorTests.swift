import Testing
@testable import DelamainAuth

@Suite("AuthError Tests")
struct AuthErrorTests {

    @Test("Not authenticated error has description")
    func notAuthenticatedHasDescription() {
        let error = AuthError.notAuthenticated
        #expect(error.errorDescription?.contains("Not authenticated") == true)
    }

    @Test("Token expired error has description")
    func tokenExpiredHasDescription() {
        let error = AuthError.tokenExpired
        #expect(error.errorDescription?.contains("expired") == true)
    }

    @Test("Refresh failed error includes message")
    func refreshFailedIncludesMessage() {
        let error = AuthError.refreshFailed("Invalid refresh token")
        #expect(error.errorDescription?.contains("Invalid refresh token") == true)
    }

    @Test("Cancelled error has description")
    func cancelledHasDescription() {
        let error = AuthError.cancelled
        #expect(error.errorDescription?.contains("cancelled") == true)
    }

    @Test("Provider error includes message")
    func providerErrorIncludesMessage() {
        let error = AuthError.providerError("Apple Sign-In failed")
        #expect(error.errorDescription?.contains("Apple Sign-In failed") == true)
    }

    @Test("Biometric failed error includes message")
    func biometricFailedIncludesMessage() {
        let error = AuthError.biometricFailed("User cancelled")
        #expect(error.errorDescription?.contains("User cancelled") == true)
    }

    @Test("Biometric not available error has description")
    func biometricNotAvailableHasDescription() {
        let error = AuthError.biometricNotAvailable
        #expect(error.errorDescription?.contains("not available") == true)
    }

    @Test("Invalid credentials error has description")
    func invalidCredentialsHasDescription() {
        let error = AuthError.invalidCredentials
        #expect(error.errorDescription?.contains("Invalid credentials") == true)
    }

    @Test("Invalid configuration error includes message")
    func invalidConfigurationIncludesMessage() {
        let error = AuthError.invalidConfiguration("Missing client ID")
        #expect(error.errorDescription?.contains("Missing client ID") == true)
    }

    @Test("Network error includes message")
    func networkErrorIncludesMessage() {
        let error = AuthError.networkError("Connection timeout")
        #expect(error.errorDescription?.contains("Connection timeout") == true)
    }

    @Test("Storage failed error includes message")
    func storageFailedIncludesMessage() {
        let error = AuthError.storageFailed("Keychain access denied")
        #expect(error.errorDescription?.contains("Keychain access denied") == true)
    }

    @Test("Unknown error includes message")
    func unknownErrorIncludesMessage() {
        let error = AuthError.unknown("Something went wrong")
        #expect(error.errorDescription?.contains("Something went wrong") == true)
    }

    @Test("Errors are equatable")
    func errorsAreEquatable() {
        let error1 = AuthError.notAuthenticated
        let error2 = AuthError.notAuthenticated
        let error3 = AuthError.tokenExpired

        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Errors with same message are equatable")
    func errorsWithSameMessageAreEquatable() {
        let error1 = AuthError.providerError("test")
        let error2 = AuthError.providerError("test")
        let error3 = AuthError.providerError("different")

        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}
