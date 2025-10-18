import 'package:openfoodfacts/openfoodfacts.dart';

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
}
