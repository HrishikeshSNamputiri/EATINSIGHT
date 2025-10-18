class Env {
  // Neutral placeholder endpoint; will be set in a later step.
  static const String baseApiUrl = 'https://example-fooddb.invalid/api';
  // Locale header example if needed later:
  static const String defaultLocale = 'en';

  /// OFF API base (production "world" server)
  static const String offApiBaseUrl = 'https://world.openfoodfacts.org';

  /// Optional: preferred locale for OFF queries (used in Step 10+)
  static const String offPreferredLocale = 'en';

  /// OFF write base — use .net for write operations
  static const String offWriteBaseUrl = 'https://world.openfoodfacts.net';

  /// User agent used for write ops
  static const String userAgent = 'EATINSIGHT/0.0.1 (Android)';
}
