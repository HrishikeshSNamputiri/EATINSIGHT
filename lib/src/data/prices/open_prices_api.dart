import 'package:openfoodfacts/openfoodfacts.dart' as off;

/// Thin wrapper around the Open Prices API exposed by Open Food Facts.
class OpenPricesApi {
  static const int _defaultPageSize = 100;

  /// Fetches price entries for a given [barcode].
  ///
  /// The API currently exposes pagination; we request a single page (100 items),
  /// which is sufficient for surfacing latest prices inline.
  static Future<List<off.Price>> getPricesForBarcode({
    required String barcode,
    String? countryCode,
    int pageSize = _defaultPageSize,
  }) async {
    final params = off.GetPricesParameters()
      ..productCode = barcode
      ..pageSize = pageSize
      ..pageNumber = 1;
    final result = await off.OpenPricesAPIClient.getPrices(params);
    final prices = result.value.items ?? const <off.Price>[];
    if (countryCode == null || countryCode.trim().isEmpty) {
      return prices;
    }
    final cc = countryCode.trim().toUpperCase();
    return prices
        .where((price) => price.location?.countryCode?.toUpperCase() == cc)
        .toList();
  }

  /// Returns at most one price per country, selecting the most recent entry.
  static List<off.Price> latestPerCountry(Iterable<off.Price> prices) {
    final latest = <String, off.Price>{};
    for (final price in prices) {
      final country = price.location?.countryCode?.toUpperCase();
      if (country == null || country.isEmpty) continue;
      final current = latest[country];
      if (current == null || _extractDate(price).isAfter(_extractDate(current))) {
        latest[country] = price;
      }
    }
    return latest.values.toList();
  }

  static DateTime _extractDate(off.Price price) {
    return price.date;
  }
}
