import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safesignal/state/app_providers.dart';
import 'package:safesignal/services/storage/secure_storage_service.dart';
import 'package:safesignal/services/storage/install_secret_generator.dart';

class AppInitializer {
  final WidgetRef ref;
  final SecureStorageService secureStorage;

  AppInitializer(this.ref, this.secureStorage);

  Future<void> initialize() async {
    // ------------------------------------------------------------
    // 1. Initialize Supabase (moved out of main.dart)
    // ------------------------------------------------------------
    await Supabase.initialize(
      url: 'https://tkzrucdpkfgnbsinugpz.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrenJ1Y2Rwa2ZnbmJzaW51Z3B6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5MTY2NTksImV4cCI6MjA1NzQ5MjY1OX0.HQGDCN3gD_imgzbi3lM-oy3lcPJHX2hwNO_pb0kr5gU',
    );

    final supabaseClient = Supabase.instance.client;
    print("AppInitializer: Supabase initialized");

    // ------------------------------------------------------------
    // 2. Load or generate anonymousId
    // ------------------------------------------------------------
    String? anonymousId = await secureStorage.getAnonymousId();
    if (anonymousId == null || anonymousId.isEmpty) {
      anonymousId = InstallSecretGenerator.generateAnonymousId();
      await secureStorage.setAnonymousId(anonymousId);
      print("AppInitializer: Generated anonymousId=$anonymousId");
    } else {
      print("AppInitializer: Loaded anonymousId=$anonymousId");
    }

    // ------------------------------------------------------------
    // 3. Load or generate installSecret
    // ------------------------------------------------------------
    String? installSecret = await secureStorage.getInstallSecret();
    if (installSecret == null || installSecret.isEmpty) {
      installSecret = InstallSecretGenerator.generateInstallSecret();
      await secureStorage.setInstallSecret(installSecret);
      print("AppInitializer: Generated installSecret");
    } else {
      print("AppInitializer: Loaded installSecret");
    }

    // ------------------------------------------------------------
    // 4. Compute appInstanceHash
    // ------------------------------------------------------------
    final hash = InstallSecretGenerator.computeAppInstanceHash(
      anonymousId,
      installSecret,
    );

    print("AppInitializer: Computed appInstanceHash=$hash");

    // ------------------------------------------------------------
    // 5. Write values into global AppState
    // ------------------------------------------------------------
    final appStateNotifier = ref.read(appStateNotifierProvider.notifier);

    appStateNotifier.setAnonymousId(anonymousId);
    appStateNotifier.setInstallSecret(installSecret);
    appStateNotifier.setAppInstanceHash(hash);

    // Mark online by default
    appStateNotifier.setOnline(true);

    print("AppInitializer: Global AppState initialized");
  }
}

