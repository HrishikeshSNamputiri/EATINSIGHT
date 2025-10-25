import 'package:openfoodfacts/openfoodfacts.dart';

import '../prefs/user_prefs.dart';

class OffConfig {
  static void init() {
    // Identify our app to OFF (recommended)
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'EATINSIGHT',
      url: 'https://example.com/eatinsight',
    );

    // Optional defaults; adjust later if you want
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ENGLISH,
    ];
    // Comment this line in if you want to default a country context:
    // OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.WORLD;
  }

  static void applyPrefs(UserPrefs prefs) {
    final String? languageCode = prefs.language?.trim().toLowerCase();
    final OpenFoodFactsLanguage resolvedLanguage =
        OpenFoodFactsLanguage.fromOffTag(languageCode) ??
            OpenFoodFactsLanguage.ENGLISH;
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      resolvedLanguage,
    ];
    final String? countryCode = prefs.country?.trim().toLowerCase();
    OpenFoodAPIConfiguration.globalCountry =
        OpenFoodFactsCountry.fromOffTag(countryCode ?? '');
  }
}
