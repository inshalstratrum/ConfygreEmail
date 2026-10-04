# Security Policy

Confygre Email can read, modify, trash, send, and in explicitly confirmed flows permanently delete Gmail messages. Treat authentication and release signing material as sensitive.

## Do not commit

- OAuth client secrets
- access tokens
- refresh tokens
- ID tokens
- Android signing keystores
- keystore passwords
- private API credentials
- user mailbox exports or diagnostic logs containing personal mail

## OAuth

Installed/native applications cannot keep a client secret confidential. Desktop authentication uses Authorization Code + PKCE with a loopback redirect and a public client ID.

Authentication tokens are stored with platform secure storage, not in the ordinary ObjectBox application database.

## Historical credential exposure

An older public commit embedded a desktop OAuth client secret. It has been removed from the current source, but Git history remains public.

The repository owner must rotate/revoke that historical client secret in Google Cloud Console. Removing it from the latest branch does not invalidate previously published copies.

## Gmail scopes

Use least privilege. The maintained flow requests Gmail modify + send scopes rather than the full mailbox scope.

## Release signing

Production Android APKs must use a stable release certificate. Never publish debug-signed builds as production releases.

## Reporting

Repository Issues are currently disabled. Until a private security-reporting channel is configured, do not post credentials, tokens, or mailbox data publicly.
