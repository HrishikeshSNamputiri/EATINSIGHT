import 'dart:async';
import 'off/off_api.dart';
import 'off/off_write_api.dart';
import 'off/off_auth.dart';
import 'off/off_search_api.dart';
import 'off/off_search_params.dart';
import '../core/env.dart';
import 'models/product.dart';

/// Repository that now uses the Open Food Facts REST API (read-only in this step).
class FoodDbRepository {
  final OffApi _api = OffApi();
  final OffSearchApi _search = OffSearchApi();

  /// Fetch product by barcode from OFF (world server). Returns null if not found.
  Future<Product?> fetchByBarcode(
    String barcode, {
    String? languageCode,
    String? countryCode,
  }) async {
    try {
      return await _api.getProduct(
        barcode,
        languageCode: languageCode,
        countryCode: countryCode,
      );
    } catch (_) {
      // Keep errors quiet for now; Step 10 will add diagnostics & retry policy.
      return null;
    }
  }

  /// Search products (OFF v2). Page is 1-based.
  Future<OffSearchResponse> searchProducts(
    String query, {
    int page = 1,
    String? languageCode,
    String? countryCode,
    bool world = false,
  }) async {
    try {
      final preferredLocale = Env.offPreferredLocale.toLowerCase();
      final normalizedLanguage = languageCode?.trim().toLowerCase();
      final fields = <String>{
        'code',
        'product_name',
        'generic_name',
        'brands',
        'image_small_url',
        'image_front_small_url',
        'selected_images',
      };
      if (preferredLocale.isNotEmpty) {
        fields
          ..add('product_name_$preferredLocale')
          ..add('generic_name_$preferredLocale');
      }
      if (normalizedLanguage != null && normalizedLanguage.isNotEmpty) {
        fields
          ..add('product_name_$normalizedLanguage')
          ..add('generic_name_$normalizedLanguage');
      }
      final params = OffSearchParams(
        query: query,
        languageCode: languageCode,
        countryCode: countryCode,
        preferNameSort: true,
        page: page,
        pageSize: 20,
        fields: fields.join(','),
        world: world,
      );
      return await _search.search(params: params);
    } catch (_) {
      return const OffSearchResponse(
        products: <Product>[],
        totalCount: 0,
        page: 1,
        pageCount: 0,
      );
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
