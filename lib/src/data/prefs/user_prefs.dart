import 'dart:convert';

class UserPrefs {
  final String? country;     // e.g., "in", "fr"
  final String? language;    // e.g., "en"
  final String? currency;    // e.g., "INR"
  final bool haptics;
  final bool scannerVibration;
  final bool keepScreenOn;

  const UserPrefs({
    this.country,
    this.language,
    this.currency,
    this.haptics = true,
    this.scannerVibration = true,
    this.keepScreenOn = false,
  });

  static const defaults = UserPrefs();

  UserPrefs copyWith({
    String? country,
    String? language,
    String? currency,
    bool? haptics,
    bool? scannerVibration,
    bool? keepScreenOn,
  }) {
    return UserPrefs(
      country: country ?? this.country,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      haptics: haptics ?? this.haptics,
      scannerVibration: scannerVibration ?? this.scannerVibration,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }

  Map<String, dynamic> toJson() => {
    'country': country,
    'language': language,
    'currency': currency,
    'haptics': haptics,
    'scannerVibration': scannerVibration,
    'keepScreenOn': keepScreenOn,
  };

  factory UserPrefs.fromJson(Map<String, dynamic> json) => UserPrefs(
    country: json['country'] as String?,
    language: json['language'] as String?,
    currency: json['currency'] as String?,
    haptics: (json['haptics'] as bool?) ?? true,
    scannerVibration: (json['scannerVibration'] as bool?) ?? true,
    keepScreenOn: (json['keepScreenOn'] as bool?) ?? false,
  );

  @override
  String toString() => jsonEncode(toJson());
}
