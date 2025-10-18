import 'package:dio/dio.dart';
import '../../core/env.dart';

class OffWriteResult {
  final bool ok;
  final String message;
  OffWriteResult(this.ok, this.message);
}

class OffWriteApi {
  final Dio _dio;

  OffWriteApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.offWriteBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 25),
              headers: {
                'User-Agent': Env.userAgent,
                'Accept': 'application/json',
                'Content-Type': Headers.formUrlEncodedContentType,
              },
            ));

  /// Create or update a product with minimal fields.
  Future<OffWriteResult> createOrUpdate({
    required String user,
    required String pass,
    required String barcode,
    String? name,
    String? brand,
  }) async {
    final data = <String, dynamic>{
      'code': barcode,
      'user_id': user,
      'password': pass,
      'json': '1',
      'comment': 'Added via EATINSIGHT',
      if (name != null && name.trim().isNotEmpty) 'product_name': name.trim(),
      if (brand != null && brand.trim().isNotEmpty) 'brands': brand.trim(),
    };
    try {
      final res = await _dio.post('/cgi/product_jqm2.pl', data: data);
      if (res.statusCode != 200) {
        return OffWriteResult(false, 'HTTP ${res.statusCode}');
      }
      final body = res.data;
      final status = (body is Map) ? body['status'] : null;
      final msg = (body is Map) ? (body['status_verbose']?.toString() ?? 'OK') : 'OK';
      return OffWriteResult(status == 1 || status == '1', msg);
    } catch (e) {
      return OffWriteResult(false, e.toString());
    }
  }
}
