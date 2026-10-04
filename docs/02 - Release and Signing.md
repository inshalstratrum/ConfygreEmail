# 02 - Release and Signing

## Android signing

Release builds must use one stable signing certificate. The project no longer falls back to the Android debug signing key for release builds.

GitHub Actions expects these repository secrets:

1. `ANDROID_KEYSTORE_BASE64`
2. `ANDROID_KEY_ALIAS`
3. `ANDROID_KEY_PASSWORD`
4. `ANDROID_STORE_PASSWORD`

A release is built from a version tag such as `v1.1.0` and published through GitHub Releases.

## Source repository hygiene

Generated APK, EXE, and ZIP artifacts do not belong in the source tree. They are distributed through GitHub Releases.

The `release/` directory and common binary artifact extensions are ignored by Git.
