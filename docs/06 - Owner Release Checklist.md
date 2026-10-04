# 06 - Owner Release Checklist

Use this checklist before publishing the next production Android release.

## Security

- [ ] Rotate/revoke the historical Google desktop OAuth client secret in Google Cloud Console.
- [ ] Verify the old secret can no longer be used.
- [ ] Keep the current PKCE implementation; do not add a desktop client secret back to source.
- [ ] Confirm no OAuth tokens, keystores, passwords, or mailbox data are committed.

## Android signing

Create or reuse one stable production signing keystore, then add these GitHub repository secrets:

- [ ] `ANDROID_KEYSTORE_BASE64`
- [ ] `ANDROID_KEY_ALIAS`
- [ ] `ANDROID_KEY_PASSWORD`
- [ ] `ANDROID_STORE_PASSWORD`

Before publishing:

- [ ] Run the release workflow.
- [ ] Confirm the workflow's APK signature verification succeeds.
- [ ] Preserve the same release certificate for future upgrades.
- [ ] Publish the generated SHA-256 checksum with the APK.

## Repository settings

- [ ] Enable GitHub Issues if public support through Issues is desired.
- [ ] Add a concise repository description.
- [ ] Add repository topics such as `gmail-cleaner`, `flutter`, `gmail-api`, `oauth2`, `android`, `windows`, and `email-management`.
- [ ] Review ruleset `Shalifeos`. Its current ref condition has an empty include list, so explicitly configure the intended protected branch/ref instead of assuming coverage.
- [ ] Enable Dependabot/security features available to the repository.

## Release preparation

- [ ] Confirm CI is green on `main`.
- [ ] Confirm `flutter test` passes.
- [ ] Confirm the Android debug smoke build passes.
- [ ] Test sign-in on Android.
- [ ] Test desktop PKCE sign-in and token refresh.
- [ ] Test ordinary Trash flow.
- [ ] Test permanent-delete confirmation with a disposable test mailbox.
- [ ] Test Empty Trash confirmation with a disposable test mailbox.
- [ ] Confirm no generated APK, EXE, or ZIP files are tracked in the current source tree.

## Git history

Old release binaries and the historical OAuth secret remain reachable in older commits. A complete history rewrite is optional but disruptive and must be planned separately with clone/fork coordination. Credential rotation is required even if history is later rewritten.
