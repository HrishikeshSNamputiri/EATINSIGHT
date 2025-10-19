import '../prefs/lookup_tables.dart';

class OffSearchParams {
  final String? query;
  final String? categoryEn;
  final String? brandEn;
  final String? countryEn;
  /// Comma-separated list of fields requested from the API.
  final String fields;
  /// If true, explicitly sort by product_name when querying (Smooth parity).
  final bool preferNameSort;
  /// Normalized tokens (client fallback) - computed in the UI, not sent to OFF.
  final List<String> tokens;
  final String? languageCode; // ISO 639-1, e.g. "en"
  final String? countryCode; // ISO 3166-1 alpha-2, e.g. "in"
  final int page;
  final int pageSize;

  const OffSearchParams({
    this.query,
    this.categoryEn,
    this.brandEn,
    this.countryEn,
    this.fields = 'code,product_name,brands,quantity,image_small_url',
    this.preferNameSort = true,
    this.tokens = const <String>[],
    this.languageCode,
    this.countryCode,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toQueryMap() {
    final map = <String, dynamic>{
      // General knobs
      'json': 1,
      'search_simple': 1,
      'nocache': 1,
      // Sort by product name when user typed keywords, else stick with recency.
      'sort_by': (preferNameSort && query != null && query!.trim().isNotEmpty)
          ? 'product_name'
          : 'last_modified_t',
      // Paging
      'page': page,
      'page_size': pageSize,
      // Trim response payload
      'fields': fields,
    };
    if (query != null) {
      final q = query!.trim();
      if (q.isNotEmpty) {
        map['search_terms'] = q;
      }
    }
    if (categoryEn != null && categoryEn!.trim().isNotEmpty) {
      map['categories_tags_en'] = categoryEn!.trim();
    }
    if (brandEn != null && brandEn!.trim().isNotEmpty) {
      map['brands_tags_en'] = brandEn!.trim();
    }
    if (languageCode != null && languageCode!.trim().isNotEmpty) {
      map['lc'] = languageCode!.trim().toLowerCase();
    }
    // Priority: explicit country name > ISO code preference.
    if (countryEn != null && countryEn!.trim().isNotEmpty) {
      map['countries_tags_en'] = countryEn!.trim();
    } else if (countryCode != null && countryCode!.trim().isNotEmpty) {
      final cc = countryCode!.trim().toLowerCase();
      final match = kCountries.firstWhere(
        (e) => e.code.toLowerCase() == cc,
        orElse: () => CodeName(cc, cc),
      );
      map['countries_tags_en'] = match.name;
    }
    return map;
  }
}
