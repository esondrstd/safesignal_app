import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ------------------------------------------------------------
  // Anonymous ID
  // ------------------------------------------------------------
  Future<String?> getAnonymousId() async {
    return await _storage.read(key: 'anonymous_id');
  }

  Future<void> setAnonymousId(String value) async {
    await _storage.write(key: 'anonymous_id', value: value);
  }

  // ------------------------------------------------------------
  // Install Secret
  // ------------------------------------------------------------
  Future<String?> getInstallSecret() async {
    return await _storage.read(key: 'install_secret');
  }

  Future<void> setInstallSecret(String value) async {
    await _storage.write(key: 'install_secret', value: value);
  }
}
