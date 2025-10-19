import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../off/off_config.dart';
import 'user_prefs.dart';

class PrefsRepository {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'prefs.json'));
  }

  Future<UserPrefs> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return UserPrefs.defaults;
      final txt = await f.readAsString();
      final map = jsonDecode(txt);
      if (map is Map<String, dynamic>) return UserPrefs.fromJson(map);
      return UserPrefs.defaults;
    } catch (_) {
      return UserPrefs.defaults;
    }
  }

  Future<void> save(UserPrefs prefs) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(prefs.toJson()));
  }
}

class PrefsController extends ChangeNotifier {
  final PrefsRepository _repo;
  UserPrefs _prefs = UserPrefs.defaults;
  bool _loading = false;
  String? _error;

  PrefsController(this._repo);

  UserPrefs get prefs => _prefs;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _prefs = await _repo.load();
      OffConfig.applyPrefs(_prefs);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> update(UserPrefs next) async {
    _prefs = next;
    OffConfig.applyPrefs(_prefs);
    notifyListeners();
    await _repo.save(next);
  }
}
