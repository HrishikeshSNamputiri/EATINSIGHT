import 'package:openfoodfacts/openfoodfacts.dart' as off;

import '../../core/env.dart';
import '../models/product.dart';
import '../prefs/lookup_tables.dart';
import 'off_search_params.dart';

class OffSearchResponse {
  const OffSearchResponse({
    required this.products,
    required this.totalCount,
    required this.page,
    required this.pageCount,
  });

  final List<Product> products;
  final int totalCount;
  final int page;
  final int pageCount;
}

class OffSearchApi {
  const OffSearchApi();

  Future<OffSearchResponse> search({required OffSearchParams params}) async {
    final String query = (params.query ?? '').trim();
    final bool hasFilters =
        (params.categoryEn != null && params.categoryEn!.trim().isNotEmpty) ||
            (params.brandEn != null && params.brandEn!.trim().isNotEmpty);

    if (query.isEmpty && !hasFilters) {
      return OffSearchResponse(
        products: const <Product>[],
        totalCount: 0,
        page: params.page,
        pageCount: 0,
      );
    }

    final off.OpenFoodFactsLanguage? language =
        _languageFromCode(params.languageCode ?? Env.offPreferredLocale);
    final off.OpenFoodFactsCountry? country =
        params.world ? null : _countryFromParams(params);

    final off.ProductSearchQueryConfiguration configuration =
        off.ProductSearchQueryConfiguration(
      language: language,
      country: country,
      fields: _searchFields,
      parametersList: <off.Parameter>[
        off.PageSize(size: params.pageSize),
        off.PageNumber(page: params.page),
        off.SearchTerms(terms: <String>[query]),
        const off.SortBy(option: off.SortOption.PRODUCT_NAME),
      ],
      version: off.ProductQueryVersion.v3,
    );

    final off.UriProductHelper uriHelper = _uriHelper;

    try {
      final off.SearchResult result =
          await off.OpenFoodAPIClient.searchProducts(
        off.OpenFoodAPIConfiguration.getUser(null),
        configuration,
        uriHelper: uriHelper,
      );

      final List<Product> products = <Product>[];
      final Iterable<off.Product> rawProducts =
          (result.products ?? const <off.Product>[]);
      for (final off.Product source in rawProducts) {
        final Product? mapped = _mapProduct(
          source: source,
          preferredLanguage: language,
        );
        if (mapped != null) {
          products.add(mapped);
        }
      }

      final int totalCount = result.count ?? products.length;
      final int currentPage = result.page ?? params.page;
      final int pageCount = result.pageCount ?? 0;

      return OffSearchResponse(
        products: products,
        totalCount: totalCount,
        page: currentPage,
        pageCount: pageCount,
      );
    } catch (_) {
      return OffSearchResponse(
        products: const <Product>[],
        totalCount: 0,
        page: params.page,
        pageCount: 0,
      );
    }
  }

  static Product? _mapProduct({
    required off.Product source,
    required off.OpenFoodFactsLanguage? preferredLanguage,
  }) {
    final String? barcode = source.barcode;
    if (barcode == null || barcode.trim().isEmpty) {
      return null;
    }
    final String? name = _bestLocalizedValue(
          source.productNameInLanguages,
          preferredLanguage,
        ) ??
        _fallbackNames(source, preferredLanguage);

    final String? brand = _firstNonEmpty(
      <String?>[
        source.brands,
        source.brandsTags?.join(', '),
      ],
    );

    final String? imageUrl = _firstNonEmpty(
      <String?>[
        source.imageFrontSmallUrl,
        source.imageFrontUrl,
        source.imagePackagingSmallUrl,
        source.imagePackagingUrl,
      ],
    );

    final String? ingredients = _firstNonEmpty(
      <String?>[
        _bestLocalizedValue(
          source.ingredientsTextInLanguages,
          preferredLanguage,
        ),
        source.ingredientsText,
      ],
    );

    return Product(
      barcode: barcode,
      name: name,
      brand: brand,
      imageUrl: imageUrl,
      quantity: source.quantity,
      ingredientsText: ingredients,
      nutritionGrade: source.nutriscore,
    );
  }

  static off.OpenFoodFactsLanguage? _languageFromCode(String? code) {
    final String normalized = (code ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return off.OpenFoodFactsLanguage.fromOffTag(normalized);
  }

  static off.OpenFoodFactsCountry? _countryFromParams(
    OffSearchParams params,
  ) {
    final String? explicitCode = params.countryCode?.trim();
    if (explicitCode != null && explicitCode.isNotEmpty) {
      final off.OpenFoodFactsCountry? byCode =
          off.OpenFoodFactsCountry.fromOffTag(explicitCode.toLowerCase());
      if (byCode != null) {
        return byCode;
      }
    }
    final String? countryName = params.countryEn?.trim();
    if (countryName != null && countryName.isNotEmpty) {
      final CodeName match = kCountries.firstWhere(
        (CodeName entry) =>
            entry.name.toLowerCase() == countryName.toLowerCase(),
        orElse: () => CodeName(countryName, countryName),
      );
      final off.OpenFoodFactsCountry? byName =
          off.OpenFoodFactsCountry.fromOffTag(match.code.toLowerCase());
      if (byName != null) {
        return byName;
      }
    }
    final String fallback = Env.offDefaultCountryEn.trim();
    if (fallback.isNotEmpty) {
      final CodeName matched = kCountries.firstWhere(
        (CodeName entry) => entry.name.toLowerCase() == fallback.toLowerCase(),
        orElse: () => CodeName(fallback, fallback),
      );
      return off.OpenFoodFactsCountry.fromOffTag(
        matched.code.toLowerCase(),
      );
    }
    return null;
  }

  static String? _bestLocalizedValue(
    Map<off.OpenFoodFactsLanguage, String>? values,
    off.OpenFoodFactsLanguage? preferred,
  ) {
    if (values == null || values.isEmpty) {
      return null;
    }
    if (preferred != null && values.containsKey(preferred)) {
      final String? value = values[preferred];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    for (final off.OpenFoodFactsLanguage language in values.keys) {
      final String? value = values[language];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static String? _fallbackNames(
    off.Product source,
    off.OpenFoodFactsLanguage? preferred,
  ) =>
      _firstNonEmpty(
        <String?>[
          source.productName,
          source.genericName,
          _bestLocalizedValue(source.genericNameInLanguages, preferred),
          source.lang != null
              ? _bestLocalizedValue(
                  source.productNameInLanguages,
                  source.lang,
                )
              : null,
        ],
      );

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final String? value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static final List<off.ProductField> _searchFields = <off.ProductField>[
    off.ProductField.BARCODE,
    off.ProductField.NAME,
    off.ProductField.NAME_ALL_LANGUAGES,
    off.ProductField.GENERIC_NAME,
    off.ProductField.GENERIC_NAME_ALL_LANGUAGES,
    off.ProductField.BRANDS,
    off.ProductField.QUANTITY,
    off.ProductField.NUTRISCORE,
    off.ProductField.INGREDIENTS_TEXT,
    off.ProductField.INGREDIENTS_TEXT_ALL_LANGUAGES,
    off.ProductField.ALLERGENS,
    off.ProductField.NUTRIMENTS,
    off.ProductField.IMAGE_FRONT_URL,
    off.ProductField.IMAGE_FRONT_SMALL_URL,
    off.ProductField.IMAGE_PACKAGING_URL,
    off.ProductField.IMAGE_PACKAGING_SMALL_URL,
  ];

  static off.UriProductHelper get _uriHelper {
    final Uri parsed = Uri.parse(Env.offApiBaseUrl);
    final String host = parsed.host;
    final List<String> parts = host.split('.');
    final String domain =
        parts.length >= 2 ? parts.sublist(parts.length - 2).join('.') : host;
    return off.UriProductHelper(domain: domain);
  }
}
