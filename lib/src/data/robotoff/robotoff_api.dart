import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/env.dart';

class RoboQuestion {
  final String id;
  final String question;
  final String? sourceImageUrl;
  RoboQuestion({required this.id, required this.question, this.sourceImageUrl});
}

class RobotoffApi {
  RobotoffApi({Dio? dio})
      : _dioRobo = dio ??
            Dio(
              BaseOptions(
                baseUrl: Env.offApiBaseUrl.replaceFirst('openfoodfacts.org', 'robotoff.openfoodfacts.org'),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {'Accept': 'application/json'},
              ),
            );

  final Dio _dioRobo;

  /// Fetch top questions for a barcode.
  Future<List<RoboQuestion>> fetchQuestions(String barcode,
      {String lang = 'en', int count = 5}) async {
    final res = await _dioRobo.get(
      '/api/v1/questions',
      queryParameters: {'barcode': barcode, 'lang': lang, 'count': count},
    );
    final data = res.data is Map ? res.data['questions'] : null;
    if (data is List) {
      return data.map((q) {
        final id = q['insight_id']?.toString() ?? q['id']?.toString() ?? '';
        final text = (q['question'] ?? q['value'] ?? q['text'] ?? '').toString();
        final img = (q['source_image_url'] ?? q['image_url'] ?? q['imageUrl'])?.toString();
        return RoboQuestion(id: id, question: text, sourceImageUrl: img);
      }).where((e) => e.id.isNotEmpty && e.question.isNotEmpty).toList();
    }
    return <RoboQuestion>[];
  }

  Future<void> answerQuestion({
    required String insightId,
    required bool value,
    required String username,
    required String password,
  }) async {
    await _dioRobo.post(
      '/api/v1/insights/$insightId/annotations',
      data: jsonEncode({
        'value': value ? 1 : 0,
        'annotation': value ? 'yes' : 'no',
        'username': username,
        'password': password,
      }),
      options: Options(headers: const {'Content-Type': 'application/json'}),
    );
  }
}
