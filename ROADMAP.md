# DelamainAuth Roadmap

This document outlines planned features and improvements for DelamainAuth.

## v1.0.0 (In Progress)

### Core Features
- [ ] AuthManager actor with session state
- [ ] Token model (access, refresh, expiration)
- [ ] Credential storage via DelamainStorage
- [ ] AuthError with LocalizedError conformance
- [ ] CI/CD pipeline (build, test, lint)

### Token Management
- [ ] Secure token storage (Keychain)
- [ ] Automatic token refresh
- [ ] Token expiration tracking
- [ ] Logout / token revocation

### Auth Providers
- [ ] Apple Sign-In integration
- [ ] OAuth 2.0 / PKCE flow
- [ ] Biometric authentication (Face ID / Touch ID)

### Quality
- [ ] Comprehensive test coverage
- [ ] Documentation and examples
- [ ] SwiftLint integration

---

## v1.1.0 (Next)

### Enhancements
- [ ] **Session persistence** — Restore sessions across app launches
- [ ] **Multi-account support** — Manage multiple authenticated accounts
- [ ] **Token interceptor** — DelamainNetworking integration
- [ ] **Auth state observation** — Combine/AsyncSequence publishers

### Additional Providers
- [ ] **Google Sign-In** — Native Google authentication
- [ ] **Custom providers** — Protocol for custom auth backends

## v1.2.0 (Future)

### Advanced Features
- [ ] **MFA support** — Two-factor authentication flows
- [ ] **Passkeys** — WebAuthn / passkey support
- [ ] **JWT utilities** — Decode and validate JWTs
- [ ] **Rate limiting** — Handle auth rate limits gracefully

### Developer Experience
- [ ] **SwiftUI views** — Pre-built sign-in buttons
- [ ] **Auth middleware** — Request authentication middleware

---

## Contributing

Want to help? Check our [issues](https://github.com/delamain-labs/DelamainAuth/issues) or open a discussion for new feature ideas.

## Related Packages

- [DelamainCore](https://github.com/delamain-labs/DelamainCore) — Shared utilities and extensions
- [DelamainNetworking](https://github.com/delamain-labs/DelamainNetworking) — Async networking with retries
- [DelamainLogger](https://github.com/delamain-labs/DelamainLogger) — Logging framework
- [DelamainStorage](https://github.com/delamain-labs/DelamainStorage) — Local data persistence

---

*Last updated: 2026-01-29*
