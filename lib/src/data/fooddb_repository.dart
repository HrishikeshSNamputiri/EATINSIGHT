import 'dart:async';
import 'off/off_api.dart';
import 'off/off_write_api.dart';
import 'off/off_auth.dart';
import 'off/off_search_api.dart';
import 'off/off_search_params.dart';
import 'models/product.dart';

/// Repository that now uses the Open Food Facts REST API (read-only in this step).
class FoodDbRepository {
  final OffApi _api = OffApi();
  final OffSearchApi _search = OffSearchApi();

  /// Fetch product by barcode from OFF (world server). Returns null if not found.
  Future<Product?> fetchByBarcode(String barcode) async {
    try {
      return await _api.getProduct(barcode);
    } catch (_) {
      // Keep errors quiet for now; Step 10 will add diagnostics & retry policy.
      return null;
    }
  }

  /// Search products (OFF v2). Page is 1-based.
  Future<List<Product>> searchProducts(
    String query, {
    int page = 1,
    String? categoryEn,
    String? brandEn,
    String? countryEn,
    String? languageCode,
    String? countryCode,
  }) async {
    try {
      final params = OffSearchParams(
        query: query,
        categoryEn: categoryEn,
        brandEn: brandEn,
        countryEn: countryEn,
        languageCode: languageCode,
        countryCode: countryCode,
        page: page,
        pageSize: 20,
      );
      final products = await _search.search(params: params);
      final trimmed = query.trim();
      if (trimmed.isEmpty) return products;
      final keyword = trimmed.toLowerCase();
      return products.where((product) {
        final name = (product.name ?? '').toLowerCase();
        final brand = (product.brand ?? '').toLowerCase();
        return name.contains(keyword) || brand.contains(keyword);
      }).toList();
    } catch (_) {
      return <Product>[];
    }
  }
}

class ProductCreateParams {
  final String barcode;
  final String? name;
  final String? brand;
  const ProductCreateParams({required this.barcode, this.name, this.brand});
}

extension FoodDbRepositoryWrite on FoodDbRepository {
  Future<OffWriteResult> createBasicProduct({
    required OffAuth auth,
    required ProductCreateParams params,
  }) async {
    final user = auth.offUser;
    if (user == null) {
      return OffWriteResult(false, 'Not logged in.');
    }
    final write = OffWriteApi();
    return write.createOrUpdate(
      user: user.userId,
      pass: user.password,
      barcode: params.barcode,
      name: params.name,
      brand: params.brand,
    );
  }
}
