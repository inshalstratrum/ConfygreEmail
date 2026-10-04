# Contributing

Contributions are welcome to the maintained Confygre Email fork.

## Before submitting changes

1. Do not add OAuth secrets, tokens, keystores, or generated release binaries.
2. Keep Gmail permissions least-privilege.
3. Preserve confirmation gates around irreversible operations.
4. Keep Android release signing separate from debug signing.
5. Run:

```bash
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

## Source layout

Flutter platform directories such as `android/`, `windows/`, `linux/`, `macos/`, `ios/`, and `web/` are source and should remain tracked. Generated build output and local secrets are ignored instead.

## Pull requests

Describe:

- what changed;
- how it was tested;
- Gmail/OAuth scope impact;
- whether the change affects destructive actions;
- release/signing impact.
