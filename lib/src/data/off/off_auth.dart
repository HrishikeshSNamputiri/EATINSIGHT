import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

class OffAuth extends ChangeNotifier {
  static const _kUser = 'off_user';
  static const _kPass = 'off_pass';

  final FlutterSecureStorage _storage;
  String? _user;
  String? _pass;
  bool _initialized = false;

  OffAuth({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  bool get isReady => _initialized;
  bool get isLoggedIn => (_user?.isNotEmpty ?? false) && (_pass?.isNotEmpty ?? false);
  String? get username => _user;

  User? get offUser =>
      isLoggedIn ? User(userId: _user!, password: _pass!) : null;

  Future<void> init() async {
    _user = await _storage.read(key: _kUser);
    _pass = await _storage.read(key: _kPass);
    if (isLoggedIn) {
      OpenFoodAPIConfiguration.globalUser = offUser!;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> save(String user, String pass) async {
    await _storage.write(key: _kUser, value: user);
    await _storage.write(key: _kPass, value: pass);
    _user = user;
    _pass = pass;
    OpenFoodAPIConfiguration.globalUser = offUser!;
    notifyListeners();
  }

  Future<void> clear() async {
    await _storage.delete(key: _kUser);
    await _storage.delete(key: _kPass);
    _user = null;
    _pass = null;
    OpenFoodAPIConfiguration.globalUser = null;
    notifyListeners();
  }

  /// Validates credentials against OFF, saves on success.
  Future<LoginStatus?> verifyAndSave(String user, String pass) async {
    final loginUser = User(userId: user.trim(), password: pass);
    final LoginStatus? status = await OpenFoodAPIClient.login2(loginUser);
    if (status != null && status.successful) {
      await save(loginUser.userId, pass);
    }
    return status;
  }
}
