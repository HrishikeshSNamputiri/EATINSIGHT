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
    final path = p.join(dir.path, 'prefs.json');
    debugPrint('[PrefsRepository] resolved prefs path: $path');
    return File(path);
  }

  Future<UserPrefs> load() async {
    debugPrint('[PrefsRepository] load() start');
    try {
      final f = await _file();
      final exists = await f.exists();
      debugPrint('[PrefsRepository] load() file exists? $exists');
      if (!await f.exists()) return UserPrefs.defaults;
      final txt = await f.readAsString();
      debugPrint('[PrefsRepository] load() raw contents: $txt');
      final map = jsonDecode(txt);
      if (map is Map<String, dynamic>) return UserPrefs.fromJson(map);
      return UserPrefs.defaults;
    } catch (_) {
      debugPrint('[PrefsRepository] load() exception -> returning defaults');
      return UserPrefs.defaults;
    }
  }

  Future<void> save(UserPrefs prefs) async {
    final f = await _file();
    debugPrint('[PrefsRepository] save() writing prefs: ${prefs.toString()}');
    await f.writeAsString(jsonEncode(prefs.toJson()));
    debugPrint('[PrefsRepository] save() write complete (path=${f.path})');
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
    debugPrint('[PrefsController] load() start (current prefs=${_prefs.toString()})');
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      debugPrint('[PrefsController] load() fetching from repository…');
      _prefs = await _repo.load();
      debugPrint('[PrefsController] load() repository returned: ${_prefs.toString()}');
      OffConfig.applyPrefs(_prefs);
      debugPrint(
        '[PrefsController] load() applied prefs => country=${_prefs.country}, language=${_prefs.language}, currency=${_prefs.currency}',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('[PrefsController] load() error: $_error');
    } finally {
      _loading = false;
      debugPrint(
        '[PrefsController] load() complete; notifying listeners (loading=$_loading, currency=${_prefs.currency})',
      );
      notifyListeners();
    }
  }

  Future<void> update(UserPrefs next) async {
    debugPrint('[PrefsController] update() invoked with: ${next.toString()}');
    _prefs = next;
    OffConfig.applyPrefs(_prefs);
    debugPrint(
      '[PrefsController] update() applied prefs => country=${_prefs.country}, language=${_prefs.language}, currency=${_prefs.currency}',
    );
    notifyListeners();
    try {
      await _repo.save(next);
      debugPrint('[PrefsController] update() persisted prefs successfully.');
    } catch (e) {
      debugPrint('[PrefsController] update() failed to persist prefs: $e');
      rethrow;
    }
  }
}
