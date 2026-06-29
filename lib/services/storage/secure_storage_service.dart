//We want installSecret to live in secure storage, not in random prefs.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _installSecretKey = 'install_secret';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getInstallSecret() async {
    return _storage.read(key: _installSecretKey);
  }

  Future<void> setInstallSecret(String secret) async {
    await _storage.write(key: _installSecretKey, value: secret);
  }
}
