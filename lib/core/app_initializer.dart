import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_providers.dart';
import '../services/storage/secure_storage_service.dart';
import '../services/storage/install_secret_generator.dart';

import 'package:safesignal/core/services/downstream_sync_service.dart';
import 'package:safesignal/core/services/realtime_mesh_sync_service.dart';
import 'package:safesignal/core/database/repositories/outbox_repository.dart';


import 'dart:async';

class AppInitializer {
  final WidgetRef ref;
  final SecureStorageService _secureStorage;

  AppInitializer(this.ref) : _secureStorage = SecureStorageService();

  Future<void> initialize() async {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    // ------------------------------------------------------------
    // 1. Load anonymousId (device identity)
    // ------------------------------------------------------------
    final anonymousId = await _loadAnonymousId();
    appStateNotifier.setAnonymousId(anonymousId);

    // ------------------------------------------------------------
    // 2. Load or generate installSecret
    // ------------------------------------------------------------
    var installSecret = await _secureStorage.getInstallSecret();
    if (installSecret == null || installSecret.isEmpty) {
      installSecret = InstallSecretGenerator.generate();
      await _secureStorage.setInstallSecret(installSecret);
    }
    appStateNotifier.setInstallSecret(installSecret);

    // ------------------------------------------------------------
    // 3. Compute appInstanceHash
    // ------------------------------------------------------------
    final appInstanceHash = _computeAppInstanceHash(
      anonymousId: anonymousId,
      installSecret: installSecret,
    );
    appStateNotifier.setAppInstanceHash(appInstanceHash);

    // ------------------------------------------------------------
    // 4. Connectivity flags (placeholder)
    // ------------------------------------------------------------
    appStateNotifier.setOnline(true);
    appStateNotifier.setSupabaseConnected(true);

    // ------------------------------------------------------------
    // 5. DOWNSTREAM SYNC (Supabase → Device)
    // ------------------------------------------------------------
    final outboxRepo = await ref.read(outboxRepositoryProvider.future);

    final downstream = DownstreamSyncService(outboxRepo);

    // Run once at startup
    await downstream.syncFromSupabase(anonymousId);

    // Polling fallback (optional)
    Timer.periodic(const Duration(seconds: 15), (_) async {
      await downstream.syncFromSupabase(anonymousId);
    });

    // ------------------------------------------------------------
    // ⭐ 6. REALTIME SYNC (Supabase Realtime → Device)
    // ------------------------------------------------------------
    final realtime = RealtimeMeshSyncService(outboxRepo);
    realtime.start(anonymousId);

    print("AppInitializer: realtime mesh sync started");
  }

  // ------------------------------------------------------------
  // LOAD DEVICE ANONYMOUS ID
  // ------------------------------------------------------------
  Future<String> _loadAnonymousId() async {
    // TODO: replace with real Supabase Auth anonymous ID if desired
    return 'anon-placeholder';
  }

  // ------------------------------------------------------------
  // COMPUTE APP INSTANCE HASH
  // ------------------------------------------------------------
  String _computeAppInstanceHash({
    required String anonymousId,
    required String installSecret,
  }) {
    final combined = '$anonymousId::$installSecret';
    return combined.hashCode.toRadixString(16);
  }
}
