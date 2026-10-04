# Confygre Email

**Confygre Email** is a Flutter-based Gmail cleanup application for Android and desktop. It helps users review senders, unsubscribe from mailing lists, move bulk mail to Trash, and optionally perform explicitly confirmed permanent cleanup actions.

This repository is a maintained GPL-3.0 fork of [confygregit/ConfygreEmail](https://github.com/confygregit/ConfygreEmail) with additional desktop support, mailbox tooling, security hardening, CI, and release automation.

## Current status

The project is in active beta. Gmail cleanup operations can modify or permanently delete mail, so users should test with non-critical accounts before relying on it for important inboxes.

## Key features

- Gmail sender cleanup and bulk review
- One-click unsubscribe support where senders provide standard unsubscribe metadata
- Inbox/category filtering
- Android and desktop Flutter targets
- OAuth authentication for mobile and desktop
- Desktop OAuth Authorization Code + PKCE
- Platform secure storage for authentication tokens
- Gmail Trash as the default delete path
- Explicit confirmation gates for permanent deletion and Empty Trash
- Local cleanup history and preferences
- GitHub Actions CI and signed Android release workflow

## Security changes

Recent security hardening includes:

- removed the embedded desktop OAuth client secret from the current source;
- replaced secret-based installed-app OAuth with PKCE;
- moved OAuth tokens out of ObjectBox and into platform secure storage;
- added refresh-token handling for desktop sessions;
- reduced Gmail scopes from full mailbox access to `gmail.modify` plus `gmail.send`;
- added explicit application guards for irreversible Gmail operations;
- removed debug-signing fallback for Android release builds.

See [Security and OAuth](docs/01%20-%20Security%20and%20OAuth.md).

> **Important owner action:** the historical desktop OAuth secret must still be rotated/revoked in Google Cloud because older public Git commits remain retrievable.

## Downloads

Use the [GitHub Releases](https://github.com/inshalstratrum/ConfygreEmail/releases) page for packaged builds.

**Legacy-release warning:** releases produced before the hardened signing workflow used the older release process and may have been debug-signed. The next production Android release should be created only after the stable signing secrets are configured and the workflow's APK-signature verification passes.

Generated APK, EXE, and ZIP artifacts are intentionally no longer stored in the source tree.

## Development

Requirements:

- Flutter stable
- Dart compatible with the version declared in `pubspec.yaml`
- Android Studio / Android SDK for Android builds
- a Google OAuth configuration suitable for the platform being tested

Clone the maintained fork:

```bash
git clone https://github.com/inshalstratrum/ConfygreEmail.git
cd ConfygreEmail
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

## Android release signing

Release CI requires a stable signing keystore supplied through GitHub repository secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

The release workflow refuses to depend on Android debug signing for production APKs.

See [Release and Signing](docs/02%20-%20Release%20and%20Signing.md).

## Gmail permissions

The maintained implementation requests:

- `gmail.modify` — list, label, trash, and modify mail;
- `gmail.send` — send unsubscribe email requests when a sender provides a `mailto:` unsubscribe method;
- OpenID/profile/email identity scopes for desktop sign-in.

It no longer requests the broader `https://mail.google.com/` scope.

## Destructive-operation policy

Normal delete flows move messages to Gmail Trash.

Permanent deletion is opt-in and requires explicit confirmation. Empty Trash is also guarded by an explicit irreversible-action confirmation.

## Documentation

0. [00 - Documentation Index](docs/00%20-%20Documentation%20Index.md)
1. [01 - Security and OAuth](docs/01%20-%20Security%20and%20OAuth.md)
2. [02 - Release and Signing](docs/02%20-%20Release%20and%20Signing.md)
3. [03 - Testing and Safety](docs/03%20-%20Testing%20and%20Safety.md)
4. [04 - Repository and Maintenance](docs/04%20-%20Repository%20and%20Maintenance.md)
5. [05 - Audit Remediation Status](docs/05%20-%20Audit%20Remediation%20Status.md)
6. [06 - Owner Release Checklist](docs/06%20-%20Owner%20Release%20Checklist.md)

## Support

Repository Issues are currently disabled at the GitHub settings level. Until they are enabled, use the guidance in [SUPPORT.md](SUPPORT.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

GPL-3.0. See [LICENSE](LICENSE).
