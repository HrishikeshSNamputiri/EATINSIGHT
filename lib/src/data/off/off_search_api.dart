import 'package:dio/dio.dart';
import '../../core/env.dart';
import '../models/product.dart';
import 'dart:developer' as dev;
import 'dart:ui' show PlatformDispatcher;

class OffSearchApi {
  final Dio _dio;
  OffSearchApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: Env.offApiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {
                  'Accept': 'application/json',
                  'User-Agent': 'EATINSIGHT/0.0.1 (Android)',
                },
              ),
            );

  /// Search products on OFF v2.
  /// Returns a list of minimal Product models for the given page (1-based).
  Future<List<Product>> search({
    required String query,
    int page = 1,
    int pageSize = 20,
    String? categoryEn,
    String? brandEn,
    String? countryEn,
  }) async {
    final q = query.trim();
    final hasTagFilters = (categoryEn != null && categoryEn.trim().isNotEmpty) ||
        (brandEn != null && brandEn.trim().isNotEmpty) ||
        (countryEn != null && countryEn.trim().isNotEmpty);
    if (q.isEmpty && !hasTagFilters) return <Product>[];

    String resolvedCountryEn = (countryEn?.trim() ?? '').isNotEmpty
        ? countryEn!.trim()
        : (Env.offDefaultCountryEn);
    if (resolvedCountryEn.isEmpty) {
      final cc = PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
      const quick = {
        'IN': 'India',
        'US': 'United States',
        'FR': 'France',
        'DE': 'Germany',
        'GB': 'United Kingdom',
      };
      resolvedCountryEn = quick[cc ?? ''] ?? '';
    }

    final params = <String, String>{
      if (q.isNotEmpty) 'search_terms': q,
      'sort_by': 'last_modified_t',
      'nocache': '1',
      'page': '$page',
      'page_size': '$pageSize',
      if (categoryEn != null && categoryEn.trim().isNotEmpty)
        'categories_tags_en': categoryEn.trim(),
      if (brandEn != null && brandEn.trim().isNotEmpty)
        'brands_tags_en': brandEn.trim(),
      if (resolvedCountryEn.isNotEmpty)
        'countries_tags_en': resolvedCountryEn,
      'fields':
          'code,product_name,product_name_${Env.offPreferredLocale},brands,image_front_url',
    };
    final resp = await _dio.get(
      '/api/v2/search',
      queryParameters: params,
    );
    try {
      dev.log('[OFF] GET \${resp.requestOptions.uri}');
    } catch (_) {}
    if (resp.statusCode != 200) return <Product>[];
    final body = resp.data;
    final prods = (body is Map && body['products'] is List)
        ? (body['products'] as List)
        : const <dynamic>[];
    return prods.whereType<Map>().map((p) {
      final String code = (p['code'] ?? '').toString();
      final String? name = (p['product_name_${Env.offPreferredLocale}'] as String?) ??
          (p['product_name'] as String?);
      final String? brand = (p['brands'] as String?)
          ?.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList()
          .firstOrNull;
      final String? img = p['image_front_url'] as String?;
      return Product(
        barcode: code,
        name: name,
        brand: brand,
        imageUrl: img,
      );
    }).toList();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
