import 'dart:convert';
import 'package:crypto/crypto.dart';

class InstallSecretGenerator {
  /// Generates a simple anonymous ID.
  /// You can replace this with a stronger generator later.
  static String generateAnonymousId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Generates a random install secret.
  /// Replace with secure random generation when ready.
  static String generateInstallSecret() {
    final bytes = List<int>.generate(32, (i) => (i * 37) % 256);
    return base64Url.encode(bytes);
  }

  /// REQUIRED BY AppInitializer
  /// Computes a stable hash for this app installation using:
  /// anonymousId + ":" + installSecret
  static String computeAppInstanceHash(String anonymousId, String installSecret) {
    final input = '$anonymousId:$installSecret';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

