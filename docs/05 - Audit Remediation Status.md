# 05 - Audit Remediation Status

Last reviewed: 2026-10-04

## Completed in repository

- [x] Removed the embedded desktop OAuth client secret from current source.
- [x] Replaced desktop secret-based OAuth with Authorization Code + PKCE.
- [x] Added desktop refresh-token persistence and refresh handling.
- [x] Moved authentication tokens from ObjectBox to platform secure storage.
- [x] Purged legacy ObjectBox credential records on startup without erasing cleanup history.
- [x] Reduced Gmail permissions from full mailbox scope to `gmail.modify` + `gmail.send`.
- [x] Added explicit guards for Empty Trash and permanent deletion.
- [x] Added a warning/confirmation before enabling permanent-delete mode.
- [x] Removed Android debug-signing fallback from release builds.
- [x] Reworked release automation to require stable signing secrets.
- [x] Added `flutter analyze` and `flutter test` CI.
- [x] Added destructive-operation safety tests.
- [x] Corrected `.gitignore` so Flutter platform source directories remain tracked.
- [x] Removed generated APK/EXE/ZIP files from the current source tree.
- [x] Corrected README links to the maintained fork and standardized contact information.
- [x] Added numbered security, release, testing, and repository documentation.
- [x] Corrected the OAuth settings source filename to Dart-style `oauth_setting_page.dart`.

## Owner-only actions still required outside the repository

These cannot be completed through source commits alone:

1. **Rotate/revoke the historical Google desktop OAuth client secret** in Google Cloud Console.
2. **Add Android signing secrets** in GitHub repository settings:
   - `ANDROID_KEYSTORE_BASE64`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`
   - `ANDROID_STORE_PASSWORD`
3. **Enable GitHub Issues** if public issue-based support is desired.
4. **Add GitHub repository topics/description** for discoverability.
5. Review the existing `Shalifeos` repository ruleset and ensure it explicitly targets the intended protected branch/ref.

## History note

Large release binaries and the historical OAuth secret still exist in old Git history. The current branch no longer references those release artifacts, but complete physical removal from history would require an intentional history rewrite and coordination with all clones/forks.
