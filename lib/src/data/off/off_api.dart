import 'package:dio/dio.dart';
import '../../core/env.dart';
import '../models/product.dart';

class OffApi {
  final Dio _dio;

  OffApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.offApiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {
                'User-Agent': 'EATINSIGHT/0.0.1 (Android)',
                'Accept': 'application/json',
              },
            ));

  Future<Product?> getProduct(
    String barcode, {
    String? languageCode,
    String? countryCode,
  }) async {
    if (barcode.trim().isEmpty) return null;
    final String normalizedLanguage = (languageCode ?? '').trim().toLowerCase();
    final String normalizedCountry = (countryCode ?? '').trim().toLowerCase();
    final String languageTag = normalizedLanguage.replaceAll('-', '_');
    final String preferredLocale = Env.offPreferredLocale.toLowerCase();

    final Set<String> fields = <String>{
      'code',
      'product_name',
      'brands',
      'image_front_url',
      'image_small_url',
      'selected_images',
      'quantity',
      'ingredients_text',
      'nutrition_grades',
      'nutriments',
    };
    if (normalizedLanguage.isNotEmpty) {
      fields
        ..add('product_name_$languageTag')
        ..add('generic_name_$languageTag')
        ..add('ingredients_text_$languageTag');
    }
    if (preferredLocale.isNotEmpty && preferredLocale != languageTag) {
      fields
        ..add('product_name_${preferredLocale.replaceAll('-', '_')}')
        ..add('generic_name_${preferredLocale.replaceAll('-', '_')}')
        ..add('ingredients_text_${preferredLocale.replaceAll('-', '_')}');
    }

    final res = await _dio.get(
      '/api/v2/product/$barcode.json',
      queryParameters: <String, dynamic>{
        if (normalizedLanguage.isNotEmpty) 'lc': normalizedLanguage,
        if (normalizedCountry.isNotEmpty) 'cc': normalizedCountry,
        'fields': fields.join(','),
      },
    );
    if (res.statusCode != 200) return null;

    final data = res.data is Map ? res.data as Map : {};
    final status = data['status']?.toString();
    if (status != '1') return null;

    final p = data['product'] as Map?;
    if (p == null) return null;

    // Helpers
    String? localizedValue(Map m, String base) {
      if (languageTag.isNotEmpty) {
        final String key = '${base}_$languageTag';
        final String? value = m[key] as String?;
        if (value != null && value.trim().isNotEmpty) return value;
      }
      if (preferredLocale.isNotEmpty) {
        final String key = '${base}_${preferredLocale.replaceAll('-', '_')}';
        final String? value = m[key] as String?;
        if (value != null && value.trim().isNotEmpty) return value;
      }
      return m[base] as String?;
    }

    String? pickName(Map m) => localizedValue(m, 'product_name');

    String? firstBrand(String? brandsCsv) =>
        brandsCsv?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).firstOrNull;

    double? numValue(Map m, String key) {
      final v = m[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    List<String>? tagList(Map m, String key) {
      final v = m[key];
      if (v is List) {
        return v
            .whereType<String>()
            .map((s) => s.contains(':') ? s.split(':').last : s)
            .map((s) => s.replaceAll('_', ' '))
            .toList();
      }
      return null;
    }

    final nutr = (p['nutriments'] as Map?) ?? {};
    return Product(
      barcode: barcode,
      name: pickName(p),
      brand: firstBrand(p['brands'] as String?),
      imageUrl: p['image_front_url'] as String?,
      quantity: p['quantity'] as String?,
      ingredientsText: localizedValue(p, 'ingredients_text'),
      nutritionGrade: (p['nutrition_grades'] as String?)?.trim(), // a..e
      energyKcal100g: numValue(nutr, 'energy-kcal_100g') ?? numValue(nutr, 'energy-kcal_value'),
      fat100g: numValue(nutr, 'fat_100g'),
      saturatedFat100g: numValue(nutr, 'saturated-fat_100g'),
      carbs100g: numValue(nutr, 'carbohydrates_100g'),
      sugars100g: numValue(nutr, 'sugars_100g'),
      fiber100g: numValue(nutr, 'fiber_100g'),
      proteins100g: numValue(nutr, 'proteins_100g'),
      salt100g: numValue(nutr, 'salt_100g'),
      sodium100g: numValue(nutr, 'sodium_100g'),
      allergens: tagList(p, 'allergens_tags'),
      additives: tagList(p, 'additives_tags'),
      labels: tagList(p, 'labels_tags'),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
