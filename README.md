# DelamainAuth

Type-safe authentication for Swift 6.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20|%20macOS%2014%20|%20watchOS%2010%20|%20tvOS%2017%20|%20visionOS%201-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Token Management** — Secure storage and lifecycle management of access/refresh tokens
- **Session Handling** — Login state tracking, persistence, expiration detection
- **OAuth 2.0 / PKCE** — Full authorization code flow with RFC 7636 PKCE
- **Sign in with Apple** — Native ASAuthorizationController integration
- **Biometric Auth** — Face ID / Touch ID via LocalAuthentication
- **Swift 6 Ready** — Full Sendable compliance and actor isolation

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/delamain-labs/DelamainAuth.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Packages → Enter the repository URL.

## Quick Start

```swift
import DelamainAuth

// Create auth manager with optional storage for persistence
let auth = AuthManager()

// Check login state
if await auth.isAuthenticated {
    print("Welcome back!")
}

// Get current token for API calls
let token = try await auth.currentToken()
print("Authorization: \(token.authorizationHeader)")

// Logout
await auth.signOut(clearPersistedSession: true)
```

## Token Management

```swift
// Create a token
let token = Token(
    accessToken: "eyJ...",
    tokenType: "Bearer",
    expiresAt: Date().addingTimeInterval(3600),
    refreshToken: "refresh_token_here"
)

// Check expiration
if token.isExpired {
    print("Token needs refresh")
}

// Check if expiring soon (within 5 minutes)
if token.willExpire(in: 300) {
    print("Token expiring soon")
}

// Get authorization header
let header = token.authorizationHeader // "Bearer eyJ..."
```

## OAuth 2.0 with PKCE

Full OAuth 2.0 authorization code flow with RFC 7636 PKCE support:

```swift
let config = OAuthConfig(
    clientID: "your-client-id",
    authorizationURL: URL(string: "https://auth.example.com/authorize")!,
    tokenURL: URL(string: "https://auth.example.com/token")!,
    redirectURL: URL(string: "myapp://callback")!,
    scopes: ["openid", "profile", "email"],
    usePKCE: true  // Enabled by default
)

// Sign in
let session = try await auth.signInWithOAuth(config: config)
print("Authenticated as: \(session.provider)")

// Token refresh
let provider = OAuthProvider(config: config)
let newToken = try await provider.refreshToken(oldToken.refreshToken!)
```

## Sign in with Apple

Native Apple authentication with ASAuthorizationController:

```swift
// Basic sign-in
let result = try await auth.signInWithApple()

// Access user info (only on first sign-in)
if let user = result.user {
    print("User ID: \(user.id)")
    print("Email: \(user.email ?? "not shared")")
    print("Name: \(user.fullName ?? "not shared")")
}

// Convert to session for storage
let session = result.toSession()

// Check credential state for existing users
let provider = AppleSignInProvider()
let isValid = await provider.checkCredentialState(for: userID)
```

## Biometric Authentication

Face ID / Touch ID support via LocalAuthentication:

```swift
let biometric = BiometricAuthenticator()

// Check availability
if await biometric.isAvailable() {
    let type = await biometric.biometricType()
    print("Available: \(type.name)")  // "Face ID" or "Touch ID"
}

// Authenticate
do {
    try await biometric.authenticate(reason: "Unlock your account")
    print("Authentication successful")
} catch AuthError.cancelled {
    print("User cancelled")
} catch AuthError.biometricNotAvailable {
    print("Biometrics not configured")
} catch {
    print("Authentication failed: \(error)")
}
```

## Session Persistence

Persist sessions across app launches:

```swift
// Create manager with storage
let auth = AuthManager()

// Save current session
try await auth.persistSession(to: storage)

// Load on app launch
let loaded = await auth.loadSession(from: storage)
if loaded {
    print("Session restored")
}

// Or initialize with auto-load
let auth = await AuthManager.withPersistedSession(from: storage)
```

## AuthSession

Track complete authentication state:

```swift
let session = AuthSession(
    token: token,
    user: AuthUser(id: "123", email: "user@example.com"),
    provider: .apple,
    createdAt: Date()
)

// Check validity
if session.isValid {
    print("Session active")
}

// Update token
let updated = session.withUpdatedToken(newToken)
```

## Error Handling

All auth operations throw typed `AuthError`:

```swift
do {
    let token = try await auth.currentToken()
} catch AuthError.notAuthenticated {
    // Redirect to login
} catch AuthError.tokenExpired {
    // Token needs refresh
} catch AuthError.cancelled {
    // User cancelled auth flow
} catch AuthError.biometricNotAvailable {
    // Fall back to passcode
} catch AuthError.providerError(let message) {
    print("Provider error: \(message)")
} catch AuthError.networkError(let message) {
    print("Network error: \(message)")
}
```

## Thread Safety

Built for Swift 6 concurrency:

```swift
// AuthManager is an actor - safe from any context
let auth = AuthManager()

await withTaskGroup(of: Void.self) { group in
    group.addTask { _ = await auth.isAuthenticated }
    group.addTask { _ = try? await auth.currentToken() }
    group.addTask { await auth.signOut() }
}

// Token, AuthSession, AuthUser are all Sendable
let session: AuthSession = // ...
Task.detached {
    print(session.token.accessToken)
}
```

## Requirements

- Swift 6.0+
- iOS 17.0+ / macOS 14.0+ / watchOS 10.0+ / tvOS 17.0+ / visionOS 1.0+

## License

MIT License. See [LICENSE](LICENSE) for details.

## Part of Delamain Labs

This package is part of the Delamain Swift ecosystem:

- [DelamainCore](https://github.com/delamain-labs/DelamainCore) - Core utilities
- [DelamainNetworking](https://github.com/delamain-labs/DelamainNetworking) - Async networking
- [DelamainLogger](https://github.com/delamain-labs/DelamainLogger) - Logging framework
- [DelamainStorage](https://github.com/delamain-labs/DelamainStorage) - Local data persistence
- **DelamainAuth** - Authentication ← You are here
