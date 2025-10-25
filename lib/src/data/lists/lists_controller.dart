import 'package:flutter/foundation.dart';

import 'lists_store.dart';

class ListsController extends ChangeNotifier {
  final ListsStore _store;
  Exception? _error;
  Map<String, UserList> _lists = <String, UserList>{};
  String? _activeId;
  bool _loading = false;

  ListsController(this._store);

  bool get loading => _loading;
  String? get activeId => _activeId;
  UserList? get active => _activeId == null ? null : _lists[_activeId];
  List<UserList> get all => _lists.values.toList()
    ..sort((a, b) => b.updatedAtMillis.compareTo(a.updatedAtMillis));

  String? get error => _error?.toString();

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _lists = await _store.loadAll();
      _activeId = await _store.loadActiveId();
    } catch (e) {
      _error = Exception(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setActive(String? id) async {
    _activeId = id;
    await _store.saveActiveId(id);
    notifyListeners();
  }

  Future<void> createList(String name) async {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    _lists[id] = UserList(
      id: id,
      name: name.trim().isEmpty ? 'My list' : name.trim(),
      barcodes: const <String>[],
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await _store.saveAll(_lists);
    if (_activeId == null) {
      await setActive(id);
    } else {
      notifyListeners();
    }
  }

  Future<void> renameList(String id, String name) async {
    final UserList? existing = _lists[id];
    if (existing == null) return;
    _lists[id] = existing.copyWith(
      name: name.trim().isEmpty ? existing.name : name.trim(),
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await _store.saveAll(_lists);
    notifyListeners();
  }

  Future<void> deleteList(String id) async {
    _lists.remove(id);
    if (_activeId == id) {
      _activeId = _lists.isEmpty ? null : _lists.values.first.id;
      await _store.saveActiveId(_activeId);
    }
    await _store.saveAll(_lists);
    notifyListeners();
  }

  Future<bool> addBarcode(String barcode) async {
    final UserList? current = active;
    if (current == null) return false;
    if (current.barcodes.contains(barcode)) return true;
    final UserList next = current.copyWith(
      barcodes: <String>[...current.barcodes, barcode],
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    _lists[current.id] = next;
    await _store.saveAll(_lists);
    notifyListeners();
    return true;
  }

  Future<void> removeBarcode(String barcode) async {
    final UserList? current = active;
    if (current == null) return;
    final UserList next = current.copyWith(
      barcodes: current.barcodes.where((b) => b != barcode).toList(),
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    _lists[current.id] = next;
    await _store.saveAll(_lists);
    notifyListeners();
  }

  Future<String?> exportListById(String id) async {
    final UserList? list = _lists[id];
    if (list == null) return null;
    return _store.exportList(list);
  }

  Future<bool> importFromPath(String filePath) async {
    final UserList? imported = await _store.importList(filePath);
    if (imported == null) return false;
    _lists[imported.id] = imported;
    await _store.saveAll(_lists);
    notifyListeners();
    return true;
  }
}
