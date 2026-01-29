import Testing
import Foundation
@testable import DelamainAuth

@Suite("BiometricAuthenticator Tests")
struct BiometricAuthenticatorTests {

    // MARK: - Initialization

    @Test("Creates biometric authenticator")
    func createsBiometricAuthenticator() async {
        let authenticator = BiometricAuthenticator()
        // Just verify it can be created
        _ = authenticator
    }

    // MARK: - Availability

    @Test("Can check if biometrics are available")
    func canCheckIfBiometricsAreAvailable() async {
        let authenticator = BiometricAuthenticator()
        // This will return true or false depending on the environment
        // We just verify it doesn't crash
        _ = authenticator.isAvailable
    }

    @Test("Can get biometric type")
    func canGetBiometricType() async {
        let authenticator = BiometricAuthenticator()
        let type = authenticator.biometricType
        // Verify it returns a valid type
        #expect([BiometricType.faceID, .touchID, .none].contains(type))
    }

    @Test("Biometric name matches type")
    func biometricNameMatchesType() async {
        let authenticator = BiometricAuthenticator()
        let name = authenticator.biometricName

        switch authenticator.biometricType {
        case .faceID:
            #expect(name == "Face ID")
        case .touchID:
            #expect(name == "Touch ID")
        case .none:
            #expect(name == "Biometric Authentication")
        }
    }

    // MARK: - BiometricType

    @Test("BiometricType is sendable")
    func biometricTypeIsSendable() async {
        let type: BiometricType = .faceID

        await withTaskGroup(of: BiometricType.self) { group in
            group.addTask {
                return type
            }
            for await result in group {
                #expect(result == .faceID)
            }
        }
    }
}

@Suite("BiometricType Tests")
struct BiometricTypeTests {

    @Test("All types are distinct")
    func allTypesAreDistinct() {
        let types: [BiometricType] = [.faceID, .touchID, .none]
        let uniqueCount = Set(types.map { "\($0)" }).count
        #expect(uniqueCount == 3)
    }
}
