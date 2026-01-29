import Testing
import Foundation
@testable import DelamainAuth

@Suite("Token Tests")
struct TokenTests {

    // MARK: - Creation

    @Test("Creates token with all properties")
    func createsTokenWithAllProperties() {
        let expiresAt = Date().addingTimeInterval(3600)
        let token = Token(
            accessToken: "access123",
            refreshToken: "refresh456",
            tokenType: "Bearer",
            expiresAt: expiresAt,
            scopes: ["read", "write"]
        )

        #expect(token.accessToken == "access123")
        #expect(token.refreshToken == "refresh456")
        #expect(token.tokenType == "Bearer")
        #expect(token.expiresAt == expiresAt)
        #expect(token.scopes == ["read", "write"])
    }

    @Test("Creates token with minimal properties")
    func createsTokenWithMinimalProperties() {
        let token = Token(accessToken: "access123")

        #expect(token.accessToken == "access123")
        #expect(token.refreshToken == nil)
        #expect(token.tokenType == "Bearer")
        #expect(token.expiresAt == nil)
        #expect(token.scopes.isEmpty)
    }

    // MARK: - Expiration

    @Test("Token without expiration is not expired")
    func tokenWithoutExpirationIsNotExpired() {
        let token = Token(accessToken: "access123")
        #expect(token.isExpired == false)
    }

    @Test("Token with future expiration is not expired")
    func tokenWithFutureExpirationIsNotExpired() {
        let token = Token(
            accessToken: "access123",
            expiresAt: Date().addingTimeInterval(3600)
        )
        #expect(token.isExpired == false)
    }

    @Test("Token with past expiration is expired")
    func tokenWithPastExpirationIsExpired() {
        let token = Token(
            accessToken: "access123",
            expiresAt: Date().addingTimeInterval(-60)
        )
        #expect(token.isExpired == true)
    }

    @Test("Checks if token will expire within interval")
    func checksIfTokenWillExpireWithinInterval() {
        let token = Token(
            accessToken: "access123",
            expiresAt: Date().addingTimeInterval(300) // 5 minutes
        )

        #expect(token.willExpire(within: 600) == true)  // 10 minutes - yes
        #expect(token.willExpire(within: 60) == false)  // 1 minute - no
    }

    // MARK: - Refresh

    @Test("Token with refresh token can refresh")
    func tokenWithRefreshTokenCanRefresh() {
        let token = Token(accessToken: "access123", refreshToken: "refresh456")
        #expect(token.canRefresh == true)
    }

    @Test("Token without refresh token cannot refresh")
    func tokenWithoutRefreshTokenCannotRefresh() {
        let token = Token(accessToken: "access123")
        #expect(token.canRefresh == false)
    }

    // MARK: - Authorization Header

    @Test("Generates correct authorization header")
    func generatesCorrectAuthorizationHeader() {
        let token = Token(accessToken: "access123", tokenType: "Bearer")
        #expect(token.authorizationHeader == "Bearer access123")
    }

    @Test("Uses custom token type in header")
    func usesCustomTokenTypeInHeader() {
        let token = Token(accessToken: "access123", tokenType: "MAC")
        #expect(token.authorizationHeader == "MAC access123")
    }

    // MARK: - Codable

    @Test("Token is encodable and decodable")
    func tokenIsEncodableAndDecodable() throws {
        let original = Token(
            accessToken: "access123",
            refreshToken: "refresh456",
            tokenType: "Bearer",
            expiresAt: Date(timeIntervalSince1970: 1000000),
            scopes: ["read", "write"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Token.self, from: data)

        #expect(decoded == original)
    }
}

@Suite("Token Response Tests")
struct TokenResponseTests {

    @Test("Converts token response to token")
    func convertsTokenResponseToToken() {
        let response = TokenResponse(
            accessToken: "access123",
            refreshToken: "refresh456",
            tokenType: "Bearer",
            expiresIn: 3600,
            scope: "read write"
        )

        let token = response.toToken()

        #expect(token.accessToken == "access123")
        #expect(token.refreshToken == "refresh456")
        #expect(token.tokenType == "Bearer")
        #expect(token.scopes == ["read", "write"])
        #expect(token.expiresAt != nil)
    }

    @Test("Handles missing optional fields")
    func handlesMissingOptionalFields() {
        let response = TokenResponse(
            accessToken: "access123",
            refreshToken: nil,
            tokenType: nil,
            expiresIn: nil,
            scope: nil
        )

        let token = response.toToken()

        #expect(token.accessToken == "access123")
        #expect(token.refreshToken == nil)
        #expect(token.tokenType == "Bearer") // Default
        #expect(token.expiresAt == nil)
        #expect(token.scopes.isEmpty)
    }

    @Test("Parses from JSON")
    func parsesFromJSON() throws {
        let json = """
        {
            "access_token": "access123",
            "refresh_token": "refresh456",
            "token_type": "Bearer",
            "expires_in": 3600,
            "scope": "openid profile"
        }
        """

        let decoder = JSONDecoder()
        let response = try decoder.decode(TokenResponse.self, from: Data(json.utf8))

        #expect(response.accessToken == "access123")
        #expect(response.refreshToken == "refresh456")
        #expect(response.expiresIn == 3600)
    }
}
