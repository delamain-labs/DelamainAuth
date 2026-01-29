import Testing
import Foundation
@testable import DelamainAuth

@Suite("AppleSignInResult Tests")
struct AppleSignInResultTests {

    // MARK: - Creation

    @Test("Creates result with all properties")
    func createsResultWithAllProperties() {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "John"
        nameComponents.familyName = "Doe"

        let result = AppleSignInResult(
            userID: "user123",
            identityToken: "eyJhbGciOiJSUzI1NiJ9...",
            authorizationCode: "auth_code_xyz",
            email: "john@example.com",
            fullName: nameComponents
        )

        #expect(result.userID == "user123")
        #expect(result.identityToken == "eyJhbGciOiJSUzI1NiJ9...")
        #expect(result.authorizationCode == "auth_code_xyz")
        #expect(result.email == "john@example.com")
        #expect(result.fullName?.givenName == "John")
        #expect(result.fullName?.familyName == "Doe")
    }

    @Test("Creates result with minimal properties")
    func createsResultWithMinimalProperties() {
        let result = AppleSignInResult(userID: "user123")

        #expect(result.userID == "user123")
        #expect(result.identityToken == nil)
        #expect(result.email == nil)
        #expect(result.fullName == nil)
    }

    // MARK: - AuthUser Conversion

    @Test("Converts to AuthUser with full name")
    func convertsToAuthUserWithFullName() {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "John"
        nameComponents.familyName = "Doe"

        let result = AppleSignInResult(
            userID: "user123",
            email: "john@example.com",
            fullName: nameComponents
        )

        let user = result.toAuthUser()

        #expect(user.id == "user123")
        #expect(user.email == "john@example.com")
        #expect(user.givenName == "John")
        #expect(user.familyName == "Doe")
        #expect(user.fullName?.contains("John") == true)
        #expect(user.fullName?.contains("Doe") == true)
    }

    @Test("Converts to AuthUser without full name")
    func convertsToAuthUserWithoutFullName() {
        let result = AppleSignInResult(userID: "user123")

        let user = result.toAuthUser()

        #expect(user.id == "user123")
        #expect(user.email == nil)
        #expect(user.fullName == nil)
    }

    // MARK: - Token Conversion

    @Test("Converts to Token with identity token")
    func convertsToTokenWithIdentityToken() {
        let result = AppleSignInResult(
            userID: "user123",
            identityToken: "jwt_token_here"
        )

        let token = result.toToken()

        #expect(token.accessToken == "jwt_token_here")
        #expect(token.tokenType == "Bearer")
    }

    @Test("Converts to Token without identity token uses userID")
    func convertsToTokenWithoutIdentityTokenUsesUserID() {
        let result = AppleSignInResult(userID: "user123")

        let token = result.toToken()

        #expect(token.accessToken == "user123")
    }

    // MARK: - Session Conversion

    @Test("Converts to AuthSession")
    func convertsToAuthSession() {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "John"

        let result = AppleSignInResult(
            userID: "user123",
            identityToken: "jwt_token",
            email: "john@example.com",
            fullName: nameComponents
        )

        let session = result.toSession()

        #expect(session.provider == .apple)
        #expect(session.token.accessToken == "jwt_token")
        #expect(session.user?.id == "user123")
        #expect(session.user?.email == "john@example.com")
    }

    // MARK: - Sendable

    @Test("AppleSignInResult is sendable")
    func appleSignInResultIsSendable() async {
        let result = AppleSignInResult(userID: "user123")

        await withTaskGroup(of: String.self) { group in
            group.addTask {
                return result.userID
            }
            for await id in group {
                #expect(id == "user123")
            }
        }
    }
}

@Suite("AppleSignInProvider Tests")
struct AppleSignInProviderTests {

    @Test("Creates provider")
    @MainActor
    func createsProvider() async {
        let provider = AppleSignInProvider()
        // Just verify it can be created
        _ = provider
    }

    // Note: Actual sign-in tests require UI interaction and cannot be unit tested.
    // Integration tests would need to mock ASAuthorizationController.
}
