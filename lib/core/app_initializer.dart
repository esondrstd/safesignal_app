// lib/core/app_initializer.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../state/app_providers.dart';

class AppInitializer {
  final WidgetRef ref;
  AppInitializer(this.ref);

  Future<void> initialize() async {
    final appState = ref.read(appStateProvider.notifier);

    // ------------------------------------------------------------
    // 1. Load or generate anonymousId (UUID)
    // ------------------------------------------------------------
    String anonId = await _loadAnonymousId();
    if (anonId.isEmpty) {
      anonId = const Uuid().v4(); // ⭐ REAL anonymous UUID
      await _saveAnonymousId(anonId);
    }
    appState.setAnonymousId(anonId);

    // ------------------------------------------------------------
    // 2. Load or generate installSecret (random UUID)
    // ------------------------------------------------------------
    String installSecret = await _loadInstallSecret();
    if (installSecret.isEmpty) {
      installSecret = const Uuid().v4();
      await _saveInstallSecret(installSecret);
    }
    appState.setInstallSecret(installSecret);

    // ------------------------------------------------------------
    // 3. Compute appInstanceHash (stable device fingerprint)
    // ------------------------------------------------------------
    final instanceHash = _computeInstanceHash(anonId, installSecret);
    appState.setAppInstanceHash(instanceHash);

    // ------------------------------------------------------------
    // 4. App is now fully initialized
    // ------------------------------------------------------------
  }

  // ============================================================
  // PERSISTENCE HELPERS
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
  // INSTANCE HASH (SHA-256 of anonId + installSecret)
  // ============================================================
  String _computeInstanceHash(String anonId, String installSecret) {
    final bytes = utf8.encode("$anonId::$installSecret");
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

