# DelamainAuth

Type-safe authentication for Swift 6.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20|%20macOS%2014%20|%20watchOS%2010%20|%20tvOS%2017%20|%20visionOS%201-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Token Management** — Secure storage and automatic refresh of access/refresh tokens
- **Session Handling** — Login state tracking, expiration, auto-logout
- **OAuth 2.0 / OIDC** — Authorization code flow with PKCE
- **Apple Sign-In** — Native ASAuthorizationController integration
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

// Create auth manager
let auth = AuthManager()

// Check login state
if await auth.isAuthenticated {
    print("Welcome back!")
}

// Login with Apple
let session = try await auth.signIn(with: .apple)

// Access token for API calls
let token = try await auth.currentToken()

// Logout
await auth.signOut()
```

## Token Management

DelamainAuth handles token lifecycle automatically:

```swift
// Tokens are stored securely in Keychain
let auth = AuthManager(storage: KeychainStorage())

// Automatic refresh when token expires
let token = try await auth.currentToken() // Refreshes if needed

// Manual refresh
try await auth.refreshToken()

// Token expiration info
if let expiresAt = await auth.tokenExpiresAt {
    print("Token expires: \(expiresAt)")
}
```

## OAuth 2.0 / PKCE

```swift
let config = OAuthConfig(
    clientId: "your-client-id",
    authorizationURL: URL(string: "https://auth.example.com/authorize")!,
    tokenURL: URL(string: "https://auth.example.com/token")!,
    redirectURL: URL(string: "myapp://callback")!,
    scopes: ["openid", "profile", "email"]
)

let auth = AuthManager(oauthConfig: config)
let session = try await auth.signIn(with: .oauth)
```

## Apple Sign-In

```swift
let session = try await auth.signIn(with: .apple)

// Access user info (first sign-in only)
if let appleUser = session.appleUser {
    print("Name: \(appleUser.fullName)")
    print("Email: \(appleUser.email)")
}
```

## Biometric Authentication

```swift
// Check availability
if await auth.canUseBiometrics {
    // Unlock with Face ID / Touch ID
    try await auth.unlock(with: .biometric)
}

// Require biometric for sensitive operations
try await auth.requireBiometric {
    // This block only runs after successful biometric auth
    try await performSensitiveOperation()
}
```

## Network Integration

Use with DelamainNetworking for automatic token injection:

```swift
import DelamainAuth
import DelamainNetworking

let auth = AuthManager()
let client = NetworkClient(authProvider: auth)

// Requests automatically include Authorization header
// Token refreshes automatically on 401
let user: User = try await client.get("/api/user")
```

## Thread Safety

DelamainAuth is built on Swift actors:

```swift
// Safe from any context
await withTaskGroup(of: Void.self) { group in
    group.addTask { await auth.isAuthenticated }
    group.addTask { try? await auth.currentToken() }
    group.addTask { await auth.signOut() }
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
