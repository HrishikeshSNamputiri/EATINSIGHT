import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserList {
  final String id;
  final String name;
  final List<String> barcodes;
  final int updatedAtMillis;

  const UserList({
    required this.id,
    required this.name,
    required this.barcodes,
    required this.updatedAtMillis,
  });

  UserList copyWith({
    String? id,
    String? name,
    List<String>? barcodes,
    int? updatedAtMillis,
  }) =>
      UserList(
        id: id ?? this.id,
        name: name ?? this.name,
        barcodes: barcodes ?? this.barcodes,
        updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'barcodes': barcodes,
        'updated_at': updatedAtMillis,
      };

  factory UserList.fromJson(Map<String, dynamic> json) => UserList(
        id: json['id'] as String,
        name: json['name'] as String,
        barcodes: (json['barcodes'] as List?)?.whereType<String>().toList() ??
            const <String>[],
        updatedAtMillis: (json['updated_at'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      );
}

class ListsStore {
  static const String _listsFile = 'lists.json';
  static const String _activeFile = 'lists_active.json';

  Future<File> _file(String name) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  Future<Map<String, UserList>> loadAll() async {
    try {
      final File f = await _file(_listsFile);
      if (!await f.exists()) return <String, UserList>{};
      final String txt = await f.readAsString();
      final dynamic data = jsonDecode(txt);
      if (data is List) {
        final Map<String, UserList> map = <String, UserList>{};
        for (final dynamic entry in data) {
          if (entry is Map<String, dynamic>) {
            final UserList list = UserList.fromJson(entry);
            map[list.id] = list;
          }
        }
        return map;
      }
      return <String, UserList>{};
    } catch (_) {
      return <String, UserList>{};
    }
  }

  Future<void> saveAll(Map<String, UserList> lists) async {
    final File f = await _file(_listsFile);
    final List<Map<String, dynamic>> arr =
        lists.values.map((UserList e) => e.toJson()).toList();
    await f.writeAsString(jsonEncode(arr));
  }

  Future<String?> loadActiveId() async {
    try {
      final File f = await _file(_activeFile);
      if (!await f.exists()) return null;
      final String txt = await f.readAsString();
      final dynamic data = jsonDecode(txt);
      if (data is Map && data['active_id'] is String) {
        return data['active_id'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveId(String? id) async {
    final File f = await _file(_activeFile);
    await f.writeAsString(jsonEncode(<String, dynamic>{'active_id': id}));
  }

  Future<String> exportList(UserList list) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String safe = list.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final String fname =
        'export_${safe}_${DateTime.now().millisecondsSinceEpoch}.json';
    final File f = File('${dir.path}/$fname');
    await f.writeAsString(jsonEncode(list.toJson()));
    return f.path;
  }

  Future<UserList?> importList(String filePath) async {
    try {
      final File f = File(filePath);
      if (!await f.exists()) return null;
      final String txt = await f.readAsString();
      final dynamic data = jsonDecode(txt);
      if (data is Map<String, dynamic>) {
        final UserList src = UserList.fromJson(data);
        final String newId = DateTime.now().millisecondsSinceEpoch.toString();
        return src.copyWith(
          id: newId,
          updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
