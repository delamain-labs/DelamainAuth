import Testing
import Foundation
@testable import DelamainAuth

// MARK: - Test Helpers

private enum TestURLs {
    // swiftlint:disable force_unwrapping
    static let authURL = URL(string: "https://auth.example.com/authorize")!
    static let tokenURL = URL(string: "https://auth.example.com/token")!
    static let redirectURL = URL(string: "myapp://callback")!
    static let genericURL = URL(string: "https://example.com")!
    static let genericTokenURL = URL(string: "https://example.com/token")!
    static let appSchemeURL = URL(string: "app://")!
    // swiftlint:enable force_unwrapping
}

@Suite("OAuthConfig Tests")
struct OAuthConfigTests {

    @Test("Creates config with all properties")
    func createsConfigWithAllProperties() {
        let config = OAuthConfig(
            clientID: "client123",
            clientSecret: "secret456",
            authorizationURL: TestURLs.authURL,
            tokenURL: TestURLs.tokenURL,
            redirectURL: TestURLs.redirectURL,
            scopes: ["openid", "profile", "email"],
            additionalParameters: ["prompt": "consent"],
            usePKCE: true
        )

        #expect(config.clientID == "client123")
        #expect(config.clientSecret == "secret456")
        #expect(config.authorizationURL.absoluteString == "https://auth.example.com/authorize")
        #expect(config.tokenURL.absoluteString == "https://auth.example.com/token")
        #expect(config.redirectURL.absoluteString == "myapp://callback")
        #expect(config.scopes == ["openid", "profile", "email"])
        #expect(config.additionalParameters["prompt"] == "consent")
        #expect(config.usePKCE == true)
    }

    @Test("Creates config with defaults")
    func createsConfigWithDefaults() {
        let config = OAuthConfig(
            clientID: "client123",
            authorizationURL: TestURLs.authURL,
            tokenURL: TestURLs.tokenURL,
            redirectURL: TestURLs.redirectURL
        )

        #expect(config.clientID == "client123")
        #expect(config.clientSecret == nil)
        #expect(config.scopes.isEmpty)
        #expect(config.additionalParameters.isEmpty)
        #expect(config.usePKCE == true) // Default
    }

    @Test("Config is sendable")
    func configIsSendable() async {
        let config = OAuthConfig(
            clientID: "test",
            authorizationURL: TestURLs.genericURL,
            tokenURL: TestURLs.genericTokenURL,
            redirectURL: TestURLs.appSchemeURL
        )

        await withTaskGroup(of: String.self) { group in
            group.addTask {
                return config.clientID
            }
            for await id in group {
                #expect(id == "test")
            }
        }
    }
}

@Suite("PKCEGenerator Tests")
struct PKCEGeneratorTests {

    @Test("Generates code verifier")
    func generatesCodeVerifier() {
        let pkce = PKCEGenerator()
        #expect(!pkce.codeVerifier.isEmpty)
        #expect(pkce.codeVerifier.count >= 43) // Base64url of 32 bytes
    }

    @Test("Generates code challenge")
    func generatesCodeChallenge() {
        let pkce = PKCEGenerator()
        #expect(!pkce.codeChallenge.isEmpty)
        #expect(pkce.codeChallenge.count >= 43) // Base64url of SHA256
    }

    @Test("Code challenge method is S256")
    func codeChallengeMethodIsS256() {
        let pkce = PKCEGenerator()
        #expect(pkce.codeChallengeMethod == "S256")
    }

    @Test("Generates unique values each time")
    func generatesUniqueValuesEachTime() {
        let pkce1 = PKCEGenerator()
        let pkce2 = PKCEGenerator()

        #expect(pkce1.codeVerifier != pkce2.codeVerifier)
        #expect(pkce1.codeChallenge != pkce2.codeChallenge)
    }

    @Test("Verifier is URL-safe base64")
    func verifierIsURLSafeBase64() {
        let pkce = PKCEGenerator()

        // Should not contain + / or =
        #expect(!pkce.codeVerifier.contains("+"))
        #expect(!pkce.codeVerifier.contains("/"))
        #expect(!pkce.codeVerifier.contains("="))
    }

    @Test("Challenge is URL-safe base64")
    func challengeIsURLSafeBase64() {
        let pkce = PKCEGenerator()

        // Should not contain + / or =
        #expect(!pkce.codeChallenge.contains("+"))
        #expect(!pkce.codeChallenge.contains("/"))
        #expect(!pkce.codeChallenge.contains("="))
    }

    @Test("PKCE is sendable")
    func pkceIsSendable() async {
        let pkce = PKCEGenerator()

        await withTaskGroup(of: String.self) { group in
            group.addTask {
                return pkce.codeVerifier
            }
            for await verifier in group {
                #expect(verifier == pkce.codeVerifier)
            }
        }
    }
}

@Suite("Data Base64URL Tests")
struct DataBase64URLTests {

    @Test("Encodes data as base64url")
    func encodesDataAsBase64URL() {
        let data = Data([0xFF, 0xEE, 0xDD])
        let encoded = data.base64URLEncodedString()

        // Should not contain + / or =
        #expect(!encoded.contains("+"))
        #expect(!encoded.contains("/"))
        #expect(!encoded.contains("="))
    }

    @Test("Replaces + with -")
    func replacesPlusWithMinus() {
        // Data that would produce + in regular base64
        let data = Data([0xFB, 0xEF]) // base64: ++8=
        let encoded = data.base64URLEncodedString()
        #expect(!encoded.contains("+"))
    }

    @Test("Replaces / with _")
    func replacesSlashWithUnderscore() {
        // Data that would produce / in regular base64
        let data = Data([0xFF, 0xFF]) // base64: //8=
        let encoded = data.base64URLEncodedString()
        #expect(!encoded.contains("/"))
    }
}

@Suite("OAuthProvider Tests")
struct OAuthProviderTests {

    @Test("Creates provider with config")
    @MainActor
    func createsProviderWithConfig() {
        let config = OAuthConfig(
            clientID: "test",
            authorizationURL: TestURLs.genericURL,
            tokenURL: TestURLs.genericTokenURL,
            redirectURL: TestURLs.appSchemeURL
        )

        let provider = OAuthProvider(config: config)
        _ = provider
    }

    // Note: Actual OAuth flow tests require network/UI interaction
    // and would need mocking or integration test setup.
}
