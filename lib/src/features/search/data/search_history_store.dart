import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Simple JSON-backed history store mirroring Smooth's DaoStringList usage.
class SearchHistoryStore {
  SearchHistoryStore({this.maxEntries = 20});

  final int maxEntries;
  static const String _fileName = 'search_history.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<List<String>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return <String>[];
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        await file.writeAsString(jsonEncode(<String>[]));
      }
    } catch (_) {
      // Ignore IO errors in history persistence.
    }
  }

  Future<List<String>> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return load();
    }
    final entries = await load();
    entries.removeWhere(
      (element) => element.toLowerCase() == trimmed.toLowerCase(),
    );
    entries.insert(0, trimmed);
    if (entries.length > maxEntries) {
      entries.removeRange(maxEntries, entries.length);
    }
    await _save(entries);
    return entries;
  }

  Future<List<String>> remove(String query) async {
    final trimmed = query.trim();
    final entries = await load();
    entries.removeWhere(
      (element) => element.toLowerCase() == trimmed.toLowerCase(),
    );
    await _save(entries);
    return entries;
  }

  Future<void> _save(List<String> entries) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(entries));
    } catch (_) {
      // Ignore IO errors in history persistence.
    }
  }
}
