# 01 - Security and OAuth

## Current security model

Confygre Email uses Google OAuth and Gmail API access. Authentication tokens must not be stored in the ordinary ObjectBox application database.

The current implementation uses:

1. Android/iOS Google Sign-In for mobile authentication.
2. Authorization Code + PKCE with a loopback redirect for desktop authentication.
3. Platform secure storage for access, ID, and refresh tokens.
4. Gmail `modify` + `send` scopes instead of the broader `mail.google.com` scope.
5. Explicit application guards for irreversible Gmail operations.

## Historical credential note

An older desktop implementation embedded an OAuth client secret in public source code. Installed/native applications cannot protect a client secret, so the current implementation removes that secret and uses PKCE.

**Owner action still required:** rotate/revoke the historical Google OAuth desktop client secret in Google Cloud Console because Git history is immutable and old commits remain publicly retrievable.

## Token storage

New authentication state is stored with `flutter_secure_storage`. Older plaintext ObjectBox credential records are purged on startup without erasing cleanup history or preferences.

## Destructive operations

- Ordinary delete actions move messages to Gmail Trash.
- Permanent deletion is opt-in and requires explicit confirmation per action.
- Empty Trash requires explicit irreversible-action confirmation.
