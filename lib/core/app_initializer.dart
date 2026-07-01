import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../state/app_providers.dart';

class AppInitializer {
  /// IMPORTANT:
  /// Use Ref (NOT WidgetRef)
  final Ref ref;

  AppInitializer(this.ref);

  Future<void> initialize() async {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    // ------------------------------------------------------------
    // 1. Load or generate anonymousId
    // ------------------------------------------------------------
    String anonId = await _loadAnonymousId();

    if (anonId.isEmpty) {
      anonId = const Uuid().v4();
      await _saveAnonymousId(anonId);
    }

    appStateNotifier.setAnonymousId(anonId);

    // ------------------------------------------------------------
    // 2. Load or generate installSecret
    // ------------------------------------------------------------
    String installSecret = await _loadInstallSecret();

    if (installSecret.isEmpty) {
      installSecret = const Uuid().v4();
      await _saveInstallSecret(installSecret);
    }

    appStateNotifier.setInstallSecret(installSecret);

    // ------------------------------------------------------------
    // 3. Compute stable instance hash
    // ------------------------------------------------------------
    final instanceHash = _computeInstanceHash(
      anonId,
      installSecret,
    );

    appStateNotifier.setAppInstanceHash(instanceHash);

    // ------------------------------------------------------------
    // 4. Initialization complete (no async provider calls here)
    // ------------------------------------------------------------
  }

  // ============================================================
  // STORAGE
  // ============================================================

  Future<String> _loadAnonymousId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("anonymousId") ?? "";
  }

  Future<void> _saveAnonymousId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("anonymousId", id);
  }

  Future<String> _loadInstallSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("installSecret") ?? "";
  }

  Future<void> _saveInstallSecret(String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("installSecret", secret);
  }

  // ============================================================
  // HASH
  // ============================================================

  String _computeInstanceHash(String anonId, String installSecret) {
    final bytes = utf8.encode("$anonId::$installSecret");
    return sha256.convert(bytes).toString();
  }
}