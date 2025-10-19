import 'dart:developer' as dev;
import 'dart:ui' show PlatformDispatcher;
import 'package:dio/dio.dart';
import '../../core/env.dart';
import '../models/product.dart';
import 'off_search_params.dart';

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
  Future<List<Product>> search({required OffSearchParams params}) async {
    final q = (params.query ?? '').trim();
    final hasTagFilters = (params.categoryEn != null && params.categoryEn!.trim().isNotEmpty) ||
        (params.brandEn != null && params.brandEn!.trim().isNotEmpty) ||
        (params.countryEn != null && params.countryEn!.trim().isNotEmpty);
    if (q.isEmpty && !hasTagFilters) return <Product>[];

    final queryParams = params.toQueryMap();
    // Fallback country preference if none supplied.
    String resolvedCountryEn = '';
    final maybeCountry = queryParams['countries_tags_en'] as String?;
    if (maybeCountry == null || maybeCountry.trim().isEmpty) {
      final fallback = Env.offDefaultCountryEn.trim();
      if (fallback.isNotEmpty) {
        resolvedCountryEn = fallback;
      } else {
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
      if (resolvedCountryEn.isNotEmpty) {
        queryParams['countries_tags_en'] = resolvedCountryEn;
      }
    }
    queryParams['nocache'] = '1';
    queryParams['fields'] =
        'code,product_name,product_name_${Env.offPreferredLocale},brands,image_front_url';

    final resp = await _dio.get(
      '/api/v2/search',
      queryParameters: queryParams,
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
