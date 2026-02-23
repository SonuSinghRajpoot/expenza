/// Build timestamp injected at build time.
/// Example: flutter build apk --dart-define=BUILD_TIMESTAMP=2026-02-23 14:30
const String buildTimestamp = String.fromEnvironment(
  'BUILD_TIMESTAMP',
  defaultValue: '',
);
