import 'package:dio/dio.dart';

/// Minimal FX converter backed by https://api.exchangerate.host.
class FxApi {
  FxApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _dio;

  /// Converts [amount] from currency [from] to [to].
  ///
  /// Returns `null` if the request fails or the response is malformed.
  Future<double?> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    final fromUp = from.toUpperCase();
    final toUp = to.toUpperCase();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.exchangerate.host/convert',
        queryParameters: <String, dynamic>{
          'from': fromUp,
          'to': toUp,
          'amount': amount,
        },
      );
      final data = response.data;
      if (data == null) return null;
      final result = data['result'];
      if (result is num) return result.toDouble();
      return null;
    } catch (_) {
      return null;
    }
  }
}
