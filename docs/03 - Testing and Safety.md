# 03 - Testing and Safety

CI runs on pushes and pull requests to `main`.

Checks:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`

Safety tests verify that:

- the unsubscribe parser handles standard List-Unsubscribe values;
- Empty Trash cannot execute without explicit confirmation;
- permanent deletion cannot execute without explicit confirmation.

Future tests should cover Gmail API error handling, OAuth refresh, secure-session migration, sender cleanup, and UI confirmation flows.
