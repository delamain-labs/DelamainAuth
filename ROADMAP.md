# DelamainAuth Roadmap

## v1.0.0 (Current) ✅

### Core Features - DONE
- [x] Token model with expiration handling
- [x] AuthSession with provider tracking
- [x] AuthUser for user info storage
- [x] AuthManager actor for session management
- [x] Session persistence with Codable
- [x] Comprehensive AuthError types
- [x] Swift 6 / Sendable compliance

### Authentication Providers - DONE
- [x] Sign in with Apple (AppleSignInProvider)
  - [x] ASAuthorizationController integration
  - [x] Credential state checking
  - [x] User info extraction
- [x] OAuth 2.0 / PKCE (OAuthProvider)
  - [x] RFC 7636 PKCE implementation
  - [x] ASWebAuthenticationSession integration
  - [x] Token exchange and refresh
- [x] Biometric Authentication (BiometricAuthenticator)
  - [x] Face ID / Touch ID support
  - [x] LAContext integration
  - [x] Availability checking

## v1.1.0 (Planned)

### Additional Providers
- [ ] Google Sign-In integration
- [ ] Facebook Login integration
- [ ] Custom OAuth provider templates

### Enhanced Features
- [ ] Automatic token refresh scheduling
- [ ] Refresh token rotation support
- [ ] Multi-account session management
- [ ] Session migration utilities

### Security
- [ ] Token encryption at rest
- [ ] Jailbreak/root detection integration
- [ ] Certificate pinning support

## v1.2.0 (Future)

### Enterprise Features
- [ ] SSO / SAML support
- [ ] MFA integration
- [ ] Device binding
- [ ] Session revocation via push

### Developer Experience
- [ ] SwiftUI property wrappers (@AuthState)
- [ ] Combine publishers for session changes
- [ ] Mock providers for testing
- [ ] Analytics integration hooks

## Testing Coverage

Current: 95 tests
- TokenTests: Token expiration, refresh, encoding
- AuthSessionTests: Session validity, updates, encoding
- AuthManagerTests: State management, persistence
- BiometricAuthenticatorTests: Availability, type detection
- AppleSignInTests: Result conversions, session creation
- OAuthTests: PKCE generation, config, URL safety
- AuthErrorTests: Error types, descriptions, equality
- SessionPersistenceTests: Storage, loading, recovery

## Breaking Changes Policy

- v1.x: No breaking changes to public API
- Deprecations marked with `@available(*, deprecated)`
- Migration guides provided for major versions
