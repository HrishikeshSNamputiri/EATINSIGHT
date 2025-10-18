import 'package:dio/dio.dart';
import '../../core/env.dart';
import '../models/product.dart';

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
  }) async {
    final q = query.trim();
    if (q.isEmpty || q.length < 2) return <Product>[];
    final resp = await _dio.get(
      '/api/v2/search',
      queryParameters: {
        'search_terms': q,
        'fields':
            'code,product_name,product_name_${Env.offPreferredLocale},brands,image_front_url',
        'page': page,
        'page_size': pageSize,
        'sort_by': 'unique_scans_n', // reasonable default
      },
    );
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
